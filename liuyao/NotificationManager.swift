//
//  NotificationManager.swift
//  人生教练
//
//  每日通知提醒管理器
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject {
    
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var dailyReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyReminderEnabled, forKey: "dailyReminderEnabled")
            if dailyReminderEnabled {
                scheduleDailyReminder()
            } else {
                cancelDailyReminder()
            }
        }
    }
    
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
            if dailyReminderEnabled {
                scheduleDailyReminder()
            }
        }
    }
    
    // 每日提醒的通知标识符
    private let dailyReminderIdentifier = "com.liuyao.dailyReminder"
    
    // 通知内容配置
    private let dailyMessages: [(title: String, body: String)] = [
        ("🌅 早安，新的一天", "与其等待运势，不如创造顺势。摇一摇，看见当下的力量。"),
        ("💡 每日觉察", "答案不在卦象里，而在你心里。让六爻做你的镜子，照见本心。"),
        ("🌫️ 有些迷茫？", "并不是为了预知未来，而是为了看清现在。摇一摇，换个视角看问题。"),
        ("✨ 相信直觉", "所有的卦象都是内心的投射。摇一摇，找回你内在的确定性。"),
        ("☯️ 顺势而为", "不在逆境中消耗，不在顺境中迷失。理解当下，才能更好地出发。"),
        ("🎯 遇事不决", "困惑的尽头是行动。摇一摇，让古老智慧为你厘清行动的方向。"),
        ("🧘🏻‍♂️ 此刻，向内看", "外部世界喧嚣，内心需要安宁。每日一卦，与潜意识对话。"),
        ("💫 智慧相伴", "看见自己、理解当下。愿六爻不仅是指引，更是陪伴。")
    ]
    
    private override init() {
        // 从UserDefaults读取设置
        self.dailyReminderEnabled = UserDefaults.standard.bool(forKey: "dailyReminderEnabled")
        
        // 默认提醒时间为早上8:30（避开通勤高峰，适合工作前觉察）
        if let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
            self.reminderTime = savedTime
        } else {
            var components = DateComponents()
            components.hour = 8
            components.minute = 30
            self.reminderTime = Calendar.current.date(from: components) ?? Date()
        }
        
        super.init()
        
        // 检查授权状态
        checkAuthorizationStatus()
    }
    
    // MARK: - 权限管理
    
    /// 请求通知权限
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                
                if granted {
                    print("✅ 通知权限已授权")
                    // 如果之前开启了提醒，重新安排
                    if self?.dailyReminderEnabled == true {
                        self?.scheduleDailyReminder()
                    }
                } else {
                    print("❌ 通知权限被拒绝")
                }
                
                if let error = error {
                    print("⚠️ 请求通知权限出错: \(error.localizedDescription)")
                }
                
                completion(granted)
            }
        }
    }
    
    /// 检查授权状态
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// 打开系统设置
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - 每日提醒
    
    /// 安排每日提醒（使用动态文案）
    func scheduleDailyReminder() {
        guard isAuthorized else {
            print("⚠️ 未授权通知权限，无法安排提醒")
            requestAuthorization { [weak self] granted in
                if granted { self?.scheduleDailyReminder() }
            }
            return
        }
        // 取动态文案（有缓存用缓存，否则用本地兜底）
        let svc = DailyNotificationContentService.shared
        let title = svc.cachedTitle
        let body  = svc.cachedBody
        scheduleWith(title: title, body: body)
    }

    /// 用指定文案更新明日通知（AI 生成后调用）
    func updateContent(title: String, body: String) {
        guard dailyReminderEnabled else { return }
        scheduleWith(title: title, body: body)
        print("🔔 通知文案已更新: \(title)")
    }

    /// 内部通用调度
    private func scheduleWith(title: String, body: String) {
        cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "dailyReminder"]

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 安排通知失败: \(error.localizedDescription)")
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                print("✅ 每日提醒已设置：\(formatter.string(from: self.reminderTime))")
            }
        }
    }
    
    /// 取消每日提醒
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        print("🗑️ 每日提醒已取消")
    }
    
    /// 获取下次提醒时间
    func getNextReminderTime(completion: @escaping (Date?) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            if let request = requests.first(where: { $0.identifier == self.dailyReminderIdentifier }),
               let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextDate = trigger.nextTriggerDate() {
                DispatchQueue.main.async {
                    completion(nextDate)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - 即时通知（可选）
    
    /// 发送即时通知（用于测试）
    func sendTestNotification() {
        guard isAuthorized else {
            print("⚠️ 未授权通知权限")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🔔 测试通知"
        content.body = "通知功能正常工作！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "testNotification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 发送测试通知失败: \(error.localizedDescription)")
            } else {
                print("✅ 测试通知将在3秒后发送")
            }
        }
    }
    
    /// 清除所有已显示的通知
    func clearDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - 格式化时间
    
    func formattedReminderTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: reminderTime)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // 当App在前台时收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 即使在前台也显示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    // 用户点击通知时
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String, type == "dailyReminder" {
            // 用户点击了每日提醒通知
            print("📱 用户点击了每日提醒通知")
            // 可以在这里添加跳转到特定页面的逻辑
        }
        
        // 清除角标
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        completionHandler()
    }
}

