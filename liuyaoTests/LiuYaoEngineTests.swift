import XCTest
@testable import LifeCoach

final class LiuYaoEngineTests: XCTestCase {
    private func pillars(month: String, day: String, kong: [String]) -> LiuYaoFourPillars {
        var value = LiuYaoCalendar.pillars(year: "丙午", month: month, day: day, hour: "辛巳")
        value.xunKong = kong
        value.xunKongIndex = kong.map { LiuYaoCalendar.zhiIndex($0) }
        return value
    }

    func testQianWeiTianCaiYunAnchor() {
        let reading = LiuYaoEngine.buildReading(
            bits: "111111",
            moving: [:],
            pillars: pillars(month: "丙申", day: "庚寅", kong: ["午", "未"]),
            category: "财运",
            question: "近期投资能否获利",
            location: nil
        )

        XCTAssertEqual(reading.palace.gua, "乾")
        XCTAssertEqual(reading.palace.wuXing, "金")
        XCTAssertEqual(reading.palace.type, "本宫")
        XCTAssertNil(reading.changed)
        XCTAssertEqual(reading.castTime.monthBranch, "申")
        XCTAssertEqual(reading.castTime.xunKong, ["午", "未"])
        XCTAssertEqual(reading.yongShen?.liuQin, "妻财")
        XCTAssertEqual(reading.yongShen?.positions, [2])
        XCTAssertEqual(reading.yongShen?.chosen, 2)
        XCTAssertEqual(reading.yongShen?.fuCang, false)
        XCTAssertEqual(reading.yongShen?.suggested, true)

        let expected: [(String, String, String, String, String?)] = [
            ("子孙", "甲", "子", "白虎", nil),
            ("妻财", "甲", "寅", "玄武", nil),
            ("父母", "甲", "辰", "青龙", "应"),
            ("官鬼", "壬", "午", "朱雀", nil),
            ("兄弟", "壬", "申", "勾陈", nil),
            ("父母", "壬", "戌", "螣蛇", "世")
        ]
        for (index, item) in expected.enumerated() {
            let line = reading.primary.lines[index]
            XCTAssertEqual(line.liuQin, item.0, "爻\(index + 1)六亲")
            XCTAssertEqual(line.naJia.gan, item.1)
            XCTAssertEqual(line.naJia.zhi, item.2)
            XCTAssertEqual(line.liuShen, item.3)
            XCTAssertEqual(line.shiYing, item.4)
            XCTAssertEqual(line.yinYang, "yang")
            XCTAssertNil(line.moving)
        }

        XCTAssertEqual(reading.primary.lines[3].flags.xunKong, true)
        XCTAssertEqual(reading.primary.lines[1].flags.yuePo, true)
        XCTAssertEqual(reading.assessment.yong?.wangShuai, "死")
        XCTAssertEqual(reading.assessment.yong?.yuePo, true)
        XCTAssertEqual(reading.assessment.yong?.deRi, true)
        XCTAssertEqual(reading.assessment.yong?.anDong, false)
        XCTAssertEqual(reading.assessment.yuan?.liuQin, "子孙")
        XCTAssertEqual(reading.assessment.yuan?.wangShuai, "相")
        XCTAssertEqual(reading.assessment.ji?.liuQin, "兄弟")
        XCTAssertEqual(reading.assessment.ji?.wangShuai, "旺")
        XCTAssertEqual(reading.assessment.ji?.beiRiChong, true)
        XCTAssertEqual(reading.assessment.ji?.anDong, true)
        XCTAssertEqual(reading.assessment.chou?.liuQin, "父母")
    }

    func testMovingLinesAndChangedHexagram() {
        let reading = LiuYaoEngine.buildReading(
            bits: "100000",
            moving: [1: "老阳", 2: "老阴"],
            pillars: pillars(month: "丙申", day: "庚寅", kong: ["午", "未"]),
            category: "财运",
            question: "有动爻",
            location: nil
        )
        XCTAssertEqual(reading.primary.lines[0].moving, "老阳")
        XCTAssertEqual(reading.primary.lines[1].moving, "老阴")
        XCTAssertEqual(reading.changed?.name, "地水师")
    }

