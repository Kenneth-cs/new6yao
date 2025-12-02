//
//  PermissionManager.swift
//  人生教练
//
//  权限和使用次数管理器（单例）
//

import Foundation
import Combine

// MARK: - 权限管理器
class PermissionManager: ObservableObject {
    
    // MARK: - 单例
    static let shared = PermissionManager()
    
    // MARK: - Published Properties
    
    /// 当前订阅层级
    @Published var currentTier: SubscriptionTier = .free
    
    /// 当前使用配额
    @Published var usageQuota: UsageQuota = .free
    
    /// 使用统计数据
    @Published var usageStats: UsageStatistics = UsageStatistics()
    
    /// 订阅状态
    @Published var subscriptionStatus: SubscriptionStatus?
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        loadSubscriptionStatus()
        loadUsageStatistics()
        checkAndResetCounters()
        
        // 监听订阅状态变化
        $currentTier
            .sink { [weak self] tier in
                self?.updateQuota(for: tier)
                self?.saveSubscriptionStatus()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 权限检查方法
    
    /// 是否可以使用问卦功能
    func canUseDivination() -> Bool {
        // 专业版无限制
        if currentTier.isPro {
            return true
        }
        
        // 检查是否需要重置计数器
        checkAndResetCounters()
        
        // 免费版检查次数限制
        return usageStats.dailyDivinationCount < usageQuota.dailyDivinationLimit
    }
    
    /// 是否可以使用SWOT分析
    func canUseSWOT() -> Bool {
        // 专业版无限制
        if currentTier.isPro {
            return true
        }
        
        // 检查是否需要重置计数器
        checkAndResetCounters()
        
        // 免费版检查次数限制
        return usageStats.monthlySWOTCount < usageQuota.monthlySWOTLimit
    }
    
    /// 是否可以使用决策矩阵
    func canUseMatrix() -> Bool {
        // 专业版无限制
        if currentTier.isPro {
            return true
        }
        
        // 检查是否需要重置计数器
        checkAndResetCounters()
        
        // 免费版检查次数限制
        return usageStats.monthlyMatrixCount < usageQuota.monthlyMatrixLimit
    }
    
    /// 是否可以保存更多历史记录
    func canSaveMoreRecords() -> Bool {
        // 专业版无限制
        if currentTier.isPro {
            return true
        }
        
        // 免费版检查记录数量限制
        return usageStats.totalHistoryRecords < usageQuota.historyRecordsLimit
    }
    
    // MARK: - 使用次数增加方法
    
    /// 增加问卦使用次数
    func incrementDivinationCount() {
        // 专业版不计数
        guard !currentTier.isPro else { return }
        
        usageStats.dailyDivinationCount += 1
        saveUsageStatistics()
        
        print("📊 问卦次数 +1，当前：\(usageStats.dailyDivinationCount)/\(usageQuota.dailyDivinationLimit)")
    }
    
    /// 增加SWOT使用次数
    func incrementSWOTCount() {
        // 专业版不计数
        guard !currentTier.isPro else { return }
        
        usageStats.monthlySWOTCount += 1
        saveUsageStatistics()
        
        print("📊 SWOT次数 +1，当前：\(usageStats.monthlySWOTCount)/\(usageQuota.monthlySWOTLimit)")
    }
    
    /// 增加决策矩阵使用次数
    func incrementMatrixCount() {
        // 专业版不计数
        guard !currentTier.isPro else { return }
        
        usageStats.monthlyMatrixCount += 1
        saveUsageStatistics()
        
        print("📊 决策矩阵次数 +1，当前：\(usageStats.monthlyMatrixCount)/\(usageQuota.monthlyMatrixLimit)")
    }
    
    /// 更新历史记录总数
    func updateHistoryRecordsCount(_ count: Int) {
        usageStats.totalHistoryRecords = count
        saveUsageStatistics()
    }
    
    // MARK: - 剩余次数查询方法
    
    /// 获取每日问卦剩余次数
    func getDailyDivinationRemaining() -> Int {
        if currentTier.isPro {
            return -1  // 无限制
        }
        
        checkAndResetCounters()
        let remaining = usageQuota.dailyDivinationLimit - usageStats.dailyDivinationCount
        return max(0, remaining)
    }
    
    /// 获取每月SWOT剩余次数
    func getMonthlySWOTRemaining() -> Int {
        if currentTier.isPro {
            return -1  // 无限制
        }
        
        checkAndResetCounters()
        let remaining = usageQuota.monthlySWOTLimit - usageStats.monthlySWOTCount
        return max(0, remaining)
    }
    
    /// 获取每月决策矩阵剩余次数
    func getMonthlyMatrixRemaining() -> Int {
        if currentTier.isPro {
            return -1  // 无限制
        }
        
        checkAndResetCounters()
        let remaining = usageQuota.monthlyMatrixLimit - usageStats.monthlyMatrixCount
        return max(0, remaining)
    }
    
    /// 获取剩余次数的描述文本
    func getRemainingText(for feature: FeaturePermission) -> String {
        if currentTier.isPro {
            return "无限次数"
        }
        
        switch feature {
        case .divination:
            let remaining = getDailyDivinationRemaining()
            return "今日还剩 \(remaining) 次"
            
        case .swot:
            let remaining = getMonthlySWOTRemaining()
            return "本月还剩 \(remaining) 次"
            
        case .matrix:
            let remaining = getMonthlyMatrixRemaining()
            return "本月还剩 \(remaining) 次"
            
        case .historyRecords:
            let used = usageStats.totalHistoryRecords
            let limit = usageQuota.historyRecordsLimit
            return "已保存 \(used)/\(limit) 条"
        }
    }
    
    // MARK: - 订阅管理方法
    
    /// 更新订阅层级
    func updateSubscriptionTier(_ tier: SubscriptionTier) {
        print("🔄 更新订阅层级：\(currentTier.displayName) → \(tier.displayName)")
        currentTier = tier
        updateQuota(for: tier)
    }
    
    /// 更新订阅状态
    func updateSubscriptionStatus(_ status: SubscriptionStatus) {
        print("🔄 更新订阅状态：\(currentTier.displayName) → \(status.tier.displayName)")
        subscriptionStatus = status
        currentTier = status.tier
        updateQuota(for: status.tier)  // 重要：更新配额以应用新的权限
    }
    
    /// 根据订阅层级更新配额
    private func updateQuota(for tier: SubscriptionTier) {
        usageQuota = SubscriptionConfig.getQuota(for: tier)
    }
    
    // MARK: - 计数器重置方法
    
    /// 检查并重置计数器（自动）
    func checkAndResetCounters() {
        // 检查是否需要重置每日计数器
        if usageStats.needsDailyReset() {
            print("🔄 重置每日计数器")
            usageStats.resetDaily()
            saveUsageStatistics()
        }
        
        // 检查是否需要重置每月计数器
        if usageStats.needsMonthlyReset() {
            print("🔄 重置每月计数器")
            usageStats.resetMonthly()
            saveUsageStatistics()
        }
    }
    
    /// 手动重置所有计数器（仅用于测试）
    func resetAllCounters() {
        usageStats.resetDaily()
        usageStats.resetMonthly()
        saveUsageStatistics()
        print("🔄 已手动重置所有计数器")
    }
    
    // MARK: - 订阅引导检查
    
    /// 是否应该显示订阅引导
    func shouldShowSubscriptionPrompt(for feature: FeaturePermission) -> Bool {
        // 专业版不显示
        guard !currentTier.isPro else { return false }
        
        // 检查冷却时间
        guard SubscriptionConfig.canShowPrompt() else { return false }
        
        // 根据不同功能检查阈值
        switch feature {
        case .divination:
            return usageStats.dailyDivinationCount >= SubscriptionConfig.PromptThresholds.divinationSoftPrompt
            
        case .swot:
            return usageStats.monthlySWOTCount >= SubscriptionConfig.PromptThresholds.swotSoftPrompt
            
        case .matrix:
            return usageStats.monthlyMatrixCount >= SubscriptionConfig.PromptThresholds.matrixSoftPrompt
            
        default:
            return false
        }
    }
    
    /// 标记已显示订阅引导
    func markPromptShown() {
        SubscriptionConfig.markPromptShown()
    }
    
    // MARK: - 数据持久化
    
    /// 保存订阅状态
    private func saveSubscriptionStatus() {
        userDefaults.set(currentTier.rawValue, forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionTier)
        
        if let status = subscriptionStatus,
           let encoded = try? JSONEncoder().encode(status) {
            userDefaults.set(encoded, forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionStatus)
        }
        
        print("💾 订阅状态已保存：\(currentTier.displayName)")
    }
    
    /// 加载订阅状态
    private func loadSubscriptionStatus() {
        // 加载订阅层级
        if let tierString = userDefaults.string(forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionTier),
           let tier = SubscriptionTier(rawValue: tierString) {
            currentTier = tier
        } else {
            currentTier = .free
        }
        
        // 加载订阅状态详情
        if let statusData = userDefaults.data(forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionStatus),
           let status = try? JSONDecoder().decode(SubscriptionStatus.self, from: statusData) {
            subscriptionStatus = status
        }
        
        // 更新配额
        updateQuota(for: currentTier)
        
        print("📂 订阅状态已加载：\(currentTier.displayName)")
    }
    
    /// 保存使用统计数据
    private func saveUsageStatistics() {
        if let encoded = try? JSONEncoder().encode(usageStats) {
            userDefaults.set(encoded, forKey: SubscriptionConfig.UserDefaultsKeys.usageStatistics)
        }
    }
    
    /// 加载使用统计数据
    private func loadUsageStatistics() {
        if let statsData = userDefaults.data(forKey: SubscriptionConfig.UserDefaultsKeys.usageStatistics),
           let stats = try? JSONDecoder().decode(UsageStatistics.self, from: statsData) {
            usageStats = stats
        } else {
            usageStats = UsageStatistics()
        }
        
        print("📂 使用统计已加载 - 问卦:\(usageStats.dailyDivinationCount), SWOT:\(usageStats.monthlySWOTCount), 矩阵:\(usageStats.monthlyMatrixCount)")
    }
    
    // MARK: - 调试方法
    
    /// 打印当前状态（仅用于调试）
    func printCurrentStatus() {
        print("""
        
        ═══════════════════════════════════════
        📊 权限管理器当前状态
        ═══════════════════════════════════════
        订阅层级: \(currentTier.displayName)
        
        配额限制:
        - 每日问卦: \(usageQuota.dailyDivinationLimit == -1 ? "无限" : "\(usageQuota.dailyDivinationLimit)次")
        - 每月SWOT: \(usageQuota.monthlySWOTLimit == -1 ? "无限" : "\(usageQuota.monthlySWOTLimit)次")
        - 每月矩阵: \(usageQuota.monthlyMatrixLimit == -1 ? "无限" : "\(usageQuota.monthlyMatrixLimit)次")
        - 历史记录: \(usageQuota.historyRecordsLimit == -1 ? "无限" : "\(usageQuota.historyRecordsLimit)条")
        
        已使用次数:
        - 今日问卦: \(usageStats.dailyDivinationCount)
        - 本月SWOT: \(usageStats.monthlySWOTCount)
        - 本月矩阵: \(usageStats.monthlyMatrixCount)
        - 历史记录: \(usageStats.totalHistoryRecords)
        
        剩余次数:
        - 问卦剩余: \(getRemainingText(for: .divination))
        - SWOT剩余: \(getRemainingText(for: .swot))
        - 矩阵剩余: \(getRemainingText(for: .matrix))
        ═══════════════════════════════════════
        
        """)
    }
    
    // MARK: - 测试辅助方法
    
    #if DEBUG
    /// 模拟升级到专业版（仅测试使用）
    func simulateUpgradeToPro() {
        updateSubscriptionTier(.proMonthly)
        subscriptionStatus = SubscriptionStatus(
            tier: .proMonthly,
            isActive: true,
            expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            autoRenewing: true,
            originalPurchaseDate: Date()
        )
        print("🎉 已模拟升级到专业版")
    }
    
    /// 模拟降级到免费版（仅测试使用）
    func simulateDowngradeToFree() {
        updateSubscriptionTier(.free)
        subscriptionStatus = nil
        print("⬇️ 已模拟降级到免费版")
    }
    
    /// 清除所有数据（仅测试使用）
    func clearAllData() {
        userDefaults.removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionTier)
        userDefaults.removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionStatus)
        userDefaults.removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.usageStatistics)
        userDefaults.removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.lastPromptTime)
        
        currentTier = .free
        subscriptionStatus = nil
        usageStats = UsageStatistics()
        updateQuota(for: .free)
        
        print("🗑️ 已清除所有订阅数据")
    }
    #endif
}

