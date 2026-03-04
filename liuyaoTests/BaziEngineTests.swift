import XCTest
@testable import liuyao

// ============================================================
// 四柱基准来源：以 2000-01-07 = 甲子日 为基准，精确推算（已与万年历交叉验证）
// 月柱依据精确节气（LunarSwift），时柱按「五鼠遁日起时法」
// 喜用神依据传统命理公认结论，仅供 AI 输出对比参考，不做自动断言
// ============================================================

class BaziEngineTests: XCTestCase {

    let engine = BaziEngine.shared
    let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    struct Case {
        let name: String
        let date: String
        let hour: ChineseHour
        let expectedDayMaster: String   // 日干，如 "庚"
        let expectedFavorable: [String] // 公认喜用神（参考，不做机器断言）
        let baziRef: String             // 正确四柱（年月日时）
        let note: String
    }

    // MARK: - 10 个验证案例（正确四柱已核对）
    let cases: [Case] = [

        // 1. 庚金 — 冬末丑月，三火克金，土旺生金，身弱
        //    四柱: 己巳 丁丑 庚辰 丙子  |  木0% 火28% 土58% 金5% 水7%
        Case(name: "1990-01-15 子时", date: "1990-01-15", hour: .zi,
             expectedDayMaster: "庚", expectedFavorable: ["土", "金"],
             baziRef: "己巳 丁丑 庚辰 丙子",
             note: "庚金冬末，三火(巳丁丙)克金身弱，土重生金，喜土(印)生金、金比劫"),

        // 2. 癸水 — 夏未月，土五重克水，身极弱
        //    四柱: 戊辰 己未 癸亥 戊午  |  木0% 火7% 土73% 金0% 水18%
        Case(name: "1988-07-07 午时", date: "1988-07-07", hour: .wu,
             expectedDayMaster: "癸", expectedFavorable: ["金", "水"],
             baziRef: "戊辰 己未 癸亥 戊午",
             note: "癸水夏未月，土多(辰未戊己戊)克水极弱，喜金生水、水比劫"),

        // 3. 甲木 — 秋酉月，金旺克木，亥水癸水援生，木金对峙（40% vs 41%）
        //    四柱: 乙亥 乙酉 甲寅 癸酉  |  木40% 火0% 土0% 金41% 水18%
        Case(name: "1995-09-20 酉时", date: "1995-09-20", hour: .you,
             expectedDayMaster: "甲", expectedFavorable: ["水", "木"],
             baziRef: "乙亥 乙酉 甲寅 癸酉",
             note: "甲木秋酉月，金旺克木，但亥水癸水护根，木金对峙，喜水生木、木比劫"),

        // 4. 辛金 — 冬亥月，水旺泄金，金水伤官局，身弱
        //    四柱: 壬申 辛亥 辛亥 戊子  |  木0% 火0% 土10% 金23% 水65%
        Case(name: "1992-12-01 子时", date: "1992-12-01", hour: .zi,
             expectedDayMaster: "辛", expectedFavorable: ["土", "火"],
             baziRef: "壬申 辛亥 辛亥 戊子",
             note: "辛金冬亥月，水极旺泄金，金水伤官格，喜土制水生金、火暖局调候"),

        // 5. 甲木 — 辰月土旺，庚金克，土重(丑辰戌己)压制，身弱
        //    四柱: 乙丑 庚辰 甲戌 己巳  |  木16% 火7% 土65% 金10% 水0%
        Case(name: "1985-04-05 巳时", date: "1985-04-05", hour: .si,
             expectedDayMaster: "甲", expectedFavorable: ["水", "木"],
             baziRef: "乙丑 庚辰 甲戌 己巳",
             note: "甲木辰月，庚金克木，土五重(丑辰戌己巳)压制，身弱，喜水生木、木比劫"),

        // 6. 乙木 — 戌月三土克木，身弱
        //    四柱: 甲戌 甲戌 乙亥 丙戌  |  木27% 火10% 土48% 金0% 水13%
        Case(name: "1994-10-16 戌时", date: "1994-10-16", hour: .xu,
             expectedDayMaster: "乙", expectedFavorable: ["水", "木"],
             baziRef: "甲戌 甲戌 乙亥 丙戌",
             note: "乙木戌月，三戌土克木，亥水有救，喜水生木、甲木比劫"),

        // 7. 乙木 — 亥月三亥水漂木，辛金克木，木漂需土制水护根
        //    四柱: 丁卯 辛亥 乙亥 丁亥  |  木12% 火21% 土0% 金10% 水54%
        Case(name: "1987-11-22 亥时", date: "1987-11-22", hour: .hai,
             expectedDayMaster: "乙", expectedFavorable: ["火", "土"],
             baziRef: "丁卯 辛亥 乙亥 丁亥",
             note: "乙木亥月，三亥水多木漂，辛金克木，土0%，喜火泄秀、土制水护根"),

        // 8. 丁火 — 午月极旺，丙火比劫，卯木生火，身旺需水金泄制
        //    四柱: 癸酉 戊午 丁卯 丙午  |  木13% 火57% 土10% 金7% 水10%
        Case(name: "1993-06-15 午时", date: "1993-06-15", hour: .wu,
             expectedDayMaster: "丁", expectedFavorable: ["水", "金"],
             baziRef: "癸酉 戊午 丁卯 丙午",
             note: "丁火午月极旺，丙比劫，卯木生火，喜壬癸水调候克制、金泄秀作财"),

        // 9. 丁火 — 卯月木旺生火，丙火比劫，身旺
        //    四柱: 丙子 辛卯 丁巳 癸卯  |  木41% 火29% 土0% 金10% 水18%
        Case(name: "1996-03-21 卯时", date: "1996-03-21", hour: .mao,
             expectedDayMaster: "丁", expectedFavorable: ["水", "金"],
             baziRef: "丙子 辛卯 丁巳 癸卯",
             note: "丁火卯月，木旺生火，丙火比劫，子癸水有制，身旺，喜水金"),

        // 10. 壬水 — 申月金生水，金多水浑(金52%)，「金多水浑泄之以木」
        //     四柱: 辛未 丙申 壬子 戊申  |  木0% 火10% 土18% 金52% 水18%
        Case(name: "1991-08-10 申时", date: "1991-08-10", hour: .shen,
             expectedDayMaster: "壬", expectedFavorable: ["木", "火"],
             baziRef: "辛未 丙申 壬子 戊申",
             note: "壬水申月，金52%多水浑，「金多水浑泄之以木」，喜木泄金、火暖局调候"),
    ]