    func testFuShenExample() {
        let reading = LiuYaoEngine.buildReading(
            bits: "011111",
            moving: [3: "老阳"],
            pillars: pillars(month: "丙子", day: "甲子", kong: ["戌", "亥"]),
            category: "财运",
            question: "求财",
            location: nil
        )
        XCTAssertEqual(reading.yongShen?.fuCang, true)
        XCTAssertEqual(reading.yongShen?.positions, [])
        XCTAssertNil(reading.yongShen?.chosen)
        XCTAssertEqual(reading.changed?.name, "天水讼")
        XCTAssertEqual(reading.primary.lines[2].moving, "老阳")
        XCTAssertEqual(reading.primary.lines[1].fuShen?.najia, "甲寅")
        XCTAssertEqual(reading.primary.lines[1].fuShen?.feiFu, "飞来生伏")
        XCTAssertEqual(reading.assessment.yong?.fuCang, true)
        XCTAssertEqual(reading.assessment.yong?.fuShenPosition, 2)
    }

    func testUnclassifiedLeavesYongShenEmpty() {
        let reading = LiuYaoEngine.buildReading(
            bits: "111111",
            moving: [:],
            pillars: pillars(month: "丙申", day: "庚寅", kong: ["午", "未"]),
            category: nil,
            question: "分手后要不要跳槽",
            location: nil
        )
        XCTAssertNil(reading.question.category)
        XCTAssertNil(reading.yongShen)
        XCTAssertTrue(reading.assessment.isEmpty)
        XCTAssertEqual(reading.primary.lines.count, 6)
        XCTAssertEqual(reading.palace.gua, "乾")
    }

    func testReadingIsDeterministic() {
        let first = LiuYaoEngine.buildReading(
            bits: "010101",
            moving: [2: "老阴", 5: "老阳"],
            pillars: pillars(month: "丙申", day: "庚寅", kong: ["午", "未"]),
            category: "事业",
            question: "同一盘",
            location: "上海"
        )
        let second = LiuYaoEngine.buildReading(
            bits: "010101",
            moving: [2: "老阴", 5: "老阳"],
            pillars: first.castTime.ganZhi.year == "丙午"
                ? pillars(month: "丙申", day: "庚寅", kong: ["午", "未"])
                : pillars(month: "丙申", day: "庚寅", kong: ["午", "未"]),
            category: "事业",
            question: "同一盘",
            location: "上海"
        )
        XCTAssertEqual(first.primary, second.primary)
        XCTAssertEqual(first.yongShen, second.yongShen)
        XCTAssertEqual(first.assessment, second.assessment)
        XCTAssertEqual(first.xingHai, second.xingHai)
    }

    func testXingHaiMarksDayBranch() {
        let reading = LiuYaoEngine.buildReading(
            bits: "111111",
            moving: [:],
            pillars: pillars(month: "丙申", day: "辛巳", kong: ["子", "丑"]),
            category: "财运",
            question: "刑害",
            location: nil
        )
        XCTAssertTrue(reading.xingHai.xing.contains { $0.position == 2 && $0.kind == "刑日" && $0.targetZhi == "巳" })
        XCTAssertTrue(reading.xingHai.hai.contains { $0.position == 2 && $0.kind == "害日" && $0.targetZhi == "巳" })
    }

    func testZiShiChangesDayPillar() {
        let early = date("2026-08-12 22:59")
        let late = date("2026-08-12 23:00")
        let before = LiuYaoCalendar.fourPillars(from: early)
        let after = LiuYaoCalendar.fourPillars(from: late)
        XCTAssertNotEqual(before.day, after.day)
        XCTAssertEqual(before.hour.suffix(1), "亥")
        XCTAssertEqual(after.hour.suffix(1), "子")
    }

