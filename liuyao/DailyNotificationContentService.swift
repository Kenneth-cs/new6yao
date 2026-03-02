import Foundation

// ============================================================
// MARK: - 每日推送文案服务（方案C：本地文案库兜底 + AI个性化）
// ============================================================

final class DailyNotificationContentService {
    static let shared = DailyNotificationContentService()
    private init() {}

    private let ud = UserDefaults.standard

    // UserDefaults keys
    private let keyLastGenDate   = "notif_last_gen_date"
    private let keyCachedTitle   = "notif_cached_title"
    private let keyCachedBody    = "notif_cached_body"

    // ── 缓存读写 ────────────────────────────────────────────────

    var cachedTitle: String {
        ud.string(forKey: keyCachedTitle) ?? localFallback().title
    }
    var cachedBody: String {
        ud.string(forKey: keyCachedBody) ?? localFallback().body
    }

    private func saveCache(title: String, body: String) {
        ud.set(title, forKey: keyCachedTitle)
        ud.set(body,  forKey: keyCachedBody)
        ud.set(Date(), forKey: keyLastGenDate)
    }

    /// 今天是否已经生成过
    private var generatedToday: Bool {
        guard let last = ud.object(forKey: keyLastGenDate) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // ============================================================
    // MARK: - 主入口：按需刷新
    // ============================================================

    /// App 启动时调用。若今日已生成则直接返回缓存；否则先写本地文案，再异步 AI 更新。
    func refreshIfNeeded() {
        guard !generatedToday else { return }

        // Step 1：先用本地文案即时更新通知（保证即使 AI 失败也有新内容）
        let local = localFallback()
        saveCache(title: local.title, body: local.body)
        NotificationManager.shared.updateContent(title: local.title, body: local.body)

        // Step 2：异步调用 AI 生成更好的文案
        Task {
            if let ai = await generateAIContent() {
                await MainActor.run {
                    saveCache(title: ai.title, body: ai.body)
                    NotificationManager.shared.updateContent(title: ai.title, body: ai.body)
                }
            }
        }
    }

    // ============================================================
    // MARK: - 方案 A：AI 生成文案
    // ============================================================

    private func generateAIContent() async -> (title: String, body: String)? {
        let calendar = Calendar.current
        let now = Date()
        let weekdayNames = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekday = weekdayNames[calendar.component(.weekday, from: now)]

        // 农历 + 节气
        let comp = calendar.dateComponents([.year, .month, .day], from: now)
        let solar = Solar.fromYmdHms(
            year: comp.year ?? 2025,
            month: comp.month ?? 1,
            day: comp.day ?? 1
        )
        let lunar = solar.lunar
        let lunarDateStr = "\(lunar.yearInGanZhi)年 \(lunar.monthInChinese)月\(lunar.dayInChinese)"
        let jieQiStr = lunar.jieQi.isEmpty ? "无节气" : lunar.jieQi

        // 用户五行命局
        let portrait = BirthInfoStore.shared.loadPortrait()
        let elementStr: String
        if let p = portrait {
            elementStr = "日主\(p.dayMaster)（\(p.dayMasterElement.rawValue)）"
        } else {
            elementStr = "未知"
        }

        // 最近关注话题（五行决策优先，次之取历史记录场景）
        let recentTopic: String
        if let lastMatrix = MatrixHistoryStore.shared.loadAll().first {
            recentTopic = lastMatrix.scenario
        } else {
            recentTopic = "通用"
        }

        let prompt = """
        你是一个中式命理文案师，专门为移动 App 撰写每日推送通知。
        请根据下方用户信息，生成一条今日推送文案。

        用户信息：
        - 今日：\(weekday)，农历 \(lunarDateStr)
        - 当前节气：\(jieQiStr)
        - 命局：\(elementStr)
        - 最近关注：\(recentTopic)

        要求：
        1. 标题：≤12个字，含一个emoji，有感染力
        2. 正文：≤45个字，温和有力，融入今日节气或五行能量，与最近关注自然衔接
        3. 不要生硬的"你的命局"字样，要像老友提醒
        4. 输出格式（只输出JSON，不要其他内容）：
           {"title":"...","body":"..."}
        """

        do {
            let raw = try await AIService.shared.getSimpleAIResponse(prompt: prompt)
            // 提取 JSON
            let jsonStr: String
            if let start = raw.range(of: "{"), let end = raw.range(of: "}", options: .backwards),
               start.lowerBound <= end.lowerBound {
                jsonStr = String(raw[start.lowerBound...end.lowerBound])
            } else {
                jsonStr = raw
            }
            if let data = jsonStr.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let t = obj["title"], let b = obj["body"],
               !t.isEmpty, !b.isEmpty {
                return (title: t, body: b)
            }
        } catch {
            print("🔔 AI推送文案生成失败，使用本地文案: \(error)")
        }
        return nil
    }

    // ============================================================
    // MARK: - 方案 B：本地文案库（兜底）
    // ============================================================

    struct NotifContent { let title: String; let body: String }

    func localFallback() -> NotifContent {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now) // 1=Sun, 7=Sat
        let month   = calendar.component(.month,   from: now)

        // 获取节气
        let comp  = calendar.dateComponents([.year, .month, .day], from: now)
        let solar = Solar.fromYmdHms(year: comp.year ?? 2025, month: comp.month ?? 1, day: comp.day ?? 1)
        let jieQi = solar.lunar.jieQi

        // 获取用户五行
        let portrait = BirthInfoStore.shared.loadPortrait()
        let element = portrait?.dayMasterElement

        // 最近关注话题
        let recentTopic = MatrixHistoryStore.shared.loadAll().first?.scenario ?? ""

        // 候选文案池：按优先级打分后选最佳
        let candidates = elementBank(element: element)
            + seasonBank(month: month, jieQi: jieQi)
            + weekdayBank(weekday: weekday)
            + topicBank(topic: recentTopic)
            + universalBank()

        // 基于日期做确定性随机（同一天总选同一条）
        let seed = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let index = seed % candidates.count
        return candidates[index]
    }

