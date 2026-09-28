import Foundation

enum LiuYaoAnalysis {
    static let categoryToYongShen: [String: String] = [
        "事业": "官鬼", "姻缘": "官鬼", "财运": "妻财",
        "健康": "官鬼", "出行": "父母", "失物": "妻财",
        "考试": "官鬼", "求子": "子孙", "官非": "官鬼",
        "搬迁": "父母", "合作": "妻财", "寻物": "妻财"
    ]

    static let yingAsYongShen: Set<String> = ["方案占", "谋望"]

    static func isKnownCategory(_ category: String) -> Bool {
        categoryToYongShen[category] != nil || yingAsYongShen.contains(category)
    }

    struct YaoFlags {
        var position: Int
        var xunKong: Bool
        var yuePo: Bool
        var riChong: Bool
    }

    struct YongShenPick {
        var liuQin: String
        var positions: [Int]
        var chosen: Int?
        var liangXian: Bool
        var fuCang: Bool
        var fuShen: LiuYaoHexagram.Yao?
        var yingAsGuide: Bool
    }

    static func wangShuai(yaoWuXing: String, monthWuXing: String) -> String {
        if yaoWuXing == monthWuXing { return "旺" }
        if LiuYaoHexagram.sheng[monthWuXing] == yaoWuXing { return "相" }
        if LiuYaoHexagram.sheng[yaoWuXing] == monthWuXing { return "休" }
        if LiuYaoHexagram.ke[yaoWuXing] == monthWuXing { return "囚" }
        return "死"
    }

    static func chong(_ zhiIndex: Int) -> Int {
        posMod(zhiIndex + 6, 12)
    }

    static func yaoFlags(
        chart: LiuYaoHexagram.Chart,
        monthBranch: Int,
        dayZhi: Int,
        xunKong: [Int]
    ) -> [YaoFlags] {
        let po = chong(monthBranch)
        let dayChong = chong(dayZhi)
        return chart.yaos.map { yao in
            let index = LiuYaoCalendar.zhiIndex(yao.zhi)
            return YaoFlags(
                position: yao.position,
                xunKong: xunKong.contains(index),
                yuePo: index == po,
                riChong: index == dayChong
            )
        }
    }

    static func selectYongShen(
        chart: LiuYaoHexagram.Chart,
        category: String,
        monthBranch: Int,
        dayZhi: Int,
        xunKong: [Int],
        moving: Set<Int>,
        dayGan: Int
    ) -> YongShenPick? {
        if yingAsYongShen.contains(category) {
            guard let ying = chart.yaos.first(where: { $0.shiYing == "应" }) else { return nil }
            return YongShenPick(
                liuQin: ying.liuQin,
                positions: [ying.position],
                chosen: ying.position,
                liangXian: false,
                fuCang: false,
                fuShen: nil,
                yingAsGuide: true
            )
        }
        guard let liuQin = categoryToYongShen[category] else { return nil }
        let positions = chart.positions(of: liuQin)
        if positions.isEmpty {
            let fu = LiuYaoHexagram.findFuShen(chart: chart, liuQin: liuQin, dayGanIndex: dayGan)
            return YongShenPick(
                liuQin: liuQin,
                positions: [],
                chosen: nil,
                liangXian: false,
                fuCang: true,
                fuShen: fu,
                yingAsGuide: false
            )
        }
        if positions.count == 1 {
            return YongShenPick(
                liuQin: liuQin,
                positions: positions,
                chosen: positions[0],
                liangXian: false,
                fuCang: false,
                fuShen: nil,
                yingAsGuide: false
            )
        }
        let chosen = resolveLiangXian(
            chart: chart,
            positions: positions,
            monthBranch: monthBranch,
            dayZhi: dayZhi,
            xunKong: xunKong,
            moving: moving
        )
        return YongShenPick(
            liuQin: liuQin,
            positions: positions,
            chosen: chosen,
            liangXian: true,
            fuCang: false,
            fuShen: nil,
            yingAsGuide: false
        )
    }

    static func forceEntry(
        chart: LiuYaoHexagram.Chart,
        position: Int?,
        liuQin: String,
        monthBranch: Int,
        dayZhi: Int,
        xunKong: [Int],
        moving: Set<Int>,
        bianChart: LiuYaoHexagram.Chart?
    ) -> ForceEntry {
        guard let position else {
            return ForceEntry(
                liuQin: liuQin, position: nil, wangShuai: "—",
                deLing: false, deRi: false, beiRiChong: false,
                xunKong: false, yuePo: false, faDong: false, anDong: false,
                huiTou: nil, feiFu: nil, fuCang: nil, fuShenPosition: nil, relations: nil
            )
        }
        let yao = chart.yaos[position - 1]
        let zi = LiuYaoCalendar.zhiIndex(yao.zhi)
        let monthWX = branchWuXing(monthBranch)
        let dayWX = branchWuXing(dayZhi)
        let state = wangShuai(yaoWuXing: yao.wuXing, monthWuXing: monthWX)
        let deRi = dayWX == yao.wuXing || LiuYaoHexagram.sheng[dayWX] == yao.wuXing
        let faDong = moving.contains(position)
        var huiTou: String?
        if faDong, let bian = bianChart {
            let changed = bian.yaos[position - 1]
            huiTou = huiTouRelation(
                benWuXing: yao.wuXing,
                benZhi: zi,
                bianWuXing: changed.wuXing,
                bianZhi: LiuYaoCalendar.zhiIndex(changed.zhi)
            )
        }
        let riChong = zi == chong(dayZhi)
        return ForceEntry(
            liuQin: liuQin,
            position: position,
            wangShuai: state,
            deLing: state == "旺" || state == "相",
            deRi: deRi,
            beiRiChong: riChong,
            xunKong: xunKong.contains(zi),
            yuePo: zi == chong(monthBranch),
            faDong: faDong,
            anDong: riChong && !faDong,
            huiTou: huiTou,
            feiFu: nil,
            fuCang: nil,
            fuShenPosition: nil,
            relations: nil
        )
    }

