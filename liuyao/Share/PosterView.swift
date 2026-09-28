import SwiftUI

enum ShareTheme {
    static let purpleTop = Color(red: 26 / 255, green: 16 / 255, blue: 51 / 255)
    static let purpleBottom = Color(red: 61 / 255, green: 31 / 255, blue: 126 / 255)
    static let indigoTop = Color(red: 10 / 255, green: 10 / 255, blue: 31 / 255)
    static let indigoBottom = Color(red: 26 / 255, green: 21 / 255, blue: 80 / 255)
    static let gold = Color(red: 247 / 255, green: 201 / 255, blue: 72 / 255)
    static let pdfBlue = Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)

    static var posterYao: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color(red: 0.86, green: 0.75, blue: 1)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

enum PosterKind {
    case summary
    case complete
}

struct PosterCanvas: View {
    let payload: SharePayload
    let qrImage: UIImage?
    var kind: PosterKind = .summary

    var body: some View {
        switch payload {
        case .divination(let content) where kind == .complete:
            AnalysisCompletePosterView(content: content, qrImage: qrImage)
        case .divination(let content):
            AnalysisPosterView(content: content, qrImage: qrImage)
        case .deduction(let content):
            DeductionPosterView(content: content, qrImage: qrImage)
        }
    }
}

private struct AnalysisPosterView: View {
    let content: DivinationShareContent
    let qrImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader
                .padding(.bottom, 28)

            if content.showsYaoGraphic {
                PosterYaoStack(lines: content.yaoLines)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 22)
                Text(content.hexagramName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            } else {
                Text(content.hexagramName)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if let summary = ShareText.nonempty(content.hexagramShortSummary) {
                Text(summary)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }

            posterDivider.padding(.vertical, 22)

            VStack(alignment: .leading, spacing: 8) {
                Text("您问的是")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.62))
                Text("「\(ShareText.posterQuestion(content.question))」")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let conclusion = ShareText.nonempty(content.resolvedConclusion) {
                posterDivider.padding(.vertical, 22)
                VStack(alignment: .leading, spacing: 8) {
                    Text("核心结论")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Text(conclusion)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                )
            }

            posterDivider.padding(.vertical, 22)

            VStack(alignment: .leading, spacing: 6) {
                Text("解卦时间：\(content.formattedTime)")
                Text("解卦地点：\(content.locationText)")
            }
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.72))
            .padding(.bottom, 28)

            PosterFooter(qrImage: qrImage)
        }
        .padding(.top, 36)
        .padding(.horizontal, 28)
        .padding(.bottom, 0)
        .background(posterBackground)
    }

    private var brandHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
            Text("人生教练")
                .font(.system(size: 18, weight: .semibold))
            Spacer()
        }
        .foregroundColor(.white)
    }

    private var posterDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.22))
            .frame(height: 1)
    }

    private var posterBackground: some View {
        ZStack {
            LinearGradient(
                colors: [ShareTheme.purpleTop, ShareTheme.purpleBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.white.opacity(0.28), Color.clear],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 260
            )
        }
    }
}

private struct AnalysisCompletePosterView: View {
    let content: DivinationShareContent
    let qrImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                    Text("人生教练")
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Text("完整解读")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.white)
                .padding(.bottom, 24)

                if content.showsYaoGraphic {
                    PosterYaoStack(lines: content.yaoLines)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 18)
                }

                Text(content.hexagramName)
                    .font(.system(size: content.showsYaoGraphic ? 32 : 40, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                if let summary = ShareText.nonempty(content.hexagramShortSummary) {
                    Text(summary)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }

                if let caption = content.chartCaption {
                    Text(caption)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.66))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(height: 1)
                    .padding(.vertical, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("您问的是")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.62))
                    Text("「\(ShareText.cleaned(content.question))」")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("解卦时间：\(content.formattedTime)")
                    Text("解卦地点：\(content.locationText)")
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.72))
                .padding(.top, 18)

                if !content.fullPosterSections.isEmpty {
                    Text("解读")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 28)
                        .padding(.bottom, 12)

                    VStack(spacing: 12) {
                        ForEach(content.fullPosterSections) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text(section.body)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.92))
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.14))
                            )
                        }
                    }
                }
            }
            .padding(.top, 36)
            .padding(.horizontal, 28)
            .padding(.bottom, 28)

            PosterFooter(qrImage: qrImage)
        }
        .background(posterBackground)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var posterBackground: some View {
        ZStack {
            LinearGradient(
                colors: [ShareTheme.purpleTop, ShareTheme.purpleBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.white.opacity(0.28), Color.clear],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 260
            )
        }
    }
}

