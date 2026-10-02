//
//  SubscriptionService.swift
//  人生教练
//
//  订阅服务 - StoreKit 2 集成
//

import Foundation
import StoreKit
import Combine
import UIKit

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

    /// 当前正在购买的商品，用来只让对应按钮进入等待状态。
    @Published var purchasingProductID: String?
    
    /// 产品加载错误
    @Published var loadError: String?
    
    /// 购买错误
    @Published var purchaseError: String?
    
    // MARK: - Private Properties
    
    private var updateListenerTask: Task<Void, Error>?
    private let permissionManager = PermissionManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var grantingTransactionIDs: Set<String> = []
    /// 交易监听先于 purchase() 返回时记下，避免把已成功的购买误报成取消。
    private var grantedProductTimes: [String: Date] = [:]
    private var recentTransactions: [String: Transaction] = [:]
    
    // MARK: - Initialization
    
    private init() {
        // 开始监听交易更新
        updateListenerTask = listenForTransactions()
        
        // 启动时先结束沙盒里积压的未完成交易，再加载产品和订阅状态。
        Task {
            await finishUnfinishedTransactions()
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
        
        print("🔄 开始加载订阅产品...")
        
        do {
            // 从App Store获取产品信息
            let productIDs = SubscriptionConfig.allProductIDs
            print("   请求产品ID：\(productIDs)")
            
            let loadedProducts = try await Product.products(for: productIDs)
            
            print("   从App Store获取到 \(loadedProducts.count) 个产品")
            
            // 检查是否成功加载到产品
            if loadedProducts.isEmpty {
                loadError = "订阅产品配置错误，请稍后重试或联系开发者"
                print("⚠️ 警告：产品ID存在但App Store未返回产品")
                print("   可能原因：产品未在App Store Connect中配置完成")
                isLoadingProducts = false
                return
            }
            
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
                print("    产品ID: \(product.id)")
            }
            
        } catch let error as NSError {
            // 检查是否是网络错误
            if error.domain == NSURLErrorDomain && error.code == -1009 {
                loadError = "网络连接失败\n请检查网络设置或在系统设置中允许App使用蜂窝数据"
                print("❌ 加载产品失败：网络错误 (Code: -1009)")
                print("   原因：网络不可达或蜂窝数据权限被拒绝")
                print("   解决：1) 连接Wi-Fi 2) 在设置→蜂窝网络→人生教练 中开启数据权限")
            } else if error.domain == NSURLErrorDomain {
                loadError = "网络错误，请检查网络连接后重试"
                print("❌ 加载产品失败：网络错误 (Code: \(error.code))")
            } else {
                loadError = "加载失败，请稍后重试\n(\(error.localizedDescription))"
                print("❌ 加载产品失败：\(error)")
            }
            print("   错误详情：\(error)")
        } catch {
            loadError = "加载失败，请稍后重试"
            print("❌ 加载产品失败：\(error)")
        }
        
        isLoadingProducts = false
    }
    
    // MARK: - 购买流程
    
    /// 购买指定产品
    func purchase(_ product: Product) async throws -> Transaction? {
        guard !isPurchasing else { return nil }
        isPurchasing = true
        purchasingProductID = product.id
        purchaseError = nil
        defer {
            isPurchasing = false
            purchasingProductID = nil
        }

        let startedAt = Date()
        do {
            print("🛒 开始购买：\(product.displayName)")

            if product.subscription != nil, alreadyOwnsSubscription(product.id) {
                purchaseError = "你已订阅此项目，无需重复购买。可在系统「订阅」里管理。"
                print("ℹ️ 已有有效订阅，跳过重复购买：\(product.id)")
                return nil
            }

            var allowFastCancelRetry = true
            while true {
                let attemptStarted = Date()
                let result = try await requestPurchase(product)
                switch result {
                case .success(let verification):
                    let transaction = try checkVerified(verification)
                    noteGranted(transaction)
                    await updateSubscriptionStatus()
                    await transaction.finish()
                    let planType = product.id == SubscriptionConfig.proMonthlyProductID ? "monthly" : "yearly"
                    AnalyticsManager.shared.trackPaywallPaySuccess(planType: planType)
                    print("✅ 购买成功：\(product.displayName)")
                    return transaction
                case .userCancelled:
                    let sheetWasShown = Date().timeIntervalSince(attemptStarted) >= 0.45
                    if await shouldTreatCancellationAsSuccess(product.id, startedAt: startedAt, wait: !sheetWasShown),
                       let transaction = recentTransactions[product.id] {
                        await updateSubscriptionStatus()
                        let planType = product.id == SubscriptionConfig.proMonthlyProductID ? "monthly" : "yearly"
                        AnalyticsManager.shared.trackPaywallPaySuccess(planType: planType)
                        print("ℹ️ 购买确认页返回取消，但交易已入账：\(product.id)")
                        return transaction
                    }
                    if allowFastCancelRetry, !sheetWasShown {
                        allowFastCancelRetry = false
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        continue
                    }
                    print("❌ 用户取消购买")
                    return nil
                case .pending:
                    print("⏳ 购买待处理（需要批准）")
                    purchaseError = "购买需要批准，请稍后查看"
                    return nil
                @unknown default:
                    print("❌ 未知购买结果")
                    purchaseError = "购买失败，请稍后重试"
                    return nil
                }
            }
        } catch {
            purchaseError = "购买失败：\(error.localizedDescription)"
            print("❌ 购买错误：\(error)")
            throw error
        }
    }

    /// 购买消耗型点券。成功后把次数记入本地，并异步同步到 iCloud。
    func purchaseConsumable(_ productID: String) async throws -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        purchasingProductID = productID
        purchaseError = nil
        defer {
            isPurchasing = false
            purchasingProductID = nil
        }

        if products.first(where: { $0.id == productID }) == nil {
            await loadProducts()
        }
        guard let product = products.first(where: { $0.id == productID }) else {
            purchaseError = "商品暂不可用，请稍后重试"
            return false
        }

        let startedAt = Date()
        var allowFastCancelRetry = true
        do {
            while true {
                let attemptStarted = Date()
                let result = try await requestPurchase(product)
                switch result {
                case .success(let verification):
                    let transaction = try checkVerified(verification)
                    grantConsumableIfNeeded(transaction)
                    await transaction.finish()
                    AnalyticsManager.shared.trackPaywallPaySuccess(planType: productID)
                    return true
                case .userCancelled:
                    let sheetWasShown = Date().timeIntervalSince(attemptStarted) >= 0.45
                    if await shouldTreatCancellationAsSuccess(product.id, startedAt: startedAt, wait: !sheetWasShown) {
                        AnalyticsManager.shared.trackPaywallPaySuccess(planType: productID)
                        print("ℹ️ 购买确认页返回取消，但点券已入账：\(product.id)")
                        return true
                    }
                    if allowFastCancelRetry, !sheetWasShown {
                        allowFastCancelRetry = false
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        continue
                    }
                    return false
                case .pending:
                    purchaseError = "购买需要批准，请稍后查看"
                    return false
                @unknown default:
                    purchaseError = "购买失败，请稍后重试"
                    return false
                }
            }
        } catch {
            purchaseError = "购买失败：\(error.localizedDescription)"
            throw error
        }
    }

    /// iOS 18.2 起必须把购买确认页挂到前台窗口，否则会报 UI anchor 并误返回取消。
    private func requestPurchase(_ product: Product) async throws -> Product.PurchaseResult {
        // 按钮手势还没结束就拉起购买页时，系统会卡住手势门，确认页要 2～3 秒才出现。
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
        try? await Task.sleep(nanoseconds: 120_000_000)

        if #available(iOS 18.2, *) {
            if let scene = Self.foregroundWindowScene() {
                return try await product.purchase(confirmIn: scene)
            }
            print("⚠️ 未找到前台窗口，购买确认页可能无法附着：\(product.id)")
        }
        return try await product.purchase()
    }

    private static func foregroundWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }

    /// 只拦截当前正在用的那一档。沙盒里旧的年付记录还在时，不能因此挡住月付用户购买年付。
    private func alreadyOwnsSubscription(_ productID: String) -> Bool {
        guard let status = subscriptionStatus, status.isActive, !status.isExpired else { return false }
        switch productID {
        case SubscriptionConfig.proMonthlyProductID:
            return status.tier == .proMonthly
        case SubscriptionConfig.proYearlyProductID:
            return status.tier == .proYearly
        default:
            return false
        }
    }

    private func noteGranted(_ transaction: Transaction) {
        recentTransactions[transaction.productID] = transaction
        grantedProductTimes[transaction.productID] = Date()
    }

    private func hasFreshGrant(_ productID: String, startedAt: Date) -> Bool {
        guard let time = grantedProductTimes[productID] else { return false }
        return time >= startedAt.addingTimeInterval(-1)
    }

    private func shouldTreatCancellationAsSuccess(_ productID: String, startedAt: Date, wait: Bool) async -> Bool {
        if hasFreshGrant(productID, startedAt: startedAt) { return true }
        guard wait else { return false }
        let deadline = Date().addingTimeInterval(0.35)
        while Date() < deadline {
            try? await Task.sleep(nanoseconds: 80_000_000)
            if hasFreshGrant(productID, startedAt: startedAt) { return true }
        }
        return false
    }

    /// 沙盒未结束的交易会反复弹出系统订阅确认。启动时入账并 finish。
    private func finishUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            do {
                let transaction = try checkVerified(result)
                if SubscriptionConfig.isConsumable(transaction.productID) {
                    grantConsumableIfNeeded(transaction)
                } else {
                    noteGranted(transaction)
                }
                await transaction.finish()
                print("🔔 已结束未完成交易：\(transaction.productID)")
            } catch {
                print("❌ 结束未完成交易失败：\(error)")
            }
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
        guard !products.isEmpty else {
            print("ℹ️ 产品尚未加载，保留当前订阅状态")
            return
        }
        
        var activeSubscriptions: [(status: Product.SubscriptionInfo.Status, tier: SubscriptionTier, purchasedAt: Date)] = []
        
        // 同一订阅组里，月付和年付都可能报「订阅中」。以交易上的商品为准，不按遍历到的商品去套层级。
        for product in products {
            guard let subscription = product.subscription else { continue }
            let statuses = try? await subscription.status
            guard let status = statuses?.first(where: { $0.state == .subscribed || $0.state == .inGracePeriod }) else { continue }
            guard let transaction = try? checkVerified(status.transaction) else { continue }
            let tier = getSubscriptionTier(for: transaction.productID)
            guard tier != .free else { continue }
            activeSubscriptions.append((status: status, tier: tier, purchasedAt: transaction.purchaseDate))
            print("📦 找到活跃订阅：\(tier.displayName) 购买于 \(transaction.purchaseDate)")
        }
        
        // 沙盒里旧订阅会和刚买的一起显示为有效。取最近一次购买，而不是固定选年付。
        let chosen = activeSubscriptions.max { $0.purchasedAt < $1.purchasedAt }
        let activeSubscription = chosen?.status
        let activeTier = chosen?.tier ?? .free
        if activeSubscriptions.count > 1, let chosen {
            print("✨ 多个订阅同时有效，采用最近购买：\(chosen.tier.displayName)")
        }
        
        // 更新订阅状态
        if let activeSubscription = activeSubscription {
            // 验证 renewalInfo 和 transaction
            do {
                let renewalInfo = try checkVerified(activeSubscription.renewalInfo)
                let transaction = try checkVerified(activeSubscription.transaction)
                
                // 到期时间以苹果这笔交易为准。沙盒月订阅只有几分钟，不能按自然月或自然年改写。
                let expirationDate = transaction.expirationDate ?? renewalInfo.renewalDate
                
                // 创建订阅状态
                let status = SubscriptionStatus(
                    tier: activeTier,
                    isActive: true,
                    expirationDate: expirationDate,
                    autoRenewing: renewalInfo.willAutoRenew,
                    originalPurchaseDate: transaction.originalPurchaseDate
                )
                
                subscriptionStatus = status
                permissionManager.updateSubscriptionStatus(status)
                AnalyticsManager.shared.updateSubscriptionStatus(activeTier.rawValue)
                
                print("✅ 订阅状态：\(activeTier.displayName)")
                print("   购买时间：\(transaction.purchaseDate.description)")
                if status.expirationDate != nil {
                    print("   到期时间：\(status.formattedExpirationDate)")
                    print("   距离到期：\(status.daysRemaining ?? 0) 天")
                } else {
                    print("   到期时间：无限期（测试环境可能）")
                }
                
            } catch {
                print("❌ 验证订阅信息失败：\(error)")
                subscriptionStatus = nil
                permissionManager.updateSubscriptionTier(.free)
                return
            }
            
        } else {
            subscriptionStatus = nil
            permissionManager.updateSubscriptionTier(.free)
            AnalyticsManager.shared.updateSubscriptionStatus("free")
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

                    if SubscriptionConfig.isConsumable(transaction.productID) {
                        await self.grantConsumableIfNeeded(transaction)
                    } else {
                        await self.noteGranted(transaction)
                        await self.updateSubscriptionStatus()
                    }

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
    
    /// 同一笔消耗型交易只入账一次。
    private func grantConsumableIfNeeded(_ transaction: Transaction) {
        let transactionID = String(transaction.id)
        guard SubscriptionConfig.isConsumable(transaction.productID) else { return }
        var processed = UserDefaults.standard.stringArray(
            forKey: SubscriptionConfig.UserDefaultsKeys.processedConsumableTransactions
        ) ?? []
        if processed.contains(transactionID) || grantingTransactionIDs.contains(transactionID) {
            return
        }
        grantingTransactionIDs.insert(transactionID)
        noteGranted(transaction)

        let masterCount = SubscriptionConfig.masterCreditCount(for: transaction.productID)
        let deductionCount = SubscriptionConfig.deductionCreditCount(for: transaction.productID)
        if masterCount > 0 {
            permissionManager.addMasterCredits(masterCount, sync: false)
        }
        if deductionCount > 0 {
            permissionManager.addDeductionCredits(deductionCount, sync: false)
        }
        permissionManager.pushQuotaToCloud()

        processed.append(transactionID)
        if processed.count > 200 {
            processed.removeFirst(processed.count - 200)
        }
        UserDefaults.standard.set(
            processed,
            forKey: SubscriptionConfig.UserDefaultsKeys.processedConsumableTransactions
        )
        grantingTransactionIDs.remove(transactionID)
        print("✅ 点券已入账：\(transaction.productID) 大师+\(masterCount) 推演+\(deductionCount)")
    }

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