    func testXunKongOfGengYin() {
        let kong = LiuYaoCalendar.xunKongBranches(dayGanZhi: "庚寅")
        XCTAssertEqual(kong.branches, ["午", "未"])
    }

    func testSolarTermSwitchesMonthBranch() {
        let calendar = shanghaiCalendar()
        var components = DateComponents()
        components.year = 2026
        components.hour = 12
        components.minute = 0
        var previous = ""
        var switched = false
        for day in 1...25 {
            components.month = 8
            components.day = day
            let date = calendar.date(from: components)!
            let month = LiuYaoCalendar.fourPillars(from: date).month
            if !previous.isEmpty && month != previous {
                switched = true
                break
            }
            previous = month
        }
        XCTAssertTrue(switched)
    }

    func testFourStateDistribution() {
        var counts: [YaoXiang: Int] = [:]
        let total = 4000
        for _ in 0..<total {
            let yao = YaoXiang.randomToss()
            counts[yao, default: 0] += 1
        }
        XCTAssertGreaterThan(counts[.oldYang] ?? 0, 350)
        XCTAssertLessThan(counts[.oldYang] ?? 0, 700)
        XCTAssertGreaterThan(counts[.oldYin] ?? 0, 350)
        XCTAssertLessThan(counts[.oldYin] ?? 0, 700)
        XCTAssertGreaterThan(counts[.youngYang] ?? 0, 1200)
        XCTAssertGreaterThan(counts[.youngYin] ?? 0, 1200)
    }

    func testAnchorHexagrams() {
        let anchors: [(String, String, String, [(String, String, String?)])] = [
            ("111111", "庚", "乾为天", [
                ("子孙", "甲子", nil), ("妻财", "甲寅", nil), ("父母", "甲辰", "应"),
                ("官鬼", "壬午", nil), ("兄弟", "壬申", nil), ("父母", "壬戌", "世")
            ]),
            ("011111", "甲", "天风姤", [
                ("父母", "辛丑", "世"), ("子孙", "辛亥", nil), ("兄弟", "辛酉", nil),
                ("官鬼", "壬午", "应"), ("兄弟", "壬申", nil), ("父母", "壬戌", nil)
            ]),
            ("010010", "壬", "坎为水", [
                ("子孙", "戊寅", nil), ("官鬼", "戊辰", nil), ("妻财", "戊午", "应"),
                ("父母", "戊申", nil), ("官鬼", "戊戌", nil), ("兄弟", "戊子", "世")
            ])
        ]
        for anchor in anchors {
            let chart = LiuYaoHexagram.castChart(bits: anchor.0, dayGanIndex: LiuYaoCalendar.ganIndex(anchor.1))
            XCTAssertEqual(chart?.name, anchor.2)
            for (index, expected) in anchor.3.enumerated() {
                XCTAssertEqual(chart?.yaos[index].liuQin, expected.0)
                XCTAssertEqual(chart?.yaos[index].najia, expected.1)
                XCTAssertEqual(chart?.yaos[index].shiYing, expected.2)
            }
        }
    }

    private func date(_ text: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: text)!
    }

    private func shanghaiCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }
}

final class MasterReportParserTests: XCTestCase {
    func testParsesFifteenSectionsAndMovesEyeUp() {
        let titles = MasterReportParser.anchors
        let text = titles.enumerated().map { index, title in
            "### \(index + 1) \(title)\n这是\(title)的正文。"
        }.joined(separator: "\n")
        let parsed = MasterReportParser.parse(text)
        XCTAssertTrue(parsed.complete)
        XCTAssertTrue(parsed.usable)
        XCTAssertEqual(parsed.sections.count, 15)
        XCTAssertEqual(MasterReportParser.displayOrder[0], "核心结论")
        XCTAssertEqual(MasterReportParser.displayOrder[1], "卦眼")
        XCTAssertTrue(parsed.sections["卦眼"]?.contains("卦眼的正文") == true)
        XCTAssertFalse(parsed.sections["核心结论"]?.contains("###") == true)
    }

