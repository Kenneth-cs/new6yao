//
//  SubscriptionModels.swift
//  人生教练
//
//  订阅相关数据模型
//

import Foundation
import StoreKit

// MARK: - 订阅层级枚举
enum SubscriptionTier: String, Codable {
    case free = "free"
    case proMonthly = "pro_monthly"
    case proYearly = "pro_yearly"
    
    var displayName: String {
        switch self {
        case .free:
            return "免费版"
        case .proMonthly:
            return "专业版（月付）"
        case .proYearly:
            return "专业版（年付）"
        }
    }
    
    var shortName: String {
        switch self {
        case .free:
            return "免费版"
        case .proMonthly, .proYearly:
            return "专业版"
        }
    }
    
    var isPro: Bool {
        return self == .proMonthly || self == .proYearly
    }
    
    var price: String {
        switch self {
        case .free:
            return "免费"
        case .proMonthly:
            return "¥9.9/月"
        case .proYearly:
            return "¥99/年"
        }
    }
    
    var pricePerMonth: String {
        switch self {
        case .free:
            return "¥0"
        case .proMonthly:
            return "¥9.9"
        case .proYearly:
            return "¥8.25" // 99/12 = 8.25
        }
    }
    
    var savingsText: String? {
        switch self {
        case .proYearly:
            return "相当于免费送2个月"
        default:
            return nil
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "决策分析：每天 1 次",
                "SWOT分析：每月 10 次",
                "决策矩阵：每月 10 次",
                "学习中心：完整访问",
                "历史记录：保留 10 条"
            ]
        case .proMonthly, .proYearly:
            return [
                "决策分析：无限次数",
                "SWOT分析：无限次数",
                "决策矩阵：无限次数",
                "学习中心：完整访问",
                "历史记录：无限保存"
            ]
        }
    }
    
    var badge: String? {
        switch self {
        case .proYearly:
            return "最超值"
        case .proMonthly:
            return "推荐"
        case .free:
            return nil
        }
    }
    
    var badgeColor: String {
        switch self {
        case .proYearly:
            return "orange"
        case .proMonthly:
            return "purple"
        case .free:
            return "gray"
        }
    }
}

// MARK: - 订阅状态
struct SubscriptionStatus: Codable {
    let tier: SubscriptionTier
    let isActive: Bool
    let expirationDate: Date?
    let autoRenewing: Bool
    let originalPurchaseDate: Date?
    
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
    
    var daysRemaining: Int? {
        guard let expirationDate = expirationDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return components.day
    }
    
    var formattedExpirationDate: String {
        guard let expirationDate = expirationDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: expirationDate)
    }
    
    var statusText: String {
        if !isActive {
            return "未订阅"
        }
        
        if tier.isPro {
            if autoRenewing {
                return "已订阅 · 自动续费"
            } else {
                if let days = daysRemaining {
                    return "已订阅 · 还剩\(days)天"
                }
                return "已订阅"
            }
        }
        
        return "免费版"
    }
}

// MARK: - 使用配额
struct UsageQuota: Codable {
    let dailyDivinationLimit: Int      // 每日问卦次数（-1表示无限）
    let monthlySWOTLimit: Int          // 每月SWOT次数（-1表示无限）
    let monthlyMatrixLimit: Int        // 每月决策矩阵次数（-1表示无限）
    let historyRecordsLimit: Int       // 历史记录保留数量（-1表示无限）
    
    var isUnlimited: Bool {
        return dailyDivinationLimit == -1 &&
               monthlySWOTLimit == -1 &&
               monthlyMatrixLimit == -1 &&
               historyRecordsLimit == -1
    }
    
    static var free: UsageQuota {
        return UsageQuota(
            dailyDivinationLimit: 1,
            monthlySWOTLimit: 10,
            monthlyMatrixLimit: 10,
            historyRecordsLimit: 10
        )
    }
    
    static var pro: UsageQuota {
        return UsageQuota(
            dailyDivinationLimit: -1,
            monthlySWOTLimit: -1,
            monthlyMatrixLimit: -1,
            historyRecordsLimit: -1
        )
    }
}

// MARK: - 使用统计
struct UsageStatistics: Codable {
    var dailyDivinationCount: Int = 0
    var monthlySWOTCount: Int = 0
    var monthlyMatrixCount: Int = 0
    var totalHistoryRecords: Int = 0
    
    var lastDailyResetDate: Date = Date()
    var lastMonthlyResetDate: Date = Date()
    
