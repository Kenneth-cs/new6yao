import Foundation

enum LiuYaoEngine {
    static func buildReading(
        bits: String,
        moving: [Int: String],
        date: Date,
        category: String?,
        question: String,
        location: String?
    ) -> LiuYaoReading {
        buildReading(
            bits: bits,
            moving: moving,
            pillars: LiuYaoCalendar.fourPillars(from: date),
            category: category,
            question: question,
            location: location
        )
    }

    static func buildReading(
        bits: String,
        moving: [Int: String],
        pillars: LiuYaoFourPillars,
        category: String?,
        question: String,
        location: String?
    ) -> LiuYaoReading {
        let movingSet = Set(moving.keys)
        let primary = LiuYaoHexagram.castChart(bits: bits, dayGanIndex: pillars.dayGanIndex)
            ?? LiuYaoHexagram.castChart(bits: "111111", dayGanIndex: pillars.dayGanIndex)!
        let bian: LiuYaoHexagram.Chart? = movingSet.isEmpty
            ? nil
            : LiuYaoHexagram.castChart(
                bits: LiuYaoHexagram.bianBits(primary.bits, moving: movingSet),
                dayGanIndex: pillars.dayGanIndex
            )

        let flags = Dictionary(uniqueKeysWithValues: LiuYaoAnalysis.yaoFlags(
            chart: primary,
            monthBranch: pillars.monthZhiIndex,
            dayZhi: pillars.dayZhiIndex,
            xunKong: pillars.xunKongIndex
        ).map { ($0.position, $0) })

        let known = category.flatMap { LiuYaoAnalysis.isKnownCategory($0) ? $0 : nil }
        let pick = known.flatMap {
            LiuYaoAnalysis.selectYongShen(
                chart: primary,
                category: $0,
                monthBranch: pillars.monthZhiIndex,
                dayZhi: pillars.dayZhiIndex,
                xunKong: pillars.xunKongIndex,
                moving: movingSet,
                dayGan: pillars.dayGanIndex
            )
        }

        var feiFuRelation: String?
        var fuShenPosition: Int?
        var assessment = LiuYaoReading.AssessmentBlock(yong: nil, yuan: nil, ji: nil, chou: nil)
        if let pick {
            if let yongPos = pick.chosen {
                let yongWX = primary.yaos[yongPos - 1].wuXing
                let roles = LiuYaoAnalysis.yuanJiChou(yongWuXing: yongWX, palaceWuXing: primary.palaceWuXing)
                assessment.yong = makeEntry(pick.liuQin, yongPos, primary, bian, pillars, movingSet)
                assessment.yuan = makeEntry(roles.yuan, firstPosition(primary, roles.yuan), primary, bian, pillars, movingSet)
                assessment.ji = makeEntry(roles.ji, firstPosition(primary, roles.ji), primary, bian, pillars, movingSet)
                assessment.chou = makeEntry(roles.chou, firstPosition(primary, roles.chou), primary, bian, pillars, movingSet)
                if var yong = assessment.yong {
                    yong.relations = LiuYaoRelations.yongRelations(
                        primary: primary,
                        bian: bian,
                        yongPosition: yongPos,
                        yongWuXing: yongWX,
                        moving: movingSet,
                        dayZhi: pillars.dayZhiIndex,
                        monthBranch: pillars.monthZhiIndex
                    )
                    assessment.yong = yong
                }
            } else if pick.fuCang, let fu = pick.fuShen {
                fuShenPosition = fu.position
                let feiWX = primary.yaos[fu.position - 1].wuXing
                feiFuRelation = LiuYaoAnalysis.feiFu(feiWuXing: feiWX, fuWuXing: fu.wuXing)
                var fuEntry = LiuYaoAnalysis.fuShenForce(
                    fuWuXing: fu.wuXing,
                    fuZhi: fu.zhi,
                    liuQin: pick.liuQin,
                    monthBranch: pillars.monthZhiIndex,
                    dayZhi: pillars.dayZhiIndex,
                    xunKong: pillars.xunKongIndex
                )
                fuEntry.feiFu = feiFuRelation
                fuEntry.fuCang = true
                fuEntry.fuShenPosition = fu.position
                let roles = LiuYaoAnalysis.yuanJiChou(yongWuXing: fu.wuXing, palaceWuXing: primary.palaceWuXing)
                assessment.yong = fuEntry
                assessment.yuan = makeEntry(roles.yuan, firstPosition(primary, roles.yuan), primary, bian, pillars, movingSet)
                assessment.ji = makeEntry(roles.ji, firstPosition(primary, roles.ji), primary, bian, pillars, movingSet)
                assessment.chou = makeEntry(roles.chou, firstPosition(primary, roles.chou), primary, bian, pillars, movingSet)
            }
        }

        let lineRels = LiuYaoRelations.lineRelations(
            primary: primary,
            bian: bian,
            moving: movingSet,
            dayZhi: pillars.dayZhiIndex,
            monthBranch: pillars.monthZhiIndex
        )
        let monthZhi = LiuYaoCalendar.zhiText(pillars.monthZhiIndex)
        let dayZhi = LiuYaoCalendar.zhiText(pillars.dayZhiIndex)

        let yongBlock: LiuYaoReading.YongShenBlock? = pick.map {
            LiuYaoReading.YongShenBlock(
                liuQin: $0.liuQin,
                positions: $0.positions,
                chosen: $0.chosen,
                liangXian: $0.liangXian,
                fuCang: $0.fuCang,
                suggested: true,
                yingAsGuide: $0.yingAsGuide
            )
        }

        let city = location?.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationBlock: LiuYaoReading.LocationBlock? = (city?.isEmpty == false)
            ? LiuYaoReading.LocationBlock(city: city!, direction: nil, wuXing: nil)
            : nil

        return LiuYaoReading(
            question: LiuYaoReading.QuestionBlock(category: known, text: question),
            castTime: LiuYaoReading.CastTimeBlock(
                localTime: isoString(pillars.localTime),
                ganZhi: LiuYaoReading.GanZhiBlock(
                    year: pillars.year,
                    month: pillars.month,
                    day: pillars.day,
                    hour: pillars.hour
                ),
                monthBranch: monthZhi,
                dayPillar: pillars.day,
                xunKong: pillars.xunKong
            ),
            palace: LiuYaoReading.PalaceBlock(
                gua: primary.palace,
                wuXing: primary.palaceWuXing,
                type: primary.guaType
            ),
            primary: chartBlock(
                primary,
                moving: moving,
                flags: flags,
                relations: lineRels,
                fuShenPosition: fuShenPosition,
                fuShen: pick?.fuShen,
                fuLiuQin: pick?.liuQin,
                feiFu: feiFuRelation
            ),
            changed: bian.map {
                chartBlock(
                    $0,
                    moving: moving,
                    flags: flags,
                    relations: [:],
                    fuShenPosition: fuShenPosition,
                    fuShen: pick?.fuShen,
                    fuLiuQin: pick?.liuQin,
                    feiFu: feiFuRelation
                )
            },
            yongShen: yongBlock,
            assessment: assessment,
            relations: LiuYaoRelations.guaRelations(primary: primary, bian: bian, moving: movingSet),
            xingHai: LiuYaoXingHai.evaluate(
                chart: primary,
                moving: movingSet,
                dayZhi: dayZhi,
                monthZhi: monthZhi
            ),
            location: locationBlock
        )
    }