    func testStripsDuplicateTitlesMarkdownAndHeadingLeaks() {
        let text = """
        ### ① 核心结论
        **标题固定：核心结论**
        **核心结论**

        读研这件事需要主动变革。核心策略是：**不要因惯性而读研**。

        ### ② 卦象档案
        - **所问之事**：我应该继续读研吗？
        - **本卦**：泽火革

        ### ③ 专业排盘
        | 六神 | 六亲 | 地支 | 五行 | 世应 | 动爻 | 变爻 |
        | --- | --- | --- | --- | --- | --- | --- |
        | 朱雀 | 兄弟 | 亥 | 水 | **世** | | |
        | 白虎 | 子孙 | 卯 | 木 | **应** | | |

        - **月建**：酉（金）

        以上专业排盘用于说明判断依据。

        ### ⑤ 卦眼
        **卦眼**

        真正的问题不是要不要继续读。

        ### ⑥ 卦象在说什么
        泽火革，上兑为泽。
        """
        let parsed = MasterReportParser.parse(text)
        let conclusion = parsed.sections["核心结论"] ?? ""
        XCTAssertFalse(conclusion.contains("**"))
        XCTAssertFalse(conclusion.contains("###"))
        XCTAssertFalse(conclusion.contains("②"))
        XCTAssertFalse(conclusion.contains("核心结论"))
        XCTAssertTrue(conclusion.contains("不要因惯性而读研"))

        let archive = parsed.sections["卦象档案"] ?? ""
        XCTAssertFalse(archive.contains("**"))
        XCTAssertFalse(archive.contains("###"))
        XCTAssertTrue(archive.contains("所问之事：我应该继续读研吗？"))
        XCTAssertTrue(archive.contains("本卦：泽火革"))

        let plate = parsed.sections["专业排盘"] ?? ""
        XCTAssertFalse(plate.contains("|"))
        XCTAssertFalse(plate.contains("**"))
        XCTAssertFalse(plate.contains("③"))
        XCTAssertTrue(plate.contains("月建：酉（金）"))
        XCTAssertTrue(plate.contains("以上专业排盘用于说明判断依据。"))
        let chart = parsed.blocks["专业排盘"]?.first { block in
            if case .chart = block.kind { return true }
            return false
        }
        guard case .chart(let headers, let rows)? = chart?.kind else {
            return XCTFail("专业排盘应解析为爻表")
        }
        XCTAssertTrue(headers.contains("六亲"))
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0][4], "世")

        let eye = parsed.sections["卦眼"] ?? ""
        XCTAssertFalse(eye.contains("###"))
        XCTAssertFalse(eye.contains("⑤"))
        XCTAssertFalse(eye.contains("**"))
        XCTAssertEqual(eye, "真正的问题不是要不要继续读。")
    }

    func testStripsBlockquotesAndEmphasizesKeyLines() {
        let text = """
        ### ⑨ 为什么这样判断
        > ① 用神月破，创业时机未到
        > 六爻依据：用神子孙卯木，月建酉金冲克，为月破。
        > 代表什么：子孙代表创业。
        > 简单来说：现在不是开新摊子的时候。

        > ② 世爻被合，现实牵绊较重
        > 简单来说：现有工作暂时离不开。

        ### ⑩ 三个关键信号
        > 信号一｜火在地下，光未露头
        > 解释：本卦地火明夷。

        ### ⑬ 现在最值得做的事
        > 稳住现有工作，但调整心态
        > 说明：世爻官鬼被日辰合住。
        """
        let parsed = MasterReportParser.parse(text)
        let reason = parsed.sections["为什么这样判断"] ?? ""
        XCTAssertFalse(reason.contains(">"))
        XCTAssertTrue(reason.contains("① 用神月破，创业时机未到"))
        XCTAssertTrue(reason.contains("简单来说：现在不是开新摊子的时候。"))

        let points = (parsed.blocks["为什么这样判断"] ?? []).compactMap { block -> (String, [MasterReportParser.Detail])? in
            if case .point(let headline, let details) = block.kind { return (headline, details) }
            return nil
        }
        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].0, "① 用神月破，创业时机未到")
        XCTAssertEqual(points[0].1.first { $0.label == "六爻依据" }?.emphasis, .quiet)
        XCTAssertEqual(points[0].1.first { $0.label == "简单来说" }?.emphasis, .strong)

        let signal = parsed.sections["三个关键信号"] ?? ""
        XCTAssertFalse(signal.contains(">"))
        XCTAssertTrue(signal.contains("信号一｜火在地下，光未露头"))
        XCTAssertEqual(parsed.blocks["三个关键信号"]?.count, 1)

        let action = parsed.sections["现在最值得做的事"] ?? ""
        XCTAssertFalse(action.contains(">"))
        XCTAssertTrue(action.contains("稳住现有工作，但调整心态"))
        XCTAssertTrue(action.contains("说明：世爻官鬼被日辰合住。"))
        let actionPoints = parsed.blocks["现在最值得做的事"] ?? []
        guard case .point(let headline, let details) = actionPoints.first?.kind else {
            return XCTFail("建议应解析成一条要点")
        }
        XCTAssertEqual(headline, "稳住现有工作，但调整心态")
        XCTAssertEqual(details.first?.label, "说明")
    }

    func testParseFailureFallsBack() {
        let parsed = MasterReportParser.parse("这是一篇没有标题的报告")
        XCTAssertFalse(parsed.usable)
        XCTAssertFalse(parsed.complete)
    }
}

