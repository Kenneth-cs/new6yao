//
//  AnalyticsManager.swift
//  人生教练
//
//  数据埋点管理器 - 唯一的数据上报出口
//

import Foundation
import UIKit

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private var isEnabled: Bool = false
    private var userProperties: [String: Any] = [:]
    private let userDefaults = UserDefaults.standard
    private let consentKey = "analytics_consent"
    
    #if DEBUG
    private let kApiBase = "http://localhost:3000"
    private let kApiKey = "cplt_f80096991351edc6bce97606bdf9b8c2fa41286e8b59d948c0b146c38e2c6dd1"
    #else
    private let kApiBase = "https://www.superindividual.youqukeji.cn"
    private let kApiKey = "cplt_eaba68f209da8b4c7f3a3db351a13cec41164ebaa536ea66ecb7eef6426da99b"
    #endif
    
    private init() {
        loadConsentState()
        loadUserProperties()
    }
    
    // MARK: - 初始化与授权
    
    func initialize() {
        loadConsentState()
    }
    
    func setEnabled(_ value: Bool) {
        isEnabled = value
        userDefaults.set(value, forKey: consentKey)
        userDefaults.synchronize()
    }
    
    func isEnabledState() -> Bool {
        return isEnabled
    }
    
    private func loadConsentState() {
        isEnabled = userDefaults.bool(forKey: consentKey)
    }
    
    // MARK: - 事件追踪
    
    func track(_ eventId: String, name: String, params: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        var allParams = params
        for (key, value) in userProperties {
            allParams[key] = value
        }
        
        let body: [String: Any] = [
            "projectId": "cmobq4d5g0001q7ggz7i71jjt",
            "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            "eventId": eventId,
            "eventName": name,
            "params": allParams,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "osVersion": UIDevice.current.systemVersion,
            "occurredAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        guard let url = URL(string: "\(kApiBase)/api/events") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(kApiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 埋点上报失败: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ 埋点上报: \(eventId) - 状态码: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // MARK: - 用户属性
    
    func setUserProperty(_ key: String, value: Any) {
        userProperties[key] = value
        saveUserProperties()
    }
    
    func getUserProperty(_ key: String) -> Any? {
        return userProperties[key]
    }
    
    private func loadUserProperties() {
        if let saved = userDefaults.dictionary(forKey: "analytics_user_properties") {
            userProperties = saved
        }
    }
    
    private func saveUserProperties() {
        userDefaults.set(userProperties, forKey: "analytics_user_properties")
        userDefaults.synchronize()
    }
    
    // MARK: - 便捷方法
    
    func trackDivinationStart() {
        track(SubscriptionConfig.AnalyticsEvents.divinationClickStart, name: "点击起卦")
    }
    
    func trackDivinationToss(tossCount: Int) {
        track(SubscriptionConfig.AnalyticsEvents.divinationTossCoin, name: "掷铜钱", params: ["toss_count": tossCount])
    }
    
    func trackDivinationResult(hexagramName: String, waitTimeMs: Int, dailyCurrentCount: Int) {
        track(SubscriptionConfig.AnalyticsEvents.divinationViewResult, name: "查看卦象结果", params: [
            "hexagram_name": hexagramName,
            "wait_time_ms": waitTimeMs,
            "daily_current_count": dailyCurrentCount
        ])
    }
    
    func trackMatrixNew(scenario: String) {
        track(SubscriptionConfig.AnalyticsEvents.matrixClickNew, name: "发起矩阵分析", params: ["scenario": scenario])
    }
    
    func trackDecisionInputBirthday() {
        track(SubscriptionConfig.AnalyticsEvents.decisionInputBirthday, name: "输入生辰日期")
    }
    
    func trackDecisionClickRecalculate() {
        track(SubscriptionConfig.AnalyticsEvents.decisionClickRecalculate, name: "重新推算")
    }
    
    func trackDecisionClickDecide() {
        track(SubscriptionConfig.AnalyticsEvents.decisionClickDecide, name: "点击告诉我纠结")
    }
    
    func trackMatrixSubmit(optionsCount: Int) {
        track(SubscriptionConfig.AnalyticsEvents.matrixSubmit, name: "提交选项分析", params: ["options_count": optionsCount])
    }
    
    func trackMatrixResult(hasVeto: Bool, topScoreLevel: String) {
        track(SubscriptionConfig.AnalyticsEvents.matrixViewResult, name: "查看矩阵结果", params: [
            "has_veto": hasVeto,
            "top_score_level": topScoreLevel
        ])
    }
    
    func trackSwotNew() {
        track(SubscriptionConfig.AnalyticsEvents.swotClickNew, name: "进入SWOT分析页")
    }
    
    func trackSwotSubmit() {
        track(SubscriptionConfig.AnalyticsEvents.swotSubmit, name: "提交SWOT分析")
    }
    
    func trackSwotResult(waitTimeMs: Int) {
        track(SubscriptionConfig.AnalyticsEvents.swotViewResult, name: "查看SWOT结果", params: ["wait_time_ms": waitTimeMs])
    }
    
    func trackLearningViewArticle(articleId: String) {
        track(SubscriptionConfig.AnalyticsEvents.learningViewArticle, name: "浏览学习文章", params: ["article_id": articleId])
    }
    
    func trackProfileViewHistory(recordType: String) {
        track(SubscriptionConfig.AnalyticsEvents.profileViewHistory, name: "查看历史记录", params: ["record_type": recordType])
    }
    
    func trackLimitReachedShow(triggerSource: String) {
        track(SubscriptionConfig.AnalyticsEvents.limitReachedShow, name: "触发次数限制", params: ["trigger_source": triggerSource])
    }
    
    func trackPaywallView(triggerSource: String) {
        track(SubscriptionConfig.AnalyticsEvents.paywallView, name: "浏览订阅详情页", params: ["trigger_source": triggerSource])
    }
    
    func trackPaywallClickBuy(planType: String, price: String) {
        track(SubscriptionConfig.AnalyticsEvents.paywallClickBuy, name: "点击购买按钮", params: [
            "plan_type": planType,
            "price": price
        ])
    }
    
    func trackPaywallPaySuccess(planType: String) {
        track(SubscriptionConfig.AnalyticsEvents.paywallPaySuccess, name: "支付成功", params: ["plan_type": planType])
    }
    
    func trackPaywallRestore() {
        track(SubscriptionConfig.AnalyticsEvents.paywallRestore, name: "恢复购买")
    }
    
    // MARK: - 用户属性更新
    
    func updateSubscriptionStatus(_ status: String) {
        setUserProperty("subscription_status", value: status)
    }
    
    func incrementDivinationCount() {
        let current = userProperties["total_divination_count"] as? Int ?? 0
        setUserProperty("total_divination_count", value: current + 1)
    }
    
    func incrementMatrixCount() {
        let current = userProperties["total_matrix_count"] as? Int ?? 0
        setUserProperty("total_matrix_count", value: current + 1)
    }
    
    func updateDaysSinceInstall() {
        let installDate = userDefaults.object(forKey: "app_install_date") as? Date ?? {
            let now = Date()
            userDefaults.set(now, forKey: "app_install_date")
            return now
        }()
        
        let days = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        setUserProperty("days_since_install", value: days)
    }
}