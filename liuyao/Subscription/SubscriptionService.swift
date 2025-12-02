//
//  SubscriptionService.swift
//  人生教练
//
//  订阅服务 - StoreKit 2 集成
//

import Foundation
import StoreKit
import Combine

// MARK: - 订阅服务
@MainActor
class SubscriptionService: ObservableObject {
    
    // MARK: - 单例
    static let shared = SubscriptionService()
    
    // MARK: - Published Properties
    
    /// 可用的订阅产品列表
    @Published var products: [Product] = []
    
    /// 已购买的产品ID集合
    @Published var purchasedProductIDs: Set<String> = []
    
    /// 当前订阅状态
    @Published var subscriptionStatus: SubscriptionStatus?
    
    /// 是否正在加载产品
    @Published var isLoadingProducts = false
    
    /// 是否正在购买
    @Published var isPurchasing = false
    
    /// 产品加载错误
    @Published var loadError: String?
    
    /// 购买错误
    @Published var purchaseError: String?
    
    // MARK: - Private Properties
    
    private var updateListenerTask: Task<Void, Error>?
    private let permissionManager = PermissionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // 开始监听交易更新
        updateListenerTask = listenForTransactions()
        
        // 启动时加载产品和检查订阅状态
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 产品加载
    
    /// 加载订阅产品
    func loadProducts() async {
        isLoadingProducts = true
        loadError = nil
        
        do {
            // 从App Store获取产品信息
            let productIDs = SubscriptionConfig.allProductIDs
            let loadedProducts = try await Product.products(for: productIDs)
            
            // 按价格排序（月付在前，年付在后）
            self.products = loadedProducts.sorted { product1, product2 in
                // 月付产品排在前面
                if product1.id == SubscriptionConfig.proMonthlyProductID {
                    return true
                }
                if product2.id == SubscriptionConfig.proMonthlyProductID {
                    return false
                }
                return product1.price < product2.price
            }
            
            print("✅ 成功加载 \(self.products.count) 个订阅产品")
            for product in self.products {
                print("  - \(product.displayName): \(product.displayPrice)")
            }
            
        } catch {
            loadError = "无法加载订阅产品：\(error.localizedDescription)"
            print("❌ 加载产品失败：\(error)")
        }
        
        isLoadingProducts = false
    }
    
    // MARK: - 购买流程
    
