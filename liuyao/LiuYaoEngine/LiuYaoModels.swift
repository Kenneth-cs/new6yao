import Foundation

// MARK: - 四态爻

enum YaoXiang: String, Codable, CaseIterable, Equatable {
    case youngYang = "少阳"
    case youngYin = "少阴"
    case oldYang = "老阳"
    case oldYin = "老阴"

    var isYang: Bool { self == .youngYang || self == .oldYang }
    var isMoving: Bool { self == .oldYang || self == .oldYin }

    /// 三钱四象。背=1、字=0；3/1/2/0 背对应老阳/少阳/少阴/老阴，概率 1:3:3:1。
    static func randomToss() -> YaoXiang {
        var backs = 0
        for _ in 0..<3 where Bool.random() {
            backs += 1
        }
        switch backs {
        case 3: return .oldYang
        case 2: return .youngYin
        case 1: return .youngYang
        default: return .oldYin
        }
    }

    var shortLabel: String {
        switch self {
        case .youngYang: return "阳"
        case .youngYin: return "阴"
        case .oldYang: return "阳·动"
        case .oldYin: return "阴·动"
        }
    }
}

enum InterpretationMode: String, Codable, Equatable {
    case professional
    case master

    var badgeTitle: String {
        switch self {
        case .professional: return "专业"
        case .master: return "大师"
        }
    }
}

enum CategorySource: String, Codable, Equatable {
    case catalog
    case keyword
    case unclassified
}

// MARK: - 排盘输出（对齐 hexagram-json-contract，并含本版扩展）

struct LiuYaoReading: Codable, Equatable {
    var question: QuestionBlock
    var castTime: CastTimeBlock
    var palace: PalaceBlock
    var primary: HexagramBlock
    var changed: HexagramBlock?
    var yongShen: YongShenBlock?
    var assessment: AssessmentBlock
    var relations: GuaRelationBlock
    var xingHai: XingHaiResult
    var location: LocationBlock?

    struct QuestionBlock: Codable, Equatable {
        var category: String?
        var text: String
    }

    struct CastTimeBlock: Codable, Equatable {
        var localTime: String
        var ganZhi: GanZhiBlock
        var monthBranch: String
        var dayPillar: String
        var xunKong: [String]

        enum CodingKeys: String, CodingKey {
            case localTime
            case ganZhi
            case monthBranch = "月建"
            case dayPillar = "日辰"
            case xunKong = "旬空"
        }
    }

    struct GanZhiBlock: Codable, Equatable {
        var year: String
        var month: String
        var day: String
        var hour: String

        enum CodingKeys: String, CodingKey {
            case year = "年"
            case month = "月"
            case day = "日"
            case hour = "时"
        }
    }

    struct PalaceBlock: Codable, Equatable {
        var gua: String
        var wuXing: String
        var type: String
    }

    struct HexagramBlock: Codable, Equatable {
        var upper: String
        var lower: String
        var name: String
        var lines: [LiuYaoLine]

        enum CodingKeys: String, CodingKey {
            case upper = "上卦"
            case lower = "下卦"
            case name
            case lines
        }
    }

    struct YongShenBlock: Codable, Equatable {
        var liuQin: String
        var positions: [Int]
        var chosen: Int?
        var liangXian: Bool
        var fuCang: Bool
        var suggested: Bool
        var yingAsGuide: Bool

        enum CodingKeys: String, CodingKey {
            case liuQin
            case positions
            case chosen
            case liangXian = "两现"
            case fuCang = "伏藏"
            case suggested
            case yingAsGuide = "应爻为纲"
        }
    }

    struct AssessmentBlock: Codable, Equatable {
        var yong: ForceEntry?
        var yuan: ForceEntry?
        var ji: ForceEntry?
        var chou: ForceEntry?

        enum CodingKeys: String, CodingKey {
            case yong = "用神"
            case yuan = "原神"
            case ji = "忌神"
            case chou = "仇神"
        }

        var isEmpty: Bool { yong == nil && yuan == nil && ji == nil && chou == nil }
    }

    struct LocationBlock: Codable, Equatable {
        var city: String
        var direction: String?
        var wuXing: String?
    }

    var movingCount: Int {
        primary.lines.filter { $0.moving != nil }.count
    }

    func jsonString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(self), let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }
}