    // ── 五行命局专属文案 ────────────────────────────────────────

    private func elementBank(element: FiveElement?) -> [NotifContent] {
        switch element {
        case .wood:
            return [
                NotifContent(title: "🌿 木气当令", body: "春木生发，正是布局好时机。今日适合主动出击，把想法落地。"),
                NotifContent(title: "🌱 生机勃发", body: "木主生长，遇阻也是在积蓄力量。今日向前一步，胜过原地等待。"),
                NotifContent(title: "🌳 根深叶茂", body: "木命之人善于谋划，今日头脑清晰，重要决策可以推进了。")
            ]
        case .fire:
            return [
                NotifContent(title: "🔥 火气旺盛", body: "火主热情，今日表达欲强。借此能量去沟通那件一直搁置的事。"),
                NotifContent(title: "✨ 灵感闪现", body: "火命直觉敏锐，今日出现的想法值得认真记录下来。"),
                NotifContent(title: "☀️ 光芒四射", body: "火能照亮暗处，今日适合展示自己，不必低调。")
            ]
        case .earth:
            return [
                NotifContent(title: "🏔 厚土承载", body: "土主稳健，今日适合把手头事情做扎实，不急于求成。"),
                NotifContent(title: "🌾 沉淀积累", body: "土命踏实，细水长流胜过急功近利。今日专注手头一件事。"),
                NotifContent(title: "🏡 稳中有进", body: "今日土气加持，处理家庭或财务事务特别得心应手。")
            ]
        case .metal:
            return [
                NotifContent(title: "⚔️ 金气清明", body: "金主决断，今日思路锐利。那个悬而未决的选择，可以今天拍板。"),
                NotifContent(title: "💎 精准出击", body: "金命行事干脆，今日效率极高。清单上最难的一项，先做它。"),
                NotifContent(title: "🗡 利器当锋", body: "金气旺时，谈判和表达最为有力。今日开口，胜算更大。")
            ]
        case .water:
            return [
                NotifContent(title: "💧 水润万物", body: "水主智慧与流动，今日思维活跃。静下来感受直觉，答案已在其中。"),
                NotifContent(title: "🌊 顺势而为", body: "水命随机应变，今日遇到变数别慌，顺着走往往柳暗花明。"),
                NotifContent(title: "🔮 深水藏珍", body: "今日适合深度思考，水命之人今日洞察力尤佳，值得独处一会儿。")
            ]
        case nil:
            return []
        }
    }

