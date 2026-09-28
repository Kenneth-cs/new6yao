import SwiftUI

struct ShareExportSheet: View {
    let payload: SharePayload
    var onPosterSaved: () -> Void
    var onPDFReady: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var busy: ExportKind?
    @State private var bannerMessage: String?
    @State private var showPermissionAlert = false

    private enum ExportKind {
        case poster
        case completePoster
        case pdf

        var posterType: String {
            switch self {
            case .poster: return "summary"
            case .completePoster: return "complete"
            case .pdf: return "pdf"
            }
        }

        var isPoster: Bool {
            self == .poster || self == .completePoster
        }
    }

    private var showsCompletePoster: Bool {
        if case .divination = payload { return true }
        return false
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 18) {
            Text("分享 & 导出")
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            if let bannerMessage {
                Text(bannerMessage)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Capsule().fill(Color.orange.opacity(0.95)))
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 16) {
                exportCard(
                    kind: .poster,
                    title: "保存海报长图",
                    subtitle: "分享到朋友圈",
                    border: ResultTheme.primary.opacity(0.3)
                ) {
                    PosterPreviewCard(title: payload.previewTitle, question: payload.previewQuestion)
                }
                if showsCompletePoster {
                    exportCard(
                        kind: .completePoster,
                        title: "完整版长图",
                        subtitle: "全部解读",
                        border: ResultTheme.primary.opacity(0.3)
                    ) {
                        CompletePosterPreviewCard(title: payload.previewTitle)
                    }
                }
                exportCard(
                    kind: .pdf,
                    title: "导出完整报告",
                    subtitle: "存档 · 发送",
                    border: ShareTheme.pdfBlue.opacity(0.3)
                ) {
                    PDFPreviewCard(
                        reportType: payload.reportTypeName,
                        title: payload.previewTitle,
                        question: payload.previewQuestion
                    )
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    line
                    Text("即将推出")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.62))
                    line
                }
                HStack(spacing: 8) {
                    Image(systemName: "link")
                    Text("生成分享链接（H5）")
                        .font(.subheadline)
                    Spacer()
                    Text("即将推出")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.gray.opacity(0.15)))
                }
                .foregroundColor(Color(white: 0.62))
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("生成分享链接，即将推出")

            Button {
                dismiss()
            } label: {
                Text("取消")
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .overlay(
                        Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(busy != nil)
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        }
        .interactiveDismissDisabled(busy != nil)
        .presentationDetents([.height(showsCompletePoster ? 760 : 500)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(36)
        .alert("需要相册权限", isPresented: $showPermissionAlert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在设置中开启相册权限")
        }
    }

    private var line: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.25))
            .frame(height: 1)
    }

    private func exportCard<Preview: View>(
        kind: ExportKind,
        title: String,
        subtitle: String,
        border: Color,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        Button {
            start(kind)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    preview()
                    if busy == kind {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(kind.isPoster ? 0.45 : 0.28))
                        VStack(spacing: 6) {
                            ProgressView()
                                .tint(kind.isPoster ? .white : ResultTheme.primary)
                            Text("生成中…")
                                .font(.caption)
                                .foregroundColor(kind.isPoster ? .white : .primary)
                        }
                    }
                }
                .frame(width: 130, height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(border, lineWidth: 1)
                )

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ShareCardButtonStyle())
        .disabled(busy != nil)
    }

    private func start(_ kind: ExportKind) {
        guard busy == nil else { return }
        bannerMessage = nil
        switch kind {
        case .poster:
            savePoster(kind: .poster)
        case .completePoster:
            savePoster(kind: .completePoster)
        case .pdf:
            exportPDF()
        }
    }

    private func savePoster(kind: ExportKind) {
        busy = kind
        let payload = payload
        let posterKind: PosterKind = kind == .completePoster ? .complete : .summary
        let started = Date()
        AnalyticsManager.shared.trackPosterGenerateStart(
            sourcePage: payload.sourcePage.rawValue,
            posterType: kind.posterType
        )
        Task {
            do {
                let image = try PosterGenerator.render(payload, kind: posterKind)
                try await PhotoLibrarySaver.save(image)
                let elapsed = Int(Date().timeIntervalSince(started) * 1000)
                AnalyticsManager.shared.trackPosterSaveSuccess(
                    sourcePage: payload.sourcePage.rawValue,
                    renderTimeMs: elapsed,
                    posterType: kind.posterType
                )
                busy = nil
                onPosterSaved()
            } catch {
                busy = nil
                let mapped = (error as? ShareExportError) ?? ShareExportError.saveFailed
                AnalyticsManager.shared.trackPosterSaveFail(
                    sourcePage: payload.sourcePage.rawValue,
                    errorReason: mapped.analyticsReason,
                    posterType: kind.posterType
                )
                if case .permissionDenied = mapped {
                    showPermissionAlert = true
                } else {
                    showBanner(mapped.posterMessage)
                }
            }
        }
    }

    private func exportPDF() {
        busy = .pdf
        let payload = payload
        let started = Date()
        AnalyticsManager.shared.trackPDFExportStart(sourcePage: payload.sourcePage.rawValue)
        Task {
            let work = Task.detached(priority: .userInitiated) { () throws -> PDFExportFile in
                try PDFReportGenerator.write(payload)
            }
            let timeout = Task {
                try await Task.sleep(nanoseconds: 10_000_000_000)
                work.cancel()
            }
            let outcome: Result<PDFExportFile, Error>
            do {
                outcome = .success(try await work.value)
            } catch {
                outcome = .failure(error)
            }
            timeout.cancel()
            let elapsed = Int(Date().timeIntervalSince(started) * 1000)

            switch outcome {
            case .success(let file):
                if elapsed > 10_000 {
                    try? FileManager.default.removeItem(at: file.url)
                    failPDF(.timedOut, source: payload.sourcePage.rawValue)
                    return
                }
                AnalyticsManager.shared.trackPDFGenerateSuccess(
                    sourcePage: payload.sourcePage.rawValue,
                    pageCount: file.pageCount,
                    renderTimeMs: elapsed
                )
                busy = nil
                onPDFReady()
                ActivitySharePresenter.present(fileURL: file.url)
            case .failure(let error):
                let mapped: ShareExportError
                if error is CancellationError {
                    mapped = .timedOut
                } else if let share = error as? ShareExportError {
                    mapped = share
                } else {
                    mapped = ShareExportError.fromFileError(error)
                }
                failPDF(mapped, source: payload.sourcePage.rawValue)
            }
        }
    }

    private func failPDF(_ error: ShareExportError, source: String) {
        busy = nil
        AnalyticsManager.shared.trackPDFGenerateFail(sourcePage: source, errorReason: error.analyticsReason)
        showBanner(error.pdfMessage)
    }

    private func showBanner(_ message: String) {
        bannerMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if bannerMessage == message {
                bannerMessage = nil
            }
        }
    }
}

