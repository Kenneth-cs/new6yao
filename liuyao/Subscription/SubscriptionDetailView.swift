//
//  SubscriptionDetailView.swift
//  人生教练
//
//  订阅详情页（主订阅页面）
//

import SwiftUI
import StoreKit

struct SubscriptionDetailView: View {
    
    let initialSelectedTier: SubscriptionTier?
    
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProduct: Product?
    @State private var showingRestoreAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    init(initialSelectedTier: SubscriptionTier? = nil) {
        self.initialSelectedTier = initialSelectedTier
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部标题区
                    headerSection
                    
                    // 订阅卡片选择
                    if subscriptionService.isLoadingProducts {
                        ProgressView("加载中...")
                            .padding()
                    } else if !subscriptionService.products.isEmpty {
                        subscriptionCardsSection
                    } else {
                        // 加载失败提示
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text(subscriptionService.loadError ?? "无法加载订阅产品")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                Task {
                                    await subscriptionService.loadProducts()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("重试")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.purple)
                                .cornerRadius(20)
                            }
                        }
                        .padding()
                    }
                    
                    // 功能对比表
                    FeatureComparisonView()
                        .padding(.horizontal)
                    
                    // 购买按钮
                    if let product = selectedProduct ?? subscriptionService.monthlyProduct {
                        purchaseButton(for: product)
                    }
                    
                    // 恢复购买按钮
                    restoreButton
                    
                    // 底部说明
                    legalSection
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("升级专业版")
        .navigationBarTitleDisplayMode(.inline)
        .alert("恢复购买", isPresented: $showingRestoreAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("已成功恢复购买")
        }
        .alert("提示", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if selectedProduct == nil {
                if let initialTier = initialSelectedTier {
                    switch initialTier {
                    case .proMonthly:
                        selectedProduct = subscriptionService.monthlyProduct
                    case .proYearly:
                        selectedProduct = subscriptionService.yearlyProduct
                    default:
                        selectedProduct = subscriptionService.monthlyProduct
                    }
                } else {
                    selectedProduct = subscriptionService.monthlyProduct
                }
            }
            AnalyticsManager.shared.trackPaywallView(triggerSource: initialSelectedTier != nil ? "限制拦截" : "个人中心")
        }
    }
    
    // MARK: - 顶部标题区
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            // 标题
            Text("解锁无限可能性")
                .font(.title)
                .fontWeight(.bold)
            
            // 副标题
            Text("每天一杯咖啡的价格，换来清晰的人生方向")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 订阅卡片区
    
    private var subscriptionCardsSection: some View {
        VStack(spacing: 16) {
            ForEach(subscriptionService.products, id: \.id) { product in
                SubscriptionCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    onSelect: {
                        selectedProduct = product
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 购买按钮
    
    private func purchaseButton(for product: Product) -> some View {
        Button(action: {
            Task {
                let planType = product.id == SubscriptionConfig.proMonthlyProductID ? "monthly" : "yearly"
                AnalyticsManager.shared.trackPaywallClickBuy(planType: planType, price: product.displayPrice)
                await purchaseProduct(product)
            }
        }) {
            HStack {
                if subscriptionService.isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("立即升级")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(subscriptionService.isPurchasing)
        .padding(.horizontal)
    }
    
    // MARK: - 恢复购买按钮
    
    private var restoreButton: some View {
        Button(action: {
            Task {
                await restorePurchases()
            }
        }) {
            Text("恢复购买")
                .font(.subheadline)
                .foregroundColor(.purple)
        }
    }
    
    // MARK: - 底部说明
    
    private var legalSection: some View {
        VStack(spacing: 12) {
            Text("订阅说明")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("""
            • 订阅会自动续费，除非在当前订阅期结束前至少24小时关闭自动续费
            • 订阅费用将在确认购买时从您的Apple ID账户扣除
            • 您可以在App Store的账户设置中管理订阅和关闭自动续费
            • 免费试用期未使用的部分将在购买订阅时失效（如适用）
            """)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            HStack(spacing: 16) {
                Button("隐私政策") {
                    // TODO: 跳转到隐私政策
                }
                
                Button("用户协议") {
                    // TODO: 跳转到用户协议
                }
            }
            .font(.caption)
            .foregroundColor(.purple)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 20)
    }
    
    // MARK: - 购买处理
    
    private func purchaseProduct(_ product: Product) async {
        do {
            let transaction = try await subscriptionService.purchase(product)
            
            if transaction != nil {
                // 购买成功
                dismiss()
            } else if let error = subscriptionService.purchaseError {
                // 显示错误
                errorMessage = error
                showingErrorAlert = true
            }
            
        } catch {
            errorMessage = "购买失败：\(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    private func restorePurchases() async {
        await subscriptionService.restorePurchases()
        
        if subscriptionService.isPro {
            AnalyticsManager.shared.trackPaywallRestore()
            showingRestoreAlert = true
        } else {
            errorMessage = "未找到可恢复的购买记录"
            showingErrorAlert = true
        }
    }
}

// MARK: - 订阅卡片
struct SubscriptionCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var isYearly: Bool {
        return product.id == SubscriptionConfig.proYearlyProductID
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // 推荐标签
                if isYearly {
                    HStack {
                        Spacer()
                        Text("最超值")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(8, corners: [.topRight, .bottomLeft])
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("推荐")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.purple)
                            .cornerRadius(8, corners: [.topRight, .bottomLeft])
                    }
                }
                
                // 卡片内容
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        // 订阅类型
                        Text(isYearly ? "年度订阅" : "月度订阅")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        // 价格
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(product.displayPrice)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text(isYearly ? "/年" : "/月")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // 每月价格（仅年订阅显示）
                        if isYearly {
                            Text("相当于 ¥8.25/月")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        // 优惠说明
                        if isYearly {
                            Text("免费送2个月")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    // 选中标记
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .purple : .gray)
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.purple.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
struct SubscriptionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SubscriptionDetailView()
        }
    }
}

