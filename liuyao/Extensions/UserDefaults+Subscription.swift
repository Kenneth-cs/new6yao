//
//  UserDefaults+Subscription.swift
//  人生教练
//
//  UserDefaults 扩展 - 订阅相关
//

import Foundation

extension UserDefaults {
    
    // MARK: - 订阅状态相关
    
    /// 获取当前订阅层级
    var subscriptionTier: SubscriptionTier {
        get {
            if let tierString = string(forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionTier),
               let tier = SubscriptionTier(rawValue: tierString) {
                return tier
            }
            return .free
        }
        set {
            set(newValue.rawValue, forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionTier)
        }
    }
    
    /// 获取订阅状态
    var subscriptionStatus: SubscriptionStatus? {
        get {
            guard let data = data(forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionStatus),
                  let status = try? JSONDecoder().decode(SubscriptionStatus.self, from: data) else {
                return nil
            }
            return status
        }
        set {
            if let status = newValue,
               let encoded = try? JSONEncoder().encode(status) {
                set(encoded, forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionStatus)
            } else {
                removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionStatus)
            }
        }
    }
    
    /// 获取使用统计数据
    var usageStatistics: UsageStatistics {
        get {
            guard let data = data(forKey: SubscriptionConfig.UserDefaultsKeys.usageStatistics),
                  let stats = try? JSONDecoder().decode(UsageStatistics.self, from: data) else {
                return UsageStatistics()
            }
            return stats
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                set(encoded, forKey: SubscriptionConfig.UserDefaultsKeys.usageStatistics)
            }
        }
    }
    
    // MARK: - 订阅引导相关
    
    /// 上次显示订阅引导的时间
    var lastSubscriptionPromptTime: Date? {
        get {
            return object(forKey: SubscriptionConfig.UserDefaultsKeys.lastPromptTime) as? Date
        }
        set {
            set(newValue, forKey: SubscriptionConfig.UserDefaultsKeys.lastPromptTime)
        }
    }
    
    /// 是否已显示过订阅介绍
    var hasShownSubscriptionIntroduction: Bool {
        get {
            return bool(forKey: SubscriptionConfig.UserDefaultsKeys.hasShownIntroduction)
        }
        set {
            set(newValue, forKey: SubscriptionConfig.UserDefaultsKeys.hasShownIntroduction)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 检查是否可以显示订阅引导（基于冷却时间）
    func canShowSubscriptionPrompt() -> Bool {
        guard let lastTime = lastSubscriptionPromptTime else {
            return true
        }
        
        let hoursSinceLast = Date().timeIntervalSince(lastTime) / 3600
        return hoursSinceLast >= Double(SubscriptionConfig.promptCooldownHours)
    }
    
    /// 标记订阅引导已显示
    func markSubscriptionPromptShown() {
        lastSubscriptionPromptTime = Date()
    }
    
    /// 是否为专业版用户
    var isPro: Bool {
        return subscriptionTier.isPro
    }
    
    /// 清除所有订阅相关数据（仅用于测试）
    func clearSubscriptionData() {
        removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionTier)
        removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.subscriptionStatus)
        removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.usageStatistics)
        removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.lastPromptTime)
        removeObject(forKey: SubscriptionConfig.UserDefaultsKeys.hasShownIntroduction)
    }
}

// MARK: - 使用示例

/*
 
 // 读取订阅层级
 let tier = UserDefaults.standard.subscriptionTier
 print("当前订阅层级：\(tier.displayName)")
 
 // 更新订阅层级
 UserDefaults.standard.subscriptionTier = .proMonthly
 
 // 读取订阅状态
 if let status = UserDefaults.standard.subscriptionStatus {
     print("订阅状态：\(status.statusText)")
 }
 
 // 检查是否可以显示引导
 if UserDefaults.standard.canShowSubscriptionPrompt() {
     // 显示订阅引导
     UserDefaults.standard.markSubscriptionPromptShown()
 }
 
 // 检查是否为专业版
 if UserDefaults.standard.isPro {
     print("专业版用户")
 }
 
 */

