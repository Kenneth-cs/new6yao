import SwiftUI
import CoreData

struct HistoryPageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var dataService = DataService()
    @State private var records: [DivinationRecord] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.08),
                    Color.indigo.opacity(0.05),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if isLoading {
                // 加载动画
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.purple)
                    
                    Text("加载历史记录...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else if records.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("暂无分析记录")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("开始您的第一次决策分析吧")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else {
                // 记录列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(records, id: \.objectID) { record in
                            NavigationLink(destination: HistoryDetailView(record: record)) {
                                HistoryRecordCardView(record: record)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("分析历史")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("清空") {
                    clearAllRecords()
                }
                .foregroundColor(.red)
                .disabled(records.isEmpty)
            }
        }
        .onAppear {
            loadRecords()
        }
    }
    
    private func loadRecords() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            records = dataService.fetchAllRecords()
            isLoading = false
        }
    }
    
    private func clearAllRecords() {
        records.forEach { dataService.deleteRecord($0) }
        records.removeAll()
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