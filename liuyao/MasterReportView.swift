import SwiftUI

enum MasterReportParser {
    static let anchors = [
        "核心结论", "卦象档案", "专业排盘", "核心断语", "卦眼",
        "卦象在说什么", "方位与地域解析", "你现在处于什么局面",
        "为什么这样判断", "三个关键信号", "时间提示",
        "回到你最初的问题", "现在最值得做的事", "这卦最需要警惕什么", "最后一句"
    ]

    /// 展示顺序：卦眼提到结论区，其余跟随分组。
    static let displayOrder = [
        "核心结论", "卦眼",
        "卦象档案", "专业排盘",
        "核心断语", "卦象在说什么", "方位与地域解析", "你现在处于什么局面",
        "为什么这样判断", "三个关键信号", "时间提示",
        "回到你最初的问题", "现在最值得做的事", "这卦最需要警惕什么", "最后一句"
    ]

    /// 判断、信号、建议里的固定标签。只有这些标签会分成「依据变浅、白话加重」。
    private static let detailEmphasis: [String: Emphasis] = [
        "六爻依据": .quiet,
        "代表什么": .normal,
        "简单来说": .strong,
        "解释": .normal,
        "说明": .normal,
        "为什么值得关注": .quiet,
        "现实中可能表现为": .strong
    ]

    /// 档案和排盘里适合拆成「标签 + 内容」的短字段。长句里的冒号保持原句。
    private static let fieldLabels: Set<String> = [
        "所问之事", "本卦", "变卦", "起卦时间", "起卦地点", "卦象", "本卦关键词",
        "月建", "日辰", "旬空", "用神", "原神", "忌神", "仇神", "起卦方位"
    ]

    enum Emphasis: Equatable {
        /// 六爻依据一类，给想看卦理的人，视觉上退后。
        case quiet
        case normal
        /// 简单来说、现实里会怎样，扫读时先看到这句。
        case strong
    }

    struct Detail: Equatable {
        var label: String
        var text: String
        var emphasis: Emphasis
    }

    struct ReportBlock: Identifiable {
        enum Kind {
            case paragraph(String)
            case bullet(String)
            case field(label: String, value: String)
            case chart(headers: [String], rows: [[String]])
            case point(headline: String, details: [Detail])
        }

        let id: Int
        let kind: Kind
    }

    struct Result {
        var sections: [String: String]
        var blocks: [String: [ReportBlock]]
        var complete: Bool
        var usable: Bool
    }

    static func parse(_ text: String) -> Result {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        struct Hit {
            var title: String
            var lineStart: String.Index
            var titleEnd: String.Index
        }

        var hits: [Hit] = []
        for anchor in anchors {
            guard let range = normalized.range(of: anchor) else { continue }
            let lineStart: String.Index
            if let newline = normalized[..<range.lowerBound].lastIndex(of: "\n") {
                lineStart = normalized.index(after: newline)
            } else {
                lineStart = normalized.startIndex
            }
            hits.append(Hit(title: anchor, lineStart: lineStart, titleEnd: range.upperBound))
        }
        hits.sort { $0.lineStart < $1.lineStart }

        var sections: [String: String] = [:]
        var blocks: [String: [ReportBlock]] = [:]
        for (index, hit) in hits.enumerated() {
            let bodyEnd = index + 1 < hits.count ? hits[index + 1].lineStart : normalized.endIndex
            guard hit.titleEnd <= bodyEnd else { continue }
            let raw = String(normalized[hit.titleEnd..<bodyEnd])
            let parsedBlocks = makeBlocks(raw, title: hit.title)
            let flat = flatten(parsedBlocks)
            if !flat.isEmpty {
                sections[hit.title] = flat
                blocks[hit.title] = parsedBlocks
            }
        }
        return Result(
            sections: sections,
            blocks: blocks,
            complete: sections.count == anchors.count,
            usable: sections.count >= 3
        )
    }

    private static func flatten(_ blocks: [ReportBlock]) -> String {
        blocks.compactMap { block in
            switch block.kind {
            case .paragraph(let text), .bullet(let text):
                return text
            case .field(let label, let value):
                return "\(label)：\(value)"
            case .point(let headline, let details):
                var lines: [String] = []
                if !headline.isEmpty { lines.append(headline) }
                lines += details.map { detail in
                    detail.label.isEmpty ? detail.text : "\(detail.label)：\(detail.text)"
                }
                return lines.isEmpty ? nil : lines.joined(separator: "\n")
            case .chart(_, let rows):
                let lines = rows.map { $0.filter { !$0.isEmpty }.joined(separator: " ") }.filter { !$0.isEmpty }
                return lines.isEmpty ? nil : lines.joined(separator: "\n")
            }
        }.joined(separator: "\n")
    }

