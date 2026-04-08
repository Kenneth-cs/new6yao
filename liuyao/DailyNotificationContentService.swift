import Foundation

// ============================================================
// MARK: - 每日推送文案服务
// 策略：用户每天首次打开 App 时
//   1. AI 异步生成「明天」文案，调度明天的一次性通知
//   2. 用预设库为「后天到第7天」各调度一条一次性通知
//   3. 每天只调用一次 AI（keyed by date），多次进出 App 不重复请求
// ============================================================

final class DailyNotificationContentService {
    static let shared = DailyNotificationContentService()
    private init() {}

    private let ud = UserDefaults.standard
    private let keyLastScheduleDate = "notif_last_schedule_date"  // 最近一次预调度的日期（yyyyMMdd）
    private let keyLastAIDate       = "notif_last_ai_date"        // 最近一次成功调用 AI 的日期
    private let keyCachedTitle      = "notif_cached_title"        // 设置页预览用
    private let keyCachedBody       = "notif_cached_body"

    // ── 预览用缓存（供 NotificationSettingsView 读取） ──────────
    var cachedTitle: String { ud.string(forKey: keyCachedTitle) ?? localContent(for: Date()).title }
    var cachedBody:  String { ud.string(forKey: keyCachedBody)  ?? localContent(for: Date()).body  }

    // ── 今天是否已完成预调度 ────────────────────────────────────
    private var scheduledToday: Bool {
        ud.string(forKey: keyLastScheduleDate) == todayKey()
    }

    // ── 今天是否已调用过 AI ─────────────────────────────────────
    private var aiCalledToday: Bool {
        ud.string(forKey: keyLastAIDate) == todayKey()
    }

