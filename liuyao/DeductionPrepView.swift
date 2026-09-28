import SwiftUI

struct DeductionPrepView: View {
    let originalQuestion: String
    let hexagramName: String
    let liuYaoChart: LiuYaoReading?
    let castTime: Date
    let aiInterpretation: String
    var sourceRecord: DivinationRecord? = nil
    let onDismiss: () -> Void
    let onViewOriginal: () -> Void
    
    @State private var backgroundText: String = ""
    @State private var isLinkedToOriginal = true
    @State private var showDeductionResult = false
    @State private var deductionReport: DeductionReport?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isBackgroundFocused: Bool
    
    private let maxBackgroundCount = 300
    
    private var backgroundCount: Int {
        backgroundText.count
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ResultTheme.soft, Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        questionCard
                        threePathsSection
                        backgroundSection
                        linkCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                
                bottomActions
            }
            
            if isLoading {
                Color.black.opacity(0.35).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("正在推演中…")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            
            if let errorMessage, !isLoading {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.78)))
                        .padding(.bottom, 28)
                }
                .transition(.opacity)
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
        .fullScreenCover(isPresented: $showDeductionResult) {
            if let report = deductionReport {
                DeductionResultView(
                    report: report,
                    hexagramName: hexagramName,
                    displayQuestion: originalQuestion,
                    sourceRecord: sourceRecord,
                    onDismiss: { showDeductionResult = false },
                    onEditBackground: { showDeductionResult = false }
                )
            }
        }
        .onChange(of: errorMessage) { message in
            guard message != nil else { return }
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                await MainActor.run {
                    if errorMessage == message {
                        errorMessage = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ResultTheme.primary)
                    .frame(width: 32, height: 32)
            }
            
            Spacer()
            
            Text("推演准备")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
    
    // MARK: - Question card
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("承接本次解卦")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(ResultTheme.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.55))
            )
            
            Text(originalQuestion)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ResultTheme.deep)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 4) {
                Text(hexagramName)
                    .foregroundColor(.secondary)
                Text("·")
                    .foregroundColor(.secondary)
                Button(action: onViewOriginal) {
                    Text("查看原解读")
                        .foregroundColor(ResultTheme.primary)
                }
                .buttonStyle(.plain)
            }
            .font(.subheadline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ResultTheme.softStrong)
                DeductionMountains()
                    .frame(width: 120, height: 78)
                    .padding(.trailing, 4)
                    .allowsHitTesting(false)
            }
        )
    }
    
    // MARK: - Three paths
    private var threePathsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("一卦，三种应对")
                .font(.headline)
                .fontWeight(.semibold)
            Text("看看不同选择下，事情可能如何发展。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                ForEach(DeductionPath.allCases) { path in
                    pathCard(path)
                }
            }
        }
    }
    
    private func pathCard(_ path: DeductionPath) -> some View {
        VStack(spacing: 6) {
            Text(path.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ResultTheme.primary)
            Text(path.subtitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text(path.detail)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(path.background)
        )
    }
    
    // MARK: - Background
    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("补充事情背景")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("最近发生了什么？你已经做过哪些尝试？")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                
                if backgroundText.isEmpty {
                    Text("例如：最近沟通变少、已经试过主动约见……")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $backgroundText)
                    .font(.subheadline)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(minHeight: 168)
                    .focused($isBackgroundFocused)
                    .onChange(of: backgroundText) { newValue in
                        if newValue.count > maxBackgroundCount {
                            backgroundText = String(newValue.prefix(maxBackgroundCount))
                        }
                    }
            }
            
            HStack {
                Spacer()
                Text("\(backgroundCount)/\(maxBackgroundCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Link card
    private var linkCard: some View {
        Button {
            isLinkedToOriginal.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isLinkedToOriginal ? "checkmark.square.fill" : "square")
                    .font(.caption)
                    .foregroundColor(isLinkedToOriginal ? ResultTheme.primary.opacity(0.55) : .secondary.opacity(0.45))
                Text("已关联本次卦象与原问题")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top, 2)
        }
        .buttonStyle(.plain)
        .opacity(0.7)
    }
    
    // MARK: - Bottom
    private var bottomActions: some View {
        VStack(spacing: 10) {
            Button {
                startDeduction(includeBackground: true)
            } label: {
                HStack(spacing: 6) {
                    Text("开始三路推演")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(ResultTheme.fill)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            
            Button {
                startDeduction(includeBackground: false)
            } label: {
                Text("不补充，直接推演")
                    .font(.subheadline)
                    .foregroundColor(ResultTheme.primary)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    private func startDeduction(includeBackground: Bool) {
        guard !isLoading else { return }
        isBackgroundFocused = false
        guard let chart = liuYaoChart else {
            errorMessage = "缺少卦象数据，无法推演"
            return
        }
        isLoading = true
        errorMessage = nil
        let background = includeBackground ? backgroundText : ""
        let question = originalQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        let interpretation = aiInterpretation
        let time = castTime
        Task {
            do {
                let parsed = MasterReportParser.parse(interpretation)
                let summary = buildCanonicalSummary(from: parsed)
                let report = try await AIService.shared.performDeduction(
                    question: question,
                    background: background,
                    liuYaoChart: chart,
                    castTime: time,
                    canonicalSummary: summary
                )
                await MainActor.run {
                    if let sourceRecord {
                        _ = DataService().saveDeductionReport(report, for: sourceRecord)
                    }
                    deductionReport = report
                    isLoading = false
                    showDeductionResult = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "推演失败，请重试"
                }
            }
        }
    }
    
    private func buildCanonicalSummary(from parsed: MasterReportParser.Result) -> String {
        let coreConclusion = parsed.sections["核心结论"] ?? ""
        let coreVerdict = parsed.sections["核心断语"] ?? ""
        var summary = ""
        if !coreConclusion.isEmpty {
            summary += "核心结论：\(coreConclusion)"
        }
        if !coreVerdict.isEmpty {
            if !summary.isEmpty { summary += "\n\n" }
            summary += "核心断语：\(coreVerdict)"
        }
        return summary
    }
}

enum DeductionPath: String, CaseIterable, Identifiable {
    case advance
    case hold
    case retreat
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .advance: return "进"
        case .hold: return "守"
        case .retreat: return "退"
        }
    }
    
    var subtitle: String {
        switch self {
        case .advance: return "主动推进"
        case .hold: return "暂守观望"
        case .retreat: return "适时退让"
        }
    }
    
    var detail: String {
        switch self {
        case .advance: return "主动促成变化"
        case .hold: return "观察新的信号"
        case .retreat: return "减少当前投入"
        }
    }
    
    var background: Color {
        switch self {
        case .advance: return ResultTheme.softStrong
        case .hold: return ResultTheme.soft
        case .retreat: return ResultTheme.primary.opacity(0.05)
        }
    }
}

struct DeductionMountains: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: 0, y: h * 0.62))
                path.addLine(to: CGPoint(x: w * 0.32, y: h * 0.28))
                path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.52))
                path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.18))
                path.addLine(to: CGPoint(x: w, y: h * 0.48))
                path.addLine(to: CGPoint(x: w, y: h))
                path.closeSubpath()
            }
            .fill(Color.white.opacity(0.45))
            
            Path { path in
                path.move(to: CGPoint(x: w * 0.12, y: h))
                path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.46))
                path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.68))
                path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.36))
                path.addLine(to: CGPoint(x: w, y: h * 0.58))
                path.addLine(to: CGPoint(x: w, y: h))
                path.closeSubpath()
            }
            .fill(Color.white.opacity(0.28))
        }
        .opacity(0.9)
    }
}

#Preview {
    DeductionPrepView(
        originalQuestion: "这段关系该如何处理？",
        hexagramName: "天地否",
        liuYaoChart: nil,
        castTime: Date(),
        aiInterpretation: "",
        onDismiss: {},
        onViewOriginal: {}
    )
}
