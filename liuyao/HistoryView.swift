import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var dataService = DataService()
    @State private var records: [DivinationRecord] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
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
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.purple.opacity(0.6))
                        
                        Text("暂无问卦记录")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("开始你的第一次问卦吧")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button("开始问卦") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .indigo]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                    }
                } else {
                    // 记录列表
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(records, id: \.id) { record in
                                NavigationLink(destination: DivinationArchiveView(record: record)) {
                                    HistoryRecordCardContent(record: record)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("问卦历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.purple)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清空") {
                        clearAllRecords()
                    }
                    .foregroundColor(.red)
                    .disabled(records.isEmpty)
                }
            }
        }
        .onAppear {
            loadRecords()
        }
    }
    
    private func loadRecords() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            records = dataService.fetchAllRecords()
            isLoading = false
        }
    }
    
    private func clearAllRecords() {
        records.forEach { dataService.deleteRecord($0) }
        records.removeAll()
    }
}

// MARK: - 历史记录卡片
struct HistoryRecordCardContent: View {
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

                if let badge = record.modeBadgeTitle {
                    InterpretationModeBadge(title: badge)
                }
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
            
            // AI解读预览
            if let interpretation = record.aiInterpretation, !interpretation.isEmpty {
                Text(interpretation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .purple.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 历史记录详情（复用最新结果页样式）
struct HistoryDetailView: View {
    let record: DivinationRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        DivinationResultPageView(
            question: record.question ?? "未知问题",
            tossResults: record.tossResults,
            yaoLines: record.yaoLines,
            hexagramData: record.resolvedHexagram,
            currentLocation: record.locationName ?? "未记录",
            onDismiss: { dismiss() },
            isHistoryRecord: true,
            savedInterpretation: record.aiInterpretation ?? "",
            savedAdvice: record.advice ?? "",
            castTime: record.resolvedCastTime,
            interpretationMode: InterpretationMode(rawValue: record.interpretationMode ?? "") ?? .professional,
            liuYaoChart: record.resolvedChart,
            categorySource: CategorySource(rawValue: record.categorySource ?? "") ?? .unclassified,
            sourceRecord: record
        )
    }
}

struct InterpretationModeBadge: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption2)
            .foregroundColor(.black)
            .padding(4)
            .background(Color.gray.opacity(0.18))
            .cornerRadius(4)
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
