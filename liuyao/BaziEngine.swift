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

        // 权重定义
        let weightSeason = 40.0 // 得令 (月支)
        let weightStem   = 15.0 // 得势 (天干)
        let weightBranch = 10.0 // 得地 (地支主气)

        // 1. 得令 (月支决定性作用)
        let monthElement = pillars.month.branch.mainElement
        scores[monthElement, default: 0] += weightSeason

        // 2. 得势 (四柱天干)
        // ⚠️ 注意：日主天干代表被测量的"主体"本身，不计入"命局环境"的支撑力量
        // 否则日主元素会被多算 15 分，导致旺弱判断偏旺
        for p in [pillars.year, pillars.month, pillars.time] {
            scores[p.stem.element, default: 0] += weightStem
        }
        // 日柱天干仅计一半权重（体现日主自身的根基，但不作为外力）
        scores[pillars.day.stem.element, default: 0] += weightStem * 0.5

        // 3. 得地 (四柱地支主气)
        for p in [pillars.year, pillars.month, pillars.day, pillars.time] {
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
