import Foundation

enum ShareSourcePage: String {
    case divination
    case deduction
}

enum ShareActionTaken: String {
    case none
    case poster
    case pdf
}

enum ShareExportError: Error {
    case permissionDenied
    case renderFailed
    case saveFailed
    case diskFull
    case timedOut

    var analyticsReason: String {
        switch self {
        case .permissionDenied: return "permission_denied"
        case .renderFailed, .timedOut: return "render_failed"
        case .saveFailed: return "save_failed"
        case .diskFull: return "disk_full"
        }
    }

    var posterMessage: String {
        switch self {
        case .permissionDenied: return "请在设置中开启相册权限"
        case .diskFull: return "储存空间不足，请清理后重试"
        default: return "保存失败，请重试"
        }
    }

    var pdfMessage: String {
        switch self {
        case .diskFull: return "储存空间不足，请清理后重试"
        default: return "生成失败，请重试"
        }
    }

    static func fromFileError(_ error: Error) -> ShareExportError {
        if let share = error as? ShareExportError { return share }
        let ns = error as NSError
        if ns.domain == NSCocoaErrorDomain && ns.code == NSFileWriteOutOfSpaceError {
            return .diskFull
        }
        if ns.domain == NSPOSIXErrorDomain && ns.code == 28 {
            return .diskFull
        }
        return .saveFailed
    }
}