final class QuestionCategoryTests: XCTestCase {
    func testCatalogCoversFiftyQuestions() {
        XCTAssertEqual(QuestionCategoryResolver.catalog.count, 50)
    }

    func testCatalogQuestions() {
        let expected: [(String, String?)] = [
            ("我现在适合换工作吗？", "事业"),
            ("留在现在的公司还有发展空间吗？", "事业"),
            ("我该争取晋升，还是考虑跳槽？", "事业"),
            ("这份新 Offer 值得接受吗？", "事业"),
            ("我现在适合转行吗？", "事业"),
            ("我现在适合裸辞吗？", "事业"),
            ("未来半年我的职业重点应该放在哪里？", "事业"),
            ("我该继续打工，还是尝试创业？", "谋望"),
            ("我目前最大的职业瓶颈是什么？", "事业"),
            ("我该继续深耕主业，还是发展副业？", "事业"),
            ("这段感情还值得继续吗？", "姻缘"),
            ("我们之间还有进一步发展的可能吗？", "姻缘"),
            ("我现在适合主动联系对方吗？", "姻缘"),
            ("这段关系的问题到底出在哪里？", "姻缘"),
            ("我们现在更适合继续磨合，还是分开？", "姻缘"),
            ("我应该接受这段关系的现状吗？", "姻缘"),
            ("对这段感情，我还应该继续投入吗？", "姻缘"),
            ("我们之间还有重新开始的机会吗？", "姻缘"),
            ("我该主动推进这段关系吗？", "姻缘"),
            ("我现在应该等待，还是做出改变？", "姻缘"),
            ("我应该继续读研吗？", "考试"),
            ("我现在适合考研还是先工作？", "考试"),
            ("我应该坚持现在的专业方向吗？", "考试"),
            ("我现在适合出国读书吗？", "考试"),
            ("我该继续备考，还是换一个方向？", "考试"),
            ("我现在最应该提升哪方面的能力？", "考试"),
            ("我应该把时间投入专业能力还是副业技能？", "考试"),
            ("这次考试我应该继续冲一把吗？", "考试"),
            ("我现在最需要解决的问题是什么？", nil),
            ("我最近为什么总感觉找不到方向？", nil),
            ("我现在适合开始创业吗？", "事业"),
            ("这个项目值得我继续投入吗？", "事业"),
            ("我应该继续坚持这个项目，还是及时止损？", "事业"),
            ("现在是扩大投入的好时机吗？", "事业"),
            ("我该独立做，还是找合伙人一起做？", "合作"),
            ("这个副业值得我长期发展吗？", "事业"),
            ("我现在应该先赚钱，还是继续打磨产品？", "事业"),
            ("这个合作机会值得接受吗？", "合作"),
            ("我现在适合做一笔较大的投资吗？", "财运"),
            ("我现在应该更积极赚钱，还是先控制支出？", "财运"),
            ("这笔大额消费现在值得做吗？", "财运"),
            ("我该把更多精力放在主业收入还是副业收入？", "财运"),
            ("我现在适合买房吗？", "搬迁"),
            ("我现在适合扩大自己的事业投入吗？", "财运"),
            ("我应该留在现在的城市，还是去新的地方发展？", "搬迁"),
            ("现在这个机会我应该抓住吗？", "谋望"),
            ("面对两个选择，我应该更看重稳定还是成长？", "谋望"),
            ("我现在适合主动改变现状吗？", "谋望"),
            ("这件事我应该继续推进，还是先等等？", "谋望"),
            ("未来三个月，我最应该把精力放在哪里？", "谋望")
        ]
        XCTAssertEqual(expected.count, 50)
        for item in expected {
            let resolved = QuestionCategoryResolver.resolve(question: item.0, hint: "职业")
            XCTAssertEqual(resolved.category, item.1, item.0)
            XCTAssertEqual(resolved.source, .catalog, item.0)
        }
    }

