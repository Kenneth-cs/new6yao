import Foundation
import SwiftUI

// ============================================================
// MARK: - 十二时辰（12 Chinese Hours）
// ============================================================
enum ChineseHour: String, CaseIterable, Codable {
    case zi   = "子时"   // 23:00–01:00
    case chou = "丑时"   // 01:00–03:00
    case yin  = "寅时"   // 03:00–05:00
    case mao  = "卯时"   // 05:00–07:00
    case chen = "辰时"   // 07:00–09:00
    case si   = "巳时"   // 09:00–11:00
    case wu   = "午时"   // 11:00–13:00
    case wei  = "未时"   // 13:00–15:00
    case shen = "申时"   // 15:00–17:00
    case you  = "酉时"   // 17:00–19:00
    case xu   = "戌时"   // 19:00–21:00
    case hai  = "亥时"   // 21:00–23:00

    /// 对应的时间区间说明
    var timeRange: String {
        switch self {
        case .zi:   return "23–01 时"
        case .chou: return "01–03 时"
        case .yin:  return "03–05 时"
        case .mao:  return "05–07 时"
        case .chen: return "07–09 时"
        case .si:   return "09–11 时"
        case .wu:   return "11–13 时"
        case .wei:  return "13–15 时"
        case .shen: return "15–17 时"
        case .you:  return "17–19 时"
        case .xu:   return "19–21 时"
        case .hai:  return "21–23 时"
        }
    }

    /// 根据24小时制小时数自动推算时辰
    static func from(hour24: Int) -> ChineseHour {
        switch hour24 {
        case 23, 0:  return .zi
        case 1, 2:   return .chou
        case 3, 4:   return .yin
        case 5, 6:   return .mao
        case 7, 8:   return .chen
        case 9, 10:  return .si
        case 11, 12: return .wu
        case 13, 14: return .wei
        case 15, 16: return .shen
        case 17, 18: return .you
        case 19, 20: return .xu
        default:     return .hai   // 21, 22
        }
    }
}

// ============================================================
// MARK: - 生辰信息本地持久化（UserDefaults）
// ============================================================
class BirthInfoStore: ObservableObject {
    static let shared = BirthInfoStore()
    private init() { load() }

    private let ud              = UserDefaults.standard
    private let keyDate         = "matrix_birth_date"
    private let keyHour         = "matrix_birth_hour"
    private let keyHasSet       = "matrix_birth_has_set"       // 是否曾主动设置过生日
    private let keyPortraitCache = "matrix_portrait_cache"     // 画像结果 JSON 缓存

    @Published var birthday: Date = {
        var c = DateComponents(); c.year = 1995; c.month = 8; c.day = 15
        return Calendar.current.date(from: c) ?? Date()
    }()
    @Published var birthHour: ChineseHour = .wu

    /// 用户是否已主动设置过生辰（区别于默认值兜底）
    var hasSetBirthday: Bool {
        ud.bool(forKey: keyHasSet)
    }

    /// 保存生辰到 UserDefaults
    func save(birthday newDate: Date, hour newHour: ChineseHour) {
        birthday  = newDate
        birthHour = newHour
        ud.set(newDate.timeIntervalSince1970, forKey: keyDate)
        ud.set(newHour.rawValue,              forKey: keyHour)
        ud.set(true,                          forKey: keyHasSet)
    }

    /// 将 AI 画像结果缓存到本地
    func savePortrait(_ portrait: EnergyPortraitResult) {
        if let data = try? JSONEncoder().encode(portrait) {
            ud.set(data, forKey: keyPortraitCache)
        }
    }

    /// 读取本地缓存的画像结果；若无则返回 nil
    func loadPortrait() -> EnergyPortraitResult? {
        guard let data = ud.data(forKey: keyPortraitCache) else { return nil }
        return try? JSONDecoder().decode(EnergyPortraitResult.self, from: data)
    }

    /// 清除画像缓存（修改生辰后调用）
    func clearPortraitCache() {
        ud.removeObject(forKey: keyPortraitCache)
    }

    /// 从 UserDefaults 读取生辰
    func load() {
        if let ts = ud.value(forKey: keyDate) as? Double {
            birthday = Date(timeIntervalSince1970: ts)
        }
        if let s = ud.string(forKey: keyHour),
           let h = ChineseHour(rawValue: s) {
            birthHour = h
        }
    }
}

// ============================================================
// MARK: - 五行能量画像结果（AI 返回 JSON 对应结构）
// ============================================================
struct EnergyPortraitResult: Codable {
    let wood:  Double   // 木元素占比 0~1
    let fire:  Double   // 火元素占比
    let earth: Double   // 土元素占比
    let metal: Double   // 金元素占比
    let water: Double   // 水元素占比

    let dayMaster:           String    // 日主，如 "丁火"
    let dominantElement:     String    // 最强元素，如 "火"
    let weakElement:         String    // 最弱元素，如 "水"
    let favorableElements:   [String]  // 喜用神（药）
    let unfavorableElements: [String]  // 忌神（病）
    let diagnosis:           String    // 通俗诊断文案
    let remedy:              String    // 调候建议

    // 转换为视图用的字典
    var values: [FiveElement: Double] {
        [.wood: wood, .fire: fire, .earth: earth, .metal: metal, .water: water]
    }

    // 日主所属五行（如"丁火"→.fire，"甲木"→.wood）
    var dayMasterElement: FiveElement {
        // 日主格式为"天干+五行"，取最后一个字符即五行
        let last = String(dayMaster.suffix(1))
        return FiveElement(rawValue: last) ?? .fire
    }

