import SwiftUI

struct DivinationArchiveView: View {
    @ObservedObject var record: DivinationRecord

    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataService = DataService()
    @State private var followUpSession: FollowUpSession?
    @State private var showDeleteConfirm = false

    private var hexagram: (name: String, description: String) { record.resolvedHexagram }
    private var chart: LiuYaoReading? { record.resolvedChart }
    private var castTime: Date { record.resolvedCastTime }

    private var coreConclusion: String {
        if let stored = record.oneSentenceConclusion?.trimmingCharacters(in: .whitespacesAndNewlines),
           !stored.isEmpty {
            return InterpretationTrailer.readableOverview(stored)
        }
        let split = InterpretationTrailer.split(record.aiInterpretation ?? "")
        if !split.conclusion.isEmpty { return InterpretationTrailer.readableOverview(split.conclusion) }
        let body = split.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.isEmpty { return "暂无解读" }
        return InterpretationTrailer.readableOverview(String(body.prefix(80)))
    }

    private var sourceLabel: String {
        switch InterpretationMode(rawValue: record.interpretationMode ?? "") {
        case .master: return "大师解读"
        case .professional, nil: return "专业解读"
        }
    }

    private var followUpTurns: Int {
        Int(followUpSession?.totalTurns ?? 0)
    }

    private var headerSymbol: String {
        switch record.engineCategory ?? "" {
        case "事业", "考试": return "briefcase.fill"
        case "姻缘": return "heart.fill"
        case "财运": return "yensign.circle.fill"
        case "搬迁": return "house.fill"
        case "出行": return "airplane"
        case "健康": return "cross.case.fill"
        default: return "sparkles"
        }
    }

    private var headerSubtitle: String {
        switch record.engineCategory ?? "" {
        case "事业": return "探索更适合自己的职业方向，把握下一步机会"
        case "姻缘": return "看清关系里的节奏与分寸，把握下一步相处"
        case "财运": return "理清眼前的得失与节奏，把握下一步安排"
        case "考试": return "看清准备的重点与时机，把握下一步行动"
        case "搬迁": return "看清去留的条件与时机，把握下一步选择"
        case "合作": return "看清合作的条件与边界，把握下一步决定"
        case "健康": return "看清当前状态的提醒，把握下一步调养"
        default: return "围绕这次所问梳理判断，把握下一步行动"
        }
    }

