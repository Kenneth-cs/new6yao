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

    // MARK: - 用户定位缓存（由 LocationManager 同步）
    private var cachedLatitude: Double?
    private var cachedLongitude: Double?
    private var cachedCity: String?
    
    private let kApiBase = "https://www.superindividual.originapex.cn"
    private let kApiKey = "cplt_eaba68f209da8b4c7f3a3db351a13cec41164ebaa536ea66ecb7eef6426da99b"
    
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
    
    /// 由 LocationManager 调用，同步定位到埋点缓存
    func updateLocation(latitude: Double, longitude: Double, city: String) {
        cachedLatitude = latitude
        cachedLongitude = longitude
        cachedCity = city
        setUserProperty("user_latitude", value: latitude)
        setUserProperty("user_longitude", value: longitude)
        setUserProperty("user_city", value: city)
    }

    func track(_ eventId: String, name: String, params: [String: Any] = [:]) {
        guard isEnabled else { return }

        var allParams = params
        for (key, value) in userProperties {
            allParams[key] = value
        }

        // 自动注入定位参数（如有）
        if let lat = cachedLatitude { allParams["user_latitude"] = lat }
        if let lng = cachedLongitude { allParams["user_longitude"] = lng }
        if let city = cachedCity { allParams["user_city"] = city }
        
        let body: [String: Any] = [
            "projectId": "cmo9rslbz0001p6ialtgfhlv5",
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
    
    func trackDivinationResult(hexagramName: String, waitTimeMs: Int, dailyCurrentCount: Int, userQuestion: String? = nil, aiInterpretation: String? = nil, extras: [String: Any] = [:]) {
        let requestId = extras["request_id"] as? String
        guard shouldReportFirstSuccess(requestId: requestId) else { return }
        var params: [String: Any] = [
            "hexagram_name": hexagramName,
            "wait_time_ms": waitTimeMs,
            "daily_current_count": dailyCurrentCount,
            "is_first_success": true
        ]
        if let requestId { params["request_id"] = requestId }
        if let q = userQuestion { params["user_question"] = q }
        if let a = aiInterpretation { params["ai_interpretation"] = a }
        for (key, value) in extras {
            params[key] = value
        }
        track(SubscriptionConfig.AnalyticsEvents.divinationViewResult, name: "查看卦象结果", params: params)
    }

    func trackDivinationFail(requestId: String, errorCode: Int, waitTimeMs: Int) {
        track(SubscriptionConfig.AnalyticsEvents.divinationFail, name: "解卦失败", params: [
            "request_id": requestId,
            "error_code": errorCode,
            "wait_time_ms": waitTimeMs
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
    
    func trackMatrixSubmit(optionsCount: Int, requestId: String) {
        track(SubscriptionConfig.AnalyticsEvents.matrixSubmit, name: "提交选项分析", params: [
            "options_count": optionsCount,
            "request_id": requestId
        ])
    }
    
    func trackMatrixResult(hasVeto: Bool, topScoreLevel: String, userQuestion: String? = nil, aiResult: String? = nil, requestId: String, waitTimeMs: Int) {
        guard shouldReportFirstSuccess(requestId: requestId) else { return }
        var params: [String: Any] = [
            "has_veto": hasVeto,
            "top_score_level": topScoreLevel,
            "request_id": requestId,
            "wait_time_ms": waitTimeMs,
            "is_first_success": true
        ]
        if let q = userQuestion { params["user_question"] = q }
        if let a = aiResult { params["ai_result"] = a }
        track(SubscriptionConfig.AnalyticsEvents.matrixViewResult, name: "查看矩阵结果", params: params)
    }

    func trackMatrixFail(requestId: String, errorCode: Int, waitTimeMs: Int) {
        track(SubscriptionConfig.AnalyticsEvents.matrixFail, name: "矩阵分析失败", params: [
            "request_id": requestId,
            "error_code": errorCode,
            "wait_time_ms": waitTimeMs
        ])
    }

    func trackDecisionSubmit(requestId: String, optionsCount: Int) {
        track(SubscriptionConfig.AnalyticsEvents.decisionSubmit, name: "提交五行决策", params: [
            "request_id": requestId,
            "options_count": optionsCount
        ])
    }

    func trackDecisionResult(hasVeto: Bool, topScoreLevel: String, userQuestion: String? = nil, aiResult: String? = nil, requestId: String, waitTimeMs: Int) {
        guard shouldReportFirstSuccess(requestId: requestId) else { return }
        var params: [String: Any] = [
            "has_veto": hasVeto,
            "top_score_level": topScoreLevel,
            "request_id": requestId,
            "wait_time_ms": waitTimeMs,
            "is_first_success": true
        ]
        if let q = userQuestion { params["user_question"] = q }
        if let a = aiResult { params["ai_result"] = a }
        track(SubscriptionConfig.AnalyticsEvents.decisionViewResult, name: "查看五行决策结果", params: params)
        incrementDecisionCount()
    }

    func trackDecisionFail(requestId: String, errorCode: Int, waitTimeMs: Int) {
        track(SubscriptionConfig.AnalyticsEvents.decisionFail, name: "五行决策失败", params: [
            "request_id": requestId,
            "error_code": errorCode,
            "wait_time_ms": waitTimeMs
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

    func incrementDecisionCount() {
        let current = userProperties["total_decision_count"] as? Int ?? 0
        setUserProperty("total_decision_count", value: current + 1)
    }

    func incrementSwotCount() {
        let current = userProperties["total_swot_count"] as? Int ?? 0
        setUserProperty("total_swot_count", value: current + 1)
    }
    
    private let reportedSuccessIdsKey = "analytics_success_request_ids"

    private func shouldReportFirstSuccess(requestId: String?) -> Bool {
        guard let requestId, !requestId.isEmpty else { return true }
        var ids = userDefaults.stringArray(forKey: reportedSuccessIdsKey) ?? []
        if ids.contains(requestId) { return false }
        ids.append(requestId)
        if ids.count > 300 {
            ids = Array(ids.suffix(300))
        }
        userDefaults.set(ids, forKey: reportedSuccessIdsKey)
        return true
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