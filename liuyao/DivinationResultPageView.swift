import SwiftUI
import Network

/// 结果页主色，对齐设计稿紫 #935CEE
enum ResultTheme {
    static let primary = Color(red: 147 / 255, green: 92 / 255, blue: 238 / 255) // #935CEE
    static let deep = Color(red: 124 / 255, green: 74 / 255, blue: 220 / 255)    // #7C4ADC
    static let accent = Color(red: 158 / 255, green: 110 / 255, blue: 242 / 255) // #9E6EF2
    static let soft = Color(red: 0.95, green: 0.93, blue: 0.99)
    static let softStrong = Color(red: 0.93, green: 0.90, blue: 0.99)
    
    static var yao: LinearGradient {
        LinearGradient(colors: [accent, primary, deep], startPoint: .leading, endPoint: .trailing)
    }
    
    static var fill: LinearGradient {
        LinearGradient(colors: [primary, deep], startPoint: .leading, endPoint: .trailing)
    }
}

struct DivinationResultPageView: View {
    let question: String
    let tossResults: [Bool]
    let yaoLines: [YaoXiang]
    let hexagramData: (name: String, description: String)
    let currentLocation: String
    let onDismiss: () -> Void
    let isHistoryRecord: Bool
    let interpretationMode: InterpretationMode
    let liuYaoChart: LiuYaoReading?
    let categorySource: CategorySource
    let chartBuildMs: Int
    private let savedInterpretation: String
    private let savedAdvice: String
    private let castTime: Date
    
    @State private var aiInterpretation: String
    @State private var hexagramAnalysis: String = ""
    @State private var questionInterpretation: String = ""
    @State private var coreConclusionSection: String = ""
    @State private var coreVerdictSection: String = ""
    @State private var guidanceAdvice: String
    @State private var isLoading: Bool
    @State private var showSaveAlert = false
    @State private var showFollowUpChat = false
    @State private var followUpEntryMode: FollowUpEntryMode = .fromIcon
    @State private var aiFollowUpSuggestions: [String]
    @State private var oneSentenceConclusion: String
    @State private var persistedRecord: DivinationRecord?
    @State private var persistedFollowUpSession: FollowUpSession?
    @State private var pendingNewArchive = false
    @State private var saveAlertTitle = "保存成功"
    @State private var saveAlertMessage = "分析结果已保存到历史记录中"
    @State private var showDeductionPrep = false
    @State private var divinationTime: Date
    @ObservedObject private var aiStore = AIRequestStateStore.shared
    @StateObject private var aiService = AIService.shared
    
    init(
        question: String,
        tossResults: [Bool],
        yaoLines: [YaoXiang]? = nil,
        hexagramData: (name: String, description: String),
        currentLocation: String,
        onDismiss: @escaping () -> Void,
        isHistoryRecord: Bool = false,
        savedInterpretation: String = "",
        savedAdvice: String = "",
        castTime: Date,
        interpretationMode: InterpretationMode = .professional,
        liuYaoChart: LiuYaoReading? = nil,
        categorySource: CategorySource = .unclassified,
        chartBuildMs: Int = 0,
        sourceRecord: DivinationRecord? = nil
    ) {
        self.question = question
        self.tossResults = tossResults
        self.yaoLines = yaoLines ?? tossResults.map { $0 ? .youngYang : .youngYin }
        self.hexagramData = hexagramData
        self.currentLocation = currentLocation
        self.onDismiss = onDismiss
        self.isHistoryRecord = isHistoryRecord
        self.interpretationMode = interpretationMode
        self.liuYaoChart = liuYaoChart
        self.categorySource = categorySource
        self.chartBuildMs = chartBuildMs
        self.savedInterpretation = savedInterpretation
        self.savedAdvice = savedAdvice
        self.castTime = castTime
        _aiInterpretation = State(initialValue: savedInterpretation)
        _guidanceAdvice = State(initialValue: "")
        _aiFollowUpSuggestions = State(initialValue: sourceRecord?.followUpSuggestions ?? [])
        _oneSentenceConclusion = State(initialValue: sourceRecord?.oneSentenceConclusion ?? "")
        _persistedRecord = State(initialValue: sourceRecord)
        _persistedFollowUpSession = State(initialValue: nil)
        _isLoading = State(initialValue: !isHistoryRecord)
        _divinationTime = State(initialValue: castTime)
    }

    private var displayYao: [YaoXiang] {
        yaoLines.count == 6 ? yaoLines : tossResults.map { $0 ? .youngYang : .youngYin }
    }

    private var requestKey: String {
        let hexBinary = displayYao.map { $0.isYang ? "1" : "0" }.joined()
        return "divination_\(hexBinary)_\(abs(question.hashValue))_\(interpretationMode.rawValue)"
    }
    @State private var masterParseOk = false
    @StateObject private var dataService = DataService()
    @State private var networkMonitor = NWPathMonitor()
    @State private var isNetworkAvailable = true
    @Environment(\.dismiss) private var dismiss
    
    private let yaoGradient = ResultTheme.yao
    
    private var hexagramShortSummary: String {
        let desc = hexagramData.description
        if let range = desc.range(of: "。象征") {
            return String(desc[..<range.lowerBound])
        }
        if let period = desc.firstIndex(of: "。") {
            return String(desc[..<period])
        }
        return desc
    }
    
    private var hasFinishedInterpretation: Bool {
        if isLoading { return false }
        if aiInterpretation.contains("解读失败") || aiInterpretation.contains("超时") || aiInterpretation.contains("网络") {
            return false
        }
        return isHistoryRecord || !aiInterpretation.isEmpty || !hexagramAnalysis.isEmpty
    }
    
