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

    var isAnnual: Bool {
        return self == .proYearly
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
            return "¥8.25"
        }
    }
    
    var savingsText: String? {
        switch self {
        case .proYearly:
            return "立省¥19.8"
        default:
            return nil
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "摇卦分析：每天 1 次",
                "五行矩阵分析：每天 1 次",
                "SWOT分析：每月 10 次",
                "决策矩阵：每月 10 次",
                "学习中心：完整访问",
                "历史记录：保留 3 条"
            ]
        case .proMonthly, .proYearly:
            return [
                "摇卦分析：无限次数",
                "五行矩阵分析：无限次数",
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
    let dailyFiveElementLimit: Int     // 每日五行决策次数（-1表示无限）
    let monthlyReadingLimit: Int       // 每月专业解读次数（0 = 走每日限额，-1 = 无限）
    let followUpLimit: Int             // 每卦追问上限
    let monthlyMasterGift: Int         // 每月大师赠送次数

    var isUnlimited: Bool {
        return dailyDivinationLimit == -1 &&
               monthlySWOTLimit == -1 &&
               monthlyMatrixLimit == -1 &&
               historyRecordsLimit == -1 &&
               dailyFiveElementLimit == -1
    }

    // 兼容旧版 UserDefaults（无 dailyFiveElementLimit 字段）
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dailyDivinationLimit  = try c.decode(Int.self, forKey: .dailyDivinationLimit)
        monthlySWOTLimit      = try c.decode(Int.self, forKey: .monthlySWOTLimit)
        monthlyMatrixLimit    = try c.decode(Int.self, forKey: .monthlyMatrixLimit)
        historyRecordsLimit   = try c.decode(Int.self, forKey: .historyRecordsLimit)
        dailyFiveElementLimit = try c.decodeIfPresent(Int.self, forKey: .dailyFiveElementLimit) ?? 1
        monthlyReadingLimit   = try c.decodeIfPresent(Int.self, forKey: .monthlyReadingLimit) ?? 0
        followUpLimit         = try c.decodeIfPresent(Int.self, forKey: .followUpLimit) ?? 3
        monthlyMasterGift     = try c.decodeIfPresent(Int.self, forKey: .monthlyMasterGift) ?? 0
    }

    init(dailyDivinationLimit: Int, monthlySWOTLimit: Int,
         monthlyMatrixLimit: Int, historyRecordsLimit: Int,
         dailyFiveElementLimit: Int,
         monthlyReadingLimit: Int = 0,
         followUpLimit: Int = 3,
         monthlyMasterGift: Int = 0) {
        self.dailyDivinationLimit  = dailyDivinationLimit
        self.monthlySWOTLimit      = monthlySWOTLimit
        self.monthlyMatrixLimit    = monthlyMatrixLimit
        self.historyRecordsLimit   = historyRecordsLimit
        self.dailyFiveElementLimit = dailyFiveElementLimit
        self.monthlyReadingLimit   = monthlyReadingLimit
        self.followUpLimit         = followUpLimit
        self.monthlyMasterGift     = monthlyMasterGift
    }

    static var free: UsageQuota {
        return UsageQuota(
            dailyDivinationLimit:  1,
            monthlySWOTLimit:      10,
            monthlyMatrixLimit:    10,
            historyRecordsLimit:   3,
            dailyFiveElementLimit: 1,
            monthlyReadingLimit:   0,
            followUpLimit:         3,
            monthlyMasterGift:     0
        )
    }

    static var pro: UsageQuota {
        return UsageQuota(
            dailyDivinationLimit:  -1,
            monthlySWOTLimit:      -1,
            monthlyMatrixLimit:    -1,
            historyRecordsLimit:   -1,
            dailyFiveElementLimit: -1,
            monthlyReadingLimit:   66,
            followUpLimit:         66,
            monthlyMasterGift:     1
        )
    }
}

// MARK: - 使用统计
struct UsageStatistics: Codable {
    var dailyDivinationCount: Int = 0
    var monthlySWOTCount: Int = 0
    var monthlyMatrixCount: Int = 0
    var totalHistoryRecords: Int = 0
    var dailyFiveElementCount: Int = 0  // 每日五行决策使用次数
    var lifetimeSuccessfulDivinationCount: Int = 0
    var monthlyReadingUsed: Int = 0
    var masterCredits: Int = 0
    var deductionCredits: Int = 0
    var monthlyMasterGiftUsed: Int = 0
    var followUpCountInCurrentReading: Int = 0
    var currentReadingID: String = ""
    var masterUnlockedReadingIDs: [String] = []