enum ShareText {
    static func cleaned(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 按段落切开超长正文，避免一整张海报超过图片编码器的高度上限后变成黑图。
    static func paragraphChunks(_ text: String, limit: Int = 600) -> [String] {
        let trimmed = cleaned(text)
        guard trimmed.count > limit else { return trimmed.isEmpty ? [] : [trimmed] }
        var chunks: [String] = []
        var current = ""
        for paragraph in trimmed.components(separatedBy: "\n") {
            let piece = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if piece.isEmpty { continue }
            if current.isEmpty {
                current = piece
            } else if current.count + 1 + piece.count <= limit {
                current += "\n" + piece
            } else {
                chunks.append(current)
                current = piece
            }
        }
        if !current.isEmpty { chunks.append(current) }
        return chunks.flatMap { hardSplit($0, limit: limit) }
    }

    private static func hardSplit(_ text: String, limit: Int) -> [String] {
        guard text.count > limit, limit > 0 else { return [text] }
        var chunks: [String] = []
        var rest = text[...]
        while rest.count > limit {
            let end = rest.index(rest.startIndex, offsetBy: limit)
            chunks.append(String(rest[..<end]))
            rest = rest[end...]
        }
        if !rest.isEmpty { chunks.append(String(rest)) }
        return chunks
    }

    static func posterQuestion(_ text: String) -> String {
        let trimmed = cleaned(text)
        guard trimmed.count > 100 else { return trimmed }
        return String(trimmed.prefix(100)) + "…"
    }

    static func nonempty(_ text: String) -> String? {
        let trimmed = cleaned(text)
        if trimmed.isEmpty || trimmed == "暂无解读" || trimmed == "未提供" { return nil }
        return trimmed
    }

    static func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

struct PosterSection: Equatable, Identifiable {
    let title: String
    let body: String
    var id: String { title }
}

struct PDFChapter: Equatable {
    enum Block: Equatable {
        case prose(String)
        case quote(String)
        case bullets([String])
        case table([[String]])
    }

    let title: String
    let blocks: [Block]
}

struct DivinationShareContent: Equatable {
    struct Section: Equatable {
        let title: String
        let body: String
    }

    let question: String
    let hexagramName: String
    let hexagramDescription: String
    let hexagramShortSummary: String
    let yaoLines: [YaoXiang]
    let liuYaoChart: LiuYaoReading?
    let time: Date
    let location: String
    let interpretationMode: InterpretationMode
    let resolvedConclusion: String
    let coreConclusionSection: String
    let coreVerdictSection: String
    let hexagramAnalysis: String
    let questionInterpretation: String
    let guidanceAdvice: String
    let suggestions: [String]
    let masterSections: [Section]
    let fallbackInterpretation: String

    var showsYaoGraphic: Bool {
        liuYaoChart != nil && yaoLines.count == 6
    }

    var locationText: String {
        let trimmed = ShareText.cleaned(location)
        return trimmed.isEmpty ? "未知地点" : trimmed
    }

    var modeTitle: String {
        switch interpretationMode {
        case .professional: return "专业模式"
        case .master: return "大师模式"
        }
    }

    var formattedTime: String {
        ShareText.formatted(time)
    }

    var pdfChapters: [PDFChapter] {
        interpretationMode == .master ? masterChapters : professionalChapters
    }

    /// 完整版长图用的章节，对应分析结果页上实际展示的解读，空章节不占位。
    var fullPosterSections: [PosterSection] {
        interpretationMode == .master ? masterPosterSections : professionalPosterSections
    }

    var chartCaption: String? {
        guard let chart = liuYaoChart else { return nil }
        var lines = ["月建 \(chart.castTime.monthBranch) · 日辰 \(chart.castTime.dayPillar) · 旬空 \(chart.castTime.xunKong.joined())"]
        if let changed = chart.changed?.name, !changed.isEmpty {
            lines.append("变卦 \(changed)")
        }
        if let yong = chart.yongShen?.liuQin, !yong.isEmpty {
            lines.append("建议用神：\(yong)")
        }
        return lines.joined(separator: "\n")
    }

    private var professionalPosterSections: [PosterSection] {
        var sections: [PosterSection] = []
        if let core = ShareText.nonempty(coreConclusionSection) {
            sections.append(PosterSection(title: "核心结论", body: core))
        } else if let oneLiner = ShareText.nonempty(resolvedConclusion) {
            sections.append(PosterSection(title: "核心结论", body: oneLiner))
        }
        appendPoster(&sections, title: "核心断语", text: coreVerdictSection)
        appendPoster(&sections, title: "卦象解析", text: hexagramAnalysis)
        appendPoster(&sections, title: "问题解读", text: questionInterpretation)
        appendPoster(&sections, title: "建议指导", text: guidanceAdvice)
        appendPosterSuggestions(&sections)
        if sections.isEmpty, let fallback = ShareText.nonempty(fallbackInterpretation) {
            sections.append(PosterSection(title: "卦象解析", body: fallback))
        }
        return sections
    }

    private var masterPosterSections: [PosterSection] {
        var sections = masterSections.compactMap { section -> PosterSection? in
            guard let body = ShareText.nonempty(section.body) else { return nil }
            return PosterSection(title: section.title, body: body)
        }
        appendPosterSuggestions(&sections)
        if sections.isEmpty, let fallback = ShareText.nonempty(fallbackInterpretation) {
            sections.append(PosterSection(title: "解读", body: fallback))
        }
        return sections
    }

    private func appendPoster(_ sections: inout [PosterSection], title: String, text: String) {
        guard let body = ShareText.nonempty(text) else { return }
        sections.append(PosterSection(title: title, body: body))
    }

    private func appendPosterSuggestions(_ sections: inout [PosterSection]) {
        let tips = suggestions.compactMap { ShareText.nonempty($0) }
        guard !tips.isEmpty else { return }
        let body = tips.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        sections.append(PosterSection(title: "追问建议", body: body))
    }

    private var professionalChapters: [PDFChapter] {
        var chapters: [PDFChapter] = []
        let info = hexagramInfoChapter
        if !info.blocks.isEmpty {
            chapters.append(info)
        }

        var conclusionBlocks: [PDFChapter.Block] = []
        let oneLiner = ShareText.nonempty(resolvedConclusion)
        if let oneLiner {
            conclusionBlocks.append(.quote(oneLiner))
        }
        if let longer = ShareText.nonempty(coreConclusionSection), longer != oneLiner {
            conclusionBlocks.append(.prose(longer))
        }
        if !conclusionBlocks.isEmpty {
            chapters.append(PDFChapter(title: "核心结论", blocks: conclusionBlocks))
        }

        appendProse(&chapters, title: "核心断语", text: coreVerdictSection)
        appendProse(&chapters, title: "卦象解析", text: hexagramAnalysis)
        appendProse(&chapters, title: "问题解读", text: questionInterpretation)
        appendProse(&chapters, title: "建议指导", text: guidanceAdvice)

        let tips = suggestions.compactMap { ShareText.nonempty($0) }
        if !tips.isEmpty {
            chapters.append(PDFChapter(title: "追问建议", blocks: [.bullets(tips)]))
        }

        let hasInterpretation = chapters.contains { $0.title != "卦象信息" }
        if !hasInterpretation, let fallback = ShareText.nonempty(fallbackInterpretation) {
            chapters.append(PDFChapter(title: "解读", blocks: [.prose(fallback)]))
        }
        return chapters
    }

    private var masterChapters: [PDFChapter] {
        let chapters = masterSections.compactMap { section -> PDFChapter? in
            guard let body = ShareText.nonempty(section.body) else { return nil }
            let block: PDFChapter.Block = (section.title == "核心结论" || section.title == "最后一句")
                ? .quote(body)
                : .prose(body)
            return PDFChapter(title: section.title, blocks: [block])
        }
        if !chapters.isEmpty { return chapters }
        if let fallback = ShareText.nonempty(fallbackInterpretation) {
            return [PDFChapter(title: "解读", blocks: [.prose(fallback)])]
        }
        return []
    }

    private var hexagramInfoChapter: PDFChapter {
        var lines: [String] = []
        if let question = ShareText.nonempty(question) {
            lines.append("问题：\(question)")
        }
        if let name = ShareText.nonempty(hexagramName) {
            lines.append("卦名：\(name)")
        }
        if let description = ShareText.nonempty(hexagramDescription) {
            lines.append("卦象说明：\(description)")
        }

        var blocks: [PDFChapter.Block] = []
        if !lines.isEmpty {
            blocks.append(.prose(lines.joined(separator: "\n")))
        }
        if let chart = liuYaoChart {
            var meta: [String] = []
            meta.append("月建 \(chart.castTime.monthBranch) · 日辰 \(chart.castTime.dayPillar) · 旬空 \(chart.castTime.xunKong.joined())")
            if let changed = chart.changed?.name, !changed.isEmpty {
                meta.append("变卦：\(changed)")
            }
            if let yong = chart.yongShen?.liuQin, !yong.isEmpty {
                meta.append("建议用神：\(yong)")
            }
            blocks.append(.prose(meta.joined(separator: "\n")))
            if let table = Self.yaoTable(from: chart) {
                blocks.append(.table(table))
            }
        }
        return PDFChapter(title: "卦象信息", blocks: blocks)
    }

    private static func yaoTable(from chart: LiuYaoReading) -> [[String]]? {
        let lines = chart.primary.lines.sorted { $0.position > $1.position }
        guard !lines.isEmpty else { return nil }
        var rows = [["爻位", "阴阳", "动静", "六亲", "六神", "世应"]]
        for line in lines {
            rows.append([
                "\(line.position)",
                line.yinYang == "yang" ? "阳" : "阴",
                line.moving == nil ? "静" : "动",
                line.liuQin,
                line.liuShen,
                line.shiYing ?? ""
            ])
        }
        return rows
    }

    private func appendProse(_ chapters: inout [PDFChapter], title: String, text: String) {
        guard let body = ShareText.nonempty(text) else { return }
        chapters.append(PDFChapter(title: title, blocks: [.prose(body)]))
    }
}

struct DeductionShareContent: Equatable {
    let report: DeductionReport
    let hexagramName: String
    let displayQuestion: String

    var orderedPaths: [DeductionReport.DeductionPathResult] {
        let order = ["advance", "hold", "withdraw", "retreat"]
        return report.paths.sorted { lhs, rhs in
            let left = order.firstIndex(of: lhs.id) ?? order.count
            let right = order.firstIndex(of: rhs.id) ?? order.count
            if left != right { return left < right }
            return lhs.rank < rhs.rank
        }
    }

    func isRecommended(_ path: DeductionReport.DeductionPathResult) -> Bool {
        if report.recommendation.isInsufficient { return false }
        if path.isRecommended { return true }
        return path.id == report.recommendation.resolvedPathId
    }

    var pdfChapters: [PDFChapter] {
        var chapters: [PDFChapter] = []
        if let background = backgroundChapter {
            chapters.append(background)
        }
        if let recommendation = recommendationChapter {
            chapters.append(recommendation)
        }
        for path in orderedPaths {
            if let chapter = pathChapter(path) {
                chapters.append(chapter)
            }
        }
        if let basis = basisChapter {
            chapters.append(basis)
        }
        return chapters
    }

    private var backgroundChapter: PDFChapter? {
        var blocks: [PDFChapter.Block] = []
        var lines: [String] = []
        if let question = ShareText.nonempty(displayQuestion) ?? ShareText.nonempty(report.question) {
            lines.append("原始问题：\(question)")
        }
        if let background = ShareText.nonempty(report.backgroundUsed) {
            lines.append("补充背景：\(background)")
        }
        if let name = ShareText.nonempty(hexagramName) {
            lines.append("关联卦象：\(name)")
        }
        if !lines.isEmpty {
            blocks.append(.prose(lines.joined(separator: "\n")))
        }
        let gaps = report.globalJudgment.informationGaps.compactMap { ShareText.nonempty($0) }
        if !gaps.isEmpty {
            blocks.append(.prose("信息缺口"))
            blocks.append(.bullets(gaps))
        }
        if let footer = ShareText.nonempty(report.reportFooter) {
            blocks.append(.prose(footer))
        }
        guard !blocks.isEmpty else { return nil }
        return PDFChapter(title: "推演背景", blocks: blocks)
    }

    private var recommendationChapter: PDFChapter? {
        var blocks: [PDFChapter.Block] = []
        if let headline = ShareText.nonempty(report.recommendation.headline) {
            blocks.append(.quote(headline))
        }
        if let reason = ShareText.nonempty(report.recommendation.reason) {
            blocks.append(.prose(reason))
        }
        let conditions = report.recommendation.applicableConditions.compactMap { ShareText.nonempty($0) }
        if !conditions.isEmpty {
            blocks.append(.prose("适用条件"))
            blocks.append(.bullets(conditions))
        }
        let reconsider = report.recommendation.reconsiderWhen.compactMap { ShareText.nonempty($0) }
        if !reconsider.isEmpty {
            blocks.append(.prose("这些情况出现时再想想"))
            blocks.append(.bullets(reconsider))
        }
        if let summary = ShareText.nonempty(report.globalJudgment.summary) {
            blocks.append(.prose(summary))
        }
        if let basis = ShareText.nonempty(report.globalJudgment.divinationBasisSummary) {
            blocks.append(.prose(basis))
        }
        guard !blocks.isEmpty else { return nil }
        return PDFChapter(title: "综合推荐", blocks: blocks)
    }

    private func pathChapter(_ path: DeductionReport.DeductionPathResult) -> PDFChapter? {
        var blocks: [PDFChapter.Block] = []
        if let assumption = ShareText.nonempty(path.pathAssumption.content) {
            blocks.append(.prose("路径假设\n\(assumption)"))
        }
        if let verdict = ShareText.nonempty(path.pathVerdict.content) {
            blocks.append(.quote(verdict))
        }
        let development = [
            path.developmentTrend.opening,
            path.developmentTrend.development,
            path.developmentTrend.possibleOutcome
        ].compactMap { ShareText.nonempty($0) }
        if !development.isEmpty {
            blocks.append(.prose("可能的发展\n\(development.joined(separator: "\n"))"))
        }
        if let symbolism = ShareText.nonempty(path.pathDivinationReasoning.pathSymbolism) {
            blocks.append(.prose("判断依据\n\(symbolism)"))
        }
        if let caution = ShareText.nonempty(path.verificationSignals.cautionText) {
            blocks.append(.prose("留意点\n\(caution)"))
        }
        guard !blocks.isEmpty else { return nil }
        return PDFChapter(title: pathChapterTitle(path), blocks: blocks)
    }

    private var basisChapter: PDFChapter? {
        var parts: [String] = []
        for path in orderedPaths {
            let prefix = path.glyph
            let reasoning = path.pathDivinationReasoning
            let labeled = [
                labeled(prefix, "本卦对此路的启示", reasoning.originalHexagram),
                labeled(prefix, "动爻分析", reasoning.movingLines),
                labeled(prefix, "变卦归向", reasoning.changedHexagram),
                labeled(prefix, "世应·用神·六亲", reasoning.relationAndUseGod),
                labeled(prefix, "路径转折点", path.developmentTrend.turningPoint)
            ].compactMap { $0 }
            var chunk = labeled
            let signals = path.verificationSignals.signals.compactMap { ShareText.nonempty($0) }
            if !signals.isEmpty {
                let bullets = signals.map { "• \($0)" }.joined(separator: "\n")
                chunk.append("\(prefix) · 关键应验点\n\(bullets)")
            }
            if !chunk.isEmpty {
                parts.append(chunk.joined(separator: "\n\n"))
            }
        }
        guard !parts.isEmpty else { return nil }
        return PDFChapter(title: "完整依据", blocks: [.prose(parts.joined(separator: "\n\n"))])
    }

    private func pathChapterTitle(_ path: DeductionReport.DeductionPathResult) -> String {
        switch path.id {
        case "advance": return "进路推演"
        case "hold": return "守路推演"
        case "withdraw", "retreat": return "退路推演"
        default: return "\(path.glyph)路推演"
        }
    }

    private func labeled(_ prefix: String, _ title: String, _ text: String) -> String? {
        guard let body = ShareText.nonempty(text) else { return nil }
        return "\(prefix) · \(title)\n\(body)"
    }
}

enum SharePayload: Equatable {
    case divination(DivinationShareContent)
    case deduction(DeductionShareContent)

    var sourcePage: ShareSourcePage {
        switch self {
        case .divination: return .divination
        case .deduction: return .deduction
        }
    }

    var reportTypeName: String {
        switch self {
        case .divination: return "解卦报告"
        case .deduction: return "推演报告"
        }
    }

    var previewTitle: String {
        switch self {
        case .divination(let content):
            return content.hexagramName
        case .deduction(let content):
            if let headline = ShareText.nonempty(content.report.recommendation.headline) {
                return headline
            }
            return content.hexagramName
        }
    }

    var previewQuestion: String {
        switch self {
        case .divination(let content):
            return ShareText.posterQuestion(content.question)
        case .deduction(let content):
            return ShareText.posterQuestion(content.displayQuestion)
        }
    }

    var pdfChapters: [PDFChapter] {
        switch self {
        case .divination(let content): return content.pdfChapters
        case .deduction(let content): return content.pdfChapters
        }
    }
}

extension SharePayload: @unchecked Sendable {}
