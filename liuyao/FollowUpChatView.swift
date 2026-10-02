import SwiftUI
import Speech
import AVFoundation

struct FollowUpChatMessage: Identifiable, Codable {
    enum Role: String, Codable {
        case user
        case coach
    }

    let id: UUID
    let role: Role
    let text: String
    let time: Date

    init(id: UUID = UUID(), role: Role, text: String, time: Date) {
        self.id = id
        self.role = role
        self.text = text
        self.time = time
    }

    enum CodingKeys: String, CodingKey {
        case role, text, time
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        role = try container.decode(Role.self, forKey: .role)
        text = try container.decode(String.self, forKey: .text)
        time = try container.decode(Date.self, forKey: .time)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(text, forKey: .text)
        try container.encode(time, forKey: .time)
    }
}

struct MiniHexagramView: View {
    var lines: [YaoXiang]

    var body: some View {
        VStack(spacing: 3) {
            if lines.isEmpty {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ResultTheme.primary)
            } else {
                ForEach(Array(lines.reversed().enumerated()), id: \.offset) { _, line in
                    miniYao(isYang: line.isYang)
                }
            }
        }
        .frame(width: 36, height: 36)
    }

    private func miniYao(isYang: Bool) -> some View {
        Group {
            if isYang {
                Capsule()
                    .fill(ResultTheme.primary)
                    .frame(width: 28, height: 3)
            } else {
                HStack(spacing: 3) {
                    Capsule().fill(ResultTheme.primary).frame(width: 12.5, height: 3)
                    Capsule().fill(ResultTheme.primary).frame(width: 12.5, height: 3)
                }
            }
        }
    }
}

struct FollowUpChatView: View {
    let entryMode: FollowUpEntryMode
    let hexagramContext: HexagramContext
    var existingSession: FollowUpSession? = nil
    var linkedRecord: DivinationRecord? = nil
    var archiveDraft: DivinationArchiveDraft? = nil
    var onArchiveCreated: (DivinationRecord) -> Void = { _ in }
    let onDismiss: (FollowUpSession?) -> Void
    let onViewFullInterpretation: () -> Void

    @State private var messages: [FollowUpChatMessage] = []
    @State private var session: FollowUpSession?
    @State private var attachedRecord: DivinationRecord?
    @State private var inputText = ""
    @State private var suggestionBatchIndex = -1
    @State private var usedSuggestions: Set<String> = []
    @State private var isReplying = false
    @State private var showClearAlert = false
    @State private var didPrepare = false
    @State private var toastText: String?
    @State private var composerMode: ComposerMode = .text
    @StateObject private var voice = VoiceInputModel()
    @StateObject private var dataService = DataService()
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var showProUpgrade = false
    @State private var followUpBlocked = false
    @State private var didWarnHistoryLimit = false
    @State private var followUpIsPaidCap = false
    @FocusState private var isInputFocused: Bool

    private var readingID: String {
        PermissionManager.readingID(
            question: hexagramContext.question,
            castTime: hexagramContext.castTime,
            hexagramName: hexagramContext.hexagramName
        )
    }

    private let fallbackBatches: [[String]] = [
        ["为什么会得出这个判断？", "现在最该先做哪一步？", "接下来趋势会怎么走？"],
        ["这个判断的卦理依据是什么？", "什么信号说明可以行动？", "如果按兵不动会怎样？"],
        ["还有哪一爻最值得看？", "眼下最该避开什么？", "怎样判断时机已经到了？"]
    ]

    private var showsSuggestionSection: Bool {
        if case .fromQuestion = entryMode { return false }
        return true
    }

