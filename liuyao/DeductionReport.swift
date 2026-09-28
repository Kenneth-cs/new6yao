import Foundation

struct DeductionReport: Codable, Equatable {
    let reportVersion: String
    let question: String
    let backgroundUsed: String
    let globalJudgment: GlobalJudgment
    let recommendation: Recommendation
    let paths: [DeductionPathResult]
    let reportFooter: String

    enum CodingKeys: String, CodingKey {
        case reportVersion = "report_version"
        case question
        case backgroundUsed = "background_used"
        case globalJudgment = "global_judgment"
        case recommendation
        case paths
        case reportFooter = "report_footer"
    }

    struct GlobalJudgment: Codable, Equatable {
        let title: String
        let summary: String
        let divinationBasisSummary: String
        let informationGaps: [String]

        enum CodingKeys: String, CodingKey {
            case title
            case summary
            case divinationBasisSummary = "divination_basis_summary"
            case informationGaps = "information_gaps"
        }
    }

    struct Recommendation: Codable, Equatable {
        let status: String
        let recommendedPathId: String?
        let headline: String
        let reason: String
        let applicableConditions: [String]
        let reconsiderWhen: [String]

        enum CodingKeys: String, CodingKey {
            case status
            case recommendedPathId = "recommended_path_id"
            case headline
            case reason
            case applicableConditions = "applicable_conditions"
            case reconsiderWhen = "reconsider_when"
        }

        var isInsufficient: Bool {
            status.trimmingCharacters(in: .whitespacesAndNewlines) == "insufficient"
        }

        /// AI 可能输出 JSON null，也可能输出字符串 "null"。
        var resolvedPathId: String? {
            guard let recommendedPathId else { return nil }
            let trimmed = recommendedPathId.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed == "null" { return nil }
            return trimmed
        }
    }

    struct DeductionPathResult: Codable, Equatable, Identifiable {
        let id: String
        let fixedName: String
        let rank: Int
        let isRecommended: Bool
        let pathAssumption: TextBlock
        let pathVerdict: TextBlock
        let developmentTrend: DevelopmentTrend
        let pathDivinationReasoning: DivinationReasoning
        let verificationSignals: VerificationSignals

        enum CodingKeys: String, CodingKey {
            case id
            case fixedName = "fixed_name"
            case rank
            case isRecommended = "is_recommended"
            case pathAssumption = "path_assumption"
            case pathVerdict = "path_verdict"
            case developmentTrend = "development_trend"
            case pathDivinationReasoning = "path_divination_reasoning"
            case verificationSignals = "verification_signals"
        }

        var glyph: String {
            switch id {
            case "advance": return "进"
            case "hold": return "守"
            case "withdraw", "retreat": return "退"
            default: return "路"
            }
        }
    }

    struct TextBlock: Codable, Equatable {
        let title: String
        let content: String

        enum CodingKeys: String, CodingKey {
            case title
            case content
        }
    }

    struct DevelopmentTrend: Codable, Equatable {
        let title: String
        let opening: String
        let development: String
        let turningPoint: String
        let possibleOutcome: String

        enum CodingKeys: String, CodingKey {
            case title
            case opening
            case development
            case turningPoint = "turning_point"
            case possibleOutcome = "possible_outcome"
        }

        var cardContent: String {
            [opening, development].filter { !$0.isEmpty }.joined(separator: "\n\n")
        }
    }

    struct DivinationReasoning: Codable, Equatable {
        let title: String
        let originalHexagram: String
        let movingLines: String
        let changedHexagram: String
        let relationAndUseGod: String
        let pathSymbolism: String

        enum CodingKeys: String, CodingKey {
            case title
            case originalHexagram = "original_hexagram"
            case movingLines = "moving_lines"
            case changedHexagram = "changed_hexagram"
            case relationAndUseGod = "relation_and_use_god"
            case pathSymbolism = "path_symbolism"
        }
    }

    struct VerificationSignals: Codable, Equatable {
        let title: String
        let signals: [String]

        enum CodingKeys: String, CodingKey {
            case title
            case signals
        }

        var cautionText: String {
            signals.prefix(3).joined(separator: "；")
        }
    }

    func path(id: String) -> DeductionPathResult? {
        paths.first { $0.id == id }
    }

    /// 丢掉没有总断的路径。一条可展示路径都没有时返回 nil。
    func keepingDisplayablePaths() -> DeductionReport? {
        let usable = paths.filter(\.hasDisplayableVerdict)
        guard !usable.isEmpty else { return nil }
        if usable.count == paths.count { return self }
        return DeductionReport(
            reportVersion: reportVersion,
            question: question,
            backgroundUsed: backgroundUsed,
            globalJudgment: globalJudgment,
            recommendation: recommendation,
            paths: usable,
            reportFooter: reportFooter
        )
    }
}

extension DeductionReport.DeductionPathResult {
    var hasDisplayableVerdict: Bool {
        !pathVerdict.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension DeductionReport {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reportVersion = LossyDecode.string(container, .reportVersion)
        question = LossyDecode.string(container, .question)
        backgroundUsed = LossyDecode.string(container, .backgroundUsed)
        globalJudgment = LossyDecode.object(container, .globalJudgment) ?? .empty
        recommendation = LossyDecode.object(container, .recommendation) ?? .empty
        paths = Self.decodePaths(from: container)
        reportFooter = LossyDecode.string(container, .reportFooter)
    }

    private static func decodePaths(from container: KeyedDecodingContainer<CodingKeys>) -> [DeductionPathResult] {
        guard var unkeyed = try? container.nestedUnkeyedContainer(forKey: .paths) else { return [] }
        var items: [DeductionPathResult] = []
        while !unkeyed.isAtEnd {
            if let path = try? unkeyed.decode(DeductionPathResult.self) {
                items.append(path)
            } else if (try? unkeyed.decode(LossyJSONValue.self)) != nil {
                continue
            } else {
                break
            }
        }
        return items
    }
}

extension DeductionReport.GlobalJudgment {
    static let empty = DeductionReport.GlobalJudgment(
        title: "", summary: "", divinationBasisSummary: "", informationGaps: []
    )

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = LossyDecode.string(container, .title)
        summary = LossyDecode.string(container, .summary)
        divinationBasisSummary = LossyDecode.string(container, .divinationBasisSummary)
        informationGaps = LossyDecode.stringArray(container, .informationGaps)
    }
}