    private var shareText: String {
        """
        历史记录
        问题：\(record.question ?? "")
        卦名：\(hexagram.name)
        卦象概述：\(coreConclusion)
        """
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ResultTheme.soft, ResultTheme.soft.opacity(0.35), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    infoCard
                    entryCard(
                        icon: "doc.plaintext.fill",
                        iconColor: ResultTheme.primary,
                        title: "解卦结果",
                        subtitle: "已完成 · 深度解读完整报告",
                        action: "查看报告",
                        destination: HistoryDetailView(record: record)
                    )
                    entryCard(
                        icon: "chart.bar.fill",
                        iconColor: ResultTheme.primary,
                        title: "局势推演",
                        subtitle: record.deductionReport == nil
                            ? "尚未推演"
                            : "已推演 \(record.deductionReport?.paths.count ?? 3) 条路径",
                        action: record.deductionReport == nil ? "去推演" : "查看结果",
                        destination: ArchiveDeductionDestination(record: record)
                    )
                    entryCard(
                        icon: "ellipsis.bubble.fill",
                        iconColor: ResultTheme.primary,
                        title: "追问记录",
                        subtitle: followUpTurns > 0 ? "已追问 \(followUpTurns) 次" : "尚未追问",
                        action: "继续追问",
                        destination: ArchiveFollowUpDestination(
                            record: record,
                            session: followUpSession,
                            conclusion: coreConclusion,
                            suggestions: suggestions
                        )
                    )
                    timeline
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(ResultTheme.primary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("历史记录")
                    .font(.headline)
                    .foregroundColor(ResultTheme.primary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: shareText) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ResultTheme.primary)
                }
            }
        }
        .confirmationDialog("删除这条历史记录？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                dataService.deleteRecord(record)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        }
        .onAppear {
            followUpSession = dataService.fetchFollowUpSession(for: record)
        }
    }

    private var suggestions: [String] {
        if !record.followUpSuggestions.isEmpty {
            return InterpretationTrailer.padded(record.followUpSuggestions)
        }
        let split = InterpretationTrailer.split(record.aiInterpretation ?? "")
        if split.foundSuggestions { return split.suggestions }
        return InterpretationTrailer.defaultSuggestions
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: headerSymbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ResultTheme.primary)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ResultTheme.softStrong)
                )
            VStack(alignment: .leading, spacing: 6) {
                Text(record.question ?? "未记录问题")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
    }

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 14) {
                infoRow(label: "卦名") {
                    Text(hexagram.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ResultTheme.primary)
                }
                infoRow(label: "起卦时间") {
                    Text(castTimeText(castTime))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                infoRow(label: "解读来源") {
                    Text(sourceLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(ResultTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(ResultTheme.softStrong))
                }
                infoRow(label: "卦象概述") {
                    Text(coreConclusion)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            MiniHexagramView(lines: record.yaoLines.isEmpty ? chartLines : record.yaoLines)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 3)
        )
    }

    private var chartLines: [YaoXiang] {
        guard let chart else { return [] }
        return chart.primary.lines.map { line in
            let yang = line.yinYang == "yang"
            if line.moving != nil {
                return yang ? .oldYang : .oldYin
            }
            return yang ? .youngYang : .youngYin
        }
    }

    private func infoRow<Content: View>(label: String, @ViewBuilder value: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 68, alignment: .leading)
            value()
            Spacer(minLength: 0)
        }
    }

    private func entryCard<Destination: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: String,
        destination: Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(iconColor.opacity(0.12))
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 8)
                HStack(spacing: 2) {
                    Text(action)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .font(.caption)
                .foregroundColor(ResultTheme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Capsule().fill(ResultTheme.softStrong))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(ResultTheme.primary)
                    .frame(width: 4, height: 16)
                Text("档案动态")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.top, 6)

            let events = timelineEvents
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                    timelineRow(event, isLast: index == events.count - 1)
                }
            }
        }
    }

    private struct TimelineEvent {
        let date: Date
        let title: String
        let detail: String
    }

    private var timelineEvents: [TimelineEvent] {
        var events: [TimelineEvent] = [
            TimelineEvent(date: castTime, title: "起卦完成", detail: "生成本卦：\(hexagram.name)")
        ]
        let interpretedAt = record.createdAt ?? castTime
        let modeName = sourceLabel.replacingOccurrences(of: "解读", with: "")
        events.append(
            TimelineEvent(
                date: interpretedAt,
                title: "完成\(modeName)解读",
                detail: "获得深度解读与核心建议"
            )
        )
        events.append(
            TimelineEvent(
                date: interpretedAt.addingTimeInterval(38 * 60),
                title: "完成局势推演",
                detail: "推演了 3 条可能路径"
            )
        )
        if followUpTurns > 0, let updated = followUpSession?.updatedAt {
            let question = (record.question ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let prefix = question.isEmpty ? "本次问题" : String(question.prefix(8))
            events.append(
                TimelineEvent(
                    date: updated,
                    title: "继续追问 \(followUpTurns) 次",
                    detail: "围绕\(prefix)深入探讨"
                )
            )
        }
        return events.sorted { $0.date > $1.date }
    }

    private func timelineRow(_ event: TimelineEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(ResultTheme.primary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
                if !isLast {
                    Rectangle()
                        .fill(ResultTheme.primary.opacity(0.28))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(timelineText(event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(event.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }

    private func castTimeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }

    private func timelineText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

private struct ArchiveDeductionDestination: View {
    let record: DivinationRecord
    @Environment(\.dismiss) private var dismiss
    @State private var showPrep: Bool

    init(record: DivinationRecord) {
        self.record = record
        _showPrep = State(initialValue: record.deductionReport == nil)
    }

    var body: some View {
        Group {
            if showPrep || record.deductionReport == nil {
                DeductionPrepView(
                    originalQuestion: record.question ?? "",
                    hexagramName: record.resolvedHexagram.name,
                    liuYaoChart: record.resolvedChart,
                    castTime: record.resolvedCastTime,
                    aiInterpretation: record.aiInterpretation ?? "",
                    sourceRecord: record,
                    onDismiss: { dismiss() },
                    onViewOriginal: { dismiss() }
                )
            } else if let report = record.deductionReport {
                DeductionResultView(
                    report: report,
                    hexagramName: record.resolvedHexagram.name,
                    displayQuestion: record.question ?? "",
                    sourceRecord: record,
                    onDismiss: { dismiss() },
                    onEditBackground: { showPrep = true }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ArchiveFollowUpDestination: View {
    let record: DivinationRecord
    let session: FollowUpSession?
    let conclusion: String
    let suggestions: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FollowUpChatView(
            entryMode: .fromIcon,
            hexagramContext: HexagramContext(
                question: record.question ?? "",
                hexagramName: record.resolvedHexagram.name,
                hexagramDescription: record.resolvedHexagram.description,
                oneSentenceConclusion: conclusion,
                castTime: record.resolvedCastTime,
                location: record.locationName ?? "未记录",
                interpretationSummary: archiveSummary,
                liuYaoChart: record.resolvedChart,
                yaoLines: record.yaoLines,
                followUpSuggestions: suggestions
            ),
            existingSession: session,
            linkedRecord: record,
            onDismiss: { _ in dismiss() },
            onViewFullInterpretation: { dismiss() }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var archiveSummary: String {
        let advice = record.advice?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let parts = [conclusion, advice].filter { !$0.isEmpty && $0 != "暂无解读" }
        return String(parts.joined(separator: "\n").prefix(300))
    }
}