    private var currentSuggestions: [String] {
        if suggestionBatchIndex < 0 {
            let primary = hexagramContext.followUpSuggestions.filter {
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if !primary.isEmpty { return Array(primary.prefix(3)) }
        }
        let index = max(suggestionBatchIndex, 0)
        return fallbackBatches[index % fallbackBatches.count]
    }

    private enum ComposerMode {
        case text
        case voice
    }

    private var welcomeText: String {
        "我已研读本次「\(hexagramContext.hexagramName)」之象。无论是卦理依据、时机把握，还是具体应对策略——有任何疑问，请直接问我。"
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

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            contextCard
                            if showsSuggestionSection {
                                suggestionSection
                            }
                            messageList
                            if isReplying {
                                typingIndicator
                            }
                            Color.clear.frame(height: 8).id("chat-bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: messages.count) { _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: isReplying) { _ in
                        scrollToBottom(proxy)
                    }
                }

                if let toastText {
                    Text(toastText)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.72)))
                        .padding(.bottom, 6)
                }

                inputBar
            }
        }
        .onAppear(perform: prepareIfNeeded)
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
        .onChange(of: voice.hint) { text in
            guard let text else { return }
            showToast(text)
            voice.hint = nil
        }
        .alert("清空对话", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                messages.removeAll()
                if let session {
                    dataService.saveFollowUpMessages([], to: session)
                }
                refreshFollowUpGate()
            }
        } message: {
            Text("将清除本次追问中的全部对话，卦象信息仍会保留。")
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(alignment: .center) {
            Button(action: { onDismiss(session) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ResultTheme.primary)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            VStack(spacing: 3) {
                Text("追问解惑")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ResultTheme.primary)
                Text("基于本次卦象 · 专业为您解答")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("清空对话") {
                showClearAlert = true
            }
            .font(.subheadline)
            .foregroundColor(ResultTheme.primary)
            .frame(minWidth: 32, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    // MARK: - Context card
    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                MiniHexagramView(lines: hexagramContext.yaoLines)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(hexagramContext.hexagramName)
                        .font(.headline)
                        .foregroundColor(ResultTheme.primary)
                    Text(hexagramContext.question)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("卦象概述")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(displayedConclusion)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button(action: onViewFullInterpretation) {
                    HStack(spacing: 2) {
                        Text("查看完整解读")
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ResultTheme.softStrong)
        )
    }

    private var displayedConclusion: String {
        let text = hexagramContext.oneSentenceConclusion.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "暂无解读" }
        return InterpretationTrailer.readableOverview(text)
    }

    // MARK: - Suggestions
    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    Text("你可能还想问")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                Spacer()
                Button(action: refreshSuggestions) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("换一批")
                    }
                    .font(.caption)
                    .foregroundColor(ResultTheme.primary)
                }
                .buttonStyle(.plain)
                .disabled(isReplying)
            }

            FollowUpChipFlow(spacing: 8) {
                ForEach(currentSuggestions, id: \.self) { item in
                    Button {
                        sendFromChip(item)
                    } label: {
                        HStack(spacing: 4) {
                            Text(item)
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(ResultTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(ResultTheme.primary.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isReplying || voice.isRecording)
                }
            }
        }
    }

    // MARK: - Messages
    private var messageList: some View {
        VStack(spacing: 14) {
            ForEach(messages) { message in
                if message.role == .user {
                    userBubble(message)
                } else {
                    coachBubble(message)
                }
            }
            if followUpBlocked {
                if followUpIsPaidCap {
                    Text("本卦追问已达上限（66次）。如需继续探索，建议重新起卦")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                } else {
                    FollowUpUpgradeBanner {
                        showProUpgrade = true
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private func userBubble(_ message: FollowUpChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Spacer(minLength: 48)
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(ResultTheme.primary)
                    )
                Text(formatTime(message.time))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Circle()
                .fill(Color(red: 0.62, green: 0.70, blue: 0.90))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                )
        }
    }

    private func coachBubble(_ message: FollowUpChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            FollowUpAvatarView()
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                FollowUpRichText(text: message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
                Text(formatTime(message.time))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 36)
        }
    }

    private var typingIndicator: some View {
        HStack(alignment: .top, spacing: 8) {
            FollowUpAvatarView()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            Text("教练正在回复...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemBackground))
                )
            Spacer()
        }
    }

    // MARK: - Input
    private var inputBar: some View {
        HStack(spacing: 10) {
            if !voice.isRecording {
                Button(action: toggleComposerMode) {
                    Image(systemName: composerMode == .text ? "mic.fill" : "keyboard")
                        .font(.title3)
                        .foregroundColor(isReplying ? Color.secondary.opacity(0.4) : ResultTheme.primary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .disabled(isReplying)
                .accessibilityLabel(composerMode == .text ? "切换到语音" : "切换到键盘")
            }

            if composerMode == .voice {
                holdToTalkBar
            } else {
                HStack {
                    TextField("继续追问本次解卦...", text: $inputText, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                Button(action: sendCurrentInput) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(
                                canSend ? ResultTheme.fill : LinearGradient(
                                    colors: [Color.gray.opacity(0.45), Color.gray.opacity(0.45)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }

    private var holdToTalkBar: some View {
        HStack(spacing: 8) {
            if voice.isRecording {
                Circle()
                    .fill(voice.willCancel ? Color.red : ResultTheme.primary)
                    .frame(width: 8, height: 8)
                Text(voice.willCancel ? "松开取消" : "松手发送")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(voice.willCancel ? .red : .primary)
                recordingMeter
                Spacer(minLength: 4)
                Text("上滑取消")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("按住 说话")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(
            Capsule(style: .continuous)
                .fill(voice.willCancel ? Color.red.opacity(0.12) : Color(.secondarySystemBackground))
        )
        .contentShape(Capsule())
        .gesture(voicePress)
        .accessibilityLabel("按住说话")
    }

    private func toggleComposerMode() {
        composerMode = composerMode == .text ? .voice : .text
        if composerMode == .text {
            isInputFocused = true
        } else {
            isInputFocused = false
        }
    }

    private var voicePress: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isReplying else { return }
                voice.notePressChanged(translationY: value.translation.height)
            }
            .onEnded { value in
                guard !isReplying else { return }
                let outcome = voice.notePressEnded(translationY: value.translation.height)
                switch outcome {
                case .hint(let text):
                    showToast(text)
                case .ignored:
                    break
                case .finish(let cancel):
                    Task {
                        let text = await voice.finish(cancel: cancel)
                        if cancel {
                            showToast("已取消")
                        } else if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showToast("没有识别到内容，请再试一次")
                        } else {
                            send(text)
                        }
                    }
                }
            }
    }

    private var recordingMeter: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: !voice.isRecording)) { timeline in
            let tick = Int(timeline.date.timeIntervalSinceReferenceDate * 8)
            HStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(ResultTheme.primary.opacity((tick + index).isMultiple(of: 3) ? 0.95 : 0.28))
                        .frame(width: 4, height: 14)
                }
            }
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isReplying && !voice.isRecording
    }

    // MARK: - Actions
    private func prepareIfNeeded() {
        guard !didPrepare else { return }
        didPrepare = true
        if let existingSession {
            session = existingSession
            let stored = existingSession.messages
            if !stored.isEmpty {
                messages = stored
            }
        }
        if messages.isEmpty, case .fromIcon = entryMode {
            messages = [FollowUpChatMessage(role: .coach, text: welcomeText, time: Date())]
        } else if let first = messages.first, first.role == .coach, first.text.hasPrefix("我已研读本次"), first.text != welcomeText {
            messages[0] = FollowUpChatMessage(role: .coach, text: welcomeText, time: first.time)
            if session != nil {
                persistMessages()
            }
        }
        refreshFollowUpGate()
        if case .fromQuestion(let preset) = entryMode {
            let text = preset.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            send(text)
        }
    }

    private func sendCurrentInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        send(text)
    }

    private func sendFromChip(_ text: String) {
        usedSuggestions.insert(text)
        if currentSuggestions.allSatisfy({ usedSuggestions.contains($0) }) {
            refreshSuggestions()
        }
        send(text)
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isReplying else { return }
        refreshFollowUpGate()
        guard permissionManager.canSendFollowUp(readingID: readingID) else {
            followUpBlocked = true
            return
        }
        isInputFocused = false
        let history = messages
        messages.append(FollowUpChatMessage(role: .user, text: trimmed, time: Date()))
        isReplying = true
        Task {
            do {
                let reply = try await AIService.shared.sendFollowUpMessage(
                    context: hexagramContext,
                    history: history,
                    userMessage: trimmed
                )
                messages.append(FollowUpChatMessage(role: .coach, text: reply, time: Date()))
                permissionManager.incrementFollowUp(readingID: readingID)
                refreshFollowUpGate()
                persistMessages()
            } catch {
                if let last = messages.last, last.role == .user, last.text == trimmed {
                    messages.removeLast()
                }
                inputText = trimmed
                showToast("网络有点慢，稍后再试～")
            }
            isReplying = false
        }
    }

    private func refreshFollowUpGate() {
        let turns = messages.filter { $0.role == .user }.count
        permissionManager.adoptFollowUpCount(readingID: readingID, observedTurns: turns)
        followUpIsPaidCap = permissionManager.followUpLimit(for: readingID) > SubscriptionConfig.freeFollowUpLimit
        followUpBlocked = !permissionManager.canSendFollowUp(readingID: readingID) && turns > 0
    }

    private var activeRecord: DivinationRecord? {
        attachedRecord ?? linkedRecord
    }

    private func persistMessages() {
        guard messages.contains(where: { $0.role == .user }) else { return }
        if activeRecord == nil, !permissionManager.canSaveMoreRecords() {
            if !didWarnHistoryLimit {
                didWarnHistoryLimit = true
                showToast("免费版最多保存 3 条历史，这次追问还没写入。")
            }
            return
        }
        let hadRecord = activeRecord != nil
        guard let record = dataService.ensureDivinationArchive(existing: activeRecord, draft: archiveDraft) else {
            if !hadRecord {
                showToast("这次没有写入历史记录，请再试一次。")
            }
            return
        }
        if !hadRecord {
            attachedRecord = record
            onArchiveCreated(record)
        }
        if session == nil {
            session = dataService.createFollowUpSession(for: record)
        } else if let session, session.divinationRecord == nil {
            dataService.attach(session, to: record)
        }
        guard let session else { return }
        dataService.saveFollowUpMessages(messages, to: session)
    }

    private func refreshSuggestions() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if suggestionBatchIndex < 0 {
                suggestionBatchIndex = 0
            } else {
                suggestionBatchIndex += 1
            }
            usedSuggestions.removeAll()
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toastText == text {
                toastText = nil
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("chat-bottom", anchor: .bottom)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct FollowUpUpgradeBanner: View {
    var onUpgrade: () -> Void

    var body: some View {
        Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: 6) {
                Text("✨ 本次卦象还有更多维度可以深聊")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.45, green: 0.28, blue: 0.05))
                Text("开通会员，每卦 66次专业追问 →")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.62, green: 0.40, blue: 0.08))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.97, blue: 0.88),
                                Color(red: 1.0, green: 0.93, blue: 0.78)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.93, green: 0.72, blue: 0.28),
                                Color(red: 0.85, green: 0.55, blue: 0.15)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 语音输入
@MainActor
final class VoiceInputModel: ObservableObject {
    enum PressOutcome {
        case ignored
        case hint(String)
        case finish(cancel: Bool)
    }

    @Published var isRecording = false
    @Published var willCancel = false
    @Published var hint: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var latestText = ""
    private var fingerDown = false
    private var armTask: Task<Void, Never>?
    private var didArm = false
    private var tapInstalled = false

    func notePressChanged(translationY: CGFloat) {
        if !fingerDown {
            fingerDown = true
            didArm = false
            armTask?.cancel()
            armTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 280_000_000)
                guard !Task.isCancelled else { return }
                await self?.beginRecording()
            }
        }
        if isRecording {
            willCancel = translationY < -36
        }
    }

    func notePressEnded(translationY: CGFloat) -> PressOutcome {
        armTask?.cancel()
        armTask = nil
        let wasDown = fingerDown
        fingerDown = false
        guard wasDown else { return .ignored }
        if isRecording || didArm {
            return .finish(cancel: translationY < -36)
        }
        if hint != nil { return .ignored }
        return .hint("长按说话")
    }

    func finish(cancel: Bool) async -> String {
        let text = await stopEngine()
        isRecording = false
        willCancel = false
        didArm = false
        return cancel ? "" : text
    }

    private func beginRecording() async {
        guard fingerDown, !isRecording else { return }
        guard let recognizer, recognizer.isAvailable else {
            hint = "当前设备不支持中文语音识别"
            return
        }
        let allowed = await requestPermissions()
        guard fingerDown else { return }
        guard allowed else {
            hint = "请在系统设置中允许麦克风和语音识别"
            return
        }

        do {
            latestText = ""
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.request = request

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                hint = "暂时无法使用麦克风"
                return
            }
            if tapInstalled {
                input.removeTap(onBus: 0)
                tapInstalled = false
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
                request?.append(buffer)
            }
            tapInstalled = true
            engine.prepare()
            try engine.start()
            task = recognizer.recognitionTask(with: request) { [weak self] result, _ in
                guard let result else { return }
                let text = result.bestTranscription.formattedString
                Task { @MainActor in
                    self?.latestText = text
                }
            }
            didArm = true
            isRecording = true
            if !fingerDown {
                _ = await stopEngine()
                isRecording = false
                didArm = false
            }
        } catch {
            hint = "暂时无法使用麦克风"
            _ = await stopEngine()
        }
    }

    private func requestPermissions() async -> Bool {
        let speechOK = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechOK else { return false }
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        }
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func stopEngine() async -> String {
        if engine.isRunning {
            engine.stop()
        }
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        request?.endAudio()
        try? await Task.sleep(nanoseconds: 350_000_000)
        let text = latestText
        task?.cancel()
        task = nil
        request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return text
    }
}

