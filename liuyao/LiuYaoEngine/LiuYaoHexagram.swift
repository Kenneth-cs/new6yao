import Foundation

/// 纳甲装卦。查表与 `hexagram.py` 一致：bits 自下而上，索引 0 = 初爻。
enum LiuYaoHexagram {
    struct Yao {
        var position: Int
        var yinYang: String
        var gan: String
        var zhi: String
        var wuXing: String
        var liuQin: String
        var liuShen: String
        var shiYing: String?

        var najia: String { gan + zhi }
    }

    struct Chart {
        var bits: String
        var name: String
        var upperName: String
        var lowerName: String
        var palace: String
        var palaceWuXing: String
        var guaType: String
        var shiPos: Int
        var yingPos: Int
        var yaos: [Yao]

        func positions(of liuQin: String) -> [Int] {
            yaos.filter { $0.liuQin == liuQin }.map(\.position)
        }
    }

    static let trigramName: [String: String] = [
        "111": "乾", "110": "兑", "101": "离", "100": "震",
        "011": "巽", "010": "坎", "001": "艮", "000": "坤"
    ]

    static let palaceWuXing: [String: String] = [
        "乾": "金", "兑": "金", "离": "火", "震": "木",
        "巽": "木", "坎": "水", "艮": "土", "坤": "土"
    ]

    /// innerGan, innerZhi, outerGan, outerZhi
    static let naJia: [String: (String, String, String, String)] = [
        "乾": ("甲", "子寅辰", "壬", "午申戌"),
        "坎": ("戊", "寅辰午", "戊", "申戌子"),
        "艮": ("丙", "辰午申", "丙", "戌子寅"),
        "震": ("庚", "子寅辰", "庚", "午申戌"),
        "巽": ("辛", "丑亥酉", "辛", "未巳卯"),
        "离": ("己", "卯丑亥", "己", "酉未巳"),
        "坤": ("乙", "未巳卯", "癸", "丑亥酉"),
        "兑": ("丁", "巳卯丑", "丁", "亥酉未")
    ]

    static let zhiWuXing: [String: String] = [
        "子": "水", "丑": "土", "寅": "木", "卯": "木", "辰": "土", "巳": "火",
        "午": "火", "未": "土", "申": "金", "酉": "金", "戌": "土", "亥": "水"
    ]

    static let shen6 = ["青龙", "朱雀", "勾陈", "螣蛇", "白虎", "玄武"]

    static let sheng: [String: String] = ["木": "火", "火": "土", "土": "金", "金": "水", "水": "木"]
    static let ke: [String: String] = ["木": "土", "土": "水", "水": "火", "火": "金", "金": "木"]

    static let gua64: [String: String] = [
        "111111": "乾为天", "011111": "天风姤", "001111": "天山遁", "000111": "天地否",
        "000011": "风地观", "000001": "山地剥", "000101": "火地晋", "111101": "火天大有",
        "110110": "兑为泽", "010110": "泽水困", "000110": "泽地萃", "001110": "泽山咸",
        "001010": "水山蹇", "001000": "地山谦", "001100": "雷山小过", "110100": "雷泽归妹",
        "101101": "离为火", "001101": "火山旅", "011101": "火风鼎", "010101": "火水未济",
        "010001": "山水蒙", "010011": "风水涣", "010111": "天水讼", "101111": "天火同人",
        "100100": "震为雷", "000100": "雷地豫", "010100": "雷水解", "011100": "雷风恒",
        "011000": "地风升", "011010": "水风井", "011110": "泽风大过", "100110": "泽雷随",
        "011011": "巽为风", "111011": "风天小畜", "101011": "风火家人", "100011": "风雷益",
        "100111": "天雷无妄", "100101": "火雷噬嗑", "100001": "山雷颐", "011001": "山风蛊",
        "010010": "坎为水", "110010": "水泽节", "100010": "水雷屯", "101010": "水火既济",
        "101110": "泽火革", "101100": "雷火丰", "101000": "地火明夷", "010000": "地水师",
        "001001": "艮为山", "101001": "山火贲", "111001": "山天大畜", "110001": "山泽损",
        "110101": "火泽睽", "110111": "天泽履", "110011": "风泽中孚", "001011": "风山渐",
        "000000": "坤为地", "100000": "地雷复", "110000": "地泽临", "111000": "地天泰",
        "111100": "雷天大壮", "111110": "泽天夬", "111010": "水天需", "000010": "水地比"
    ]

    private static let flipSeq: [(Set<Int>, Int, String)] = [
        ([], 6, "本宫"),
        ([0], 1, "一世"),
        ([0, 1], 2, "二世"),
        ([0, 1, 2], 3, "三世"),
        ([0, 1, 2, 3], 4, "四世"),
        ([0, 1, 2, 3, 4], 5, "五世"),
        ([0, 1, 2, 4], 4, "游魂"),
        ([4], 3, "归魂")
    ]