    private var mockOneSentenceConclusion: String {
        let desc = hexagramData.description
        if desc.contains("宜守静待时") || desc.contains("不可妄动") || hexagramData.name.contains("否") {
            return "当前不宜主动推进，宜静待时机"
        }
        if let range = desc.range(of: "象征") {
            let rest = String(desc[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if let period = rest.firstIndex(of: "。") {
                return String(rest[..<period])
            }
            return rest
        }
        return hexagramShortSummary
    }
    
    private var displaySuggestions: [String] {
        InterpretationTrailer.padded(aiFollowUpSuggestions)
    }

    private var resolvedConclusion: String {
        let trimmed = oneSentenceConclusion.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return InterpretationTrailer.readableOverview(trimmed) }
        if interpretationMode == .master {
            let parsed = MasterReportParser.parse(aiInterpretation)
            if let last = parsed.sections["最后一句"], !last.isEmpty {
                return InterpretationTrailer.readableOverview(last)
            }
            if let core = parsed.sections["核心结论"], !core.isEmpty {
                return InterpretationTrailer.readableOverview(String(core.prefix(80)))
            }
        }
        if !mockOneSentenceConclusion.isEmpty {
            return InterpretationTrailer.readableOverview(mockOneSentenceConclusion)
        }
        let source = (guidanceAdvice.isEmpty ? aiInterpretation : guidanceAdvice)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if source.isEmpty { return "暂无解读" }
        return InterpretationTrailer.readableOverview(String(source.prefix(80)))
    }

    private func buildInterpretationSummary() -> String {
        let parts = [resolvedConclusion, guidanceAdvice]
        let joined = parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "暂无解读" }
            .joined(separator: "\n")
        return String(joined.prefix(300))
    }

    private var followUpContext: HexagramContext {
        HexagramContext(
            question: question,
            hexagramName: hexagramData.name,
            hexagramDescription: hexagramData.description,
            oneSentenceConclusion: resolvedConclusion,
            castTime: castTime,
            location: currentLocation,
            interpretationSummary: buildInterpretationSummary(),
            liuYaoChart: liuYaoChart,
            yaoLines: displayYao,
            followUpSuggestions: displaySuggestions
        )
    }

    private func openFollowUpChat(mode: FollowUpEntryMode) {
        if persistedFollowUpSession == nil, let record = persistedRecord {
            persistedFollowUpSession = dataService.fetchFollowUpSession(for: record)
        }
        followUpEntryMode = mode
        showFollowUpChat = true
    }
    