    private static func makeBlocks(_ raw: String, title: String) -> [ReportBlock] {
        let lines = raw.components(separatedBy: "\n")
        var blocks: [ReportBlock] = []
        var paragraph: [String] = []
        var pointHeadline: String?
        var pointDetails: [Detail] = []
        var nextID = 0

        func flushParagraph() {
            let text = paragraph.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                blocks.append(ReportBlock(id: nextID, kind: .paragraph(text)))
                nextID += 1
            }
            paragraph = []
        }

        func flushPoint() {
            guard pointHeadline != nil || !pointDetails.isEmpty else { return }
            blocks.append(ReportBlock(
                id: nextID,
                kind: .point(headline: pointHeadline ?? "", details: pointDetails)
            ))
            nextID += 1
            pointHeadline = nil
            pointDetails = []
        }

        var index = 0
        while index < lines.count {
            if tableCells(lines[index]) != nil {
                flushParagraph()
                flushPoint()
                var tableRows: [[String]] = []
                while index < lines.count, let row = tableCells(lines[index]) {
                    if !isSeparatorRow(row) {
                        tableRows.append(row)
                    }
                    index += 1
                }
                if tableRows.count >= 2 {
                    blocks.append(ReportBlock(
                        id: nextID,
                        kind: .chart(headers: tableRows[0], rows: Array(tableRows.dropFirst()))
                    ))
                    nextID += 1
                } else if let only = tableRows.first {
                    let text = only.filter { !$0.isEmpty }.joined(separator: " ")
                    if !text.isEmpty { paragraph.append(text) }
                }
                continue
            }

            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || stripBlockquote(trimmed).isEmpty {
                if pointHeadline != nil || !pointDetails.isEmpty,
                   let upcoming = nextPrepared(from: index + 1, lines: lines),
                   detailPair(upcoming) != nil {
                    index += 1
                    continue
                }
                flushPoint()
                flushParagraph()
                index += 1
                continue
            }

            let line = preparedLine(lines[index])
            index += 1
            if line.text.isEmpty || isRepeatedTitle(line.text, title: title) || isMarkerOnly(line.text) {
                continue
            }
            if let detail = detailPair(line.text) {
                flushParagraph()
                if pointHeadline == nil && pointDetails.isEmpty {
                    pointHeadline = ""
                }
                pointDetails.append(detail)
                continue
            }
            if let field = fieldPair(line.text) {
                flushParagraph()
                flushPoint()
                blocks.append(ReportBlock(id: nextID, kind: .field(label: field.label, value: field.value)))
                nextID += 1
                continue
            }
            let upcoming = nextPrepared(from: index, lines: lines)
            if !line.isBullet, isHeadline(line.text, following: upcoming) {
                flushParagraph()
                flushPoint()
                pointHeadline = line.text
                continue
            }

            flushPoint()
            if line.isBullet {
                flushParagraph()
                blocks.append(ReportBlock(id: nextID, kind: .bullet(line.text)))
                nextID += 1
            } else {
                paragraph.append(line.text)
            }
        }
        flushPoint()
        flushParagraph()
        return blocks
    }

    private static func preparedLine(_ line: String) -> (isBullet: Bool, text: String) {
        var text = stripBlockquote(line.trimmingCharacters(in: .whitespaces))
        let isBullet = text.hasPrefix("- ") || text.hasPrefix("* ") || text.hasPrefix("• ") || text.hasPrefix("· ")
        if isBullet {
            text = String(text.dropFirst(2))
        }
        return (isBullet, stripInline(text))
    }

    private static func nextPrepared(from index: Int, lines: [String]) -> String? {
        var cursor = index
        while cursor < lines.count {
            let trimmed = lines[cursor].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || stripBlockquote(trimmed).isEmpty {
                cursor += 1
                continue
            }
            if tableCells(lines[cursor]) != nil { return nil }
            let line = preparedLine(lines[cursor])
            if line.text.isEmpty || isMarkerOnly(line.text) {
                cursor += 1
                continue
            }
            return line.text
        }
        return nil
    }

    /// ①、信号一，或下一行就是「说明 / 解释」的短标题。
    private static func isHeadline(_ text: String, following: String?) -> Bool {
        if text.range(of: #"^[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮]"#, options: .regularExpression) != nil {
            return text.count <= 42
        }
        if text.range(of: #"^信号[一二三四五12345]"#, options: .regularExpression) != nil {
            return text.count <= 42
        }
        guard text.count <= 32, !text.contains("。"), !text.contains("："), !text.contains(":") else { return false }
        guard let following, let detail = detailPair(following) else { return false }
        return detailEmphasis[detail.label] != nil
    }

    private static func detailPair(_ text: String) -> Detail? {
        guard let separator = ["：", ":"].first(where: { text.contains($0) }),
              let range = text.range(of: separator) else { return nil }
        let label = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        let value = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        guard let emphasis = detailEmphasis[label], !value.isEmpty else { return nil }
        return Detail(label: label, text: value, emphasis: emphasis)
    }

    private static func stripBlockquote(_ text: String) -> String {
        var line = text.trimmingCharacters(in: .whitespaces)
        while line.hasPrefix(">") || line.hasPrefix("＞") {
            line.removeFirst()
            line = line.trimmingCharacters(in: .whitespaces)
        }
        return line
    }

    private static func tableCells(_ line: String) -> [String]? {
        let trimmed = line.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "｜", with: "|")
        guard trimmed.filter({ $0 == "|" }).count >= 2 else { return nil }
        var parts = trimmed.split(separator: "|", omittingEmptySubsequences: false).map { stripInline(String($0)) }
        if parts.first?.isEmpty == true { parts.removeFirst() }
        if parts.last?.isEmpty == true { parts.removeLast() }
        guard parts.count >= 2 else { return nil }
        return parts
    }

    private static func isSeparatorRow(_ cells: [String]) -> Bool {
        !cells.isEmpty && cells.allSatisfy { cell in
            cell.replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: ":", with: "")
                .trimmingCharacters(in: .whitespaces)
                .isEmpty
        }
    }

    private static func fieldPair(_ text: String) -> (label: String, value: String)? {
        let separators = ["：", ":"]
        guard let separator = separators.first(where: { text.contains($0) }),
              let range = text.range(of: separator) else { return nil }
        let label = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        let value = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        guard fieldLabels.contains(label), !value.isEmpty else { return nil }
        return (label, value)
    }

    /// 去掉标题行、加粗、列表星号，以及单独成行的 `### ⑤`。
    private static func stripInline(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespaces)
        if let range = text.range(of: #"^#{1,6}\s*"#, options: .regularExpression) {
            text.removeSubrange(range)
        }
        if let range = text.range(of: #"^[0-9０-９]+[.、．]\s*"#, options: .regularExpression) {
            text.removeSubrange(range)
        }
        text = text.replacingOccurrences(of: "**", with: "")
        text = text.replacingOccurrences(of: "__", with: "")
        text = text.replacingOccurrences(of: "`", with: "")
        text = text.replacingOccurrences(of: "*", with: "")
        while text.hasPrefix("：") || text.hasPrefix(":") {
            text = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        return text.trimmingCharacters(in: .whitespaces)
    }

    private static func isRepeatedTitle(_ text: String, title: String) -> Bool {
        if text == title { return true }
        return ["标题固定：", "标题固定:", "标题：", "标题:"].contains { text == $0 + title }
    }

    private static func isMarkerOnly(_ text: String) -> Bool {
        !text.unicodeScalars.contains { CharacterSet.letters.contains($0) }
    }
}