private struct DeductionPosterView: View {
    let content: DeductionShareContent
    let qrImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("人生教练")
                }
                .font(.system(size: 18, weight: .semibold))
                Spacer()
                Text("三路推演")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .foregroundColor(.white)

            if let question = ShareText.nonempty(content.displayQuestion) {
                Text(question)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(content.hexagramName)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))

            Text(ShareText.nonempty(content.report.recommendation.headline) ?? "三路推演")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            if let reason = ShareText.nonempty(content.report.recommendation.reason) {
                Text(reason)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                ForEach(content.orderedPaths) { path in
                    DeductionPathCard(content: content, path: path)
                }
            }
            .padding(.top, 4)

            PosterFooter(qrImage: qrImage)
                .padding(.horizontal, -28)
                .padding(.top, 8)
        }
        .padding(.top, 36)
        .padding(.horizontal, 28)
        .background(background)
    }

    private var background: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [ShareTheme.indigoTop, ShareTheme.indigoBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            DeductionMountains()
                .frame(width: 160, height: 90)
                .padding(.top, 24)
                .padding(.trailing, 8)
                .allowsHitTesting(false)
        }
    }
}

private struct PosterYaoStack: View {
    let lines: [YaoXiang]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(lines.enumerated().reversed()), id: \.offset) { _, yao in
                HStack(spacing: 8) {
                    YaoStrokeView(isYang: yao.isYang, gradient: ShareTheme.posterYao)
                    Circle()
                        .fill(yao.isMoving ? Color.orange : Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}

private struct PosterFooter: View {
    let qrImage: UIImage?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("人生教练")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("来自人生教练")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.75))
                Text("App Store 下载")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.75))
            }
            Spacer()
            if let qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: ShareQRCode.pointSize, height: ShareQRCode.pointSize)
                    .padding(4)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.28))
    }
}

private struct DeductionPathCard: View {
    let content: DeductionShareContent
    let path: DeductionReport.DeductionPathResult

    var body: some View {
        let recommended = content.isRecommended(path)
        let verdict = ShareText.nonempty(path.pathVerdict.content) ?? ""
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Self.pathColor(path.id))
                    .frame(width: 8, height: 8)
                Text("\(path.glyph) · \(path.fixedName)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                if recommended {
                    Text("推荐")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ShareTheme.gold)
                }
                Spacer(minLength: 0)
            }
            if !verdict.isEmpty {
                Text(verdict)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Self.detailRows(path)) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ShareTheme.gold.opacity(0.95))
                    Text(row.body)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(recommended ? ShareTheme.gold.opacity(0.16) : Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(recommended ? ShareTheme.gold.opacity(0.85) : Color.clear, lineWidth: 1)
        )
    }

    private static func pathColor(_ id: String) -> Color {
        switch id {
        case "advance": return Color(red: 1, green: 0.55, blue: 0.22)
        case "hold": return Color(red: 0.38, green: 0.62, blue: 1)
        case "withdraw", "retreat": return Color.white.opacity(0.55)
        default: return Color.white.opacity(0.7)
        }
    }

    private static func detailRows(_ path: DeductionReport.DeductionPathResult) -> [PosterCopy] {
        var rows: [PosterCopy] = []
        func add(_ title: String, _ text: String) {
            guard let body = ShareText.nonempty(text) else { return }
            rows.append(PosterCopy(title: title, body: body))
        }
        let assumption = ShareText.nonempty(path.pathAssumption.content)
        if assumption != ShareText.nonempty(path.pathVerdict.content) {
            add("路径假设", path.pathAssumption.content)
        }
        let development = [
            path.developmentTrend.opening,
            path.developmentTrend.development,
            path.developmentTrend.possibleOutcome
        ].compactMap { ShareText.nonempty($0) }.joined(separator: "\n")
        add("可能的发展", development)
        add("判断依据", path.pathDivinationReasoning.pathSymbolism)
        add("留意点", path.verificationSignals.cautionText)
        add("本卦对此路的启示", path.pathDivinationReasoning.originalHexagram)
        add("动爻分析", path.pathDivinationReasoning.movingLines)
        add("变卦归向", path.pathDivinationReasoning.changedHexagram)
        add("世应·用神·六亲", path.pathDivinationReasoning.relationAndUseGod)
        add("路径转折点", path.developmentTrend.turningPoint)
        let signals = path.verificationSignals.signals.compactMap { ShareText.nonempty($0) }
        if signals.count > 3 {
            add("关键应验点", signals.map { "• \($0)" }.joined(separator: "\n"))
        }
        return rows
    }
}

