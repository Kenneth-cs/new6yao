import CoreText
import UIKit

struct PDFExportFile {
    let url: URL
    let pageCount: Int
}

enum PDFReportGenerator {
    static func write(_ payload: SharePayload) throws -> PDFExportFile {
        let started = Date()
        let builder = PDFDocumentBuilder(payload: payload, started: started)
        let data = builder.renderData()
        if let failure = builder.failure {
            throw failure
        }
        if Task.isCancelled || Date().timeIntervalSince(started) > 10 {
            throw ShareExportError.timedOut
        }
        guard !data.isEmpty, builder.pageCount > 0 else {
            throw ShareExportError.renderFailed
        }

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let stamp = fileStamp.string(from: Date())
        let url = caches.appendingPathComponent("人生教练-\(payload.reportTypeName)-\(stamp).pdf")
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ShareExportError.fromFileError(error)
        }
        return PDFExportFile(url: url, pageCount: builder.pageCount)
    }

    /// 测试和调用方需要页数时直接拿数据，不落盘。
    static func makeData(_ payload: SharePayload) throws -> (data: Data, pageCount: Int) {
        let builder = PDFDocumentBuilder(payload: payload, started: Date())
        let data = builder.renderData()
        if let failure = builder.failure { throw failure }
        guard !data.isEmpty, builder.pageCount > 0 else {
            throw ShareExportError.renderFailed
        }
        return (data, builder.pageCount)
    }

    private static let fileStamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}

private final class PDFDocumentBuilder {
    let pageWidth: CGFloat = 595.2
    let pageHeight: CGFloat = 841.8
    let marginX: CGFloat = 50
    let contentTop: CGFloat = 56
    let payload: SharePayload
    let started: Date

    let accent = UIColor(red: 147 / 255, green: 92 / 255, blue: 238 / 255, alpha: 1)
    let titleColor = UIColor(red: 26 / 255, green: 16 / 255, blue: 51 / 255, alpha: 1)
    let bodyColor = UIColor(red: 61 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1)
    let mutedColor = UIColor(white: 0.6, alpha: 1)

    var pageCount = 0
    var y: CGFloat = 56
    var failure: ShareExportError?
    private var context: UIGraphicsPDFRendererContext?
    private let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    init(payload: SharePayload, started: Date) {
        self.payload = payload
        self.started = started
    }

