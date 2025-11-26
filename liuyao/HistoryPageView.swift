import SwiftUI
import CoreData

struct HistoryPageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var dataService = DataService()
    @State private var records: [DivinationRecord] = []
    @State private var selectedRecord: DivinationRecord?
    @State private var showingDetail = false
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
                            HistoryRecordCard(record: record) {
                                selectedRecord = record
                                showingDetail = true
                            }
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
        .sheet(isPresented: $showingDetail) {
            if let record = selectedRecord {
                HistoryDetailView(record: record)
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

#Preview {
    NavigationStack {
        HistoryPageView()
    }
}