    // 最需补充的五行元素
    var remedyFiveElement: FiveElement {
        FiveElement(rawValue: weakElement) ?? .water
    }

    var favorableFiveElements: [FiveElement] {
        favorableElements.compactMap { FiveElement(rawValue: $0) }
    }

    var unfavorableFiveElements: [FiveElement] {
        unfavorableElements.compactMap { FiveElement(rawValue: $0) }
    }

    // MARK: - Mock（UI 开发 / API 失败时的兜底数据）
    static let mock = EnergyPortraitResult(
        wood:  0.15,
        fire:  0.45,
        earth: 0.25,
        metal: 0.10,
        water: 0.05,
        dayMaster:           "丁火",
        dominantElement:     "火",
        weakElement:         "水",
        favorableElements:   ["水", "木"],
        unfavorableElements: ["土", "金"],
        diagnosis: "你是典型的燥火命局，极度缺水。如同干裂的大地急需雨露滋润。决策往往过于急躁，容易冲动消费，缺乏长远战略思维。",
        remedy: "宜选择含水木元素的环境与机会，远离金土属性过重的选择。"
    )
}

// ============================================================
// MARK: - 决策选项分析结果
// ============================================================
struct DecisionOptionResult: Codable {
    let name:         String   // 如 "选项A（湖畔花园）"
    let score:        Int      // 0~100
    let verdict:      String   // 大吉 / 小吉 / 平 / 小凶 / 大凶
    let remedyPower:  Int      // 药力 0~100
    let ailmentPower: Int      // 病灶 0~100
    let elements:     [String] // 主要五行属性
    let tags:         [String] // 补益 / 消耗 / 忌神 等标签
    let summary:      String   // 30字内分析

    var verdictColor: Color {
        switch verdict {
        case "大吉": return Color(red: 0.1,  green: 0.72, blue: 0.55)
        case "小吉": return Color(red: 0.2,  green: 0.6,  blue: 0.85)
        case "平":   return Color(red: 0.5,  green: 0.5,  blue: 0.5)
        case "小凶": return Color(red: 0.85, green: 0.55, blue: 0.15)
        case "大凶": return Color(red: 0.9,  green: 0.2,  blue: 0.2)
        default:     return Color(red: 0.5,  green: 0.5,  blue: 0.5)
        }
    }

    var remedyRatio: Double { Double(remedyPower)  / 100.0 }
    var ailmentRatio: Double { Double(ailmentPower) / 100.0 }
}

// ============================================================
// MARK: - 矩阵维度的单个选项详情
// ============================================================
struct MatrixOptionResultDetail: Codable {
    let type:        String // "benefit" | "consumption" | "danger" | "neutral"
    let elements:    String // 如 "[水/木]"
    let description: String // 简短说明
}

// ============================================================
// MARK: - 矩阵维度（三才之一）
// ============================================================
struct MatrixDimensionResult: Codable {
    let name:          String                      // 如 "地利 (环境)"
    let weight:        Int                         // 权重百分比
    let optionDetails: [MatrixOptionResultDetail]  // 每个选项的详情
}

// ============================================================
// MARK: - 完整决策矩阵结果（AI 返回 JSON 对应结构）
// ============================================================
struct DecisionMatrixResult: Codable {
    let options:         [DecisionOptionResult]   // 各选项分析
    let recommendation:  Int                      // 推荐选项索引（0-based）
    let hasFatalRisk:    Bool                     // 是否触发一票否决
    let fatalRiskOption: Int                      // 触发一票否决的选项索引，无则 -1
    let fatalRiskReason: String                   // 一票否决原因
    let dimensions:      [MatrixDimensionResult]  // 三才维度详情

    var recommendedOption: DecisionOptionResult? {
        guard recommendation >= 0, recommendation < options.count else { return nil }
        return options[recommendation]
    }

    // MARK: - Mock
    static let mock = DecisionMatrixResult(
        options: [
            DecisionOptionResult(
                name: "选项A", score: 85, verdict: "大吉",
                remedyPower: 75, ailmentPower: 16,
                elements: ["水", "木"], tags: ["补益", "顺势"],
                summary: "临水格局，水木相生，顺应日主需求，整体利大于弊。"
            ),
            DecisionOptionResult(
                name: "选项B", score: 52, verdict: "平",
                remedyPower: 30, ailmentPower: 62,
                elements: ["土", "金"], tags: ["消耗", "忌神"],
                summary: "土金过重，克制命局所需水木能量，需谨慎权衡。"
            )
        ],
        recommendation: 0,
        hasFatalRisk: false,
        fatalRiskOption: -1,
        fatalRiskReason: "",
        dimensions: [
            MatrixDimensionResult(name: "地利 (环境)", weight: 40, optionDetails: [
                MatrixOptionResultDetail(type: "benefit",     elements: "[水/木]",   description: "临水聚气，北方有活水"),
                MatrixOptionResultDetail(type: "consumption", elements: "[火]",       description: "靠山稍远，无水遮挡")
            ]),
            MatrixDimensionResult(name: "人和 (楼层)", weight: 30, optionDetails: [
                MatrixOptionResultDetail(type: "benefit",     elements: "[金/土]",   description: "8层，土金相生"),
                MatrixOptionResultDetail(type: "consumption", elements: "[木]",       description: "4层，金木相克")
            ]),
            MatrixDimensionResult(name: "天时 (装修)", weight: 30, optionDetails: [
                MatrixOptionResultDetail(type: "benefit",     elements: "[木/水]",   description: "精装现房，即可入住"),
                MatrixOptionResultDetail(type: "danger",      elements: "[金-忌神]", description: "豪华装修，金气过重")
            ])
        ]
    )
}