    func testFreeInputGoldenSet() {
        let cases: [(String, String?, CategorySource)] = [
            ("下周我想跳槽", "事业", .keyword),
            ("分手后要不要跳槽", nil, .unclassified),
            ("现在适合买房吗", "搬迁", .keyword),
            ("想去旅游", "出行", .keyword),
            ("要不要做手术", "健康", .keyword),
            ("钱包丢了", "失物", .keyword),
            ("未来怎么办", nil, .unclassified),
            ("我面对两个选择", "谋望", .keyword),
            ("创业还是找人合作", nil, .unclassified),
            ("准备考研", "考试", .keyword),
            ("我要结婚吗", "姻缘", .keyword),
            ("股票还能不能拿", "财运", .keyword),
            ("找不到方向", nil, .unclassified),
            ("钥匙找不到了", "失物", .keyword),
            ("明天有个面试", nil, .unclassified),
            ("明天求职面试", "事业", .keyword),
            ("备考面试很紧张", "考试", .keyword),
            ("打算搬家", "搬迁", .keyword),
            ("下周出差", "出行", .keyword),
            ("要不要融资", "事业", .keyword),
            ("这份合同要不要签约", "合作", .keyword),
            ("体检报告出来了", "健康", .keyword),
            ("该不该抓住这个机会", "谋望", .keyword),
            ("投资还是买房", nil, .unclassified),
            ("裸辞去考研", nil, .unclassified),
            ("我老公想离婚", "姻缘", .keyword),
            ("工资太低想跳槽", nil, .unclassified),
            ("租房还是买房", "搬迁", .keyword),
            ("这个项目要不要继续", "事业", .keyword),
            ("和同事加班太多", "事业", .keyword),
            ("要不要去相亲", "姻缘", .keyword),
            ("有一笔借款要不要追", "财运", .keyword),
            ("我现在适合买房吗？", "搬迁", .catalog)
        ]
        for item in cases {
            let resolved = QuestionCategoryResolver.resolve(question: item.0, hint: nil)
            XCTAssertEqual(resolved.category, item.1, item.0)
            XCTAssertEqual(resolved.source, item.2, item.0)
        }
    }
}
