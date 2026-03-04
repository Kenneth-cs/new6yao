import Foundation

// ============================================================
// MARK: - 八字排盘与五行量化引擎 (BaziEngine)
// ============================================================
// 核心职责：
// 1. 天文历法：公历 -> 农历 -> 干支 (精确到节气)
// 2. 能量量化：基于“得令、得地、得势”计算五行强弱数值
// ============================================================

class BaziEngine {
    static let shared = BaziEngine()
    private init() {}
    
    // MARK: - 公共接口
    
    /// 计算五行能量分布
    /// - Parameters:
    ///   - date: 公历日期
    ///   - hour: 时辰
    /// - Returns: 五行能量占比 (总和 1.0)
    func calculateEnergy(date: Date, hour: ChineseHour) -> [FiveElement: Double] {
        // 1. 排盘 (四柱)
        let pillars = calculatePillars(date: date, hour: hour)
        
        // 2. 量化打分
        let scores = quantifyEnergy(pillars: pillars)
        
        // 3. 归一化 (转为百分比)
        return normalize(scores)
    }
    
    /// 获取日主 (Day Master)
    func getDayMaster(date: Date, hour: ChineseHour) -> String {
        let pillars = calculatePillars(date: date, hour: hour)
        return pillars.day.stem.rawValue + pillars.day.stem.element.rawValue // e.g. "甲木"
    }
    
    /// 获取八字排盘字符串 (如：甲辰年 丙寅月 戊午日 壬子时)
    func getBaziString(date: Date, hour: ChineseHour) -> String {
        let pillars = calculatePillars(date: date, hour: hour)
        return "\(pillars.year.stem.rawValue)\(pillars.year.branch.rawValue)年  \(pillars.month.stem.rawValue)\(pillars.month.branch.rawValue)月  \(pillars.day.stem.rawValue)\(pillars.day.branch.rawValue)日  \(pillars.time.stem.rawValue)\(pillars.time.branch.rawValue)时"
    }
    
    // MARK: - 内部结构
    
    struct Pillar {
        let stem: HeavenlyStem   // 天干
        let branch: EarthlyBranch // 地支
    }
    
    struct FourPillars {
        let year: Pillar
        let month: Pillar
        let day: Pillar
        let time: Pillar
    }
    
    // MARK: - 1. 排盘逻辑 (集成 LunarSwift)
    
    private func calculatePillars(date: Date, hour: ChineseHour) -> FourPillars {
        // 真实逻辑：使用 LunarSwift 进行高精度天文历法排盘
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 2000
        let month = components.month ?? 1
        let day = components.day ?? 1
        
        let hourValue: Int
        switch hour {
        case .zi:   hourValue = 0
        case .chou: hourValue = 2
        case .yin:  hourValue = 4
        case .mao:  hourValue = 6
        case .chen: hourValue = 8
        case .si:   hourValue = 10
        case .wu:   hourValue = 12
        case .wei:  hourValue = 14
        case .shen: hourValue = 16
        case .you:  hourValue = 18
        case .xu:   hourValue = 20
        case .hai:  hourValue = 22
        }
        
        let solar = Solar.fromYmdHms(year: year, month: month, day: day, hour: hourValue, minute: 0, second: 0)
        let lunar = solar.lunar
        let eightChar = lunar.eightChar
        
        return FourPillars(
            year: parseGanZhi(eightChar.year),
            month: parseGanZhi(eightChar.month),
            day: parseGanZhi(eightChar.day),
            time: parseGanZhi(eightChar.time)
        )
        
        /*
        // --- 模拟逻辑 (Mock) ---
        let calendar = Calendar(identifier: .chinese)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // 模拟年柱
        let yearIndex = ((components.year ?? 2024) - 4) % 60
        let yearStem = HeavenlyStem.allCases[yearIndex % 10]
        let yearBranch = EarthlyBranch.allCases[yearIndex % 12]
        
        // 模拟月柱 (简单推算)
        let monthStem = HeavenlyStem.bing
        let monthBranch = EarthlyBranch.chen // 辰月 (土)
        
        // 模拟日柱
        let dayStem = HeavenlyStem.ding
        let dayBranch = EarthlyBranch.si
        
        // 时柱 (基于日上起时)
        let timeStem = getTimeStem(dayStem: dayStem, hour: hour)
        let timeBranch = getBranch(from: hour)
        
        return FourPillars(
            year: Pillar(stem: yearStem, branch: yearBranch),
            month: Pillar(stem: monthStem, branch: monthBranch),
            day: Pillar(stem: dayStem, branch: dayBranch),
            time: Pillar(stem: timeStem, branch: timeBranch)
        )
        */
    }
    