struct LiuYaoLine: Codable, Equatable {
    var position: Int
    var yinYang: String
    var moving: String?
    var naJia: NaJia
    var wuXing: String
    var liuQin: String
    var liuShen: String
    var shiYing: String?
    var fuShen: FuShenInfo?
    var flags: LineFlags
    var relations: LineRelations

    struct NaJia: Codable, Equatable {
        var gan: String
        var zhi: String

        enum CodingKeys: String, CodingKey {
            case gan = "干"
            case zhi = "支"
        }
    }

    struct FuShenInfo: Codable, Equatable {
        var gan: String
        var zhi: String
        var najia: String
        var liuQin: String
        var wuXing: String
        var feiFu: String?

        enum CodingKeys: String, CodingKey {
            case gan = "干"
            case zhi = "支"
            case najia
            case liuQin
            case wuXing
            case feiFu
        }
    }

    struct LineFlags: Codable, Equatable {
        var xunKong: Bool
        var yuePo: Bool
        var riChong: Bool

        enum CodingKeys: String, CodingKey {
            case xunKong = "旬空"
            case yuePo = "月破"
            case riChong = "日冲"
        }
    }

    enum CodingKeys: String, CodingKey {
        case position
        case yinYang
        case moving
        case naJia = "纳甲"
        case wuXing
        case liuQin
        case liuShen
        case shiYing
        case fuShen = "伏神"
        case flags
        case relations
    }
}

struct LineRelations: Codable, Equatable {
    var fuYin: Bool?
    var fanYin: Bool?
    var he: [String]?
    var dongHe: Bool?

    enum CodingKeys: String, CodingKey {
        case fuYin = "伏吟"
        case fanYin = "反吟"
        case he = "合"
        case dongHe = "动合"
    }

    static let empty = LineRelations(fuYin: nil, fanYin: nil, he: nil, dongHe: nil)

    var isEmpty: Bool { fuYin == nil && fanYin == nil && he == nil && dongHe == nil }
}

struct ForceEntry: Codable, Equatable {
    var liuQin: String
    var position: Int?
    var wangShuai: String
    var deLing: Bool
    var deRi: Bool
    var beiRiChong: Bool
    var xunKong: Bool
    var yuePo: Bool
    var faDong: Bool
    var anDong: Bool
    var huiTou: String?
    var feiFu: String?
    var fuCang: Bool?
    var fuShenPosition: Int?
    var relations: YongRelations?

    struct YongRelations: Codable, Equatable {
        var ruMu: RuMu?
        var suiGui: Bool?
        var jue: Bool?
        var changSheng: [String: String]?

        struct RuMu: Codable, Equatable {
            var type: String
        }

        enum CodingKeys: String, CodingKey {
            case ruMu = "入墓"
            case suiGui = "随鬼入墓"
            case jue = "绝"
            case changSheng = "长生态"
        }
    }

    enum CodingKeys: String, CodingKey {
        case liuQin
        case position
        case wangShuai
        case deLing = "得令"
        case deRi = "得日"
        case beiRiChong = "日冲"
        case xunKong = "旬空"
        case yuePo = "月破"
        case faDong = "发动"
        case anDong = "暗动"
        case huiTou
        case feiFu
        case fuCang = "伏藏"
        case fuShenPosition = "伏神位"
        case relations
    }
}

struct GuaRelationBlock: Codable, Equatable {
    var fanYin: String
    var fuYin: String
    var liuHe: Bool
    var sanHe: [SanHeItem]

    struct SanHeItem: Codable, Equatable {
        var wuXing: String
        var chengJu: String
        var hanDong: Bool

        enum CodingKeys: String, CodingKey {
            case wuXing = "五行"
            case chengJu = "成局"
            case hanDong = "含动"
        }
    }

    enum CodingKeys: String, CodingKey {
        case fanYin = "反吟"
        case fuYin = "伏吟"
        case liuHe = "六合"
        case sanHe = "三合"
    }
}

struct XingHaiResult: Codable, Equatable {
    var xing: [XingHaiHit]
    var hai: [XingHaiHit]
}

struct XingHaiHit: Codable, Equatable {
    var position: Int
    var kind: String
    var zhi: String
    var targetZhi: String
    var targetPosition: Int?
}

struct LiuYaoFourPillars: Equatable {
    var year: String
    var month: String
    var day: String
    var hour: String
    var dayGanIndex: Int
    var monthZhiIndex: Int
    var dayZhiIndex: Int
    var xunKong: [String]
    var xunKongIndex: [Int]
    var localTime: Date
}
