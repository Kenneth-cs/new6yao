import SwiftUI

struct DeductionResultView: View {
    let report: DeductionReport
    let hexagramName: String
    let displayQuestion: String
    var sourceRecord: DivinationRecord? = nil
    let onDismiss: () -> Void
    let onEditBackground: () -> Void
    
    @State private var expandedPathIds: Set<String> = []
    @State private var showSaveAlert = false
    @State private var saveAlertTitle = "保存成功"
    @State private var saveAlertMessage = ""
    @State private var showFullBasis = false
    @State private var basisPathId: String?
    
    private static let disclaimerText = "本推演基于本次卦象与已知背景，仅供参考，不代表确定结果。"
    /// 比纯黑浅一档，比系统浅灰深，用来读长段正文。
    private static let readingBody = Color.primary.opacity(0.78)
    
    private var recommendedPath: DeductionReport.DeductionPathResult? {
        guard let id = report.recommendation.resolvedPathId else { return nil }
        return report.path(id: id)
    }
    
    /// 卡片固定为进、守、退，不按推荐把某一路提前。
    private var orderedPaths: [DeductionReport.DeductionPathResult] {
        let order = ["advance", "hold", "withdraw"]
        return report.paths.sorted { lhs, rhs in
            let left = order.firstIndex(of: lhs.id) ?? order.count
            let right = order.firstIndex(of: rhs.id) ?? order.count
            return left < right
        }
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
                    VStack(alignment: .leading, spacing: 16) {
                        questionCard
                        VStack(alignment: .leading, spacing: 8) {
                            recommendationCard
                            Text(Self.disclaimerText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        pathsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                
                bottomBar
            }
        }
        .alert(saveAlertTitle, isPresented: $showSaveAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(saveAlertMessage)
        }
        .sheet(isPresented: $showFullBasis) {
            fullBasisSheet
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
            
            Text("三路推演")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
    
    // MARK: - Question
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayText(displayQuestion))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ResultTheme.deep)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("\(hexagramName) · 基于本次解卦")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ResultTheme.softStrong)
                DeductionMountains()
                    .frame(width: 120, height: 72)
                    .padding(.trailing, 4)
                    .allowsHitTesting(false)
            }
        )
    }
    
    // MARK: - Recommendation
    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !report.recommendation.isInsufficient, let path = recommendedPath {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("当前较宜 · \(path.glyph)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
            }
            
            Text(displayText(report.recommendation.headline))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(displayText(report.recommendation.reason))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ResultTheme.fill)
        )
    }
    
    // MARK: - Paths
    private var pathsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("三种应对，三路推演")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "hand.tap")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("点击卡片展开详情，可同时查看多条路径。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 10) {
                ForEach(orderedPaths) { path in
                    pathCard(path)
                }
            }
        }
    }
    
    private func pathCard(_ path: DeductionReport.DeductionPathResult) -> some View {
        let isExpanded = expandedPathIds.contains(path.id)
        let isPriority = isPriority(path)
        
        return VStack(alignment: .leading, spacing: 12) {
            if isExpanded {
                HStack {
                    if isPriority {
                        Text("本次优先")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(ResultTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color.white.opacity(0.8))
                            )
                    }
                    Spacer()
                    Button {
                        toggle(path.id)
                    } label: {
                        HStack(spacing: 2) {
                            Text("收起")
                            Image(systemName: "chevron.up")
                                .font(.caption2)
                        }
                        .font(.subheadline)
                        .foregroundColor(ResultTheme.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button {
                if !isExpanded { toggle(path.id) }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Text(path.glyph)
                        .font(.system(size: isExpanded ? 32 : 26, weight: .bold))
                        .foregroundColor(ResultTheme.primary)
                        .frame(width: 36, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayText(path.fixedName))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(displayText(path.pathVerdict.content))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ResultTheme.deep)
                            .multilineTextAlignment(.leading)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    Spacer(minLength: 0)
                    
                    if !isExpanded {
                        Text("展开")
                            .font(.subheadline)
                            .foregroundColor(ResultTheme.primary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                detailRows(path)
                
                Button {
                    basisPathId = path.id
                    showFullBasis = true
                } label: {
                    HStack(spacing: 2) {
                        Text("查看完整依据")
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(ResultTheme.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isPriority ? ResultTheme.softStrong : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isPriority ? ResultTheme.primary.opacity(0.35) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func detailRows(_ path: DeductionReport.DeductionPathResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !path.pathAssumption.content.isEmpty {
                Text(path.pathAssumption.content)
                    .font(.system(size: 15))
                    .foregroundColor(Self.readingBody)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            labeledBlock(icon: "chart.bar.fill", title: "可能的发展", text: path.developmentTrend.cardContent)
            labeledBlock(icon: "text.alignleft", title: "判断依据", text: path.pathDivinationReasoning.pathSymbolism)
            
            if !path.verificationSignals.cautionText.isEmpty {
                (
                    Text("留意点：")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.62, green: 0.32, blue: 0.08))
                    + Text(path.verificationSignals.cautionText)
                        .foregroundColor(Self.readingBody)
                )
                .font(.system(size: 15))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 1, green: 0.95, blue: 0.88))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(red: 0.86, green: 0.48, blue: 0.16), lineWidth: 1)
                )
            }
        }
    }
    
    private func labeledBlock(icon: String, title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(ResultTheme.primary)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            Text(displayText(text))
                .font(.system(size: 15))
                .foregroundColor(Self.readingBody)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Bottom
    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button(action: onEditBackground) {
                Text("修改背景")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(ResultTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(ResultTheme.primary.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            
            Button(action: saveReport) {
                Text("保存推演")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(ResultTheme.fill)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    private var fullBasisSheet: some View {
        let path = basisPathId.flatMap { report.path(id: $0) }
        let title = path.map { "完整依据 · \($0.glyph)" } ?? "完整依据"
        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let path {
                        labeledBlock(icon: "hexagon", title: "本卦对此路的启示", text: path.pathDivinationReasoning.originalHexagram)
                        labeledBlock(icon: "arrow.triangle.2.circlepath", title: "动爻分析", text: path.pathDivinationReasoning.movingLines)
                        labeledBlock(icon: "arrow.triangle.branch", title: "变卦归向", text: path.pathDivinationReasoning.changedHexagram)
                        labeledBlock(icon: "person.2", title: "世应·用神·六亲", text: path.pathDivinationReasoning.relationAndUseGod)
                        labeledBlock(icon: "arrow.triangle.turn.up.right.diamond", title: "路径转折点", text: path.developmentTrend.turningPoint)
                        signalsBlock(path.verificationSignals.signals)
                    }
                }
                .padding(20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { showFullBasis = false }
                        .foregroundColor(ResultTheme.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func signalsBlock(_ signals: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "eye")
                    .font(.caption)
                    .foregroundColor(ResultTheme.primary)
                Text("关键应验点")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            if signals.isEmpty {
                Text("未提供")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(signals.enumerated()), id: \.offset) { _, signal in
                        Text("• \(signal)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
    
    private func isPriority(_ path: DeductionReport.DeductionPathResult) -> Bool {
        if report.recommendation.isInsufficient { return false }
        if path.isRecommended { return true }
        return path.id == report.recommendation.resolvedPathId
    }
    
    private func displayText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未提供" : trimmed
    }
    
    private func toggle(_ pathId: String) {
        withAnimation(.easeInOut(duration: 0.22)) {
            if expandedPathIds.contains(pathId) {
                expandedPathIds.remove(pathId)
            } else {
                expandedPathIds.insert(pathId)
            }
        }
    }
    
    private func saveReport() {
        guard let sourceRecord else {
            saveAlertTitle = "还不能保存"
            saveAlertMessage = "请先在解卦结果页保存本次记录，再保存推演。"
            showSaveAlert = true
            return
        }
        let saved = DataService().saveDeductionReport(report, for: sourceRecord)
        saveAlertTitle = saved ? "保存成功" : "保存失败"
        saveAlertMessage = saved ? "本次三路推演已保存。" : "这次没有写入记录，请再试一次。"
        showSaveAlert = true
    }
}

#Preview {
    DeductionResultView(
        report: DeductionReport(
            reportVersion: "v1",
            question: "这段关系接下来会如何发展？",
            backgroundUsed: "无补充背景",
            globalJudgment: .init(
                title: "原卦核心判断",
                summary: "当前节奏不一致。",
                divinationBasisSummary: "本卦示阻滞。",
                informationGaps: []
            ),
            recommendation: .init(
                status: "clear",
                recommendedPathId: "hold",
                headline: "先观其变，再定进退",
                reason: "原卦所示的阻滞仍待观察，先看看是否出现实际回应，再决定后续投入。",
                applicableConditions: [],
                reconsiderWhen: []
            ),
            paths: [
                DeductionReport.DeductionPathResult(
                    id: "hold",
                    fixedName: "暂守观望",
                    rank: 1,
                    isRecommended: true,
                    pathAssumption: .init(title: "路径假设", content: "先不追加主动联系，观察对方是否给出具体安排。"),
                    pathVerdict: .init(title: "本路总断", content: "暂缓推进，留意互动是否变化。"),
                    developmentTrend: .init(
                        title: "此路演变",
                        opening: "联系可能暂时保持低频。",
                        development: "若对方主动回应，仍有继续沟通的空间。",
                        turningPoint: "见面落实后再评估是否转入推进。",
                        possibleOutcome: "关系维持观望。"
                    ),
                    pathDivinationReasoning: .init(
                        title: "深度卦理推演",
                        originalHexagram: "本卦示闭塞。",
                        movingLines: "当前无动爻。",
                        changedHexagram: "当前无变卦。",
                        relationAndUseGod: "用神未见明显发动。",
                        pathSymbolism: "沿用本次解卦对阻滞的判断。"
                    ),
                    verificationSignals: .init(title: "关键应验点", signals: ["是否主动联系", "是否落实见面"])
                )
            ],
            reportFooter: "示例"
        ),
        hexagramName: "风泽中孚",
        displayQuestion: "这段关系该如何处理？",
        onDismiss: {},
        onEditBackground: {}
    )
}