    // ── 节气/季节专属文案 ───────────────────────────────────────

    private func seasonBank(month: Int, jieQi: String) -> [NotifContent] {
        // 精确节气匹配
        let jieQiMessages: [String: NotifContent] = [
            "立春": NotifContent(title: "🌸 立春到了", body: "一年之计在于春，万物复苏正当时。今日定下三个小目标，春天会给你答案。"),
            "雨水": NotifContent(title: "🌧 雨水润生机", body: "春雨贵如油，今日适合滋养计划，给近期目标加一把水。"),
            "惊蛰": NotifContent(title: "⚡️ 惊蛰启新程", body: "雷声惊百虫，今日是行动的号角。那件一直没开始的事，今天破土。"),
            "春分": NotifContent(title: "☯️ 春分阴阳平", body: "阴阳各半，今日适合审视平衡：工作与休息、付出与获取，哪边需要加一加？"),
            "清明": NotifContent(title: "🌿 清明气清朗", body: "天清地明，今日头脑尤为清醒。整理思绪，把模糊的计划说清楚。"),
            "谷雨": NotifContent(title: "🌾 谷雨百谷生", body: "万物生长期，今日种下的努力，秋天可期有收获。"),
            "立夏": NotifContent(title: "☀️ 立夏热力来", body: "夏火渐旺，今日精力充沛。趁热打铁，推进一个停滞已久的项目。"),
            "小满": NotifContent(title: "🌱 小满初成熟", body: "果实渐丰未全熟，今日检视手头工作，查缺补漏，别急着收割。"),
            "芒种": NotifContent(title: "🌾 芒种正当时", body: "忙碌是芒种的主旋律，今日全力以赴，身体也别忘了补水。"),
            "夏至": NotifContent(title: "🌞 夏至阳气极", body: "一年中白昼最长，今日能量最足。把最重要的事排在今天。"),
            "小暑": NotifContent(title: "🌡 小暑防燥热", body: "暑气渐旺，心静自然凉。今日遇事不急，先深呼吸再行动。"),
            "大暑": NotifContent(title: "🔥 大暑厚积能", body: "烈日考验耐力，今日保持定力，再熬一熬，秋收不远了。"),
            "立秋": NotifContent(title: "🍂 立秋收敛时", body: "秋气已至，该放手的放手，该收获的着手收割。今日适合做减法。"),
            "处暑": NotifContent(title: "🌬 处暑暑退去", body: "暑热渐消，今日精力回升。把夏天拖延的计划，秋天补上来。"),
            "白露": NotifContent(title: "💧 白露凝清气", body: "清晨露水折射光芒，今日细心观察，往往在小处发现大机遇。"),
            "秋分": NotifContent(title: "🍁 秋分收硕果", body: "收获时节，今日盘点成果，也要为下一轮播种做好准备。"),
            "寒露": NotifContent(title: "❄️ 寒露金气旺", body: "金秋寒露，决断力最强。今日适合做那个一直犹豫的决定。"),
            "霜降": NotifContent(title: "🌫 霜降藏能量", body: "万物内敛，今日适合内省：哪件事值得坚持，哪件事可以放下？"),
            "立冬": NotifContent(title: "❄️ 立冬藏元气", body: "冬藏之始，今日为自己充电：早睡、少消耗、多积蓄。"),
            "小雪": NotifContent(title: "🌨 小雪宜静思", body: "雪落无声，今日适合安静思考：年末目标完成了多少？"),
            "大雪": NotifContent(title: "⛄️ 大雪厚积蓄", body: "积雪越深，春天能量越足。今日把年度总结写下来，为新年蓄力。"),
            "冬至": NotifContent(title: "☯️ 冬至一阳生", body: "阴极阳生，今日是转折点。给自己一个新的承诺，从今天开始。"),
            "小寒": NotifContent(title: "🥶 小寒护阳气", body: "寒冬护阳为本，今日保持好心态，阳气足才能迎来开春好运。"),
            "大寒": NotifContent(title: "❄️ 大寒末冬时", body: "冬将尽，春将至，今日播下的心愿，立春后便要发芽了。")
        ]
        if let match = jieQiMessages[jieQi] { return [match] }

        // 季节兜底
        switch month {
        case 3...5:
            return [NotifContent(title: "🌸 春日气场佳", body: "木气生发，今日适合启动新计划、结交新朋友，顺势而上。")]
        case 6...8:
            return [NotifContent(title: "☀️ 夏火旺精力", body: "火气旺盛，今日执行力强，趁热把重要任务推进到下一个阶段。")]
        case 9...11:
            return [NotifContent(title: "🍂 秋金利决断", body: "金气旺时，思维清晰，今日做决定特别果断，抓住时机。")]
        default:
            return [NotifContent(title: "❄️ 冬水养智慧", body: "水气藏纳，今日适合深度思考和休养，积蓄力量迎接新年。")]
        }
    }