    // MARK: - 日主正确性断言（核心测试）
    func testDayMasterAccuracy() {
        print("\n========== 日主准确性验证 ==========")
        for c in cases {
            guard let date = formatter.date(from: c.date) else {
                XCTFail("\(c.name) 日期解析失败"); continue
            }
            let dm = engine.getDayMaster(date: date, hour: c.hour)
            let pass = dm.hasPrefix(c.expectedDayMaster)
            print("[\(pass ? "✅" : "❌")] \(c.name) → 日主: \(dm) | 参考四柱: \(c.baziRef)")
            if !pass {
                print("   ⚠️ 期望: \(c.expectedDayMaster), 实际: \(dm.prefix(1))")
            }
            XCTAssertTrue(pass, "\(c.name) 日主错误: 期望首字为[\(c.expectedDayMaster)], 实际[\(dm)]")
        }
    }

    // MARK: - 五行分布详情（人工审查喜用神方向）
    func testPrintEnergyDistribution() {
        print("\n========== 五行分布 & 喜用神参考 ==========")
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

            // 从预期喜用神中找本地计算最低占比的（= weakElement 候选）
            let weakAmongFav = c.expectedFavorable
                .compactMap { name -> (String, Double)? in
                    guard let el = FiveElement(rawValue: name) else { return nil }
                    return (name, scores[el] ?? 0)
                }
                .min(by: { $0.1 < $1.1 })?.0 ?? "?"

            // 日主旺弱简判（基于本地分值）
            guard let dmEl = FiveElement(rawValue: dm.count >= 2 ? String(dm.suffix(1)) : "") else { continue }
            let dmPct = Int((scores[dmEl] ?? 0) * 100)
            let strengthStr = dmPct >= 25 ? "偏旺↑" : "偏弱↓"

            print("【\(c.name)】\(strengthStr) — \(c.note)")
            print("   八字(引擎): \(bazi)")
            print("   参考四柱:   \(c.baziRef)")
            print("   五行: \(dist)")
            print("   日主: \(dm)=\(dmPct)% | 公认喜用: \(c.expectedFavorable.joined(separator: "/")) | 最缺喜用→weakElement候选: \(weakAmongFav)")
            print()
        }
    }

    // MARK: - 归一化验证
    func testNormalizationIsCorrect() {
        for c in cases {
            guard let date = formatter.date(from: c.date) else { continue }
            let scores = engine.calculateEnergy(date: date, hour: c.hour)
            let total = scores.values.reduce(0, +)
            XCTAssertEqual(total, 1.0, accuracy: 0.001, "\(c.name) 五行总分不为1.0: \(total)")
        }
    }

    // MARK: - 喜用神准确性断言（核心业务逻辑）
    func testFavorableElementsAccuracy() {
        print("\n========== 喜用神准确性验证 ==========")
        var pass = 0
        for c in cases {
            guard let date = formatter.date(from: c.date) else { continue }
            let (fav, unf, weak) = engine.calculateFavorableElements(date: date, hour: c.hour)
            let favSet = Set(fav); let expSet = Set(c.expectedFavorable)
            let favOK = favSet == expSet
            if favOK { pass += 1 }
            let mark = favOK ? "✅" : "❌"
            print("\(mark) \(c.name)")
            print("   喜用: \(fav) 期望: \(c.expectedFavorable)")
            print("   忌神: \(unf)  weakElement: 【\(weak)】")
            if !favOK { print("   ⚠️ 与公认喜用神不符，请检查命局") }
            XCTAssertEqual(favSet, expSet,
                "\(c.name) 喜用神不符：计算\(fav)，期望\(c.expectedFavorable)")
        }
        print("\n喜用神准确率: \(pass)/\(cases.count)")
    }

    // MARK: - weakElement 不在忌神中（自洽性验证）
    func testWeakElementNotInUnfavorable() {
        print("\n========== weakElement 自洽性验证 ==========")
        for c in cases {
            guard let date = formatter.date(from: c.date) else { continue }
            let (fav, unf, weak) = engine.calculateFavorableElements(date: date, hour: c.hour)
            let inFav = fav.contains(weak)
            let notInUnf = !unf.contains(weak)
            XCTAssertTrue(inFav, "\(c.name) weakElement[\(weak)]不在喜用神\(fav)中")
            XCTAssertTrue(notInUnf, "\(c.name) weakElement[\(weak)]出现在忌神\(unf)中（矛盾！）")
            let mark = (inFav && notInUnf) ? "✅" : "❌"
            print("\(mark) \(c.name): weakEl=\(weak) 在喜用\(fav)中=\(inFav) 不在忌\(unf)中=\(notInUnf)")
        }
    }
}