    private func parseGanZhi(_ ganZhi: String) -> Pillar {
        guard ganZhi.count >= 2 else { return Pillar(stem: .jia, branch: .zi) }
        let stemChar = String(ganZhi.prefix(1))
        let branchChar = String(ganZhi.suffix(1))
        let stem = HeavenlyStem(rawValue: stemChar) ?? .jia
        let branch = EarthlyBranch(rawValue: branchChar) ?? .zi
        return Pillar(stem: stem, branch: branch)
    }
    
    // MARK: - 2. 能量量化 (得令、得地、得势)
    
    private func quantifyEnergy(pillars: FourPillars) -> [FiveElement: Double] {
        var scores: [FiveElement: Double] = [.wood: 0, .fire: 0, .earth: 0, .metal: 0, .water: 0]

        // 优化后的权重定义（降低月令垄断性，提升日支重要性）
        let weightSeason = 30.0 // 得令 (月支) - 降权，避免土月独大
        let weightStem   = 12.0 // 得势 (天干)
        let weightDayBranch = 15.0 // 日支 (坐支) - 离日主最近，影响大
        let weightBranch = 8.0  // 得地 (其他地支)

        // 1. 得令 (月支)
        let monthElement = pillars.month.branch.mainElement
        scores[monthElement, default: 0] += weightSeason

        // 2. 得势 (四柱天干)
        // 日主天干权重减半策略保持不变
        for p in [pillars.year, pillars.month, pillars.time] {
            scores[p.stem.element, default: 0] += weightStem
        }
        scores[pillars.day.stem.element, default: 0] += weightStem * 0.5

        // 3. 得地 (四柱地支主气)
        // 日支单独加权
        scores[pillars.day.branch.mainElement, default: 0] += weightDayBranch
        // 其他三支
        for p in [pillars.year, pillars.month, pillars.time] {
            scores[p.branch.mainElement, default: 0] += weightBranch
        }

        return scores
    }
    
    private func normalize(_ scores: [FiveElement: Double]) -> [FiveElement: Double] {
        let total = scores.values.reduce(0, +)
        guard total > 0 else { return scores }
        
        var result = scores
        for (key, value) in scores {
            result[key] = value / total
        }
        return result
    }
    
    // MARK: - 辅助方法
    
    private func getBranch(from hour: ChineseHour) -> EarthlyBranch {
        switch hour {
        case .zi: return .zi
        case .chou: return .chou
        case .yin: return .yin
        case .mao: return .mao
        case .chen: return .chen
        case .si: return .si
        case .wu: return .wu
        case .wei: return .wei
        case .shen: return .shen
        case .you: return .you
        case .xu: return .xu
        case .hai: return .hai
        }
    }
    
    // 五鼠遁元 (日上起时法)
    private func getTimeStem(dayStem: HeavenlyStem, hour: ChineseHour) -> HeavenlyStem {
        let dayIndex = HeavenlyStem.allCases.firstIndex(of: dayStem)!
        let hourIndex = EarthlyBranch.allCases.firstIndex(of: getBranch(from: hour))!
        
        let startStemIndex: Int
        switch dayIndex % 5 {
        case 0: startStemIndex = 0 // 甲/己 -> 甲
        case 1: startStemIndex = 2 // 乙/庚 -> 丙
        case 2: startStemIndex = 4 // 丙/辛 -> 戊
        case 3: startStemIndex = 6 // 丁/壬 -> 庚
        case 4: startStemIndex = 8 // 戊/癸 -> 壬
        default: startStemIndex = 0
        }
        
        let stemIndex = (startStemIndex + hourIndex) % 10
        return HeavenlyStem.allCases[stemIndex]
    }

    // MARK: - 喜用神推算（本地传统命理规则，确定性算法）

    /// 计算喜用神、忌神、急需补充能量
    /// - Returns: (喜用神列表, 忌神列表, weakElement急需补充)
    func calculateFavorableElements(date: Date, hour: ChineseHour) -> (favorable: [String], unfavorable: [String], weakElement: String) {
        let scores = calculateEnergy(date: date, hour: hour)
        let pillars = calculatePillars(date: date, hour: hour)
        let dmEl = pillars.day.stem.element
        let monthBranch = pillars.month.branch
        let isColdMonth = [EarthlyBranch.hai, .zi, .chou].contains(monthBranch)
        return BaziEngine.favorableRule(dayMaster: dmEl, scores: scores, isColdMonth: isColdMonth)
    }

