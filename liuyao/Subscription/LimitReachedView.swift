//
//  LimitReachedView.swift
//  人生教练
//
//  达到限制提示页
//

import SwiftUI

struct LimitReachedView: View {
    let limitType: LimitType
    let remaining: Int?
    let resetTime: Date?
    
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscriptionDetail = false
    @State private var selectedTier: SubscriptionTier = .proYearly  // 默认选择年付
    
    enum LimitType {
        case dailyDivination
        case monthlySWOT
        case monthlyMatrix
        case historyRecords
        
        var title: String {
            switch self {
            case .dailyDivination:
                return "今日分析次数已用完"
            case .monthlySWOT:
                return "本月SWOT分析次数已用完"
            case .monthlyMatrix:
                return "本月决策矩阵次数已用完"
            case .historyRecords:
                return "历史记录已达上限"
            }
        }
        
        var icon: String {
            switch self {
            case .dailyDivination:
                return "clock.badge.exclamationmark"
            case .monthlySWOT:
                return "square.grid.2x2"
            case .monthlyMatrix:
                return "tablecells"
            case .historyRecords:
                return "folder.badge.plus"
            }
        }
        
        var message: String {
            switch self {
            case .dailyDivination:
                return "免费版用户每天可以进行1次决策分析"
            case .monthlySWOT:
                return "免费版用户每月可以使用10次SWOT分析"
            case .monthlyMatrix:
                return "免费版用户每月可以使用10次决策矩阵"
            case .historyRecords:
                return "免费版用户最多保留3条历史记录"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部插图
                topIllustration
                
                // 内容区域
                ScrollView {
                    VStack(spacing: 24) {
                        // 标题和描述
                        titleSection
                        
                        // 重置时间提示
                        if let resetTime = resetTime {
                            resetTimeSection(resetTime: resetTime)
                        }
                        
                        // 升级专业版卖点
                        upgradeFeatures
                        
                        // 价格展示
                        pricingSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
                
                // 底部按钮
                bottomButtons
            }
            .navigationTitle("使用限制")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showSubscriptionDetail) {
            NavigationStack {
                SubscriptionDetailView(initialSelectedTier: selectedTier)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("关闭") {
                                showSubscriptionDetail = false
                                dismiss()
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - 顶部插图
    
    private var topIllustration: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            
            // 图标
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: limitType.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                }
                
                Text(limitType.title)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }
    
    // MARK: - 标题区域
    
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(limitType.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let remaining = remaining, remaining > 0 {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text("您还剩 \(remaining) 次可用")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 重置时间提示
    
    private func resetTimeSection(resetTime: Date) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.orange)
                
                Text("重置时间")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            Text(formattedResetTime(resetTime))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 升级特性
    
    private var upgradeFeatures: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("升级专业版，解锁完整功能")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                featureItem("无限次AI决策分析", icon: "sparkles", color: .purple)
                featureItem("无限使用思维工具", icon: "square.grid.2x2", color: .blue)
                featureItem("无限保存历史记录", icon: "clock.arrow.circlepath", color: .green)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 价格区域
    
    private var pricingSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // 月付
                Button(action: {
                    selectedTier = .proMonthly
                }) {
                    VStack(spacing: 4) {
                        Text("月付")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("¥9.9")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text("/月")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedTier == .proMonthly ? Color.purple.opacity(0.15) : Color.purple.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedTier == .proMonthly ? Color.purple : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 年付（推荐）
                Button(action: {
                    selectedTier = .proYearly
                }) {
                    VStack(spacing: 4) {
                        HStack {
                            Text("年付")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("推荐")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("¥99")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text("/年")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("相当于¥8.25/月")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedTier == .proYearly ? Color.orange.opacity(0.15) : Color.orange.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedTier == .proYearly ? Color.orange : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - 底部按钮
    
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // 主按钮 - 立即升级
            Button(action: {
                showSubscriptionDetail = true
            }) {
                Text("立即升级专业版")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            // 次要按钮 - 返回
            Button(action: {
                dismiss()
            }) {
                Text("暂不升级")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
    
    // MARK: - 辅助视图
    
    private func featureItem(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
    
    // MARK: - 辅助方法
    
    private func formattedResetTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        
        switch limitType {
        case .dailyDivination:
            return "明天凌晨重置"
        case .monthlySWOT, .monthlyMatrix:
            let calendar = Calendar.current
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()),
               let firstDayOfNextMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) {
                return "下月1号重置（\(formatter.string(from: firstDayOfNextMonth))）"
            }
            return "下月1号重置"
        case .historyRecords:
            return "删除旧记录可继续使用"
        }
    }
}

// MARK: - Preview
struct LimitReachedView_Previews: PreviewProvider {
    static var previews: some View {
        LimitReachedView(
            limitType: .dailyDivination,
            remaining: 0,
            resetTime: Date()
        )
    }
}