    static let palaceTable: [String: (palace: String, type: String, shi: Int)] = {
        var table: [String: (String, String, Int)] = [:]
        let trigramBits = Dictionary(uniqueKeysWithValues: trigramName.map { ($1, $0) })
        for palace in trigramName.values {
            let base = trigramBits[palace]! + trigramBits[palace]!
            let chars = Array(base)
            for (flips, shi, guaType) in flipSeq {
                var bits = ""
                for (index, char) in chars.enumerated() {
                    if flips.contains(index) {
                        bits.append(char == "1" ? "0" : "1")
                    } else {
                        bits.append(char)
                    }
                }
                table[bits] = (palace, guaType, shi)
            }
        }
        return table
    }()

    static func name(forBits bits: String) -> String? {
        gua64[bits]
    }

    static func liuQin(yaoWuXing: String, palaceWuXing: String) -> String {
        if yaoWuXing == palaceWuXing { return "兄弟" }
        if sheng[yaoWuXing] == palaceWuXing { return "父母" }
        if sheng[palaceWuXing] == yaoWuXing { return "子孙" }
        if ke[yaoWuXing] == palaceWuXing { return "官鬼" }
        return "妻财"
    }

    static func castChart(bits: String, dayGanIndex: Int) -> Chart? {
        guard bits.count == 6, bits.allSatisfy({ $0 == "0" || $0 == "1" }) else { return nil }
        guard let palaceInfo = palaceTable[bits], let guaName = gua64[bits] else { return nil }
        let lower = String(bits.prefix(3))
        let upper = String(bits.suffix(3))
        guard let lowerName = trigramName[lower], let upperName = trigramName[upper],
              let inner = naJia[lowerName], let outer = naJia[upperName] else { return nil }

        let gans = [inner.0, inner.0, inner.0, outer.2, outer.2, outer.2]
        let zhis = Array(inner.1).map(String.init) + Array(outer.3).map(String.init)
        let shenStart = liuShenStart(dayGanIndex)
        let ying = yingPos(palaceInfo.shi)
        let palaceWX = palaceWuXing[palaceInfo.palace] ?? ""

        var yaos: [Yao] = []
        for index in 0..<6 {
            let zhi = zhis[index]
            let wx = zhiWuXing[zhi] ?? ""
            let position = index + 1
            let shiYing: String?
            if position == palaceInfo.shi { shiYing = "世" }
            else if position == ying { shiYing = "应" }
            else { shiYing = nil }
            yaos.append(Yao(
                position: position,
                yinYang: bits[bits.index(bits.startIndex, offsetBy: index)] == "1" ? "阳" : "阴",
                gan: gans[index],
                zhi: zhi,
                wuXing: wx,
                liuQin: liuQin(yaoWuXing: wx, palaceWuXing: palaceWX),
                liuShen: shen6[(shenStart + index) % 6],
                shiYing: shiYing
            ))
        }

        return Chart(
            bits: bits,
            name: guaName,
            upperName: upperName,
            lowerName: lowerName,
            palace: palaceInfo.palace,
            palaceWuXing: palaceWX,
            guaType: palaceInfo.type,
            shiPos: palaceInfo.shi,
            yingPos: ying,
            yaos: yaos
        )
    }

    static func findFuShen(chart: Chart, liuQin: String, dayGanIndex: Int) -> Yao? {
        if !chart.positions(of: liuQin).isEmpty { return nil }
        guard let bits = trigramBits(chart.palace) else { return nil }
        let baseBits = bits + bits
        guard let base = castChart(bits: baseBits, dayGanIndex: dayGanIndex) else { return nil }
        return base.yaos.first { $0.liuQin == liuQin }
    }

    static func bianBits(_ bits: String, moving: Set<Int>) -> String {
        var result = ""
        for (index, char) in bits.enumerated() {
            if moving.contains(index + 1) {
                result.append(char == "1" ? "0" : "1")
            } else {
                result.append(char)
            }
        }
        return result
    }

    private static func trigramBits(_ name: String) -> String? {
        trigramName.first { $0.value == name }?.key
    }

    private static func liuShenStart(_ dayGan: Int) -> Int {
        let table = [0, 0, 1, 1, 2, 3, 4, 4, 5, 5]
        guard dayGan >= 0, dayGan < table.count else { return 0 }
        return table[dayGan]
    }

    private static func yingPos(_ shi: Int) -> Int {
        shi <= 3 ? shi + 3 : shi - 3
    }
}