extension DeductionReport.Recommendation {
    static let empty = DeductionReport.Recommendation(
        status: "",
        recommendedPathId: nil,
        headline: "",
        reason: "",
        applicableConditions: [],
        reconsiderWhen: []
    )

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = LossyDecode.string(container, .status)
        let rawPathId = LossyDecode.string(container, .recommendedPathId)
        recommendedPathId = rawPathId.isEmpty ? nil : rawPathId
        headline = LossyDecode.string(container, .headline)
        reason = LossyDecode.string(container, .reason)
        applicableConditions = LossyDecode.stringArray(container, .applicableConditions)
        reconsiderWhen = LossyDecode.stringArray(container, .reconsiderWhen)
    }
}

extension DeductionReport.DeductionPathResult {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedId = LossyDecode.string(container, .id)
        id = decodedId.isEmpty ? "path-\(UUID().uuidString)" : decodedId
        fixedName = LossyDecode.string(container, .fixedName)
        rank = LossyDecode.int(container, .rank)
        isRecommended = LossyDecode.bool(container, .isRecommended)
        pathAssumption = LossyDecode.object(container, .pathAssumption) ?? .empty
        pathVerdict = LossyDecode.object(container, .pathVerdict) ?? .empty
        developmentTrend = LossyDecode.object(container, .developmentTrend) ?? .empty
        pathDivinationReasoning = LossyDecode.object(container, .pathDivinationReasoning) ?? .empty
        verificationSignals = LossyDecode.object(container, .verificationSignals) ?? .empty
    }
}

extension DeductionReport.TextBlock {
    static let empty = DeductionReport.TextBlock(title: "", content: "")

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            title = LossyDecode.string(container, .title)
            content = LossyDecode.string(container, .content)
            return
        }
        if let single = try? decoder.singleValueContainer(),
           let text = try? single.decode(String.self) {
            title = ""
            content = text
            return
        }
        title = ""
        content = ""
    }
}

extension DeductionReport.DevelopmentTrend {
    static let empty = DeductionReport.DevelopmentTrend(
        title: "", opening: "", development: "", turningPoint: "", possibleOutcome: ""
    )

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = LossyDecode.string(container, .title)
        opening = LossyDecode.string(container, .opening)
        development = LossyDecode.string(container, .development)
        turningPoint = LossyDecode.string(container, .turningPoint)
        possibleOutcome = LossyDecode.string(container, .possibleOutcome)
    }
}

extension DeductionReport.DivinationReasoning {
    static let empty = DeductionReport.DivinationReasoning(
        title: "",
        originalHexagram: "",
        movingLines: "",
        changedHexagram: "",
        relationAndUseGod: "",
        pathSymbolism: ""
    )

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = LossyDecode.string(container, .title)
        originalHexagram = LossyDecode.string(container, .originalHexagram)
        movingLines = LossyDecode.string(container, .movingLines)
        changedHexagram = LossyDecode.string(container, .changedHexagram)
        relationAndUseGod = LossyDecode.string(container, .relationAndUseGod)
        pathSymbolism = LossyDecode.string(container, .pathSymbolism)
    }
}

extension DeductionReport.VerificationSignals {
    static let empty = DeductionReport.VerificationSignals(title: "", signals: [])

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = LossyDecode.string(container, .title)
        signals = LossyDecode.stringArray(container, .signals)
    }
}

private enum LossyDecode {
    static func string<K: CodingKey>(_ container: KeyedDecodingContainer<K>, _ key: K) -> String {
        (try? container.decodeIfPresent(String.self, forKey: key)) ?? ""
    }

    static func bool<K: CodingKey>(_ container: KeyedDecodingContainer<K>, _ key: K) -> Bool {
        (try? container.decodeIfPresent(Bool.self, forKey: key)) ?? false
    }

    static func int<K: CodingKey>(_ container: KeyedDecodingContainer<K>, _ key: K) -> Int {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) { return Int(value) }
        return 0
    }

    static func stringArray<K: CodingKey>(_ container: KeyedDecodingContainer<K>, _ key: K) -> [String] {
        (try? container.decodeIfPresent([String].self, forKey: key)) ?? []
    }

    static func object<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, _ key: K) -> T? {
        try? container.decodeIfPresent(T.self, forKey: key)
    }
}

private struct LossyJSONValue: Decodable {
    init(from decoder: Decoder) throws {
        if var unkeyed = try? decoder.unkeyedContainer() {
            while !unkeyed.isAtEnd {
                _ = try unkeyed.decode(LossyJSONValue.self)
            }
            return
        }
        if let keyed = try? decoder.container(keyedBy: LossyCodingKey.self) {
            for key in keyed.allKeys {
                _ = try keyed.decode(LossyJSONValue.self, forKey: key)
            }
            return
        }
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { return }
        if (try? container.decode(Bool.self)) != nil { return }
        if (try? container.decode(Double.self)) != nil { return }
        if (try? container.decode(String.self)) != nil { return }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "无法跳过的 JSON 值")
    }
}

private struct LossyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
