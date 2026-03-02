import XCTest
@testable import liuyao

class BaziEngineTests: XCTestCase {

    let engine = BaziEngine.shared
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - 10 案例验证（五行分布 + 日主 + 预期喜用方向）
    // 预期喜用神来源：命理界公认结论，用于对比 AI 输出
    struct Case {
        let name: String
        let date: String
        let hour: ChineseHour
        let expectedDayMaster: String   // 如 "甲木"
        let expectedFavorable: [String] // 公认喜用（至少包含其中一个算通过）
        let note: String
    }

    let cases: [Case] = [
        // 1. 甲木生于冬月（水旺）—— 木有水生，但太寒，喜火暖局
        Case(name: "1990-01-15 子时", date: "1990-01-15", hour: .zi,
             expectedDayMaster: "甲", expectedFavorable: ["火", "土"],
             note: "寒冬甲木，喜火暖，忌水过寒"),
        // 2. 丙火生于夏月（火旺）—— 日主旺，喜水财、金官来制
        Case(name: "1988-07-07 午时", date: "1988-07-07", hour: .wu,
             expectedDayMaster: "丙", expectedFavorable: ["水", "金"],
             note: "夏火旺极，喜水金制泄"),
        // 3. 庚金生于秋月（金旺）—— 日主极旺，喜火来炼，水来流通
        Case(name: "1995-09-20 酉时", date: "1995-09-20", hour: .you,
             expectedDayMaster: "庚", expectedFavorable: ["火", "水"],
             note: "秋金旺，喜火炼金或水流"),
        // 4. 壬水生于冬月（水旺）—— 身强，喜木食神泄秀或土制
        Case(name: "1992-12-01 子时", date: "1992-12-01", hour: .zi,
             expectedDayMaster: "壬", expectedFavorable: ["木", "土"],
             note: "冬水身旺，喜木泄或土制"),
        // 5. 己土生于春月（木旺克土）—— 日主弱，喜火生土、金泄木
        Case(name: "1985-04-05 巳时", date: "1985-04-05", hour: .si,
             expectedDayMaster: "己", expectedFavorable: ["火", "金"],
             note: "春木克土，己土弱，喜火金"),
        // 6. 乙木生于秋月（金旺克木）—— 日主弱，喜水生木、木比肩
        Case(name: "1994-10-16 戌时", date: "1994-10-16", hour: .xu,
             expectedDayMaster: "乙", expectedFavorable: ["水", "木"],
             note: "秋金克木，乙木弱，喜水木"),
        // 7. 丁火生于冬月（水旺克火）—— 日主弱，喜木生火、火比肩
        Case(name: "1987-11-22 亥时", date: "1987-11-22", hour: .hai,
             expectedDayMaster: "丁", expectedFavorable: ["木", "火"],
             note: "冬水克火，丁火弱，喜木火"),
        // 8. 戊土生于夏月（火旺生土）—— 日主旺，喜水财调候
        Case(name: "1993-06-15 午时", date: "1993-06-15", hour: .wu,
             expectedDayMaster: "戊", expectedFavorable: ["水", "木"],
             note: "夏火生土，戊土旺，喜水调候"),
        // 9. 辛金生于春月（木旺）—— 辛金弱，喜土生金、水洗金
        Case(name: "1996-03-21 卯时", date: "1996-03-21", hour: .mao,
             expectedDayMaster: "辛", expectedFavorable: ["土", "水"],
             note: "春木盛，辛金弱，喜土水"),
        // 10. 癸水生于夏月（火旺）—— 癸水弱，喜金生水、水比肩
        Case(name: "1991-08-10 申时", date: "1991-08-10", hour: .shen,
             expectedDayMaster: "癸", expectedFavorable: ["金", "水"],
             note: "夏火旺，癸水弱，喜金水"),
    ]

    // MARK: - 日主正确性测试
    func testDayMasterAccuracy() {
        print("\n========== 日主验证 ==========")
        for c in cases {
            guard let date = formatter.date(from: c.date) else { continue }
            let dm = engine.getDayMaster(date: date, hour: c.hour)
            let pass = dm.hasPrefix(c.expectedDayMaster)
            print("[\(pass ? "✅" : "❌")] \(c.name) → 日主: \(dm) (预期含\(c.expectedDayMaster)) | \(c.note)")
            XCTAssertTrue(pass, "\(c.name) 日主错误: 预期含\(c.expectedDayMaster), 实际\(dm)")
        }
    }

    // MARK: - 五行分布打印（人工审查）
    func testPrintEnergyDistribution() {
        print("\n========== 五行分布详情 ==========")
        let elementOrder: [FiveElement] = [.wood, .fire, .earth, .metal, .water]
        let names = ["木", "火", "土", "金", "水"]

        for c in cases {
            guard let date = formatter.date(from: c.date) else { continue }
            let scores = engine.calculateEnergy(date: date, hour: c.hour)
            let dm = engine.getDayMaster(date: date, hour: c.hour)
            let bazi = engine.getBaziString(date: date, hour: c.hour)

            let dist = elementOrder.enumerated()
                .map { i, el in "\(names[i]):\(Int((scores[el] ?? 0) * 100))%" }
                .joined(separator: " ")

            // 找出预期喜用神中占比最低的（当前 weakElement 逻辑）
            let weakAmongFavorable = c.expectedFavorable
                .compactMap { name -> (String, Double)? in
                    guard let el = FiveElement(rawValue: name) else { return nil }
                    return (name, scores[el] ?? 0)
                }
                .min(by: { $0.1 < $1.1 })?.0 ?? "?"

            print("【\(c.name)】\(c.note)")
            print("   八字: \(bazi)")
            print("   日主: \(dm) | 五行: \(dist)")
            print("   预期喜用: \(c.expectedFavorable) → 预期缺: \(weakAmongFavorable)")
            print("   金元素占比: \(Int((scores[.metal] ?? 0) * 100))% (需关注是否合理)")
            print()
        }
    }

    // MARK: - 总分归一化验证
    func testNormalizationIsCorrect() {
        for c in cases {
            guard let date = formatter.date(from: c.date) else { continue }
            let scores = engine.calculateEnergy(date: date, hour: c.hour)
            let total = scores.values.reduce(0, +)
            XCTAssertEqual(total, 1.0, accuracy: 0.001, "\(c.name) 总分不为1: \(total)")
        }
    }
}