    private func todayKey() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd"
        return fmt.string(from: Date())
    }

    private func dateKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd"
        return fmt.string(from: date)
    }

    // ============================================================
    // MARK: - 主入口：App 进入前台时调用
    // ============================================================

    /// MainTabView.onAppear 调用。每天首次进入执行完整预调度流程。
    func refreshIfNeeded() {
        guard !scheduledToday else { return }

        let calendar = Calendar.current
        let today    = Date()

        // 取消所有旧的 pending 通知后重新调度
        NotificationManager.shared.cancelAllDailyReminders()

        // 先用预设库为未来 7 天全部调度（保底）
        for offset in 1...7 {
            guard let targetDate = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let content = localContent(for: targetDate)
            NotificationManager.shared.scheduleOnceFor(date: targetDate, title: content.title, body: content.body)
        }

        // 记录今天已调度，供预览用也更新一下缓存（明天的文案）
        ud.set(todayKey(), forKey: keyLastScheduleDate)
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            let preview = localContent(for: tomorrow)
            ud.set(preview.title, forKey: keyCachedTitle)
            ud.set(preview.body,  forKey: keyCachedBody)
        }

        // 异步 AI：每天只调一次，生成「明天」的文案，成功后替换明天那条
        guard !aiCalledToday else { return }
        ud.set(todayKey(), forKey: keyLastAIDate)   // 先标记，防止并发多次触发

        Task {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
                  let ai = await generateAIContent(for: tomorrow) else { return }
            await MainActor.run {
                // 用 AI 文案替换明天那条通知
                NotificationManager.shared.scheduleOnceFor(date: tomorrow, title: ai.title, body: ai.body)
                // 同步更新预览缓存
                ud.set(ai.title, forKey: keyCachedTitle)
                ud.set(ai.body,  forKey: keyCachedBody)
                print("🤖 AI 文案已更新明天通知: \(ai.title)")
            }
        }
    }

    // ============================================================
    // MARK: - AI 生成文案（针对指定日期）
    // ============================================================

    private func generateAIContent(for date: Date) async -> (title: String, body: String)? {
        let calendar = Calendar.current
        let weekdayNames = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekday = weekdayNames[calendar.component(.weekday, from: date)]

        let comp  = calendar.dateComponents([.year, .month, .day], from: date)
        let solar = Solar.fromYmdHms(year: comp.year ?? 2025, month: comp.month ?? 1, day: comp.day ?? 1)
        let lunar = solar.lunar
        let lunarDateStr = "\(lunar.yearInGanZhi)年 \(lunar.monthInChinese)月\(lunar.dayInChinese)"
        let jieQiStr = lunar.jieQi.isEmpty ? "无节气" : lunar.jieQi

        let portrait = BirthInfoStore.shared.loadPortrait()
        let elementStr: String
        if let p = portrait {
            elementStr = "日主\(p.dayMaster)（\(p.dayMasterElement.rawValue)）"
        } else {
            elementStr = "未知"
        }

        let recentTopic: String
        if let lastMatrix = MatrixHistoryStore.shared.loadAll().first {
            recentTopic = lastMatrix.scenario
        } else {
            recentTopic = "通用"
        }

        let prompt = """
        你是一个中式命理文案师，专门为移动 App 撰写每日推送通知。
        请根据下方信息，生成一条推送文案（将在明天推送给用户）。

        目标日期信息：
        - 日期：\(weekday)，农历 \(lunarDateStr)
        - 当前节气：\(jieQiStr)
        - 命局：\(elementStr)
        - 最近关注：\(recentTopic)

        要求：
        1. 标题：≤12个字，含一个emoji，有感染力
        2. 正文：≤45个字，温和有力，融入节气或五行能量，与最近关注自然衔接
        3. 不要生硬的"你的命局"字样，要像老友提醒
        4. 输出格式（只输出JSON，不要其他内容）：
           {"title":"...","body":"..."}
        """

        do {
            let raw = try await AIService.shared.getSimpleAIResponse(prompt: prompt)
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
            print("🔔 AI推送文案生成失败，使用预设文案: \(error)")
        }
        return nil
    }

    // ============================================================
    // MARK: - 预设文案库（按目标日期选取）
    // ============================================================

    struct NotifContent { let title: String; let body: String }

    /// 根据目标日期从预设库选一条文案（确定性随机：同一天总选同一条）
    func localContent(for date: Date) -> NotifContent {
        let calendar = Calendar.current
        let weekday  = calendar.component(.weekday, from: date)  // 1=Sun…7=Sat
        let month    = calendar.component(.month,   from: date)

        let comp  = calendar.dateComponents([.year, .month, .day], from: date)
        let solar = Solar.fromYmdHms(year: comp.year ?? 2025, month: comp.month ?? 1, day: comp.day ?? 1)
        let jieQi = solar.lunar.jieQi

        let portrait     = BirthInfoStore.shared.loadPortrait()
        let element      = portrait?.dayMasterElement
        let recentTopic  = MatrixHistoryStore.shared.loadAll().first?.scenario ?? ""

        // 候选池：节气 > 五行命局 > 话题 > 周几 > 季节 > 通用
        var candidates: [NotifContent] = []
        if let jieQiContent = jieQiBank()[jieQi] { candidates.append(jieQiContent) }
        candidates += elementBank(element: element)
        candidates += topicBank(topic: recentTopic)
        candidates += weekdayBank(weekday: weekday)
        candidates += seasonBank(month: month)
        candidates += universalBank()

        // 用目标日期的天序号做确定性随机（同一天总选同一条）
        let seed  = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        return candidates[seed % candidates.count]
    }

    // ── 节气专属（24条，优先级最高）────────────────────────────

    private func jieQiBank() -> [String: NotifContent] {
        [
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
    }

    // ── 五行命局专属（每种 3 条）────────────────────────────────

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

    // ── 话题相关（4 类）────────────────────────────────────────

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

    // ── 七曜专属（7天全覆盖，每天 2 条轮换）────────────────────
    // weekday: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat

    private func weekdayBank(weekday: Int) -> [NotifContent] {
        switch weekday {
        case 1: // 周日
            return [
                NotifContent(title: "☀️ 周日好时光", body: "一周将尽，今日不必焦虑下周。充电、陪人、做喜欢的事，这才是周日该有的样子。"),
                NotifContent(title: "🧘 周日向内看", body: "休息也是生产力。今日放慢节奏，让身心重新对齐，明天才能全力以赴。")
            ]
        case 2: // 周一
            return [
                NotifContent(title: "🌅 周一新气象", body: "新的一周，带着清醒开始。今日摇一摇，看看本周的能量走向。"),
                NotifContent(title: "🚀 周一启动日", body: "万事开头难，但开了头就好办。今日先做最重要的那一件，其余顺势而来。")
            ]
        case 3: // 周二
            return [
                NotifContent(title: "🌱 周二扎根时", body: "周一的热情还在，今日正是深入推进的好时机。把昨天启动的事，今天往深里做一步。"),
                NotifContent(title: "💡 周二蓄势中", body: "不急着出结果，今日先把逻辑理顺。稳扎稳打的周二，决定这周能走多远。")
            ]
        case 4: // 周三
            return [
                NotifContent(title: "⚡️ 周三爬坡时", body: "周中疲倦是正常的，但今日也是能量回升的节点。坚持，就快见顶了。"),
                NotifContent(title: "🔥 周三不松劲", body: "一周过半，成果就在眼前。今日再推一把，后两天就能轻松收尾。")
            ]
        case 5: // 周四
            return [
                NotifContent(title: "🎯 周四冲刺日", body: "离周末只剩两步，今日是提速的好时机。把本周目标再推进一大截。"),
                NotifContent(title: "✅ 周四完成时", body: "把积压的事今天清一清，周五才能轻装上阵，踏实迎接周末。")
            ]
        case 6: // 周五
            return [
                NotifContent(title: "🎯 周五收尾日", body: "今天完成一件本周最重要的事，周末才能真正放松。"),
                NotifContent(title: "🏁 周五冲线了", body: "终点在望，今日给这周一个漂亮的结尾。完成比完美更重要。")
            ]
        case 7: // 周六
            return [
                NotifContent(title: "🌈 周六充电日", body: "好好玩，认真休息。今日的能量储备，决定下周的状态上限。"),
                NotifContent(title: "🎉 周六自由时", body: "把时间还给自己，去做那件一直想做却没时间做的事。今日就是最好的时机。")
            ]
        default:
            return []
        }
    }

    // ── 季节通用（春夏秋冬各 4 条）──────────────────────────────

    private func seasonBank(month: Int) -> [NotifContent] {
        switch month {
        case 3...5: // 春
            return [
                NotifContent(title: "🌸 春日气场佳", body: "木气生发，今日适合启动新计划、结交新朋友，顺势而上。"),
                NotifContent(title: "🌿 春风送暖意", body: "万物生长时节，今日播下的种子，夏天就能看见苗头。"),
                NotifContent(title: "🌺 春生勃发时", body: "春气最旺，今日行动力加倍。那个犹豫已久的想法，现在动手正当时。"),
                NotifContent(title: "🦋 春日轻盈感", body: "脱去冬日的沉重，今日保持轻盈。身轻才能走得更远。")
            ]
        case 6...8: // 夏
            return [
                NotifContent(title: "☀️ 夏火旺精力", body: "火气旺盛，今日执行力强，趁热把重要任务推进到下一个阶段。"),
                NotifContent(title: "🌊 夏日保持凉", body: "天热心不躁。今日遇到催促和压力，先深呼一口气，从容应对。"),
                NotifContent(title: "🍉 夏至精力旺", body: "一年中阳气最盛的季节，今日把最难的任务放在精力最好的时段。"),
                NotifContent(title: "🌴 夏日稳住心", body: "暑热考验心性，越是忙乱越要静。今日找到节奏，效率自然来。")
            ]
        case 9...11: // 秋
            return [
                NotifContent(title: "🍂 秋金利决断", body: "金气旺时，思维清晰，今日做决定特别果断，抓住时机。"),
                NotifContent(title: "🍁 秋收正当时", body: "该收割的收割，该放下的放下。今日做一次清理，轻装进入冬季。"),
                NotifContent(title: "🌾 秋日沉淀时", body: "秋气内敛，今日适合回顾和总结。把走过的路看清楚，才知道下一步往哪走。"),
                NotifContent(title: "🌙 秋夜思绪清", body: "金秋夜凉，今日适合深度思考那件心里放不下的事。答案往往在静中来。")
            ]
        default: // 冬（12, 1, 2月）
            return [
                NotifContent(title: "❄️ 冬水养智慧", body: "水气藏纳，今日适合深度思考和休养，积蓄力量迎接新年。"),
                NotifContent(title: "☃️ 冬日蓄力时", body: "大地在沉睡中积蓄，今日不妨也给自己一段安静的充电时间。"),
                NotifContent(title: "🕯 冬夜护阳气", body: "寒冬最需温暖，今日主动联系一个久未联系的人，互相温暖。"),
                NotifContent(title: "🌟 冬藏待春来", body: "越是寒冷，越要珍惜内在的火苗。今日做一件让自己感到温暖的事。")
            ]
        }
    }

    // ── 通用兜底（15 条，风格偏「功能引导」，保留原有 8 条并扩充）

    private func universalBank() -> [NotifContent] {
        [
            // 原有 8 条
            NotifContent(title: "🌅 早安，觉察时刻", body: "与其等待运势，不如看清现在。摇一摇，今日方向更清晰。"),
            NotifContent(title: "💡 今日问一问", body: "答案不在卦象里，而在你心里。让六爻做你的镜子，照见本心。"),
            NotifContent(title: "☯️ 顺势而为", body: "不在逆境中消耗，不在顺境中迷失。理解当下，才能更好地出发。"),
            NotifContent(title: "🎯 遇事不决时", body: "困惑的尽头是行动。摇一摇，让古老智慧为你厘清方向。"),
            NotifContent(title: "🧘 此刻，向内看", body: "外部世界喧嚣，内心需要安宁。每日一卦，与直觉对话。"),
            NotifContent(title: "✨ 相信直觉", body: "所有的卦象都是内心的投射。摇一摇，找回你内在的确定性。"),
            NotifContent(title: "🌙 夜晚复盘时", body: "今日有什么还没想清楚？摇一卦，给迷雾里的自己一盏灯。"),
            NotifContent(title: "🔮 五行能量今日", body: "每天的能量都在流动，今日适合留意身边微小的变化与信号。"),
            // 扩充 7 条
            NotifContent(title: "🌊 随机而动", body: "计划赶不上变化，但顺势而为的人永远不慌。今日先摇一卦，再做安排。"),
            NotifContent(title: "🗝 今日开一门", body: "每天打开一扇新门，不管大小。今日的一小步，是明天的一大步。"),
            NotifContent(title: "🌀 理清一件事", body: "脑海中最乱的那团线，今日挑一根拉直。小清晰，大轻松。"),
            NotifContent(title: "💬 说出来更轻", body: "憋在心里的事越来越重，今日找个出口，说出来或写下来都好。"),
            NotifContent(title: "🌐 换个角度看", body: "卡住的问题，往往换个角度就通了。摇一摇，试试不同的视角。"),
            NotifContent(title: "⚡️ 能量充满时", body: "感受一下今天的状态，是进攻还是防守？跟着节奏走，事半功倍。"),
            NotifContent(title: "🏮 每日一觉察", body: "觉察是改变的开始。今日停一停，问问自己：此刻最需要的是什么？")
        ]
    }
}
