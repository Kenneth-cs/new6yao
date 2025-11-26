//
//  GrowthProfileView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  成长档案 - Tab 4
//

import SwiftUI
import CoreData

struct GrowthProfileView: View {
    @ObservedObject private var statisticsService = StatisticsService.shared
    @State private var records: [DivinationRecord] = []
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部卡片
                headerCard
                
                // 统计卡片
                statisticsSection
                
                // 最近决策记录
                recentDecisionsSection
                
                // 成长见解（占位）
                insightsPlaceholder
            }
            .padding()
        }
        .navigationTitle("成长档案")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            fetchRecords()
            statisticsService.loadStatistics(context: viewContext)
        }
    }
    
    // 获取记录
    private func fetchRecords() {
        let request: NSFetchRequest<DivinationRecord> = DivinationRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DivinationRecord.createdAt, ascending: false)]
        
        do {
            records = try viewContext.fetch(request)
        } catch {
            print("获取记录失败: \(error)")
            records = []
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("成长轨迹")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("记录每一次决策和思考")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.2), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据统计")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "总决策数",
                    value: "\(statisticsService.totalDivinations)",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "本月决策",
                    value: "\(statisticsService.monthlyDivinations)",
                    icon: "calendar.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "准确反馈",
                    value: "\(statisticsService.accuracyFeedbacks)",
                    icon: "checkmark.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "连续天数",
                    value: "\(statisticsService.consecutiveDays)",
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
    }
    
    private var recentDecisionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近决策")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: HistoryPageView()) {
                    Text("查看全部")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if records.isEmpty {
                EmptyStateView()
            } else {
                ForEach(records.prefix(3), id: \.objectID) { record in
                    DecisionRecordCardSimple(record: record)
                }
            }
        }
    }
    
    private var insightsPlaceholder: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("成长见解")
                    .font(.headline)
            }
            
            Text("🚧 即将上线\n\n基于你的决策历史，AI将提供个性化的成长建议和思维模式分析")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

// MARK: - StatCard Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - DecisionRecordCardSimple Component

struct DecisionRecordCardSimple: View {
    let record: DivinationRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.question ?? "无标题")
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
            }
            
            HStack {
                Text("决策记录")
                    .font(.subheadline)
                    .foregroundColor(.purple)
                
                Spacer()
                
                if let date = record.createdAt {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - EmptyStateView Component

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("还没有决策记录")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("开始你的第一次决策分析吧")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        GrowthProfileView()
    }
}