    var lastDailyResetDate: Date = Date()
    var lastMonthlyResetDate: Date = Date()

    // 兼容旧版（无 dailyFiveElementCount 字段）
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dailyDivinationCount  = try c.decodeIfPresent(Int.self,  forKey: .dailyDivinationCount)  ?? 0
        monthlySWOTCount      = try c.decodeIfPresent(Int.self,  forKey: .monthlySWOTCount)      ?? 0
        monthlyMatrixCount    = try c.decodeIfPresent(Int.self,  forKey: .monthlyMatrixCount)    ?? 0
        totalHistoryRecords   = try c.decodeIfPresent(Int.self,  forKey: .totalHistoryRecords)   ?? 0
        dailyFiveElementCount = try c.decodeIfPresent(Int.self,  forKey: .dailyFiveElementCount) ?? 0
        lifetimeSuccessfulDivinationCount = try c.decodeIfPresent(Int.self, forKey: .lifetimeSuccessfulDivinationCount) ?? 0
        monthlyReadingUsed    = try c.decodeIfPresent(Int.self, forKey: .monthlyReadingUsed) ?? 0
        masterCredits         = try c.decodeIfPresent(Int.self, forKey: .masterCredits) ?? 0
        deductionCredits      = try c.decodeIfPresent(Int.self, forKey: .deductionCredits) ?? 0
        monthlyMasterGiftUsed = try c.decodeIfPresent(Int.self, forKey: .monthlyMasterGiftUsed) ?? 0
        followUpCountInCurrentReading = try c.decodeIfPresent(Int.self, forKey: .followUpCountInCurrentReading) ?? 0
        currentReadingID      = try c.decodeIfPresent(String.self, forKey: .currentReadingID) ?? ""
        masterUnlockedReadingIDs = try c.decodeIfPresent([String].self, forKey: .masterUnlockedReadingIDs) ?? []
        lastDailyResetDate    = try c.decodeIfPresent(Date.self, forKey: .lastDailyResetDate)    ?? Date()
        lastMonthlyResetDate  = try c.decodeIfPresent(Date.self, forKey: .lastMonthlyResetDate)  ?? Date()
    }

    init() {}

    mutating func resetDaily() {
        dailyDivinationCount  = 0
        dailyFiveElementCount = 0
        lastDailyResetDate = Date()
    }

    mutating func resetMonthly() {
        monthlySWOTCount   = 0
        monthlyMatrixCount = 0
        monthlyReadingUsed = 0
        monthlyMasterGiftUsed = 0
        lastMonthlyResetDate = Date()
    }
    
    func needsDailyReset() -> Bool {
        let calendar = Calendar.current
        return !calendar.isDate(lastDailyResetDate, inSameDayAs: Date())
    }
    
    func needsMonthlyReset() -> Bool {
        let calendar = Calendar.current
        let last = calendar.dateComponents([.year, .month], from: lastMonthlyResetDate)
        let now = calendar.dateComponents([.year, .month], from: Date())
        return last.year != now.year || last.month != now.month
    }
}

struct CloudQuotaSnapshot {
    var masterCredits: Int
    var deductionCredits: Int
    var monthlyReadingUsed: Int
    var monthlyMasterGiftUsed: Int
    var monthlyResetDate: Date
    var masterUnlockedReadingIDs: [String]
    var lastUpdatedAt: Date = .distantPast
}

// MARK: - 功能权限类型
enum FeaturePermission {
    case divination        // 摇卦分析
    case swot              // SWOT分析
    case matrix            // 决策矩阵
    case historyRecords    // 历史记录
    
    var displayName: String {
        switch self {
        case .divination:
            return "摇卦分析"
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
            return "基于六爻框架的AI摇卦分析"
        case .swot:
            return "结构化问题分析工具"
        case .matrix:
            return "多维度选项对比工具"
        case .historyRecords:
            return "保存和查看历史分析记录"
        }
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
            name: "摇卦分析",
            freeDescription: "每天 1 次专业分析",
            proDescription: "无限次数",
            icon: "sparkles"
        ),
        FeatureComparisonItem(
            name: "五行矩阵分析",
            freeDescription: "每天 1 次",
            proDescription: "无限次数",
            icon: "circle.hexagongrid.fill"
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
            freeDescription: "保留 3 条",
            proDescription: "无限保存",
            icon: "clock.arrow.circlepath"
        )
    ]
}