private struct PosterCopy: Identifiable {
    let title: String
    let body: String
    var id: String { title }
}

enum PosterSliceViews {
    static func make(payload: SharePayload, kind: PosterKind, qrImage: UIImage?) -> [AnyView] {
        switch payload {
        case .divination(let content) where kind == .complete:
            return completeAnalysis(content, qrImage: qrImage)
        case .divination:
            return [AnyView(PosterCanvas(payload: payload, qrImage: qrImage).frame(width: 390))]
        case .deduction(let content):
            return deduction(content, qrImage: qrImage)
        }
    }

    private static func completeAnalysis(_ content: DivinationShareContent, qrImage: UIImage?) -> [AnyView] {
        var slices: [AnyView] = [
            AnyView(AnalysisCompleteHeaderSlice(content: content).posterSlice(ShareTheme.purpleBottom))
        ]
        for section in content.fullPosterSections {
            let chunks = ShareText.paragraphChunks(section.body)
            for (index, chunk) in chunks.enumerated() {
                slices.append(AnyView(
                    AnalysisTextSlice(title: index == 0 ? section.title : nil, bodyText: chunk)
                        .posterSlice(ShareTheme.purpleBottom)
                ))
            }
        }
        slices.append(AnyView(PosterFooter(qrImage: qrImage).posterSlice(ShareTheme.purpleBottom)))
        return slices
    }

    private static func deduction(_ content: DeductionShareContent, qrImage: UIImage?) -> [AnyView] {
        var slices: [AnyView] = [
            AnyView(DeductionHeaderSlice(content: content).posterSlice(ShareTheme.indigoBottom))
        ]
        for path in content.orderedPaths {
            slices.append(AnyView(
                DeductionPathCard(content: content, path: path)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 6)
                    .posterSlice(ShareTheme.indigoBottom)
            ))
        }
        slices.append(AnyView(PosterFooter(qrImage: qrImage).posterSlice(ShareTheme.indigoBottom)))
        return slices
    }
}

private struct AnalysisCompleteHeaderSlice: View {
    let content: DivinationShareContent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                Text("人生教练")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Text("完整解读")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .foregroundColor(.white)
            .padding(.bottom, 22)

            if content.showsYaoGraphic {
                PosterYaoStack(lines: content.yaoLines)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)
            }
            Text(content.hexagramName)
                .font(.system(size: content.showsYaoGraphic ? 32 : 40, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            if let summary = ShareText.nonempty(content.hexagramShortSummary) {
                Text(summary)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            if let caption = content.chartCaption {
                Text(caption)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.66))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("您问的是")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.62))
                Text("「\(ShareText.cleaned(content.question))」")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 18)
            VStack(alignment: .leading, spacing: 6) {
                Text("解卦时间：\(content.formattedTime)")
                Text("解卦地点：\(content.locationText)")
            }
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.72))
            .padding(.top, 14)
        }
        .padding(.top, 36)
        .padding(.horizontal, 28)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [ShareTheme.purpleTop, ShareTheme.purpleBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct AnalysisTextSlice: View {
    let title: String?
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(bodyText)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.92))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.14))
        )
        .padding(.horizontal, 28)
        .padding(.vertical, 6)
    }
}

private struct DeductionHeaderSlice: View {
    let content: DeductionShareContent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("人生教练")
                }
                .font(.system(size: 18, weight: .semibold))
                Spacer()
                Text("三路推演")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .foregroundColor(.white)
            if let question = ShareText.nonempty(content.displayQuestion) {
                Text(question)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(content.hexagramName)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
            Text(ShareText.nonempty(content.report.recommendation.headline) ?? "三路推演")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            if let reason = ShareText.nonempty(content.report.recommendation.reason) {
                Text(reason)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 36)
        .padding(.horizontal, 28)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [ShareTheme.indigoTop, ShareTheme.indigoBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                DeductionMountains()
                    .frame(width: 160, height: 90)
                    .padding(.top, 24)
                    .padding(.trailing, 8)
            }
        )
    }
}

private extension View {
    func posterSlice(_ color: Color) -> some View {
        frame(width: 390)
            .background(color)
    }
}