    /// 购买指定产品
    func purchase(_ product: Product) async throws -> Transaction? {
        isPurchasing = true
        purchaseError = nil
        
        do {
            print("🛒 开始购买：\(product.displayName)")
            
            // 发起购买请求
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 验证交易
                let transaction = try checkVerified(verification)
                
                // 更新订阅状态
                await updateSubscriptionStatus()
                
                // 完成交易
                await transaction.finish()
                
                print("✅ 购买成功：\(product.displayName)")
                isPurchasing = false
                return transaction
                
            case .userCancelled:
                print("❌ 用户取消购买")
                purchaseError = "购买已取消"
                isPurchasing = false
                return nil
                
            case .pending:
                print("⏳ 购买待处理（需要批准）")
                purchaseError = "购买需要批准，请稍后查看"
                isPurchasing = false
                return nil
                
            @unknown default:
                print("❌ 未知购买结果")
                purchaseError = "购买失败，请稍后重试"
                isPurchasing = false
                return nil
            }
            
        } catch {
            purchaseError = "购买失败：\(error.localizedDescription)"
            print("❌ 购买错误：\(error)")
            isPurchasing = false
            throw error
        }
    }
    
    // MARK: - 恢复购买
    
    /// 恢复购买
    func restorePurchases() async {
        print("🔄 开始恢复购买...")
        
        do {
            // 同步App Store的购买记录
            try await AppStore.sync()
            
            // 重新检查订阅状态
            await checkSubscriptionStatus()
            
            print("✅ 恢复购买成功")
            
        } catch {
            purchaseError = "恢复购买失败：\(error.localizedDescription)"
            print("❌ 恢复购买失败：\(error)")
        }
    }
    
    // MARK: - 订阅状态检查
    
    /// 检查当前订阅状态
    func checkSubscriptionStatus() async {
        print("🔍 检查订阅状态...")
        
        var activeSubscription: Product.SubscriptionInfo.Status?
        var activeTier: SubscriptionTier = .free
        
        // 遍历所有产品，查找有效订阅
        for product in products {
            guard let subscription = product.subscription else { continue }
            
            let statuses = try? await subscription.status
            
            // 查找当前有效的订阅
            if let status = statuses?.first(where: { $0.state == .subscribed || $0.state == .inGracePeriod }) {
                activeSubscription = status
                
                // 根据产品ID确定订阅层级
                if product.id == SubscriptionConfig.proMonthlyProductID {
                    activeTier = .proMonthly
                } else if product.id == SubscriptionConfig.proYearlyProductID {
                    activeTier = .proYearly
                }
                
                break
            }
        }
        
        // 更新订阅状态
        if let activeSubscription = activeSubscription {
            // 验证 renewalInfo 和 transaction
            do {
                let renewalInfo = try checkVerified(activeSubscription.renewalInfo)
                let transaction = try checkVerified(activeSubscription.transaction)
                
                // 创建订阅状态
                let status = SubscriptionStatus(
                    tier: activeTier,
                    isActive: true,
                    expirationDate: renewalInfo.renewalDate,
                    autoRenewing: renewalInfo.willAutoRenew,
                    originalPurchaseDate: transaction.originalPurchaseDate
                )
                
                subscriptionStatus = status
                permissionManager.updateSubscriptionStatus(status)
                
                print("✅ 订阅状态：\(activeTier.displayName)")
                if status.expirationDate != nil {
                    print("   到期时间：\(status.formattedExpirationDate)")
                    print("   自动续费：\(status.autoRenewing ? "是" : "否")")
                }
                
            } catch {
                print("❌ 验证订阅信息失败：\(error)")
                subscriptionStatus = nil
                permissionManager.updateSubscriptionTier(.free)
                return
            }
            
        } else {
            // 无有效订阅，使用免费版
            subscriptionStatus = nil
            permissionManager.updateSubscriptionTier(.free)
            print("ℹ️ 当前为免费版")
        }
        
        // 更新已购买产品ID集合
        await updatePurchasedProducts()
    }
    
    /// 更新已购买产品ID集合
    private func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedIDs.insert(transaction.productID)
            } catch {
                print("❌ 验证交易失败：\(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedIDs
    }
    
    /// 更新订阅状态（简化版）
    private func updateSubscriptionStatus() async {
        await checkSubscriptionStatus()
    }
    
    // MARK: - 监听交易更新
    
    /// 监听交易更新（自动续订、退款等）
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // 监听所有交易更新
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // 更新订阅状态
                    await self.updateSubscriptionStatus()
                    
                    // 完成交易
                    await transaction.finish()
                    
                    print("🔔 交易更新：\(transaction.productID)")
                    
                } catch {
                    print("❌ 处理交易更新失败：\(error)")
                }
            }
        }
    }
    
    // MARK: - 交易验证
    
    /// 验证交易的真实性
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            // 交易验证失败，可能被篡改
            throw StoreError.failedVerification
        case .verified(let safe):
            // 交易已验证，可以信任
            return safe
        }
    }
    
    // MARK: - 辅助方法
    
    /// 根据产品ID获取订阅层级
    func getSubscriptionTier(for productID: String) -> SubscriptionTier {
        switch productID {
        case SubscriptionConfig.proMonthlyProductID:
            return .proMonthly
        case SubscriptionConfig.proYearlyProductID:
            return .proYearly
        default:
            return .free
        }
    }
    
    /// 获取月订阅产品
    var monthlyProduct: Product? {
        return products.first { $0.id == SubscriptionConfig.proMonthlyProductID }
    }
    
    /// 获取年订阅产品
    var yearlyProduct: Product? {
        return products.first { $0.id == SubscriptionConfig.proYearlyProductID }
    }
    
    /// 当前订阅层级名称
    var currentTierName: String {
        return subscriptionStatus?.tier.displayName ?? "免费版"
    }
    
    /// 是否为专业版用户
    var isPro: Bool {
        return subscriptionStatus?.tier.isPro ?? false
    }
    
    // MARK: - 价格格式化
    
    /// 获取格式化的价格文本
    func formattedPrice(for product: Product) -> String {
        return product.displayPrice
    }
    
    /// 获取每月价格（年订阅会计算平均值）
    func monthlyPrice(for product: Product) -> String {
        if product.id == SubscriptionConfig.proYearlyProductID {
            // 年订阅，计算每月价格
            let yearlyPrice = product.price
            let monthlyPrice = yearlyPrice / 12
            return monthlyPrice.formatted(.currency(code: product.priceFormatStyle.currencyCode))
        }
        return product.displayPrice
    }
    
    /// 获取节省金额文本（年订阅相比月订阅）
    func savingsText() -> String? {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else {
            return nil
        }
        
        let monthlyYearlyCost = monthly.price * 12
        let savings = monthlyYearlyCost - yearly.price
        
        if savings > 0 {
            let savingsFormatted = savings.formatted(.currency(code: monthly.priceFormatStyle.currencyCode))
            return "年付可省 \(savingsFormatted)"
        }
        
        return nil
    }
    
    // MARK: - 调试方法
    
    #if DEBUG
    /// 打印当前订阅信息（仅调试使用）
    func printSubscriptionInfo() {
        print("""
        
        ═══════════════════════════════════════
        💎 订阅服务当前状态
        ═══════════════════════════════════════
        产品数量: \(products.count)
        已购产品: \(purchasedProductIDs.count)
        当前层级: \(currentTierName)
        是否专业版: \(isPro)
        
        可用产品:
        \(products.map { "  - \($0.displayName): \($0.displayPrice)" }.joined(separator: "\n"))
        
        订阅状态: \(subscriptionStatus?.statusText ?? "无")
        ═══════════════════════════════════════
        
        """)
    }
    #endif
}

// MARK: - Store Error
enum StoreError: Error {
    case failedVerification
    
    var localizedDescription: String {
        switch self {
        case .failedVerification:
            return "交易验证失败"
        }
    }
}

// MARK: - Product Extension
extension Product {
    /// 获取本地化的产品名称
    var localizedDisplayName: String {
        if id == SubscriptionConfig.proMonthlyProductID {
            return "专业版月订阅"
        } else if id == SubscriptionConfig.proYearlyProductID {
            return "专业版年订阅"
        }
        return displayName
    }
}

