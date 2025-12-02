//
//  SubscriptionManagementView.swift
//  人生教练
//
//  订阅管理页面
//

import SwiftUI
import StoreKit

struct SubscriptionManagementView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSubscriptionDetail = false
    @State private var showingManageSubscription = false
    
    var body: some View {
        List {
            // 当前订阅状态
            subscriptionStatusSection
            
            // 使用情况统计
            usageStatisticsSection
            
            // 订阅权益说明
            if !subscriptionService.isPro {
                upgradeSection
            }
            
            // 专业版特权说明
            benefitsSection
            
            // 管理订阅
            manageSection
        }
        .navigationTitle("订阅管理")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSubscriptionDetail) {
            NavigationStack {
                SubscriptionDetailView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("关闭") {
                                showSubscriptionDetail = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            Task {
                await subscriptionService.checkSubscriptionStatus()
            }
        }
    }
    
    // MARK: - 订阅状态区
    
    private var subscriptionStatusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // 订阅层级
                HStack {
                    Image(systemName: subscriptionService.isPro ? "crown.fill" : "person.fill")
                        .font(.title2)
                        .foregroundColor(subscriptionService.isPro ? .yellow : .gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subscriptionService.currentTierName)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        if let status = subscriptionService.subscriptionStatus {
                            Text(status.statusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("体验基础功能")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // 到期时间（仅专业版显示）
                if let status = subscriptionService.subscriptionStatus,
                   status.isActive,
                   let expirationDate = status.expirationDate {
                    Divider()
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.purple)
                        
                        Text("到期时间")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(status.formattedExpirationDate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Image(systemName: status.autoRenewing ? "arrow.clockwise.circle.fill" : "xmark.circle")
                            .foregroundColor(status.autoRenewing ? .green : .orange)
                        
                        Text("自动续费")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(status.autoRenewing ? "已开启" : "已关闭")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(status.autoRenewing ? .green : .orange)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("订阅状态")
        }
    }
    
    // MARK: - 使用情况统计
    
    private var usageStatisticsSection: some View {
        Section {
            // 问卦使用情况
            UsageRow(
                icon: "sparkles",
                title: "决策分析",
                used: permissionManager.usageStats.dailyDivinationCount,
                limit: permissionManager.usageQuota.dailyDivinationLimit,
                period: "今日",
                color: .purple
            )
            
            // SWOT使用情况
            UsageRow(
                icon: "square.grid.2x2",
                title: "SWOT分析",
                used: permissionManager.usageStats.monthlySWOTCount,
                limit: permissionManager.usageQuota.monthlySWOTLimit,
                period: "本月",
                color: .blue
            )
            
            // 决策矩阵使用情况
            UsageRow(
                icon: "tablecells",
                title: "决策矩阵",
                used: permissionManager.usageStats.monthlyMatrixCount,
                limit: permissionManager.usageQuota.monthlyMatrixLimit,
                period: "本月",
                color: .green
            )
            
            // 历史记录使用情况
            UsageRow(
                icon: "clock.arrow.circlepath",
                title: "历史记录",
                used: permissionManager.usageStats.totalHistoryRecords,
                limit: permissionManager.usageQuota.historyRecordsLimit,
                period: "已保存",
                color: .orange
            )
        } header: {
            Text("使用情况")
        } footer: {
            if !subscriptionService.isPro {
                Text("升级专业版后，所有功能无限制使用")
                    .font(.caption)
            }
        }
    }
    
    // MARK: - 升级区域（仅免费版显示）
    
    private var upgradeSection: some View {
        Section {
            Button(action: {
                showSubscriptionDetail = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("升级到专业版")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        Text("解锁所有功能，无限制使用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - 权益说明
    
    private var benefitsSection: some View {
        Section {
            ForEach(FeatureComparisonItem.allFeatures.filter { $0.isAvailableForPro }, id: \.name) { feature in
                HStack {
                    Image(systemName: feature.icon)
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.name)
                            .font(.subheadline)
                        
                        Text(feature.proDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if subscriptionService.isPro {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
        } header: {
            Text(subscriptionService.isPro ? "您的专业版权益" : "专业版权益")
        }
    }
    
    // MARK: - 管理订阅
    
    private var manageSection: some View {
        Section {
            // 在App Store中管理
            if subscriptionService.isPro {
                Button(action: {
                    openAppStoreManageSubscriptions()
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.purple)
                        
                        Text("在App Store中管理")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 恢复购买
            Button(action: {
                Task {
                    await subscriptionService.restorePurchases()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                    
                    Text("恢复购买")
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        } header: {
            Text("订阅管理")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("• 订阅会自动续费，除非在当前订阅期结束前至少24小时关闭自动续费")
                Text("• 您可以在App Store的账户设置中管理订阅和关闭自动续费")
                Text("• 取消订阅后，您可以继续使用至当前订阅期结束")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 辅助方法
    
    private func openAppStoreManageSubscriptions() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 使用情况行
struct UsageRow: View {
    let icon: String
    let title: String
    let used: Int
    let limit: Int  // -1 表示无限
    let period: String
    let color: Color
    
    private var isUnlimited: Bool {
        return limit == -1
    }
    
    private var progress: Double {
        guard !isUnlimited && limit > 0 else { return 1.0 }
        return Double(min(used, limit)) / Double(limit)
    }
    
    private var usageText: String {
        if isUnlimited {
            return "无限制"
        } else {
            return "\(used) / \(limit)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(usageText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                    
                    Text(period)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 进度条（仅有限制时显示）
            if !isUnlimited {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        // 进度
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct SubscriptionManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SubscriptionManagementView()
        }
    }
}

