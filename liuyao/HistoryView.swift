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
                                NavigationLink(destination: HistoryDetailView(record: record)) {
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

// MARK: - 历史记录详情
struct HistoryDetailView: View {
    let record: DivinationRecord
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 问题
                    VStack(alignment: .leading, spacing: 8) {
                        Text("您的问题")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(record.question ?? "未知问题")
                            .font(.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // 卦象
                    VStack(alignment: .leading, spacing: 16) {
                        Text("卦象")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .indigo]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            ForEach(Array(record.tossResults.enumerated().reversed()), id: \.offset) { index, result in
                                HStack {
                                    Text("第\(6-index)爻")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 40, alignment: .leading)
                                    
                                    if result {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.purple, .indigo]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: 60, height: 8)
                                    } else {
                                        HStack(spacing: 4) {
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.purple, .indigo]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: 28, height: 8)
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.purple, .indigo]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: 28, height: 8)
                                        }
                                    }
                                    
                                    Text(result ? "阳" : "阴")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(result ? .orange : .blue)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple.opacity(0.05), .indigo.opacity(0.03)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    
                    // AI解读
                    if let interpretation = record.aiInterpretation, !interpretation.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.purple)
                                    .font(.title3)
                                Text("卦象分析")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                Spacer()
                            }
                            
                            Text(interpretation)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple.opacity(0.08), .indigo.opacity(0.05)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    
                    // 建议指导
                    if let advice = record.advice, !advice.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                Text("建议指导")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            
                            Text(advice)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange.opacity(0.08), .yellow.opacity(0.05)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    
                    // 时间信息
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("问卦时间: \(record.formattedDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("问卦详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
