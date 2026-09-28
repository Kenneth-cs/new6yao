import Foundation

/// Date → 四柱 + 旬空。月建走节气，日柱 23:00 换日，时柱五鼠遁用换日后日干。
enum LiuYaoCalendar {
    static let gan = Array("甲乙丙丁戊己庚辛壬癸")
    static let zhi = Array("子丑寅卯辰巳午未申酉戌亥")

    static func fourPillars(from date: Date) -> LiuYaoFourPillars {
        let lunar = Lunar.fromDate(date: date)
        let day = lunar.dayInGanZhiExact
        let kong = xunKongBranches(dayGanZhi: day)
        return LiuYaoFourPillars(
            year: lunar.yearInGanZhiExact,
            month: lunar.monthInGanZhiExact,
            day: day,
            hour: lunar.timeInGanZhi,
            dayGanIndex: lunar.dayGanIndexExact,
            monthZhiIndex: lunar.monthZhiIndexExact,
            dayZhiIndex: lunar.dayZhiIndexExact,
            xunKong: kong.branches,
            xunKongIndex: kong.indexes,
            localTime: date
        )
    }

    /// 古籍卦例：直接按干支建四柱，不反推节气。
    static func pillars(
        year: String,
        month: String,
        day: String,
        hour: String = "甲子",
        localTime: Date = Date(timeIntervalSince1970: 0)
    ) -> LiuYaoFourPillars {
        let dayParts = split(day)
        let monthParts = split(month)
        let kong = xunKongBranches(dayGanZhi: day)
        return LiuYaoFourPillars(
            year: year,
            month: month,
            day: day,
            hour: hour,
            dayGanIndex: dayParts.gan,
            monthZhiIndex: monthParts.zhi,
            dayZhiIndex: dayParts.zhi,
            xunKong: kong.branches,
            xunKongIndex: kong.indexes,
            localTime: localTime
        )
    }

    static func xunKongBranches(dayGanZhi: String) -> (branches: [String], indexes: [Int]) {
        let text = LunarUtil.getXunKong(ganZhi: dayGanZhi)
        let chars = Array(text)
        let branches = chars.map { String($0) }
        let indexes = branches.map { zhiIndex($0) }
        return (branches, indexes)
    }

    static func ganIndex(_ value: String) -> Int {
        gan.firstIndex(of: Character(value)) ?? 0
    }

    static func zhiIndex(_ value: String) -> Int {
        zhi.firstIndex(of: Character(value)) ?? 0
    }

    static func ganText(_ index: Int) -> String {
        String(gan[posMod(index, 10)])
    }

    static func zhiText(_ index: Int) -> String {
        String(zhi[posMod(index, 12)])
    }

    private static func split(_ pillar: String) -> (gan: Int, zhi: Int) {
        let chars = Array(pillar)
        guard chars.count == 2 else { return (0, 0) }
        return (ganIndex(String(chars[0])), zhiIndex(String(chars[1])))
    }
}

func posMod(_ value: Int, _ modulus: Int) -> Int {
    let remainder = value % modulus
    return remainder >= 0 ? remainder : remainder + modulus
}
