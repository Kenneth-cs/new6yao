//
//  SubscriptionConfig.swift
//  人生教练
//
//  订阅配置文件
//

import Foundation

// MARK: - 订阅配置
struct SubscriptionConfig {
    
    // MARK: - App Store 产品ID
    
    /// 专业版月订阅产品ID
    static let proMonthlyProductID = "com.renshengjiaoliankd.pro.monthly"
    
    /// 专业版年订阅产品ID
    static let proYearlyProductID = "com.renshengjiaoliankd.pro.yearly"
    
    /// 所有产品ID列表
    static let allProductIDs: Set<String> = [
        proMonthlyProductID,
        proYearlyProductID
    ]
    
    // MARK: - 免费版配额
    
    /// 免费版：每日问卦次数
    static let freeDailyDivination = 1
    
    /// 免费版：每月SWOT分析次数
    static let freeMonthlySWOT = 10
    
    /// 免费版：每月决策矩阵次数
    static let freeMonthlyMatrix = 10
    
    /// 免费版：历史记录保留数量
    static let freeHistoryLimit = 3
    
    // MARK: - 专业版配额（-1 表示无限）
    
    /// 专业版：每日问卦次数（无限）
    static let proDailyDivination = -1
    
    /// 专业版：每月SWOT分析次数（无限）
    static let proMonthlySWOT = -1
    
    /// 专业版：每月决策矩阵次数（无限）
    static let proMonthlyMatrix = -1
    
    /// 专业版：历史记录保留数量（无限）
    static let proHistoryLimit = -1
    
    // MARK: - 订阅引导配置
    
    /// 显示订阅引导的时机（使用次数阈值）
    struct PromptThresholds {
        /// 问卦次数达到多少时显示轻提示
        static let divinationSoftPrompt = 0  // 第1次使用时就提示
        
        /// SWOT次数达到多少时显示轻提示
        static let swotSoftPrompt = 8  // 第9次使用时提示
        
        /// 决策矩阵次数达到多少时显示轻提示
        static let matrixSoftPrompt = 8  // 第9次使用时提示
    }
    
    /// 订阅引导弹窗显示间隔（避免过度打扰）
    static let promptCooldownHours = 24  // 24小时内只显示一次
    
    // MARK: - 试用期配置
    
    /// 是否启用免费试用
    static let enableFreeTrial = true
    
    /// 免费试用天数
    static let freeTrialDays = 7
    
    // MARK: - 营销配置
    
    /// 限时优惠价格（可选）
    struct PromoConfig {
        /// 是否启用限时优惠
        static let enablePromo = false
        
        /// 优惠价格（月订阅）
        static let promoMonthlyPrice: Decimal = 15.0
        
        /// 优惠价格（年订阅）
        static let promoYearlyPrice: Decimal = 88.0
        
        /// 优惠结束时间
        static let promoEndDate = Date(timeIntervalSince1970: 1735660800) // 2025-01-01 00:00:00
    }
    
    /// 推荐奖励配置
    struct ReferralConfig {
        /// 邀请好友奖励次数
        static let referralBonusCount = 5
        
        /// 被邀请好友奖励次数
        static let inviteeBonusCount = 5
    }
    
    // MARK: - 本地存储Key
    
    struct UserDefaultsKeys {
        /// 当前订阅层级
        static let subscriptionTier = "subscription_tier"
        
        /// 订阅状态
        static let subscriptionStatus = "subscription_status"
        
        /// 使用统计数据
        static let usageStatistics = "usage_statistics"
        
        /// 上次显示订阅引导的时间
        static let lastPromptTime = "last_subscription_prompt_time"
        
        /// 是否已显示过订阅介绍
        static let hasShownIntroduction = "has_shown_subscription_intro"
    }
    
    // MARK: - 功能开关
    
    /// 功能特性开关
    struct FeatureFlags {
        /// 是否启用推荐奖励系统
        static let enableReferralSystem = false
        
        /// 是否显示订阅引导（可用于测试时临时关闭）
        static let enableSubscriptionPrompt = true
    }
    
    // MARK: - 分析埋点事件
    
    /// 用于统计分析的事件名称
    struct AnalyticsEvents {
        static let viewSubscriptionPage = "view_subscription_page"
        static let clickUpgradeButton = "click_upgrade_button"
        static let startPurchase = "start_purchase"
        static let completePurchase = "complete_purchase"
        static let cancelPurchase = "cancel_purchase"
        static let restorePurchase = "restore_purchase"
        static let hitUsageLimit = "hit_usage_limit"
        static let viewSubscriptionPrompt = "view_subscription_prompt"
        static let dismissSubscriptionPrompt = "dismiss_subscription_prompt"
    }
    
    // MARK: - 辅助方法
    
    /// 根据订阅层级获取使用配额
    static func getQuota(for tier: SubscriptionTier) -> UsageQuota {
        switch tier {
        case .free:
            return UsageQuota(
                dailyDivinationLimit: freeDailyDivination,
                monthlySWOTLimit: freeMonthlySWOT,
                monthlyMatrixLimit: freeMonthlyMatrix,
                historyRecordsLimit: freeHistoryLimit
            )
        case .proMonthly, .proYearly:
            return UsageQuota(
                dailyDivinationLimit: proDailyDivination,
                monthlySWOTLimit: proMonthlySWOT,
                monthlyMatrixLimit: proMonthlyMatrix,
                historyRecordsLimit: proHistoryLimit
            )
        }
    }
    
    /// 检查是否可以显示订阅引导（冷却时间）
    static func canShowPrompt() -> Bool {
        guard FeatureFlags.enableSubscriptionPrompt else { return false }
        
        if let lastPromptTime = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastPromptTime) as? Date {
            let hoursSinceLastPrompt = Date().timeIntervalSince(lastPromptTime) / 3600
            return hoursSinceLastPrompt >= Double(promptCooldownHours)
        }
        
        return true
    }
    
    /// 记录订阅引导显示时间
    static func markPromptShown() {
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastPromptTime)
    }
    
    /// 检查是否处于限时优惠期
    static func isPromoActive() -> Bool {
        return PromoConfig.enablePromo && Date() < PromoConfig.promoEndDate
    }
}