    mutating func resetDaily() {
        dailyDivinationCount = 0
        lastDailyResetDate = Date()
    }
    
    mutating func resetMonthly() {
        monthlySWOTCount = 0
        monthlyMatrixCount = 0
        lastMonthlyResetDate = Date()
    }
    
    func needsDailyReset() -> Bool {
        let calendar = Calendar.current
        return !calendar.isDate(lastDailyResetDate, inSameDayAs: Date())
    }
    
    func needsMonthlyReset() -> Bool {
        let calendar = Calendar.current
        let lastMonth = calendar.component(.month, from: lastMonthlyResetDate)
        let currentMonth = calendar.component(.month, from: Date())
        return lastMonth != currentMonth
    }
}

// MARK: - 功能权限类型
enum FeaturePermission {
    case divination        // 决策分析
    case swot              // SWOT分析
    case matrix            // 决策矩阵
    case historyRecords    // 历史记录
    
    var displayName: String {
        switch self {
        case .divination:
            return "决策分析"
        case .swot:
            return "SWOT分析"
        case .matrix:
            return "决策矩阵"
        case .historyRecords:
            return "历史记录"
        }
    }
    
    var icon: String {
        switch self {
        case .divination:
            return "sparkles"
        case .swot:
            return "square.grid.2x2"
        case .matrix:
            return "tablecells"
        case .historyRecords:
            return "clock.arrow.circlepath"
        }
    }
    
    var description: String {
        switch self {
        case .divination:
            return "基于六爻框架的AI决策分析"
        case .swot:
            return "结构化问题分析工具"
        case .matrix:
            return "多维度选项对比工具"
        case .historyRecords:
            return "保存和查看历史分析记录"
        }
    }
}

// MARK: - 订阅引导触发场景
enum SubscriptionPromptTrigger {
    case dailyLimitReached           // 每日问卦次数用完
    case swotLimitReached            // SWOT次数用完
    case matrixLimitReached          // 决策矩阵次数用完
    case historyLimitReached         // 历史记录已满
    case manualUpgrade               // 用户主动点击升级
    
    var title: String {
        switch self {
        case .dailyLimitReached:
            return "今日分析次数已用完"
        case .swotLimitReached:
            return "本月SWOT分析次数已用完"
        case .matrixLimitReached:
            return "本月决策矩阵次数已用完"
        case .historyLimitReached:
            return "历史记录已达上限"
        case .manualUpgrade:
            return "升级专业版，解锁完整功能"
        }
    }
    
    var message: String {
        switch self {
        case .dailyLimitReached:
            return "升级专业版，享受无限次AI决策分析"
        case .swotLimitReached:
            return "升级专业版，无限使用SWOT分析工具"
        case .matrixLimitReached:
            return "升级专业版，无限使用决策矩阵工具"
        case .historyLimitReached:
            return "升级专业版，无限保存历史记录"
        case .manualUpgrade:
            return "每天一杯咖啡的价格，换来清晰的人生方向"
        }
    }
    
    var actionText: String {
        return "立即升级"
    }
}

// MARK: - 功能对比项
struct FeatureComparisonItem {
    let name: String
    let freeDescription: String
    let proDescription: String
    let icon: String
    
    var isAvailableForFree: Bool {
        return freeDescription != "❌" && !freeDescription.isEmpty
    }
    
    var isAvailableForPro: Bool {
        return proDescription != "❌" && !proDescription.isEmpty
    }
}

extension FeatureComparisonItem {
    static let allFeatures: [FeatureComparisonItem] = [
        FeatureComparisonItem(
            name: "决策分析",
            freeDescription: "每天 1 次",
            proDescription: "无限次数",
            icon: "sparkles"
        ),
        FeatureComparisonItem(
            name: "SWOT分析",
            freeDescription: "每月 10 次",
            proDescription: "无限次数",
            icon: "square.grid.2x2"
        ),
        FeatureComparisonItem(
            name: "决策矩阵",
            freeDescription: "每月 10 次",
            proDescription: "无限次数",
            icon: "tablecells"
        ),
        FeatureComparisonItem(
            name: "学习中心",
            freeDescription: "完整访问",
            proDescription: "完整访问",
            icon: "book.fill"
        ),
        FeatureComparisonItem(
            name: "历史记录",
            freeDescription: "保留 10 条",
            proDescription: "无限保存",
            icon: "clock.arrow.circlepath"
        )
    ]
}

