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
                self?.saveSubscriptionStatus(tier: tier)
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
        
        // 免费版：按「专业分析」计数。从未成功过的用户可一直重试，直到拿到第 1 次成功结果。
        if usageStats.lifetimeSuccessfulDivinationCount == 0 {
            return true
        }
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
    
    /// 是否可以保存更多历史记录。按实际存档条数判断，避免本地计数一直是 0。
    func canSaveMoreRecords() -> Bool {
        if currentTier.isPro { return true }
        syncHistoryRecordCount()
        let limit = usageQuota.historyRecordsLimit
        if limit < 0 { return true }
        return usageStats.totalHistoryRecords < limit
    }

    func syncHistoryRecordCount() {
        let count = DataService().fetchAllRecords().count
        guard usageStats.totalHistoryRecords != count else { return }
        usageStats.totalHistoryRecords = count
        saveUsageStatistics()
    }

    /// 是否可以使用五行决策（每日限额）
    func canUseFiveElementDecision() -> Bool {
        if currentTier.isPro { return true }
        checkAndResetCounters()
        return usageStats.dailyFiveElementCount < usageQuota.dailyFiveElementLimit
    }

    /// 今日五行决策剩余次数（-1 = 无限）
    func getDailyFiveElementRemaining() -> Int {
        if currentTier.isPro { return -1 }
        checkAndResetCounters()
        return max(0, usageQuota.dailyFiveElementLimit - usageStats.dailyFiveElementCount)
    }
    
    // MARK: - 使用次数增加方法
    
    /// 增加问卦使用次数（仅在 AI 成功返回有效解读后调用）
    func incrementDivinationCount() {
        usageStats.lifetimeSuccessfulDivinationCount += 1
        guard !currentTier.isPro else {
            saveUsageStatistics()
            return
        }
        
        usageStats.dailyDivinationCount += 1
        saveUsageStatistics()
        
        print("📊 问卦成功次数 +1，当前：\(usageStats.dailyDivinationCount)/\(usageQuota.dailyDivinationLimit)")
    }

    /// 失败、超时或取消时返还问卦次数（仅当此前已预扣）
    func refundDivinationCount() {
        guard !currentTier.isPro else { return }
        guard usageStats.dailyDivinationCount > 0 else { return }
        usageStats.dailyDivinationCount -= 1
        saveUsageStatistics()
        print("📊 问卦次数已返还，当前：\(usageStats.dailyDivinationCount)/\(usageQuota.dailyDivinationLimit)")
    }
    
    /// 增加SWOT使用次数（仅在 AI 成功后调用）
    func incrementSWOTCount() {
        guard !currentTier.isPro else { return }
        
        usageStats.monthlySWOTCount += 1
        saveUsageStatistics()
        
        print("📊 SWOT成功次数 +1，当前：\(usageStats.monthlySWOTCount)/\(usageQuota.monthlySWOTLimit)")
    }

    func refundSWOTCount() {
        guard !currentTier.isPro else { return }
        guard usageStats.monthlySWOTCount > 0 else { return }
        usageStats.monthlySWOTCount -= 1
        saveUsageStatistics()
        print("📊 SWOT次数已返还，当前：\(usageStats.monthlySWOTCount)/\(usageQuota.monthlySWOTLimit)")
    }
    
    /// 增加决策矩阵使用次数（仅在 AI 成功后调用）
    func incrementMatrixCount() {
        guard !currentTier.isPro else { return }
        usageStats.monthlyMatrixCount += 1
        saveUsageStatistics()
        print("📊 决策矩阵成功次数 +1，当前：\(usageStats.monthlyMatrixCount)/\(usageQuota.monthlyMatrixLimit)")
    }

    func refundMatrixCount() {
        guard !currentTier.isPro else { return }
        guard usageStats.monthlyMatrixCount > 0 else { return }
        usageStats.monthlyMatrixCount -= 1
        saveUsageStatistics()
        print("📊 决策矩阵次数已返还，当前：\(usageStats.monthlyMatrixCount)/\(usageQuota.monthlyMatrixLimit)")
    }

    /// 增加五行决策使用次数（每天计数）
    func incrementFiveElementDecisionCount() {
        guard !currentTier.isPro else { return }
        usageStats.dailyFiveElementCount += 1
        saveUsageStatistics()
        print("📊 五行决策次数 +1，今日：\(usageStats.dailyFiveElementCount)/\(usageQuota.dailyFiveElementLimit)")
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
        if usageStats.lifetimeSuccessfulDivinationCount == 0 {
            return max(1, usageQuota.dailyDivinationLimit)
        }
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
            if feature == .divination {
                return "本月还剩 \(monthlyReadingRemaining()) 次专业解读"
            }
            return "无限次数"
        }
        
        switch feature {
        case .divination:
            let remaining = getDailyDivinationRemaining()
            return "今日还剩 \(remaining) 次专业分析"
            
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
        if tier == .free {
            subscriptionStatus = nil
        }
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
            pushQuotaToCloud()
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
    
    /// 保存订阅状态。必须用传入的新层级：`@Published` 在属性写完前就通知，此时 `currentTier` 还是旧值。
    private func saveSubscriptionStatus(tier: SubscriptionTier) {
        userDefaults.set(tier.rawValue, forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionTier)
        
        if let status = subscriptionStatus, status.tier == tier,
           let encoded = try? JSONEncoder().encode(status) {
            userDefaults.set(encoded, forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionStatus)
        } else {
            userDefaults.removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionStatus)
        }
        
        print("💾 订阅状态已保存：\(tier.displayName)")
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
    
    // MARK: - 开发者模式辅助方法

    private static let devQuotaStampKey = "dev_quota_stamp"

    /// 开发者改完本地配额后打上时间戳再上传。比这个时间旧的云端记录不能盖回来。
    private func devCommit(_ change: () -> Void) {
        userDefaults.set(Date(), forKey: Self.devQuotaStampKey)
        change()
        saveUsageStatistics()
        objectWillChange.send()
        pushQuotaToCloud()
    }

    /// 恢复本月专业解读和大师赠送。已购次数不动。恢复后不会出现拦截。
    func devRestoreMonthlyQuota() {
        devCommit {
            usageStats.monthlyReadingUsed = 0
            usageStats.monthlyMasterGiftUsed = 0
            usageStats.dailyDivinationCount = 0
        }
        print("🔧 [Dev] 已恢复本月额度")
    }

    /// 把专业解读用满，用来测月度拦截。
    func devExhaustProfessionalReading() {
        devCommit {
            if currentTier.isPro {
                let limit = usageQuota.monthlyReadingLimit
                usageStats.monthlyReadingUsed = limit > 0 ? limit : 0
            } else if usageQuota.dailyDivinationLimit > 0 {
                usageStats.dailyDivinationCount = usageQuota.dailyDivinationLimit
                usageStats.lifetimeSuccessfulDivinationCount = max(usageStats.lifetimeSuccessfulDivinationCount, 1)
            }
        }
        print("🔧 [Dev] 已用尽专业解读")
    }

    /// 大师赠送和已购大师次数都清掉。
    func devClearMasterAccess() {
        devCommit {
            if usageQuota.monthlyMasterGift > 0 {
                usageStats.monthlyMasterGiftUsed = usageQuota.monthlyMasterGift
            }
            usageStats.masterCredits = 0
        }
        print("🔧 [Dev] 已清空大师赠送和已购大师")
    }

    /// 已购推演次数清掉。
    func devClearDeductionCredits() {
        devCommit {
            usageStats.deductionCredits = 0
        }
        print("🔧 [Dev] 已清空已购推演")
    }

    /// 专业解读、大师赠送、已购大师、已购推演一次用尽。
    func devExhaustPaywall() {
        devCommit {
            let readingLimit = usageQuota.monthlyReadingLimit
            usageStats.monthlyReadingUsed = readingLimit > 0 ? readingLimit : 0
            if usageQuota.monthlyMasterGift > 0 {
                usageStats.monthlyMasterGiftUsed = usageQuota.monthlyMasterGift
            }
            usageStats.masterCredits = 0
            usageStats.deductionCredits = 0
            if !currentTier.isPro, usageQuota.dailyDivinationLimit > 0 {
                usageStats.dailyDivinationCount = usageQuota.dailyDivinationLimit
                usageStats.lifetimeSuccessfulDivinationCount = max(usageStats.lifetimeSuccessfulDivinationCount, 1)
            }
        }
        print("🔧 [Dev] 已用尽专业解读、大师和推演")
    }

    // MARK: - v3.3 配额

    static func readingID(question: String, castTime: Date, hexagramName: String) -> String {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(trimmed)|\(Int(castTime.timeIntervalSince1970))|\(hexagramName)"
    }

    func canUseProfessionalReading() -> Bool {
        checkAndResetCounters()
        guard currentTier.isPro else { return true }
        let limit = usageQuota.monthlyReadingLimit
        guard limit >= 0 else { return true }
        return usageStats.monthlyReadingUsed < limit
    }

    func monthlyReadingRemaining() -> Int {
        checkAndResetCounters()
        guard currentTier.isPro else { return getDailyDivinationRemaining() }
        let limit = usageQuota.monthlyReadingLimit
        guard limit >= 0 else { return -1 }
        return max(0, limit - usageStats.monthlyReadingUsed)
    }

    func daysUntilMonthlyReset() -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) else {
            return 0
        }
        return max(0, calendar.dateComponents([.day], from: now, to: start).day ?? 0)
    }

    func recordProfessionalReadingUse() {
        guard currentTier.isPro else { return }
        checkAndResetCounters()
        usageStats.monthlyReadingUsed += 1
        saveUsageStatistics()
        pushQuotaToCloud()
    }

    func followUpLimit(for readingID: String) -> Int {
        if currentTier.isPro { return usageQuota.followUpLimit }
        if usageStats.masterUnlockedReadingIDs.contains(readingID) {
            return SubscriptionConfig.paidFollowUpLimit
        }
        return SubscriptionConfig.freeFollowUpLimit
    }

    func canSendFollowUp(readingID: String) -> Bool {
        alignFollowUpReading(readingID)
        return usageStats.followUpCountInCurrentReading < followUpLimit(for: readingID)
    }

    func followUpRemaining(readingID: String) -> Int {
        alignFollowUpReading(readingID)
        return max(0, followUpLimit(for: readingID) - usageStats.followUpCountInCurrentReading)
    }

    func adoptFollowUpCount(readingID: String, observedTurns: Int) {
        alignFollowUpReading(readingID)
        if observedTurns > usageStats.followUpCountInCurrentReading {
            usageStats.followUpCountInCurrentReading = observedTurns
            saveUsageStatistics()
        }
    }

    func incrementFollowUp(readingID: String) {
        alignFollowUpReading(readingID)
        usageStats.followUpCountInCurrentReading += 1
        saveUsageStatistics()
    }

    func monthlyMasterGiftRemaining() -> Int {
        checkAndResetCounters()
        return max(0, usageQuota.monthlyMasterGift - usageStats.monthlyMasterGiftUsed)
    }

    func totalMasterCredits() -> Int {
        usageStats.masterCredits + monthlyMasterGiftRemaining()
    }

    @discardableResult
    func consumeMasterCredit(readingID: String) -> Bool {
        checkAndResetCounters()
        if currentTier.isPro, usageStats.monthlyMasterGiftUsed < usageQuota.monthlyMasterGift {
            usageStats.monthlyMasterGiftUsed += 1
        } else if usageStats.masterCredits > 0 {
            usageStats.masterCredits -= 1
        } else {
            return false
        }
        unlockMasterReading(readingID)
        saveUsageStatistics()
        pushQuotaToCloud()
        return true
    }

    @discardableResult
    func consumeDeductionCredit() -> Bool {
        guard usageStats.deductionCredits > 0 else { return false }
        usageStats.deductionCredits -= 1
        saveUsageStatistics()
        pushQuotaToCloud()
        return true
    }

    func refundDeductionCredit() {
        usageStats.deductionCredits += 1
        saveUsageStatistics()
        pushQuotaToCloud()
    }

    func addMasterCredits(_ count: Int, sync: Bool = true) {
        guard count > 0 else { return }
        usageStats.masterCredits += count
        saveUsageStatistics()
        if sync { pushQuotaToCloud() }
    }

    func addDeductionCredits(_ count: Int, sync: Bool = true) {
        guard count > 0 else { return }
        usageStats.deductionCredits += count
        saveUsageStatistics()
        if sync { pushQuotaToCloud() }
    }

    func pushQuotaToCloud() {
        let snapshot = cloudSnapshot()
        Task { @MainActor in
            await CloudKitSyncManager.shared.saveQuota(snapshot)
        }
    }

    func cloudSnapshot() -> CloudQuotaSnapshot {
        CloudQuotaSnapshot(
            masterCredits: usageStats.masterCredits,
            deductionCredits: usageStats.deductionCredits,
            monthlyReadingUsed: usageStats.monthlyReadingUsed,
            monthlyMasterGiftUsed: usageStats.monthlyMasterGiftUsed,
            monthlyResetDate: usageStats.lastMonthlyResetDate,
            masterUnlockedReadingIDs: usageStats.masterUnlockedReadingIDs
        )
    }

    /// 与云端合并。余额和同月已用次数取较大值，避免后写入的设备把已购点券盖掉。
    /// 开发者模式刚改过本地时，以本地为准回写，避免云端把测试值盖回来。
    /// 返回 true 表示本地结果比云端更新，需要回写。
    @discardableResult
    func mergeCloudSnapshot(_ remote: CloudQuotaSnapshot) -> Bool {
        if let stamp = userDefaults.object(forKey: Self.devQuotaStampKey) as? Date,
           remote.lastUpdatedAt < stamp {
            return true
        }
        checkAndResetCounters()
        let localMaster = usageStats.masterCredits
        let localDeduction = usageStats.deductionCredits
        let localReading = usageStats.monthlyReadingUsed
        let localGift = usageStats.monthlyMasterGiftUsed
        let localIDs = Set(usageStats.masterUnlockedReadingIDs)

        usageStats.masterCredits = max(localMaster, remote.masterCredits)
        usageStats.deductionCredits = max(localDeduction, remote.deductionCredits)

        let calendar = Calendar.current
        let localMonth = calendar.dateComponents([.year, .month], from: usageStats.lastMonthlyResetDate)
        let remoteMonth = calendar.dateComponents([.year, .month], from: remote.monthlyResetDate)
        let nowMonth = calendar.dateComponents([.year, .month], from: Date())
        if localMonth.year == remoteMonth.year && localMonth.month == remoteMonth.month {
            usageStats.monthlyReadingUsed = max(localReading, remote.monthlyReadingUsed)
            usageStats.monthlyMasterGiftUsed = max(localGift, remote.monthlyMasterGiftUsed)
        } else if remoteMonth.year == nowMonth.year && remoteMonth.month == nowMonth.month {
            usageStats.monthlyReadingUsed = remote.monthlyReadingUsed
            usageStats.monthlyMasterGiftUsed = remote.monthlyMasterGiftUsed
            usageStats.lastMonthlyResetDate = remote.monthlyResetDate
        }

        var unlocked = localIDs.union(remote.masterUnlockedReadingIDs)
        if unlocked.count > 40 {
            unlocked = Set(Array(unlocked).suffix(40))
        }
        usageStats.masterUnlockedReadingIDs = Array(unlocked)
        saveUsageStatistics()
        objectWillChange.send()

        let changedCredits = usageStats.masterCredits != remote.masterCredits
            || usageStats.deductionCredits != remote.deductionCredits
        let changedUsage = usageStats.monthlyReadingUsed != remote.monthlyReadingUsed
            || usageStats.monthlyMasterGiftUsed != remote.monthlyMasterGiftUsed
        let changedIDs = Set(usageStats.masterUnlockedReadingIDs) != Set(remote.masterUnlockedReadingIDs)
        return changedCredits || changedUsage || changedIDs
    }

    private func alignFollowUpReading(_ readingID: String) {
        guard usageStats.currentReadingID != readingID else { return }
        usageStats.currentReadingID = readingID
        usageStats.followUpCountInCurrentReading = 0
        saveUsageStatistics()
    }

    private func unlockMasterReading(_ readingID: String) {
        guard !readingID.isEmpty else { return }
        var ids = usageStats.masterUnlockedReadingIDs.filter { $0 != readingID }
        ids.append(readingID)
        if ids.count > 40 {
            ids.removeFirst(ids.count - 40)
        }
        usageStats.masterUnlockedReadingIDs = ids
    }

    // MARK: - 测试辅助方法（开发者模式可调用）

    /// 模拟升级到专业版
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

    /// 模拟降级到免费版
    func simulateDowngradeToFree() {
        updateSubscriptionTier(.free)
        subscriptionStatus = nil
        print("⬇️ 已模拟降级到免费版")
    }

    #if DEBUG
    /// 清除所有数据（仅 DEBUG 使用）
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

