import SwiftUI
import CoreData

struct HistoryPageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var dataService = DataService()
    @State private var divinationRecords: [DivinationRecord] = []
    @State private var matrixRecords: [MatrixDecisionRecord] = []
    @State private var isLoading = true
    @State private var selectedTab = 0   // 0=全部 1=六爻 2=五行决策

    @ObservedObject private var pm = PermissionManager.shared

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.06), Color.indigo.opacity(0.04), Color.white]),
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── 分类 Picker ─────────────────────────────────
                Picker("", selection: $selectedTab) {
                    Text("全部").tag(0)
                    Text("六爻预测").tag(1)
                    Text("五行决策").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if isLoading {
                    Spacer()
                    ProgressView().scaleEffect(1.2).tint(.purple)
                    Text("加载中...").font(.body).foregroundColor(.secondary).padding(.top, 12)
                    Spacer()
                } else {
                    contentForTab
                }
            }
        }
        .navigationTitle("历史记录")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: clearCurrentTab) {
                        Label(selectedTab == 2 ? "清空五行决策记录" : "清空六爻记录",
                              systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundColor(.purple)
                }
                .disabled(currentTabEmpty)
            }
        }
        .onAppear { loadAll() }
    }

    // ── 当前 Tab 内容 ────────────────────────────────────────
    @ViewBuilder
    private var contentForTab: some View {
        let showDivination = selectedTab == 0 || selectedTab == 1
        let showMatrix     = selectedTab == 0 || selectedTab == 2
        let divEmpty       = divinationRecords.isEmpty
        let matEmpty       = matrixRecords.isEmpty

        if (showDivination && !divEmpty) || (showMatrix && !matEmpty) {
            ScrollView {
                LazyVStack(spacing: 14) {
                    // 免费用户保留数限制提示
                    if !pm.currentTier.isPro {
                        freeUserBanner
                    }
                    if showMatrix {
                        ForEach(matrixRecords) { record in
                            MatrixHistoryCardView(record: record) {
                                MatrixHistoryStore.shared.delete(id: record.id)
                                loadAll()
                            }
                        }
                    }
                    if showDivination {
                        ForEach(divinationRecords, id: \.objectID) { record in
                            NavigationLink(destination: HistoryDetailView(record: record)) {
                                HistoryRecordCardView(record: record)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        } else {
            emptyView
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 56)).foregroundColor(.gray.opacity(0.5))
            Text("暂无记录").font(.title3).fontWeight(.medium).foregroundColor(.secondary)
            Text(selectedTab == 2 ? "完成一次五行决策后将在此显示" : "开始第一次分析吧")
                .font(.body).foregroundColor(.secondary)
            Spacer()
        }
    }

    private var freeUserBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("免费版最多保留 3 条历史记录")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.orange)
                Text("升级专业版可无限保存")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private var currentTabEmpty: Bool {
        switch selectedTab {
        case 1: return divinationRecords.isEmpty
        case 2: return matrixRecords.isEmpty
        default: return divinationRecords.isEmpty && matrixRecords.isEmpty
        }
    }

    // ── 数据操作 ─────────────────────────────────────────────
    private func loadAll() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            divinationRecords = dataService.fetchAllRecords()
            matrixRecords     = MatrixHistoryStore.shared.loadAll()
            isLoading         = false
        }
    }

    private func clearCurrentTab() {
        if selectedTab == 2 {
            matrixRecords.forEach { MatrixHistoryStore.shared.delete(id: $0.id) }
            matrixRecords.removeAll()
        } else {
            divinationRecords.forEach { dataService.deleteRecord($0) }
            divinationRecords.removeAll()
        }
    }
}

// MARK: - 五行决策历史卡片
struct MatrixHistoryCardView: View {
    let record: MatrixDecisionRecord
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: record.scenarioIcon)
                    .font(.body).foregroundColor(.indigo)
                    .frame(width: 36, height: 36)
                    .background(Color.indigo.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(record.scenario).font(.caption).foregroundColor(.secondary)
                    Text(record.options.joined(separator: "  vs  "))
                        .font(.headline).fontWeight(.semibold)
                        .foregroundColor(.primary).lineLimit(1)
                }
                Spacer()
                // 分数+吉凶
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(record.score)分")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(record.verdictColor)
                    Text(record.verdictLabel)
                        .font(.caption2).foregroundColor(record.verdictColor)
                }
            }

            if !record.verdict.isEmpty {
                Text(record.verdict)
                    .font(.subheadline).foregroundColor(.secondary).lineLimit(2)
            }

            HStack {
                Text("推荐：\(record.recommendedName)")
                    .font(.caption).fontWeight(.medium)
                    .foregroundColor(.indigo)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.indigo.opacity(0.08))
                    .cornerRadius(6)
                Spacer()
                Text(record.date, style: .date)
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.indigo.opacity(0.08), radius: 8, x: 0, y: 3)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// MARK: - 历史记录卡片视图
struct HistoryRecordCardView: View {
    let record: DivinationRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 问题
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text(record.question ?? "未知问题")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Spacer()
            }
            
            // 卦象
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("卦象: \(record.hexagramDisplay)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(record.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // AI解读预览（清理markdown符号）
            if let interpretation = record.aiInterpretation, !interpretation.isEmpty {
                Text(cleanMarkdownSymbols(interpretation))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .purple.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    /// 清理Markdown符号，用于预览显示
    private func cleanMarkdownSymbols(_ text: String) -> String {
        var result = text
        
        // 移除标题符号 ### ## #
        result = result.replacingOccurrences(of: "###", with: "")
        result = result.replacingOccurrences(of: "##", with: "")
        result = result.replacingOccurrences(of: "#", with: "")
        
        // 移除加粗符号 **
        result = result.replacingOccurrences(of: "**", with: "")
        
        // 移除斜体符号 *（但保留单独的星号）
        // 这里用正则更精确，但简单处理也可以
        
        // 移除列表符号 - 开头的（保留连字符在文字中间的情况）
        let lines = result.components(separatedBy: "\n")
        result = lines.map { line in
            var trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("- ") {
                trimmedLine = String(trimmedLine.dropFirst(2))
            }
            return trimmedLine
        }.joined(separator: " ")
        
        // 移除【】中的标记词（如【框架解析】【总结】等）
        if let regex = try? NSRegularExpression(pattern: "【[^】]*】", options: []) {
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }
        
        // 清理多余空格
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        
        // 去除首尾空格
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return result
    }
}

#Preview {
    NavigationStack {
        HistoryPageView()
    }
}