private struct PosterPreviewCard: View {
    let title: String
    let question: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("人生教练")
                .font(.system(size: 9, weight: .semibold))
            Text(title.isEmpty ? "卦象" : title)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(3)
            Text(question)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(4)
            Spacer(minLength: 0)
        }
        .foregroundColor(.white)
        .padding(12)
        .frame(width: 130, height: 200, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [ShareTheme.purpleTop, ShareTheme.purpleBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct CompletePosterPreviewCard: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("人生教练")
                .font(.system(size: 9, weight: .semibold))
            Text(title.isEmpty ? "卦象" : title)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(2)
            Text("完整解读")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.75))
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 3) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 36, height: 3)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.35))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 70, height: 3)
                }
                .padding(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )
            }
            Spacer(minLength: 0)
        }
        .foregroundColor(.white)
        .padding(12)
        .frame(width: 130, height: 200, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [ShareTheme.purpleTop, ShareTheme.purpleBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct PDFPreviewCard: View {
    let reportType: String
    let title: String
    let question: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(ResultTheme.primary)
                .frame(width: 28, height: 3)
            Text("人生教练")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(ResultTheme.primary)
            Text(reportType)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(red: 0.1, green: 0.06, blue: 0.2))
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
            Text(question)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(3)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.gray.opacity(0.22))
                        .frame(height: 4)
                }
            }
        }
        .padding(12)
        .frame(width: 130, height: 200, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ShareCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