    static func fuShenForce(
        fuWuXing: String,
        fuZhi: String,
        liuQin: String,
        monthBranch: Int,
        dayZhi: Int,
        xunKong: [Int]
    ) -> ForceEntry {
        let zi = LiuYaoCalendar.zhiIndex(fuZhi)
        let monthWX = branchWuXing(monthBranch)
        let dayWX = branchWuXing(dayZhi)
        let state = wangShuai(yaoWuXing: fuWuXing, monthWuXing: monthWX)
        let deRi = dayWX == fuWuXing || LiuYaoHexagram.sheng[dayWX] == fuWuXing
        return ForceEntry(
            liuQin: liuQin,
            position: nil,
            wangShuai: state,
            deLing: state == "旺" || state == "相",
            deRi: deRi,
            beiRiChong: zi == chong(dayZhi),
            xunKong: xunKong.contains(zi),
            yuePo: zi == chong(monthBranch),
            faDong: false,
            anDong: false,
            huiTou: nil,
            feiFu: nil,
            fuCang: nil,
            fuShenPosition: nil,
            relations: nil
        )
    }

    static func feiFu(feiWuXing: String, fuWuXing: String) -> String {
        if feiWuXing == fuWuXing { return "飞伏比和" }
        if LiuYaoHexagram.sheng[feiWuXing] == fuWuXing { return "飞来生伏" }
        if LiuYaoHexagram.ke[feiWuXing] == fuWuXing { return "飞来克伏" }
        if LiuYaoHexagram.sheng[fuWuXing] == feiWuXing { return "伏来生飞" }
        if LiuYaoHexagram.ke[fuWuXing] == feiWuXing { return "伏来克飞" }
        return "飞伏比和"
    }

    static func yuanJiChou(yongWuXing: String, palaceWuXing: String) -> (yuan: String, ji: String, chou: String) {
        let yuanWX = LiuYaoHexagram.sheng.first { $0.value == yongWuXing }?.key ?? ""
        let jiWX = LiuYaoHexagram.ke.first { $0.value == yongWuXing }?.key ?? ""
        let chouWX = LiuYaoHexagram.sheng.first { $0.value == jiWX }?.key ?? ""
        return (
            LiuYaoHexagram.liuQin(yaoWuXing: yuanWX, palaceWuXing: palaceWuXing),
            LiuYaoHexagram.liuQin(yaoWuXing: jiWX, palaceWuXing: palaceWuXing),
            LiuYaoHexagram.liuQin(yaoWuXing: chouWX, palaceWuXing: palaceWuXing)
        )
    }

    static func huiTouRelation(benWuXing: String, benZhi: Int, bianWuXing: String, bianZhi: Int) -> String? {
        if benWuXing == bianWuXing {
            let step = posMod(bianZhi - benZhi, 12)
            return (step == 1 || step == 2) ? "化进" : "化退"
        }
        if LiuYaoHexagram.sheng[bianWuXing] == benWuXing { return "回头生" }
        if LiuYaoHexagram.ke[bianWuXing] == benWuXing { return "回头克" }
        return nil
    }

    private static func resolveLiangXian(
        chart: LiuYaoHexagram.Chart,
        positions: [Int],
        monthBranch: Int,
        dayZhi: Int,
        xunKong: [Int],
        moving: Set<Int>
    ) -> Int {
        let po = chong(monthBranch)
        let dayChong = chong(dayZhi)
        let monthWX = branchWuXing(monthBranch)
        let dayWX = branchWuXing(dayZhi)
        return positions.max { lhs, rhs in
            let left = rank(lhs)
            let right = rank(rhs)
            for index in 0..<left.count where left[index] != right[index] {
                return left[index] < right[index]
            }
            return false
        } ?? positions[0]

        func rank(_ position: Int) -> [Int] {
            let yao = chart.yaos[position - 1]
            let zi = LiuYaoCalendar.zhiIndex(yao.zhi)
            let state = wangShuai(yaoWuXing: yao.wuXing, monthWuXing: monthWX)
            let de = state == "旺" || state == "相" || dayWX == yao.wuXing || LiuYaoHexagram.sheng[dayWX] == yao.wuXing
            return [
                moving.contains(position) ? 1 : 0,
                (xunKong.contains(zi) || zi == po) ? 1 : 0,
                yao.shiYing != nil ? 1 : 0,
                de ? 1 : 0,
                -abs(position - chart.shiPos)
            ]
        }
    }

    private static func branchWuXing(_ zhiIndex: Int) -> String {
        let name = LiuYaoCalendar.zhiText(zhiIndex)
        return LiuYaoHexagram.zhiWuXing[name] ?? ""
    }
}