    private static func makeEntry(
        _ liuQin: String,
        _ position: Int?,
        _ primary: LiuYaoHexagram.Chart,
        _ bian: LiuYaoHexagram.Chart?,
        _ pillars: LiuYaoFourPillars,
        _ moving: Set<Int>
    ) -> ForceEntry {
        LiuYaoAnalysis.forceEntry(
            chart: primary,
            position: position,
            liuQin: liuQin,
            monthBranch: pillars.monthZhiIndex,
            dayZhi: pillars.dayZhiIndex,
            xunKong: pillars.xunKongIndex,
            moving: moving,
            bianChart: bian
        )
    }

    private static func firstPosition(_ chart: LiuYaoHexagram.Chart, _ liuQin: String) -> Int? {
        chart.positions(of: liuQin).first
    }

    private static func chartBlock(
        _ chart: LiuYaoHexagram.Chart,
        moving: [Int: String],
        flags: [Int: LiuYaoAnalysis.YaoFlags],
        relations: [Int: LineRelations],
        fuShenPosition: Int?,
        fuShen: LiuYaoHexagram.Yao?,
        fuLiuQin: String?,
        feiFu: String?
    ) -> LiuYaoReading.HexagramBlock {
        let lines = chart.yaos.map { yao -> LiuYaoLine in
            let flag = flags[yao.position]
            var fu: LiuYaoLine.FuShenInfo?
            if fuShenPosition == yao.position, let hidden = fuShen {
                fu = LiuYaoLine.FuShenInfo(
                    gan: hidden.gan,
                    zhi: hidden.zhi,
                    najia: hidden.najia,
                    liuQin: fuLiuQin ?? hidden.liuQin,
                    wuXing: hidden.wuXing,
                    feiFu: feiFu
                )
            }
            return LiuYaoLine(
                position: yao.position,
                yinYang: yao.yinYang == "阳" ? "yang" : "yin",
                moving: moving[yao.position],
                naJia: LiuYaoLine.NaJia(gan: yao.gan, zhi: yao.zhi),
                wuXing: yao.wuXing,
                liuQin: yao.liuQin,
                liuShen: yao.liuShen,
                shiYing: yao.shiYing,
                fuShen: fu,
                flags: LiuYaoLine.LineFlags(
                    xunKong: flag?.xunKong ?? false,
                    yuePo: flag?.yuePo ?? false,
                    riChong: flag?.riChong ?? false
                ),
                relations: relations[yao.position] ?? .empty
            )
        }
        return LiuYaoReading.HexagramBlock(
            upper: chart.upperName,
            lower: chart.lowerName,
            name: chart.name,
            lines: lines
        )
    }

    private static func isoString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}