    var contentWidth: CGFloat { pageWidth - marginX * 2 }
    var contentBottom: CGFloat { pageHeight - 56 }
    var pageRect: CGRect { CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight) }

    func renderData() -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            self.context = ctx
            self.drawCover()
            self.drawChapters()
            if self.failure == nil {
                self.drawDisclaimer()
            }
        }
    }

    private func drawCover() {
        guard beginPage(chrome: false) else { return }
        var cursor = y
        cursor = drawCentered("人生教练", font: .systemFont(ofSize: 28, weight: .bold), color: titleColor, y: cursor)
        cursor += 8
        cursor = drawCentered(payload.reportTypeName, font: .systemFont(ofSize: 16, weight: .medium), color: accent, y: cursor)
        cursor += 18
        cursor = drawDivider(y: cursor)
        cursor += 20

        switch payload {
        case .divination(let content):
            cursor = drawCoverLabel("您的问题", y: cursor)
            cursor = drawWrapped(content.question, font: .systemFont(ofSize: 16, weight: .semibold), color: titleColor, y: cursor, maxHeight: 96)
            cursor += 16
            cursor = drawMetaRow("解卦时间", content.formattedTime, y: cursor)
            cursor = drawMetaRow("解卦地点", content.locationText, y: cursor)
            cursor = drawMetaRow("解卦卦名", content.hexagramName, y: cursor)
            cursor = drawMetaRow("解卦模式", content.modeTitle, y: cursor)
            cursor += 18
            cursor = drawDivider(y: cursor)
            cursor += 24
            if content.showsYaoGraphic {
                cursor = drawYao(content.yaoLines, y: cursor)
            } else if ShareText.nonempty(content.hexagramName) != nil {
                cursor = drawCentered(content.hexagramName, font: .systemFont(ofSize: 28, weight: .bold), color: titleColor, y: cursor)
            }
        case .deduction(let content):
            cursor = drawCoverLabel("您的问题", y: cursor)
            cursor = drawWrapped(content.displayQuestion, font: .systemFont(ofSize: 16, weight: .semibold), color: titleColor, y: cursor, maxHeight: 120)
            cursor += 16
            cursor = drawMetaRow("关联卦象", content.hexagramName, y: cursor)
            if let background = ShareText.nonempty(content.report.backgroundUsed) {
                cursor = drawMetaRow("补充背景", background, y: cursor)
            }
            cursor += 18
            cursor = drawDivider(y: cursor)
            cursor += 28
            if ShareText.nonempty(content.hexagramName) != nil {
                cursor = drawCentered(content.hexagramName, font: .systemFont(ofSize: 28, weight: .bold), color: titleColor, y: cursor)
            }
        }

        let footerTop = pageHeight - 108
        if cursor < footerTop - 12 {
            _ = drawDivider(y: footerTop)
            _ = drawCentered("本报告由「人生教练」生成", font: .systemFont(ofSize: 11), color: bodyColor, y: footerTop + 14)
            _ = drawCentered("仅供参考，不构成任何决策依据", font: .systemFont(ofSize: 11), color: mutedColor, y: footerTop + 32)
        }
    }

    private func drawChapters() {
        for (index, chapter) in payload.pdfChapters.enumerated() {
            if failure != nil { return }
            guard chapterHasContent(chapter) else { continue }
            guard beginChapterPageIfNeeded() else { return }
            drawChapterTitle(chapter.title, index: index)
            for block in chapter.blocks {
                if failure != nil { return }
                switch block {
                case .prose(let text):
                    guard let text = ShareText.nonempty(text) else { continue }
                    drawFlowing(text, quote: false)
                    y += 8
                case .quote(let text):
                    guard let text = ShareText.nonempty(text) else { continue }
                    drawFlowing(text, quote: true)
                    y += 10
                case .bullets(let items):
                    let lines = items.compactMap { ShareText.nonempty($0) }.map { "• \($0)" }
                    guard !lines.isEmpty else { continue }
                    drawFlowing(lines.joined(separator: "\n"), quote: false)
                    y += 8
                case .table(let rows):
                    drawTable(rows)
                }
            }
            y += 10
        }
    }

    private func drawDisclaimer() {
        guard beginPage(chrome: true) else { return }
        drawPlainTitle("免责声明")
        let body = "本报告由「人生教练」根据本次卦象自动生成，仅供参考。六爻是一种传统文化工具，解读结果存在一定的主观性与局限性，不应作为重大决策的唯一依据。请理性看待，独立判断。"
        drawFlowing(body, quote: false)
        y += 16
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let versionText = version.isEmpty ? "人生教练" : "人生教练 v\(version)"
        drawFlowing("生成时间：\(clock.string(from: Date()))\n应用版本：\(versionText)", quote: false)
    }

    @discardableResult
    private func beginPage(chrome: Bool) -> Bool {
        if failure != nil { return false }
        if Task.isCancelled || Date().timeIntervalSince(started) > 10 {
            failure = .timedOut
            return false
        }
        if pageCount > 80 {
            failure = .renderFailed
            return false
        }
        guard let context else {
            failure = .renderFailed
            return false
        }
        context.beginPage()
        pageCount += 1
        drawPageNumber()
        if chrome {
            drawRunningHeader()
            y = contentTop
        } else {
            y = 78
        }
        return true
    }

    private func beginChapterPageIfNeeded() -> Bool {
        if pageCount == 0 {
            return beginPage(chrome: true)
        }
        if y > contentTop + 24 && contentBottom - y < 72 {
            return beginPage(chrome: true)
        }
        if pageCount == 1 {
            return beginPage(chrome: true)
        }
        return failure == nil
    }

    private func drawRunningHeader() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: accent
        ]
        let left = NSAttributedString(string: "人生教练", attributes: attributes)
        let right = NSAttributedString(string: payload.reportTypeName, attributes: attributes)
        left.draw(in: CGRect(x: marginX, y: 32, width: 140, height: 12))
        let rightWidth = right.size().width
        right.draw(in: CGRect(x: pageWidth - marginX - rightWidth, y: 32, width: rightWidth, height: 12))
    }

    private func drawPageNumber() {
        let text = NSAttributedString(string: "\(pageCount)", attributes: [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: mutedColor
        ])
        let size = text.size()
        text.draw(in: CGRect(x: (pageWidth - size.width) / 2, y: pageHeight - 36, width: size.width, height: size.height))
    }

    private func drawChapterTitle(_ title: String, index: Int) {
        let label = "\(ChineseNumerals.chapter(index))、\(title)"
        drawPlainTitle(label)
    }

    private func drawPlainTitle(_ title: String) {
        if contentBottom - y < 48, pageCount > 0 {
            _ = beginPage(chrome: true)
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: titleColor
        ]
        let attributed = NSAttributedString(string: title, attributes: attributes)
        let height = max(22, measure(attributed, width: contentWidth))
        attributed.draw(with: CGRect(x: marginX, y: y, width: contentWidth, height: height), options: [.usesLineFragmentOrigin], context: nil)
        y += height + 4
        accent.setFill()
        UIBezierPath(rect: CGRect(x: marginX, y: y, width: 36, height: 2)).fill()
        y += 12
    }

    private func drawFlowing(_ text: String, quote: Bool) {
        let source = text as NSString
        var location = 0
        let inset: CGFloat = quote ? 14 : 0
        while location < source.length {
            if failure != nil { return }
            var available = contentBottom - y
            if available < 24 {
                guard beginPage(chrome: true) else { return }
                available = contentBottom - y
            }
            let remaining = source.substring(from: location)
            let attributed = NSAttributedString(string: remaining, attributes: bodyAttributes)
            let width = contentWidth - inset
            var fit = fittedLength(attributed, width: width, height: available - (quote ? 6 : 0))
            if fit <= 0 {
                guard beginPage(chrome: true) else { return }
                fit = fittedLength(attributed, width: width, height: contentBottom - y)
                if fit <= 0 { fit = min(1, source.length - location) }
            }
            let length = min(fit, source.length - location)
            guard length > 0 else { return }
            let chunk = source.substring(with: NSRange(location: location, length: length))
            let chunkText = NSAttributedString(string: chunk, attributes: bodyAttributes)
            let height = measure(chunkText, width: width)
            if quote {
                let background = CGRect(x: marginX, y: y, width: contentWidth, height: height + 6)
                accent.withAlphaComponent(0.08).setFill()
                UIBezierPath(roundedRect: background, cornerRadius: 4).fill()
                accent.setFill()
                UIBezierPath(rect: CGRect(x: marginX, y: y, width: 3, height: height + 6)).fill()
            }
            let rect = CGRect(x: marginX + inset, y: y + (quote ? 3 : 0), width: width, height: height)
            chunkText.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            y += height + (quote ? 6 : 0)
            location += length
        }
    }

    private func drawTable(_ rows: [[String]]) {
        guard let columnCount = rows.map(\.count).max(), columnCount > 0 else { return }
        let rowHeight: CGFloat = 24
        let columnWidth = contentWidth / CGFloat(columnCount)
        for (index, row) in rows.enumerated() {
            if failure != nil { return }
            if y + rowHeight > contentBottom {
                guard beginPage(chrome: true) else { return }
            }
            let background: UIColor = index == 0
                ? accent.withAlphaComponent(0.12)
                : (index % 2 == 0 ? accent.withAlphaComponent(0.05) : UIColor.clear)
            background.setFill()
            UIBezierPath(rect: CGRect(x: marginX, y: y, width: contentWidth, height: rowHeight)).fill()
            accent.withAlphaComponent(0.2).setStroke()
            let border = UIBezierPath(rect: CGRect(x: marginX, y: y, width: contentWidth, height: rowHeight))
            border.lineWidth = 0.5
            border.stroke()
            for (column, cell) in row.enumerated() where column < columnCount {
                let rect = CGRect(
                    x: marginX + CGFloat(column) * columnWidth + 4,
                    y: y + 5,
                    width: columnWidth - 8,
                    height: rowHeight - 8
                )
                let text = NSAttributedString(string: cell, attributes: [
                    .font: UIFont.systemFont(ofSize: 9, weight: index == 0 ? .semibold : .regular),
                    .foregroundColor: bodyColor
                ])
                text.draw(with: rect, options: [.usesLineFragmentOrigin], context: nil)
            }
            y += rowHeight
        }
        y += 8
    }

    private var bodyAttributes: [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 20
        style.maximumLineHeight = 20
        style.lineBreakMode = .byWordWrapping
        return [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: bodyColor,
            .paragraphStyle: style
        ]
    }

    private func fittedLength(_ text: NSAttributedString, width: CGFloat, height: CGFloat) -> Int {
        guard text.length > 0, width > 1, height > 1 else { return 0 }
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        var range = CFRange()
        _ = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRange(location: 0, length: text.length),
            nil,
            CGSize(width: width, height: height),
            &range
        )
        return range.length
    }

    private func measure(_ text: NSAttributedString, width: CGFloat) -> CGFloat {
        let rect = text.boundingRect(
            with: CGSize(width: max(width, 1), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(rect.height)
    }

    @discardableResult
    private func drawCentered(_ text: String, font: UIFont, color: UIColor, y: CGFloat) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attributed = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ])
        let height = max(font.lineHeight, measure(attributed, width: contentWidth))
        attributed.draw(with: CGRect(x: marginX, y: y, width: contentWidth, height: height), options: [.usesLineFragmentOrigin], context: nil)
        return y + height
    }

    private func drawWrapped(_ text: String, font: UIFont, color: UIColor, y: CGFloat, maxHeight: CGFloat) -> CGFloat {
        let trimmed = ShareText.cleaned(text)
        guard !trimmed.isEmpty else { return y }
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byTruncatingTail
        let attributed = NSAttributedString(string: trimmed, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ])
        let natural = measure(attributed, width: contentWidth)
        let height = min(maxHeight, max(natural, font.lineHeight))
        attributed.draw(
            with: CGRect(x: marginX, y: y, width: contentWidth, height: height),
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            context: nil
        )
        return y + height
    }

    private func drawCoverLabel(_ text: String, y: CGFloat) -> CGFloat {
        drawCentered(text, font: .systemFont(ofSize: 12), color: mutedColor, y: y) + 6
    }

    private func drawMetaRow(_ label: String, _ value: String, y: CGFloat) -> CGFloat {
        let labelText = NSAttributedString(string: label, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: mutedColor
        ])
        let valueText = NSAttributedString(string: value, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: titleColor
        ])
        labelText.draw(in: CGRect(x: marginX, y: y, width: 72, height: 18))
        valueText.draw(
            with: CGRect(x: marginX + 84, y: y, width: contentWidth - 84, height: 32),
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            context: nil
        )
        return y + 22
    }

    private func drawDivider(y: CGFloat) -> CGFloat {
        accent.withAlphaComponent(0.2).setFill()
        UIBezierPath(rect: CGRect(x: marginX, y: y, width: contentWidth, height: 1)).fill()
        return y + 1
    }

    private func drawYao(_ lines: [YaoXiang], y: CGFloat) -> CGFloat {
        let segment: CGFloat = 52
        let gap: CGFloat = 14
        let total = segment * 2 + gap
        let thickness: CGFloat = 7
        let startX = (pageWidth - total) / 2
        var cursor = y
        for yao in lines.reversed() {
            if yao.isYang {
                fillCapsule(CGRect(x: startX, y: cursor, width: total, height: thickness))
            } else {
                fillCapsule(CGRect(x: startX, y: cursor, width: segment, height: thickness))
                fillCapsule(CGRect(x: startX + segment + gap, y: cursor, width: segment, height: thickness))
            }
            if yao.isMoving {
                UIColor.orange.setFill()
                UIBezierPath(ovalIn: CGRect(x: startX + total + 8, y: cursor, width: 7, height: 7)).fill()
            }
            cursor += 18
        }
        return cursor
    }

    private func fillCapsule(_ rect: CGRect) {
        accent.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2).fill()
    }

    private func chapterHasContent(_ chapter: PDFChapter) -> Bool {
        chapter.blocks.contains { block in
            switch block {
            case .prose(let text), .quote(let text):
                return ShareText.nonempty(text) != nil
            case .bullets(let items):
                return items.contains { ShareText.nonempty($0) != nil }
            case .table(let rows):
                return rows.count > 1
            }
        }
    }
}

private enum ChineseNumerals {
    static func chapter(_ index: Int) -> String {
        let number = index + 1
        let digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
        if number < 10 { return digits[number] }
        if number == 10 { return "十" }
        if number < 20 { return "十" + digits[number - 10] }
        return "\(number)"
    }
}