struct MasterReportView: View {
    let rawText: String

    private var parsed: MasterReportParser.Result {
        MasterReportParser.parse(rawText)
    }

    var body: some View {
        if parsed.usable {
            VStack(spacing: 14) {
                ForEach(MasterReportParser.displayOrder, id: \.self) { title in
                    if let body = parsed.sections[title], !body.isEmpty {
                        sectionCard(title: title, blocks: parsed.blocks[title] ?? [])
                    }
                }
            }
        } else {
            ResultWhiteCard {
                Text(rawText.isEmpty ? "暂无解读内容" : rawText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func sectionCard(title: String, blocks: [MasterReportParser.ReportBlock]) -> some View {
        ResultWhiteCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(title == "核心结论" ? .title3 : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(ResultTheme.primary)
                ForEach(blocks) { block in
                    blockView(block)
                }
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: MasterReportParser.ReportBlock) -> some View {
        switch block.kind {
        case .paragraph(let text):
            styledText(text)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .bullet(let text):
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(ResultTheme.primary.opacity(0.45))
                    .frame(width: 5, height: 5)
                    .padding(.top, 8)
                styledText(text)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .point(let headline, let details):
            pointView(headline: headline, details: details)
        case .field(let label, let value):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 76, alignment: .leading)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .chart(let headers, let rows):
            MasterReportChart(headers: headers, rows: rows)
        }
    }

    /// 冒号前的短标签加重，方便在长段落里先看到结论。
    private func styledText(_ text: String) -> Text {
        var attributed = AttributedString(text)
        attributed.font = .body
        attributed.foregroundColor = .primary
        if let separator = text.range(of: "："),
           text.distance(from: text.startIndex, to: separator.lowerBound) <= 12,
           !text[..<separator.lowerBound].contains("。") {
            let lead = String(text[..<separator.upperBound])
            if let range = attributed.range(of: lead) {
                attributed[range].font = Font.body.weight(.semibold)
                attributed[range].foregroundColor = ResultTheme.primary
            }
        }
        return Text(attributed)
    }

    private func pointView(headline: String, details: [MasterReportParser.Detail]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !headline.isEmpty {
                headlineView(headline)
            }
            ForEach(Array(details.enumerated()), id: \.offset) { _, detail in
                VStack(alignment: .leading, spacing: 2) {
                    if !detail.label.isEmpty {
                        Text(detail.label)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(detail.emphasis == .strong ? ResultTheme.primary : .secondary)
                    }
                    Text(detail.text)
                        .font(detail.emphasis == .quiet ? .caption : .subheadline)
                        .fontWeight(detail.emphasis == .strong ? .semibold : .regular)
                        .foregroundColor(detail.emphasis == .quiet ? .secondary : .primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ResultTheme.primary.opacity(0.06))
        )
    }

    @ViewBuilder
    private func headlineView(_ headline: String) -> some View {
        let separators = ["｜", "|"]
        if let separator = separators.first(where: { headline.contains($0) }),
           let range = headline.range(of: separator) {
            let tag = String(headline[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let title = String(headline[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(tag)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(ResultTheme.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(ResultTheme.primary.opacity(0.12)))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            Text(headline)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(ResultTheme.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 专业排盘：六爻从上爻到初爻竖排，世、应、动爻用标记，不再画管道符表格。
private struct MasterReportChart: View {
    let headers: [String]
    let rows: [[String]]

    private var isYaoChart: Bool {
        headers.contains { $0.contains("六亲") || $0.contains("六神") || $0.contains("地支") }
    }

    private let positionsFromTop = ["上爻", "五爻", "四爻", "三爻", "二爻", "初爻"]

    var body: some View {
        VStack(spacing: 0) {
            if isYaoChart {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, cells in
                    yaoRow(index: index, cells: cells)
                    if index < rows.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            } else {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, cells in
                    Text(cells.filter { !$0.isEmpty }.joined(separator: "  "))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    if index < rows.count - 1 {
                        Divider().padding(.leading, 12)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func yaoRow(index: Int, cells: [String]) -> some View {
        let position = rows.count == 6 && index < positionsFromTop.count ? positionsFromTop[index] : "\(index + 1)"
        let spirit = column("六神", cells)
        let kin = column("六亲", cells)
        let branch = column("地支", cells)
        let element = column("五行", cells)
        let role = column("世应", cells)
        let moving = column("动爻", cells)
        let changed = column("变爻", cells)
        let branchElement = [branch, element].filter { !$0.isEmpty }.joined()

        return HStack(spacing: 8) {
            Text(position)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if !kin.isEmpty {
                        Text(kin)
                            .font(.subheadline.weight(.semibold))
                    }
                    if !branchElement.isEmpty {
                        Text(branchElement)
                            .font(.subheadline)
                    }
                    if !spirit.isEmpty {
                        Text(spirit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                if !changed.isEmpty {
                    Text("变 \(changed)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 4)
            if !role.isEmpty {
                Text(role)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(role.contains("世") ? ResultTheme.primary : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill((role.contains("世") ? ResultTheme.primary : Color.secondary).opacity(0.12))
                    )
            }
            if !moving.isEmpty {
                Text(moving)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(role.isEmpty ? Color.clear : ResultTheme.primary.opacity(0.05))
    }

    private func column(_ name: String, _ cells: [String]) -> String {
        guard let index = headers.firstIndex(where: { $0.contains(name) }), index < cells.count else { return "" }
        return cells[index]
    }
}

struct ResultWhiteCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: ResultTheme.primary.opacity(0.10), radius: 12, x: 0, y: 4)
            )
    }
}