    // ── 星期专属文案 ────────────────────────────────────────────

    private func weekdayBank(weekday: Int) -> [NotifContent] {
        switch weekday {
        case 2: // 周一
            return [NotifContent(title: "🌅 周一新气象", body: "新的一周，带着清醒开始。今日摇一摇，看看本周的能量走向。")]
        case 4: // 周三
            return [NotifContent(title: "⚡️ 周三爬坡时", body: "周中疲倦是正常的，但今日也是能量回升的节点。坚持，就快见顶了。")]
        case 6: // 周五
            return [NotifContent(title: "🎯 周五收尾日", body: "今天完成一件本周最重要的事，周末才能真正放松。")]
        case 7, 1: // 周六、周日
            return [NotifContent(title: "☀️ 周末好时光", body: "休息也是积蓄，今日不妨放下手机，为下周的自己充满电。")]
        default:
            return []
        }
    }

    // ── 话题相关文案 ────────────────────────────────────────────

    private func topicBank(topic: String) -> [NotifContent] {
        guard !topic.isEmpty else { return [] }
        let t = topic.lowercased()
        if t.contains("感情") || t.contains("爱情") || t.contains("婚姻") {
            return [NotifContent(title: "💕 情感能量日", body: "感情的事急不得，今日静心感受对方，比说任何话都更有力量。")]
        }
        if t.contains("事业") || t.contains("工作") || t.contains("职业") {
            return [NotifContent(title: "💼 事业运势到", body: "职场风水轮流转，今日贵人方位偏东南，主动出击效果加倍。")]
        }
        if t.contains("投资") || t.contains("理财") || t.contains("财") {
            return [NotifContent(title: "💰 财运观察日", body: "财来有时，今日适合复盘财务，而非追涨。冷静分析胜过冲动下注。")]
        }
        if t.contains("健康") || t.contains("身体") {
            return [NotifContent(title: "🌿 健康能量日", body: "身体是本钱，今日注意休息与补水，好状态才是最大的运势。")]
        }
        return []
    }

    // ── 通用文案（无任何匹配时的最终兜底）──────────────────────

    private func universalBank() -> [NotifContent] {
        [
            NotifContent(title: "🌅 早安，觉察时刻", body: "与其等待运势，不如看清现在。摇一摇，今日方向更清晰。"),
            NotifContent(title: "💡 今日问一问", body: "答案不在卦象里，而在你心里。让六爻做你的镜子，照见本心。"),
            NotifContent(title: "☯️ 顺势而为", body: "不在逆境中消耗，不在顺境中迷失。理解当下，才能更好地出发。"),
            NotifContent(title: "🎯 遇事不决时", body: "困惑的尽头是行动。摇一摇，让古老智慧为你厘清方向。"),
            NotifContent(title: "🧘 此刻，向内看", body: "外部世界喧嚣，内心需要安宁。每日一卦，与直觉对话。"),
            NotifContent(title: "✨ 相信直觉", body: "所有的卦象都是内心的投射。摇一摇，找回你内在的确定性。"),
            NotifContent(title: "🌙 夜晚复盘时", body: "今日有什么还没想清楚？摇一卦，给迷雾里的自己一盏灯。"),
            NotifContent(title: "🔮 五行能量今日", body: "每天的能量都在流动，今日适合留意身边微小的变化与信号。")
        ]
    }
}
