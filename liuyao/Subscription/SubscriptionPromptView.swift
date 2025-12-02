//
//  SubscriptionPromptView.swift
//  人生教练
//
//  订阅引导弹窗
//

import SwiftUI

struct SubscriptionPromptView: View {
    @Binding var isPresented: Bool
    let trigger: SubscriptionPromptTrigger
    
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showSubscriptionDetail = false
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // 弹窗内容
            VStack(spacing: 0) {
                // 顶部图标
                topIconSection
                
                // 内容区域
                contentSection
                
                // 按钮区域
                buttonsSection
            }
            .frame(maxWidth: 320)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
        .fullScreenCover(isPresented: $showSubscriptionDetail) {
            NavigationStack {
                SubscriptionDetailView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("关闭") {
                                showSubscriptionDetail = false
                                isPresented = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - 顶部图标
    
    private var topIconSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            
            Image(systemName: iconName)
                .font(.system(size: 50))
                .foregroundColor(.purple)
        }
        .padding(.top, 32)
    }
    
    // MARK: - 内容区域
    
    private var contentSection: some View {
        VStack(spacing: 12) {
            // 标题
            Text(trigger.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // 描述
            Text(trigger.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // 特色功能列表
            VStack(alignment: .leading, spacing: 12) {
                featureItem("无限次AI决策分析", icon: "sparkles")
                featureItem("深度思考框架工具", icon: "chart.bar.doc.horizontal")
                featureItem("成长轨迹可视化", icon: "chart.line.uptrend.xyaxis")
                featureItem("随时导出分析报告", icon: "square.and.arrow.up")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    // MARK: - 按钮区域
    
    private var buttonsSection: some View {
        VStack(spacing: 12) {
            // 主按钮 - 立即升级
            Button(action: {
                PermissionManager.shared.markPromptShown()
                showSubscriptionDetail = true
            }) {
                Text(trigger.actionText)
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
            
            // 次要按钮 - 稍后再说
            Button(action: {
                PermissionManager.shared.markPromptShown()
                dismiss()
            }) {
                Text("稍后再说")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - 辅助方法
    
    private func featureItem(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private var iconName: String {
        switch trigger {
        case .dailyLimitReached, .swotLimitReached, .matrixLimitReached:
            return "clock.badge.exclamationmark"
        case .historyLimitReached:
            return "folder.badge.plus"
        case .featureLockedDeepAnalysis:
            return "chart.bar.doc.horizontal"
        case .featureLockedExport:
            return "square.and.arrow.up"
        case .featureLockedTrend:
            return "chart.line.uptrend.xyaxis"
        case .manualUpgrade:
            return "crown.fill"
        }
    }
    
    private func dismiss() {
        isPresented = false
    }
}

// MARK: - Preview
struct SubscriptionPromptView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionPromptView(
            isPresented: .constant(true),
            trigger: .dailyLimitReached
        )
    }
}