    var body: some View {
        ZStack {
            pageBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                
                ZStack(alignment: .bottomTrailing) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 14) {
                            questionCard
                            analysisInfoCard
                            hexagramCard
                            interpretationSection
                            if hasFinishedInterpretation {
                                FollowUpCoachCard(
                                    questions: displaySuggestions,
                                    onSelectQuestion: { openFollowUpChat(mode: .fromQuestion(preset: $0)) },
                                    onContinue: { openFollowUpChat(mode: .fromIcon) }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, hasFinishedInterpretation ? 110 : 28)
                    }
                    
                    if hasFinishedInterpretation {
                        FollowUpEntryView(action: { openFollowUpChat(mode: .fromIcon) })
                            .padding(.trailing, 10)
                            .padding(.bottom, 12)
                    }
                }
                
                if hasFinishedInterpretation {
                    bottomActionBar
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(isHistoryRecord ? .hidden : .automatic, for: .tabBar)
        .alert(saveAlertTitle, isPresented: $showSaveAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
        .fullScreenCover(isPresented: $showFollowUpChat) {
            FollowUpChatView(
                entryMode: followUpEntryMode,
                hexagramContext: followUpContext,
                existingSession: pendingNewArchive ? nil : persistedFollowUpSession,
                linkedRecord: pendingNewArchive ? nil : persistedRecord,
                onDismiss: { session in
                    if let session { persistedFollowUpSession = session }
                    showFollowUpChat = false
                },
                onViewFullInterpretation: { showFollowUpChat = false }
            )
        }
        .fullScreenCover(isPresented: $showDeductionPrep) {
            DeductionPrepView(
                originalQuestion: question,
                hexagramName: hexagramData.name,
                liuYaoChart: liuYaoChart,
                castTime: castTime,
                aiInterpretation: aiInterpretation,
                sourceRecord: persistedRecord,
                onDismiss: { showDeductionPrep = false },
                onViewOriginal: { showDeductionPrep = false }
            )
        }
        .onAppear {
            if isHistoryRecord {
                loadHistoryContent()
                startNetworkMonitoring()
                return
            }
            AnalyticsManager.shared.incrementDivinationCount()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                startNetworkMonitoring()
                if let slot = aiStore.slot(for: requestKey) {
                    switch slot.status {
                    case .loading:
                        isLoading = true
                    case .success:
                        applyRawInterpretation(slot.result)
                        if hexagramAnalysis.isEmpty {
                            hexagramAnalysis = slot.hexagramAnalysis ?? ""
                        }
                        if questionInterpretation.isEmpty {
                            questionInterpretation = slot.questionInterpretation ?? ""
                        }
                        if guidanceAdvice.isEmpty {
                            guidanceAdvice = slot.guidanceAdvice ?? ""
                        }
                        isLoading = false
                    case .failed:
                        aiInterpretation = slot.result
                        isLoading = false
                    }
                } else {
                    requestAIInterpretation()
                }
            }
        }
        .onDisappear {
            stopNetworkMonitoring()
        }
    }
    
    // MARK: - 页面背景
    private var pageBackground: some View {
        LinearGradient(
            colors: [
                ResultTheme.soft,
                ResultTheme.soft.opacity(0.45),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - 顶部栏
    private var headerBar: some View {
        HStack(alignment: .center) {
            Text("分析结果")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ResultTheme.primary)
            
            Spacer()
            
            Button(action: {
                print("[DivinationResultPageView] 点击完成按钮")
                if !isHistoryRecord {
                    aiStore.clearSlot(key: requestKey)
                }
                onDismiss()
            }) {
                Text("完成")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(ResultTheme.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
    
    // MARK: - 问题卡片
    private var questionCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.title2)
                .foregroundStyle(ResultTheme.fill)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("您的问题")
                    .font(.subheadline)
                    .foregroundColor(ResultTheme.primary.opacity(0.75))
                
                Text(question)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ResultTheme.softStrong)
                
                ResultQuestionMountains()
                    .frame(width: 118, height: 72)
                    .padding(.trailing, 6)
                    .allowsHitTesting(false)
            }
        )
    }
    
    // MARK: - 分析信息卡片
    private var analysisInfoCard: some View {
        whiteCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.body)
                    Text("分析信息")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                HStack(alignment: .center, spacing: 16) {
                    Text("卦名")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .leading)
                    
                    Text(hexagramData.name)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                HStack(alignment: .top, spacing: 16) {
                    Text("卦象")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .leading)
                        .padding(.top, 1)
                    
                    Text(hexagramData.description)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("分析时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatDate(divinationTime))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("分析地点")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(currentLocation.isEmpty ? "未知地点" : currentLocation)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - 卦象卡片
    private var hexagramCard: some View {
        whiteCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "square.3.layers.3d")
                        .font(.body)
                        .foregroundColor(ResultTheme.primary)
                    Text("卦象")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                if let chart = liuYaoChart {
                    Text(chart.changed == nil ? "无动爻，不变" : "变卦 \(chart.changed?.name ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("月建 \(chart.castTime.monthBranch) · 日辰 \(chart.castTime.dayPillar) · 旬空 \(chart.castTime.xunKong.joined())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(chart.yongShen == nil ? "未指定，由解读综合取用" : "建议用神：\(chart.yongShen?.liuQin ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 10) {
                    ForEach(Array(displayYao.enumerated().reversed()), id: \.offset) { index, yao in
                        let line = (liuYaoChart?.primary.lines.indices.contains(index) == true)
                            ? liuYaoChart?.primary.lines[index]
                            : nil
                        yaoRow(isYang: yao.isYang, isMoving: yao.isMoving, detail: line.map { item in
                            item.shiYing == nil ? item.liuQin : "\(item.liuQin) \(item.shiYing!)"
                        })
                    }
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground).opacity(0.85))
                )
                
                VStack(spacing: 4) {
                    Text("'\(hexagramData.name)'")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(hexagramShortSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            }
        }
    }
    
    private func yaoRow(isYang: Bool, isMoving: Bool, detail: String?) -> some View {
        HStack(spacing: 12) {
            Group {
                if isYang {
                    Capsule()
                        .fill(yaoGradient)
                        .frame(width: 118, height: 7)
                } else {
                    HStack(spacing: 10) {
                        Capsule()
                            .fill(yaoGradient)
                            .frame(width: 54, height: 7)
                        Capsule()
                            .fill(yaoGradient)
                            .frame(width: 54, height: 7)
                    }
                }
            }
            
            HStack(spacing: 4) {
                Text(isYang ? "阳" : "阴")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                if isMoving {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 36, alignment: .leading)

            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - 解读区域
    @ViewBuilder
    private var interpretationSection: some View {
        if isLoading {
            loadingCard
        } else if aiInterpretation.contains("解读失败") || aiInterpretation.contains("超时") || aiInterpretation.contains("网络") {
            errorCard
        } else if interpretationMode == .master {
            MasterReportView(rawText: aiInterpretation)
        } else {
            VStack(spacing: 14) {
                if !coreConclusionSection.isEmpty {
                    interpretationBlock(
                        icon: "text.badge.checkmark",
                        iconColor: ResultTheme.primary,
                        title: "核心结论",
                        titleColor: ResultTheme.primary,
                        content: coreConclusionSection,
                        placeholder: "正在生成核心结论..."
                    )
                }
                if !coreVerdictSection.isEmpty {
                    interpretationBlock(
                        icon: "seal.fill",
                        iconColor: ResultTheme.deep,
                        title: "核心断语",
                        titleColor: ResultTheme.deep,
                        content: coreVerdictSection,
                        placeholder: "正在生成核心断语..."
                    )
                }
                if !hexagramAnalysis.isEmpty {
                    interpretationBlock(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .blue,
                        title: "卦象解析",
                        titleColor: .blue,
                        content: hexagramAnalysis,
                        placeholder: "正在解析卦象含义..."
                    )
                }
                if !questionInterpretation.isEmpty {
                    interpretationBlock(
                        icon: "questionmark.circle.fill",
                        iconColor: .green,
                        title: "问题解读",
                        titleColor: .green,
                        content: questionInterpretation,
                        placeholder: "正在解读问题..."
                    )
                }
                if !guidanceAdvice.isEmpty {
                    interpretationBlock(
                        icon: "lightbulb.fill",
                        iconColor: .orange,
                        title: "建议指导",
                        titleColor: .orange,
                        content: guidanceAdvice,
                        placeholder: "正在生成建议指导..."
                    )
                }
                if hexagramAnalysis.isEmpty && questionInterpretation.isEmpty && guidanceAdvice.isEmpty && !aiInterpretation.isEmpty {
                    interpretationBlock(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .blue,
                        title: "卦象解析",
                        titleColor: .blue,
                        content: cleanAndFormatText(aiInterpretation),
                        placeholder: "暂无解读内容"
                    )
                }
            }
        }
    }
    
    private var loadingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.title3)
                    .foregroundColor(ResultTheme.primary)
                Text("大师正在解读卦象...")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Text("请稍候，正在为您分析卦象含义")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 6) {
                Text("💡")
                    .font(.subheadline)
                Text("解读过程可能需要30-60秒")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
            .padding(.top, 4)
            
            Text("网络不佳时会自动重试，请耐心等待")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ResultTheme.soft)
        )
    }
    
    private var errorCard: some View {
        whiteCard {
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("网络请求超时")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("请检查网络连接，或稍后重试")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("重新解读") {
                    retryInterpretation()
                }
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(ResultTheme.fill)
                .cornerRadius(20)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    private func interpretationBlock(
        icon: String,
        iconColor: Color,
        title: String,
        titleColor: Color,
        content: String,
        placeholder: String
    ) -> some View {
        whiteCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title3)
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(titleColor)
                    Spacer()
                }
                
                if !content.isEmpty {
                    FormattedDivinationText(content: content)
                } else {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
    }
    
    // MARK: - 底部操作栏
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(0.05))
                .frame(height: 0.5)
            
            HStack(spacing: 10) {
                outlineActionButton(icon: "bookmark", title: "保存", action: saveResult)
                outlineActionButton(icon: "arrow.triangle.2.circlepath", title: "重解", action: retryInterpretation)
                
                Spacer(minLength: 12)
                
                Button(action: { showDeductionPrep = true }) {
                    HStack(spacing: 6) {
                        Text("推演事件趋势")
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(Capsule().fill(ResultTheme.fill))
                    .shadow(color: ResultTheme.primary.opacity(0.28), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: -2)
        )
    }
    
    private func outlineActionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(ResultTheme.primary)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ResultTheme.primary.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func whiteCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: ResultTheme.primary.opacity(0.10), radius: 12, x: 0, y: 4)
            )
    }
    
    private func retryInterpretation() {
        print("[DivinationResultPageView] 点击重新解读")
        pendingNewArchive = true
        persistedFollowUpSession = nil
        aiStore.clearSlot(key: requestKey)
        isLoading = true
        aiInterpretation = ""
        hexagramAnalysis = ""
        questionInterpretation = ""
        coreConclusionSection = ""
        coreVerdictSection = ""
        guidanceAdvice = ""
        oneSentenceConclusion = ""
        aiFollowUpSuggestions = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            requestAIInterpretation()
        }
    }
    
    private func loadHistoryContent() {
        isLoading = false
        if savedInterpretation.isEmpty {
            aiInterpretation = ""
            hexagramAnalysis = ""
            questionInterpretation = ""
            coreConclusionSection = ""
            coreVerdictSection = ""
            guidanceAdvice = savedAdvice.isEmpty ? "" : cleanAndFormatText(savedAdvice)
            if aiFollowUpSuggestions.isEmpty {
                aiFollowUpSuggestions = InterpretationTrailer.defaultSuggestions
            }
            backfillStoredFieldsIfNeeded()
            return
        }
        applyRawInterpretation(savedInterpretation)
        if guidanceAdvice.isEmpty,
           !savedAdvice.isEmpty,
           savedAdvice != savedInterpretation {
            guidanceAdvice = cleanAndFormatText(savedAdvice)
        }
        backfillStoredFieldsIfNeeded()
    }

    private func applyRawInterpretation(_ raw: String) {
        let split = InterpretationTrailer.split(raw)
        aiInterpretation = split.body
        if !split.conclusion.isEmpty {
            oneSentenceConclusion = InterpretationTrailer.readableOverview(split.conclusion)
        }
        if split.foundSuggestions {
            aiFollowUpSuggestions = split.suggestions
        }
        if interpretationMode == .master {
            let parsed = MasterReportParser.parse(split.body)
            masterParseOk = parsed.complete
            if let advice = parsed.sections["现在最值得做的事"], !advice.isEmpty {
                guidanceAdvice = advice
            }
            if oneSentenceConclusion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let last = parsed.sections["最后一句"], !last.isEmpty {
                oneSentenceConclusion = InterpretationTrailer.readableOverview(last)
            }
        } else {
            parseAIInterpretation(split.body)
        }
        if aiFollowUpSuggestions.isEmpty {
            aiFollowUpSuggestions = InterpretationTrailer.defaultSuggestions
        }
    }

    private func backfillStoredFieldsIfNeeded() {
        guard isHistoryRecord, let record = persistedRecord else { return }
        var changed = false
        if (record.oneSentenceConclusion ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            record.oneSentenceConclusion = resolvedConclusion
            changed = true
        }
        if record.followUpSuggestions.isEmpty {
            record.followUpSuggestions = displaySuggestions
            changed = true
        }
        if changed {
            try? record.managedObjectContext?.save()
        }
    }

    // MARK: - 私有方法
    private func requestAIInterpretation() {
        print("[DivinationResultPageView] 开始请求AI解读")
        aiStore.markLoading(key: requestKey)
        
        // 检查网络连接
        if !isNetworkAvailable {
            print("[DivinationResultPageView] 网络不可用")
            aiInterpretation = "网络连接不可用，请检查网络设置后重试。"
            isLoading = false
            return
        }
        
        print("[DivinationResultPageView] 卦象信息: \(hexagramData.name)")
        
        Task {
            do {
                // 先测试API连接
                print("[DivinationResultPageView] 测试API连接...")
                let testResult = try await aiService.testAPIConnection()
                print("[DivinationResultPageView] API连接测试结果: \(testResult)")
                
                // 如果测试成功，进行正式解读
                print("[DivinationResultPageView] 调用AIService.interpretDivinationStream")
                let hexagramStruct = HexagramData(name: hexagramData.name, description: hexagramData.description)
                
                let interpretation = try await aiService.interpretDivinationStream(
                    question: question,
                    hexagram: hexagramStruct,
                    tossResults: tossResults,
                    divinationTime: self.castTime,
                    divinationLocation: currentLocation.isEmpty ? "未知地点" : currentLocation,
                    mode: interpretationMode,
                    chart: liuYaoChart
                )
                
                print("[DivinationResultPageView] AI解读完成，长度: \(interpretation.count)")
                
                await MainActor.run {
                    self.applyRawInterpretation(interpretation)
                    self.isLoading = false
                    let waitMs = Int(Date().timeIntervalSince(self.castTime) * 1000)
                    let usageStats = UserDefaults.standard.usageStatistics
                    let movingCount = self.displayYao.filter(\.isMoving).count
                    AnalyticsManager.shared.trackDivinationResult(
                        hexagramName: self.hexagramData.name,
                        waitTimeMs: waitMs,
                        dailyCurrentCount: usageStats.dailyDivinationCount,
                        userQuestion: self.question,
                        aiInterpretation: interpretation,
                        extras: [
                            "interpretation_mode": self.interpretationMode.rawValue,
                            "has_moving_lines": movingCount > 0,
                            "moving_count": movingCount,
                            "engine_category": self.liuYaoChart?.question.category ?? "unclassified",
                            "category_source": self.categorySource.rawValue,
                            "chart_build_ms": self.chartBuildMs,
                            "ai_max_tokens": self.interpretationMode == .master ? 8000 : 3000,
                            "master_section_parse_ok": self.interpretationMode == .master ? self.masterParseOk : false,
                            "question_length": self.question.count
                        ]
                    )
                    DispatchQueue.main.async {
                        self.aiStore.markSuccess(
                            key: self.requestKey,
                            result: interpretation,
                            hexagramAnalysis: self.hexagramAnalysis,
                            questionInterpretation: self.questionInterpretation,
                            guidanceAdvice: self.guidanceAdvice
                        )
                    }
                }
            } catch {
                print("[DivinationResultPageView] AI解读失败: \(error.localizedDescription)")
                
                // 更详细的错误处理
                let errorMessage: String
                if let networkError = error as? NetworkError {
                    errorMessage = networkError.localizedDescription
                } else if let aiError = error as? AIServiceError {
                    errorMessage = aiError.localizedDescription
                } else {
                    errorMessage = "网络连接超时，请检查网络后重试"
                }
                
                await MainActor.run {
                    self.aiInterpretation = "解读失败：\(errorMessage)"
                    self.isLoading = false
                    self.aiStore.markFailed(key: self.requestKey, message: "解读失败：\(errorMessage)")
                }
            }
        }
    }
    
    private func saveResult() {
        if persistedRecord != nil && !pendingNewArchive {
            saveAlertTitle = "已在历史中"
            saveAlertMessage = "重新解读并点保存后，会另外生成一条新记录。"
            showSaveAlert = true
            return
        }
        let wasRetry = pendingNewArchive && persistedRecord != nil
        let saved = dataService.saveDivinationRecord(
            question: question,
            tossResults: tossResults,
            aiInterpretation: aiInterpretation,
            advice: guidanceAdvice.isEmpty ? aiInterpretation : guidanceAdvice,
            castTime: castTime,
            mode: interpretationMode,
            chart: liuYaoChart,
            yaoLines: displayYao,
            category: liuYaoChart?.question.category,
            categorySource: categorySource,
            locationName: currentLocation,
            oneSentenceConclusion: resolvedConclusion,
            followUpSuggestions: displaySuggestions
        )
        if let saved {
            if let session = persistedFollowUpSession, session.divinationRecord == nil {
                dataService.attach(session, to: saved)
            }
            persistedRecord = saved
            pendingNewArchive = false
            saveAlertTitle = "保存成功"
            saveAlertMessage = wasRetry
                ? "已另存为一条新的历史记录，原来的记录仍保留。"
                : "分析结果已保存到历史记录中"
        } else {
            saveAlertTitle = "保存失败"
            saveAlertMessage = "这次没有写入历史记录，请再试一次。"
        }
        showSaveAlert = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func parseAIInterpretation(_ interpretation: String) {
        let lines = interpretation.components(separatedBy: .newlines)
        var coreConclusionContent = ""
        var coreVerdictContent = ""
        var hexagramContent = ""
        var questionContent = ""
        var guidanceContent = ""
        var currentSection = "hexagram"
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let header = trimmedLine
                .replacingOccurrences(of: "【", with: "")
                .replacingOccurrences(of: "】", with: "")
            
            if header.hasPrefix("核心结论") {
                currentSection = "coreConclusion"
                continue
            }
            if header.hasPrefix("核心断语") {
                currentSection = "coreVerdict"
                continue
            }
            if header.contains("问题解读") || header.contains("问题分析") || header.contains("问题含义") {
                currentSection = "question"
                continue
            }
            if header.contains("建议指导") || header.contains("指导建议") {
                currentSection = "guidance"
                continue
            }
            if header.contains("卦象解析") || header.contains("框架解析") || header.contains("卦象含义") || header.contains("核心含义") {
                currentSection = "hexagram"
                continue
            }
            if header.hasPrefix("一句话结论") || header.hasPrefix("追问建议") {
                currentSection = "skip"
                continue
            }
            
            guard !trimmedLine.isEmpty, currentSection != "skip" else { continue }
            switch currentSection {
            case "coreConclusion":
                appendLine(trimmedLine, to: &coreConclusionContent)
            case "coreVerdict":
                appendLine(trimmedLine, to: &coreVerdictContent)
            case "question":
                appendLine(trimmedLine, to: &questionContent)
            case "guidance":
                appendLine(trimmedLine, to: &guidanceContent)
            default:
                appendLine(trimmedLine, to: &hexagramContent)
            }
        }
        
        if hexagramContent.isEmpty && questionContent.isEmpty && guidanceContent.isEmpty
            && coreConclusionContent.isEmpty && coreVerdictContent.isEmpty {
            let totalLength = interpretation.count
            let firstThird = totalLength / 3
            let secondThird = firstThird * 2
            hexagramContent = String(interpretation.prefix(firstThird))
            questionContent = String(interpretation.dropFirst(firstThird).prefix(firstThird))
            guidanceContent = String(interpretation.suffix(totalLength - secondThird))
        }
        
        DispatchQueue.main.async {
            self.coreConclusionSection = coreConclusionContent.isEmpty ? "" : self.cleanAndFormatText(coreConclusionContent)
            self.coreVerdictSection = coreVerdictContent.isEmpty ? "" : self.cleanAndFormatText(coreVerdictContent)
            self.hexagramAnalysis = hexagramContent.isEmpty ? "" : self.cleanAndFormatText(hexagramContent)
            self.questionInterpretation = questionContent.isEmpty ? "" : self.cleanAndFormatText(questionContent)
            self.guidanceAdvice = guidanceContent.isEmpty ? "" : self.cleanAndFormatText(guidanceContent)
        }
    }
    
    private func appendLine(_ line: String, to target: inout String) {
        if !target.isEmpty {
            target += "\n"
        }
        target += line
    }
    
    // 清理和格式化文本
    private func cleanAndFormatText(_ text: String) -> String {
        var cleanedText = text
        
        // 1. 先统一换行符
        cleanedText = cleanedText.replacingOccurrences(of: "\r\n", with: "\n")
        cleanedText = cleanedText.replacingOccurrences(of: "\r", with: "\n")
        
        // 2. 移除Markdown标题符号（保留标题内容）
        // #### 标题 -> 标题
        // ### 标题 -> 标题
        // ## 标题 -> 标题
        // # 标题 -> 标题
        cleanedText = cleanedText.replacingOccurrences(of: "#{1,6} ", with: "", options: .regularExpression)
        // 移除可能没有空格的情况
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^#{1,6}", with: "", options: .regularExpression)
        
        // 3. 移除粗体和斜体符号（保留内容）
        // ***文本*** -> 文本
        cleanedText = cleanedText.replacingOccurrences(of: "\\*{3,}([^*]+)\\*{3,}", with: "$1", options: .regularExpression)
        // **文本** -> 文本
        cleanedText = cleanedText.replacingOccurrences(of: "\\*{2}([^*]+)\\*{2}", with: "$1", options: .regularExpression)
        // *文本* -> 文本
        cleanedText = cleanedText.replacingOccurrences(of: "\\*([^*\\n]+)\\*", with: "$1", options: .regularExpression)
        // 移除孤立的星号
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^\\*+$", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^\\*+ ", with: "", options: .regularExpression)
        
        // 4. 移除下划线符号
        cleanedText = cleanedText.replacingOccurrences(of: "__([^_]+)__", with: "$1", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "_([^_]+)_", with: "$1", options: .regularExpression)
        
        // 5. 移除删除线
        cleanedText = cleanedText.replacingOccurrences(of: "~~([^~]+)~~", with: "$1", options: .regularExpression)
        
        // 6. 移除代码块符号
        cleanedText = cleanedText.replacingOccurrences(of: "```[\\s\\S]*?```", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "`([^`]+)`", with: "$1", options: .regularExpression)
        
        // 7. 移除分隔线（使用多行模式）
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^---+$", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^___+$", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^\\*\\*\\*+$", with: "", options: .regularExpression)
        
        // 8. 移除方括号【】和特殊括号
        cleanedText = cleanedText.replacingOccurrences(of: "【", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "】", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "『", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "』", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "「", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "」", with: "")
        
        // 9. 处理列表符号
        // - 项目 -> 项目
        // * 项目 -> 项目
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^[\\-\\*] ", with: "", options: .regularExpression)
        
        // 10. 处理数字列表，保留数字但美化格式
        // 1. 项目 -> 1. 项目
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^([0-9]+)\\. ", with: "$1. ", options: .regularExpression)
        
        // 11. 在中文标点后适当换行
        // 句号后换行
        cleanedText = cleanedText.replacingOccurrences(of: "。(?!\\n)", with: "。\n", options: .regularExpression)
        // 问号后换行（但不在问号已经后面跟换行的情况）
        cleanedText = cleanedText.replacingOccurrences(of: "？(?!\\n)", with: "？\n", options: .regularExpression)
        // 感叹号后换行
        cleanedText = cleanedText.replacingOccurrences(of: "！(?!\\n)", with: "！\n", options: .regularExpression)
        
        // 12. 冒号后换行（用于要点说明）
        cleanedText = cleanedText.replacingOccurrences(of: "：(?!\\n)", with: "：\n", options: .regularExpression)
        
        // 13. 清理多余的空格
        // 多个空格变成一个
        cleanedText = cleanedText.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
        // 行首行尾空格
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^ +", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "(?m) +$", with: "", options: .regularExpression)
        
        // 14. 清理多余的空行
        // 三个以上换行变成两个
        cleanedText = cleanedText.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // 14.5. 移除只包含符号的行（更彻底）
        let lines = cleanedText.components(separatedBy: .newlines)
        cleanedText = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // 跳过空行
            if trimmed.isEmpty { return false }
            // 跳过只有符号的行
            if trimmed.range(of: "^[\\s\\*\\-_=#:：、。，！？•·]+$", options: .regularExpression) != nil {
                return false
            }
            // 跳过太短的行（少于2个字符）
            if trimmed.count < 2 { return false }
            return true
        }.joined(separator: "\n")
        
        // 15. 移除孤立的符号行
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^[\\*\\-_=#+]+$", with: "", options: .regularExpression)
        
        // 16. 移除引号符号（中英文）- 使用Unicode转义
        cleanedText = cleanedText.replacingOccurrences(of: "\u{201C}", with: "")  // "
        cleanedText = cleanedText.replacingOccurrences(of: "\u{201D}", with: "")  // "
        cleanedText = cleanedText.replacingOccurrences(of: "\u{2018}", with: "")  // '
        cleanedText = cleanedText.replacingOccurrences(of: "\u{2019}", with: "")  // '
        
        // 17. 移除可能残留的单个星号（不在句子中间的）
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^\\* ", with: "• ", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: " \\*$", with: "", options: .regularExpression)
        
        // 18. 处理可能残留的井号
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^#+ ", with: "", options: .regularExpression)
        
        // 19. 清理可能的HTML标签（如果有）
        cleanedText = cleanedText.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // 20. 清理连续的标点符号
        cleanedText = cleanedText.replacingOccurrences(of: "([，。！？]){2,}", with: "$1", options: .regularExpression)
        
        // 21. 清理首尾空白
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedText
    }
    
    private func startNetworkMonitoring() {
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
        
        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isNetworkAvailable = path.status == .satisfied
                print("[DivinationResultPageView] 网络状态: \(path.status == .satisfied ? "可用" : "不可用")")
            }
        }
    }
    
    private func stopNetworkMonitoring() {
          networkMonitor.cancel()
      }
}

