import Foundation

/// 三刑、六害。只标地支关系，不下吉凶。
enum LiuYaoXingHai {
    private static let sanXingGroups: [Set<String>] = [
        ["寅", "巳", "申"],
        ["丑", "戌", "未"],
        ["子", "卯"]
    ]
    private static let selfXing: Set<String> = ["辰", "午", "酉", "亥"]
    private static let liuHai: Set<String> = [
        "子未", "未子", "丑午", "午丑", "寅巳", "巳寅",
        "卯辰", "辰卯", "申亥", "亥申", "酉戌", "戌酉"
    ]

    static func evaluate(
        chart: LiuYaoHexagram.Chart,
        moving: Set<Int>,
        dayZhi: String,
        monthZhi: String
    ) -> XingHaiResult {
        var xing: [XingHaiHit] = []
        var hai: [XingHaiHit] = []
        let movingYaos = chart.yaos.filter { moving.contains($0.position) }
        for yao in chart.yaos {
            appendPair(
                position: yao.position,
                zhi: yao.zhi,
                targetZhi: dayZhi,
                targetPosition: nil,
                xingKind: "刑日",
                haiKind: "害日",
                xing: &xing,
                hai: &hai
            )
            appendPair(
                position: yao.position,
                zhi: yao.zhi,
                targetZhi: monthZhi,
                targetPosition: nil,
                xingKind: "刑月",
                haiKind: "害月",
                xing: &xing,
                hai: &hai
            )
            for other in movingYaos where other.position != yao.position {
                appendPair(
                    position: yao.position,
                    zhi: yao.zhi,
                    targetZhi: other.zhi,
                    targetPosition: other.position,
                    xingKind: "刑动爻",
                    haiKind: "害动爻",
                    xing: &xing,
                    hai: &hai
                )
            }
        }
        return XingHaiResult(xing: xing, hai: hai)
    }

    private static func appendPair(
        position: Int,
        zhi: String,
        targetZhi: String,
        targetPosition: Int?,
        xingKind: String,
        haiKind: String,
        xing: inout [XingHaiHit],
        hai: inout [XingHaiHit]
    ) {
        if isXing(zhi, targetZhi) {
            xing.append(XingHaiHit(
                position: position,
                kind: xingKind,
                zhi: zhi,
                targetZhi: targetZhi,
                targetPosition: targetPosition
            ))
        }
        if isHai(zhi, targetZhi) {
            hai.append(XingHaiHit(
                position: position,
                kind: haiKind,
                zhi: zhi,
                targetZhi: targetZhi,
                targetPosition: targetPosition
            ))
        }
    }

    static func isXing(_ a: String, _ b: String) -> Bool {
        if a == b { return selfXing.contains(a) }
        return sanXingGroups.contains { $0.contains(a) && $0.contains(b) }
    }

    static func isHai(_ a: String, _ b: String) -> Bool {
        liuHai.contains(a + b)
    }
}