    /// 核心喜用神规则引擎（静态，便于单元测试）
    static func favorableRule(
        dayMaster dm: FiveElement,
        scores: [FiveElement: Double],
        isColdMonth: Bool
    ) -> (favorable: [String], unfavorable: [String], weakElement: String) {
        let prt = dm.generatedBy    // 印星（生我）
        let fod = dm.generates      // 食伤（我生）
        let wlt = dm.controls       // 财星（我克）
        let ofc = dm.controlledBy   // 官杀（克我）

        let g: (FiveElement) -> Double = { scores[$0] ?? 0 }

        // 有效强度 = 自身 - 官杀克*0.5 - 财泄*0.3 - 食伤泄*0.2 + 印生*0.3
        let eff = g(dm) - g(ofc)*0.5 - g(wlt)*0.3 - g(fod)*0.2 + g(prt)*0.3
        // 官克等身修正：当官杀 ≥ 日主*90% 时，日主实为竞争弱势
        let officerContesting = g(ofc) >= g(dm) * 0.9
        let isStrong = eff >= 0.25 && !officerContesting

        var fav: [FiveElement]
        var unf: [FiveElement]

        if isStrong {
            if g(prt) > 0.35 {
                // 印旺助身过（如木旺生旺火）→ 财星克印 + 官杀制身
                fav = [prt.controlledBy, ofc]
            } else {
                // 正常身旺 → 官杀/食伤/财中取占比最低2个，官杀优先
                let cands = [(ofc, g(ofc), 0), (fod, g(fod), 1), (wlt, g(wlt), 2)]
                    .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.2 < $1.2 }
                fav = cands.prefix(2).map { $0.0 }
            }
            unf = [prt, dm]
        } else {
            // 水多木漂 / 金多水浑（印星过旺特殊格局）
            let woodFloats = prt == .water && dm == .wood && g(prt) > 0.40
            let waterMurky = prt == .metal && dm == .water && g(prt) > 0.40
            if woodFloats || waterMurky {
                fav = [fod, prt.controlledBy]   // 泄印（食伤）+ 克印（财）
                unf = [prt, ofc]
            } else if g(fod) > 0.40 {
                // 食伤过旺泄身 → 印制食 + 冬月加火调候
                fav = isColdMonth ? [prt, .fire] : [prt, dm]
                unf = [fod, wlt]
            } else {
                // 普通身弱 → 印星 + 比劫
                fav = [prt, dm]
                unf = [ofc, fod]
            }
        }

        // 去重
        var seen = Set<FiveElement>()
        fav = fav.filter { seen.insert($0).inserted }

        // weakElement = 喜用神中占比最低的（= 最急需补充的有益能量）
        let weakEl = fav.min(by: { g($0) < g($1) }) ?? fav[0]

        return (fav.map { $0.rawValue }, unf.map { $0.rawValue }, weakEl.rawValue)
    }
}

// MARK: - FiveElement 五行生克关系扩展

extension FiveElement {
    /// 我生（食伤星，泄我）
    var generates: FiveElement {
        switch self { case .wood: return .fire; case .fire: return .earth; case .earth: return .metal; case .metal: return .water; case .water: return .wood }
    }
    /// 生我（印星，生我）
    var generatedBy: FiveElement {
        switch self { case .wood: return .water; case .fire: return .wood; case .earth: return .fire; case .metal: return .earth; case .water: return .metal }
    }
    /// 我克（财星，我克）
    var controls: FiveElement {
        switch self { case .wood: return .earth; case .fire: return .metal; case .earth: return .water; case .metal: return .wood; case .water: return .fire }
    }
    /// 克我（官杀星，克我）
    var controlledBy: FiveElement {
        switch self { case .wood: return .metal; case .fire: return .water; case .earth: return .wood; case .metal: return .fire; case .water: return .earth }
    }
}

// MARK: - 天干地支定义

enum HeavenlyStem: String, CaseIterable {
    case jia = "甲", yi = "乙"
    case bing = "丙", ding = "丁"
    case wu = "戊", ji = "己"
    case geng = "庚", xin = "辛"
    case ren = "壬", gui = "癸"
    
    var element: FiveElement {
        switch self {
        case .jia, .yi: return .wood
        case .bing, .ding: return .fire
        case .wu, .ji: return .earth
        case .geng, .xin: return .metal
        case .ren, .gui: return .water
        }
    }
}

enum EarthlyBranch: String, CaseIterable {
    case zi = "子", chou = "丑"
    case yin = "寅", mao = "卯"
    case chen = "辰", si = "巳"
    case wu = "午", wei = "未"
    case shen = "申", you = "酉"
    case xu = "戌", hai = "亥"
    
    var mainElement: FiveElement {
        switch self {
        case .yin, .mao: return .wood
        case .si, .wu: return .fire
        case .chen, .xu, .chou, .wei: return .earth
        case .shen, .you: return .metal
        case .zi, .hai: return .water
        }
    }
}