// MARK: - 建议问题自动换行
private struct FollowUpChipFlow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

private struct FollowUpRichText: View {
    let text: String

    var body: some View {
        Text(attributed)
            .font(.subheadline)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributed: AttributedString {
        let source = text as NSString
        let fullRange = NSRange(location: 0, length: source.length)
        guard let regex = try? NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*") else {
            return plain(text)
        }
        let matches = regex.matches(in: text, range: fullRange)
        if matches.isEmpty { return plain(text) }

        var result = AttributedString()
        var cursor = 0
        for match in matches {
            if match.range.location > cursor {
                let chunk = source.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
                result += plain(chunk)
            }
            let highlighted = source.substring(with: match.range(at: 1))
            result += emphasis(highlighted)
            cursor = match.range.location + match.range.length
        }
        if cursor < source.length {
            result += plain(source.substring(from: cursor))
        }
        return result
    }

    private func plain(_ value: String) -> AttributedString {
        var text = AttributedString(value)
        text.foregroundColor = .primary
        return text
    }

    private func emphasis(_ value: String) -> AttributedString {
        var text = AttributedString(value)
        text.font = .subheadline.weight(.semibold)
        text.foregroundColor = ResultTheme.primary
        return text
    }
}

#Preview {
    FollowUpChatView(
        entryMode: .fromIcon,
        hexagramContext: HexagramContext(
            question: "这段关系该如何处理？",
            hexagramName: "天地否",
            hexagramDescription: "天地否，阴阳不交。",
            oneSentenceConclusion: "当前不宜主动推进，宜静待时机",
            castTime: Date(),
            location: "杭州",
            interpretationSummary: "当前不宜主动推进，宜静待时机。",
            liuYaoChart: nil,
            yaoLines: [.youngYang, .youngYang, .youngYang, .youngYin, .youngYin, .youngYin],
            followUpSuggestions: ["为什么说现在不宜主动？", "什么时候可以行动？", "后续会有变化吗？"]
        ),
        onDismiss: { _ in },
        onViewFullInterpretation: {}
    )
}
