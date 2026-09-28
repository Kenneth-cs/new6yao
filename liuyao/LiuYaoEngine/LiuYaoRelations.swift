import Foundation

enum LiuYaoRelations {
    private static let liuHePairs: Set<Int> = {
        let pairs = [(0, 1), (2, 11), (3, 10), (4, 9), (5, 8), (6, 7)]
        var set = Set<Int>()
        for (a, b) in pairs {
            set.insert(a * 12 + b)
            set.insert(b * 12 + a)
        }
        return set
    }()

    private static let sanHe: [String: (trio: Set<Int>, zhong: Int)] = [
        "水": ([8, 0, 4], 0),
        "木": ([11, 3, 7], 3),
        "火": ([2, 6, 10], 6),
        "金": ([5, 9, 1], 9)
    ]

    private static let changSheng: [String: [String: Int]] = [
        "木": ["长生": 11, "帝旺": 3, "墓": 7, "绝": 8],
        "火": ["长生": 2, "帝旺": 6, "墓": 10, "绝": 11],
        "金": ["长生": 5, "帝旺": 9, "墓": 1, "绝": 2],
        "水": ["长生": 8, "帝旺": 0, "墓": 4, "绝": 5],
        "土": ["长生": 8, "帝旺": 0, "墓": 4, "绝": 5]
    ]

    static func isLiuHe(_ a: Int, _ b: Int) -> Bool {
        liuHePairs.contains(a * 12 + b)
    }

    static func changShengState(wuXing: String, zhiIndex: Int) -> String? {
        changSheng[wuXing]?.first { $0.value == zhiIndex }?.key
    }

    static func lineRelations(
        primary: LiuYaoHexagram.Chart,
        bian: LiuYaoHexagram.Chart?,
        moving: Set<Int>,
        dayZhi: Int,
        monthBranch: Int
    ) -> [Int: LineRelations] {
        var output: [Int: LineRelations] = [:]
        for yao in primary.yaos {
            let zi = LiuYaoCalendar.zhiIndex(yao.zhi)
            var relation = LineRelations.empty
            if let bian, moving.contains(yao.position) {
                let changed = LiuYaoCalendar.zhiIndex(bian.yaos[yao.position - 1].zhi)
                if changed == zi { relation.fuYin = true }
                else if changed == LiuYaoAnalysis.chong(zi) { relation.fanYin = true }
            }
            var he: [String] = []
            if isLiuHe(zi, dayZhi) { he.append("日合") }
            if isLiuHe(zi, monthBranch) { he.append("月合") }
            if !he.isEmpty { relation.he = he }
            if moving.contains(yao.position) {
                for other in moving where other != yao.position {
                    let otherZhi = LiuYaoCalendar.zhiIndex(primary.yaos[other - 1].zhi)
                    if isLiuHe(zi, otherZhi) {
                        relation.dongHe = true
                        break
                    }
                }
            }
            if !relation.isEmpty {
                output[yao.position] = relation
            }
        }
        return output
    }

    static func guaRelations(
        primary: LiuYaoHexagram.Chart,
        bian: LiuYaoHexagram.Chart?,
        moving: Set<Int>
    ) -> GuaRelationBlock {
        var fanYin = "无"
        var fuYin = "无"
        if let bian {
            for (name, positions) in [("内卦", [1, 2, 3]), ("外卦", [4, 5, 6])] {
                let movers = positions.filter { moving.contains($0) }
                if movers.isEmpty { continue }
                let same = movers.allSatisfy { position in
                    LiuYaoCalendar.zhiIndex(primary.yaos[position - 1].zhi)
                        == LiuYaoCalendar.zhiIndex(bian.yaos[position - 1].zhi)
                }
                let clash = movers.allSatisfy { position in
                    let base = LiuYaoCalendar.zhiIndex(primary.yaos[position - 1].zhi)
                    let changed = LiuYaoCalendar.zhiIndex(bian.yaos[position - 1].zhi)
                    return changed == LiuYaoAnalysis.chong(base)
                }
                if same {
                    fuYin = fuYin == "无" ? name : fuYin + "+" + name
                } else if clash {
                    fanYin = fanYin == "无" ? name : fanYin + "+" + name
                }
            }
        }
        let zhis = primary.yaos.map { LiuYaoCalendar.zhiIndex($0.zhi) }
        let liuHe = (0..<3).allSatisfy { isLiuHe(zhis[$0], zhis[$0 + 3]) }
        let movingZhi = Set(moving.map { LiuYaoCalendar.zhiIndex(primary.yaos[$0 - 1].zhi) })
        let present = Set(zhis)
        var sanHeItems: [GuaRelationBlock.SanHeItem] = []
        for (wuXing, info) in Self.sanHe.sorted(by: { $0.key < $1.key }) {
            let have = info.trio.intersection(present)
            if have.count == 3 || (have.count == 2 && have.contains(info.zhong)) {
                sanHeItems.append(GuaRelationBlock.SanHeItem(
                    wuXing: wuXing,
                    chengJu: have.count == 3 ? "全" : "半",
                    hanDong: !info.trio.intersection(movingZhi).isEmpty
                ))
            }
        }
        return GuaRelationBlock(fanYin: fanYin, fuYin: fuYin, liuHe: liuHe, sanHe: sanHeItems)
    }

    static func yongRelations(
        primary: LiuYaoHexagram.Chart,
        bian: LiuYaoHexagram.Chart?,
        yongPosition: Int?,
        yongWuXing: String,
        moving: Set<Int>,
        dayZhi: Int,
        monthBranch: Int
    ) -> ForceEntry.YongRelations? {
        guard let yongPosition, !yongWuXing.isEmpty else { return nil }
        let mu = changSheng[yongWuXing]?["墓"]
        let jue = changSheng[yongWuXing]?["绝"]
        var types: [String] = []
        var suiGui = false
        if let mu {
            if dayZhi == mu { types.append("日") }
            for position in moving {
                if LiuYaoCalendar.zhiIndex(primary.yaos[position - 1].zhi) == mu {
                    types.append("动")
                    if primary.yaos[position - 1].liuQin == "官鬼" { suiGui = true }
                    break
                }
            }
            if let bian, moving.contains(yongPosition) {
                let changed = bian.yaos[yongPosition - 1]
                if LiuYaoCalendar.zhiIndex(changed.zhi) == mu {
                    types.append("化")
                    if changed.liuQin == "官鬼" { suiGui = true }
                }
            }
        }
        var relation = ForceEntry.YongRelations(ruMu: nil, suiGui: nil, jue: nil, changSheng: nil)
        var hasValue = false
        if !types.isEmpty {
            var seen = Set<String>()
            let joined = types.filter { seen.insert($0).inserted }.joined()
            relation.ruMu = ForceEntry.YongRelations.RuMu(type: joined)
            hasValue = true
            if suiGui {
                relation.suiGui = true
            }
        }
        if let jue, dayZhi == jue || monthBranch == jue {
            relation.jue = true
            hasValue = true
        }
        var states: [String: String] = [:]
        if let dayState = changShengState(wuXing: yongWuXing, zhiIndex: dayZhi) {
            states["日"] = dayState
        }
        if let monthState = changShengState(wuXing: yongWuXing, zhiIndex: monthBranch) {
            states["月"] = monthState
        }
        if !states.isEmpty {
            relation.changSheng = states
            hasValue = true
        }
        return hasValue ? relation : nil
    }
}