// MARK: - 格式化文本显示组件
struct FormattedDivinationText: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(formatTextContent(content), id: \.id) { segment in
                HStack(alignment: .top, spacing: 10) {
                    if segment.isBulletPoint {
                        // 要点样式 - 圆点标记
                        VStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue.opacity(0.8), .blue.opacity(0.5)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 7, height: 7)
                                .padding(.top, 9)
                            Spacer()
                        }
                        
                        Text(segment.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if segment.isImportant {
                        // 重要信息样式 - 高亮背景
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                            
                            Text(segment.text)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineSpacing(8)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange.opacity(0.12),
                                            Color.orange.opacity(0.08)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    } else {
                        // 普通文本样式 - 更好的行间距
                        Text(segment.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    private func formatTextContent(_ text: String) -> [TextSegment] {
        var segments: [TextSegment] = []
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行
            if trimmedLine.isEmpty { continue }
            
            // 跳过只包含符号的行（扩展符号集）
            if trimmedLine.range(of: "^[\\s\\*\\-_=#:：、。，！？]+$", options: .regularExpression) != nil {
                continue
            }
            
            // 跳过只包含少量字符的行（可能是残留符号）
            if trimmedLine.count < 2 {
                continue
            }
            
            // 判断是否是数字列表项
            let isNumberedList = trimmedLine.range(of: "^[0-9]+\\.", options: .regularExpression) != nil
            
            // 判断是否是要点（包含特定关键词或短句）
            let isBulletPoint = isNumberedList ||
                               trimmedLine.hasPrefix("•") ||
                               trimmedLine.hasPrefix("·") ||
                               trimmedLine.hasPrefix("⭐") ||
                               trimmedLine.hasPrefix("✓") ||
                               (trimmedLine.contains("：") && trimmedLine.count < 50)
            
            // 判断是否是重要信息/标题
            let isImportant = !isBulletPoint && (
                               trimmedLine.contains("核心") ||
                               trimmedLine.contains("关键") ||
                               trimmedLine.contains("重要") ||
                               trimmedLine.contains("注意") ||
                               trimmedLine.contains("记住") ||
                               trimmedLine.contains("总结") ||
                               trimmedLine.contains("小结") ||
                               trimmedLine.contains("结论") ||
                               trimmedLine.contains("要点") ||
                               trimmedLine.contains("提醒") ||
                               trimmedLine.contains("提示") ||
                               // 短句且包含冒号（可能是小标题）
                               (trimmedLine.count < 30 && trimmedLine.contains("："))
            )
            
            // 处理行内容
            var cleanLine = trimmedLine
            
            // 如果是数字列表，保留数字
            if isNumberedList {
                // 不做额外处理，保持 "1. 内容" 的格式
            }
            
            // 移除可能残留的符号
            cleanLine = cleanLine.replacingOccurrences(of: "^[•·\\-\\*] *", with: "", options: .regularExpression)
            
            // 移除行首的井号和冒号
            cleanLine = cleanLine.replacingOccurrences(of: "^[#:]+ *", with: "", options: .regularExpression)
            
            // 移除行首行尾的星号
            cleanLine = cleanLine.replacingOccurrences(of: "^\\*+ *", with: "", options: .regularExpression)
            cleanLine = cleanLine.replacingOccurrences(of: " *\\*+$", with: "", options: .regularExpression)
            
            // 移除方括号
            cleanLine = cleanLine.replacingOccurrences(of: "[【】『』「」]", with: "", options: .regularExpression)
            
            // 确保行不为空
            cleanLine = cleanLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanLine.isEmpty { continue }
            if cleanLine.count < 2 { continue }  // 跳过太短的行
            
            segments.append(TextSegment(
                id: index,
                text: cleanLine,
                isBulletPoint: isBulletPoint,
                isImportant: isImportant
            ))
        }
        
        return segments
    }
}

struct TextSegment {
    let id: Int
    let text: String
    let isBulletPoint: Bool
    let isImportant: Bool
}

// MARK: - 问题卡山脉装饰
private struct ResultQuestionMountains: View {
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
            .fill(Color.white.opacity(0.42))
            
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

// MARK: - 追问入口（悬浮在内容区右下角，暂不接逻辑）
private struct FollowUpEntryView: View {
    var action: () -> Void = {}
    
    /// 圆形头像显示尺寸。换底图时导出 216×216 像素的正方形，资源名 FollowUpAvatar。
    private let avatarSize: CGFloat = 72
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                avatar
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(color: ResultTheme.primary.opacity(0.28), radius: 8, y: 3)
                
                ZStack {
                    Circle()
                        .fill(ResultTheme.primary)
                    HStack(spacing: 2.5) {
                        Circle().frame(width: 3.5, height: 3.5)
                        Circle().frame(width: 3.5, height: 3.5)
                    }
                    .foregroundColor(.white)
                }
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: 2, y: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("追问")
    }
    
    private var avatar: some View {
        FollowUpAvatarView()
    }
}

struct FollowUpAvatarView: View {
    var body: some View {
        Group {
            if UIImage(named: "FollowUpAvatar") != nil {
                Image("FollowUpAvatar")
                    .resizable()
                    .scaledToFill()
            } else {
                FollowUpPortrait()
            }
        }
    }
}

// MARK: - 追问教练模块（解卦完成后展示，目前为假数据）
private struct FollowUpCoachCard: View {
    let questions: [String]
    var onSelectQuestion: (String) -> Void = { _ in }
    var onContinue: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                FollowUpAvatarView()
                    .frame(width: 52, height: 52)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [ResultTheme.soft, ResultTheme.softStrong],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    )
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: ResultTheme.primary.opacity(0.18), radius: 4, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("追问教练")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("看不懂？继续追问这次解卦")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 0)
            }
            
            VStack(spacing: 10) {
                ForEach(questions, id: \.self) { question in
                    Button {
                        onSelectQuestion(question)
                    } label: {
                        HStack(spacing: 8) {
                            Text(question)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ResultTheme.primary)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(ResultTheme.primary.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(ResultTheme.primary.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.fill")
                    Text("继续追问本次解卦")
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: ResultTheme.primary.opacity(0.10), radius: 12, x: 0, y: 4)
        )
    }
}

struct FollowUpPortrait: View {
    var body: some View {
        Canvas { context, size in
            let hair = Color(red: 0.28, green: 0.22, blue: 0.28)
            let skin = Color(red: 0.99, green: 0.86, blue: 0.76)
            let feature = Color(red: 0.42, green: 0.28, blue: 0.30)
            
            var hairPath = Path()
            hairPath.addEllipse(in: CGRect(
                x: size.width * 0.16,
                y: size.height * 0.10,
                width: size.width * 0.68,
                height: size.height * 0.62
            ))
            context.fill(hairPath, with: .color(hair))
            
            var face = Path()
            face.addEllipse(in: CGRect(
                x: size.width * 0.27,
                y: size.height * 0.28,
                width: size.width * 0.46,
                height: size.height * 0.46
            ))
            context.fill(face, with: .color(skin))
            
            var bangs = Path()
            bangs.addEllipse(in: CGRect(
                x: size.width * 0.22,
                y: size.height * 0.12,
                width: size.width * 0.56,
                height: size.height * 0.28
            ))
            context.fill(bangs, with: .color(hair))
            
            let eyeY = size.height * 0.48
            let eyeR: CGFloat = 2.4
            context.fill(
                Path(ellipseIn: CGRect(x: size.width * 0.36 - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2)),
                with: .color(feature)
            )
            context.fill(
                Path(ellipseIn: CGRect(x: size.width * 0.64 - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2)),
                with: .color(feature)
            )
            
            var smile = Path()
            smile.addArc(
                center: CGPoint(x: size.width * 0.50, y: size.height * 0.56),
                radius: size.width * 0.09,
                startAngle: .degrees(25),
                endAngle: .degrees(155),
                clockwise: false
            )
            context.stroke(smile, with: .color(Color(red: 0.93, green: 0.62, blue: 0.58)), lineWidth: max(1.4, size.width * 0.028))
        }
        .clipShape(Circle())
    }
}

#Preview {
    let mockHex = HexagramData.getHexagram(for: "000111")
    DivinationResultPageView(
        question: "这段关系该如何处理？",
        tossResults: [false, false, false, true, true, true],
        hexagramData: (name: mockHex.name, description: mockHex.description),
        currentLocation: "解析失败",
        onDismiss: {},
        castTime: Date()
    )
}