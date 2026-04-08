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
    
    // 每日提醒通知 identifier 前缀，每天一条：前缀 + yyyyMMdd
    private let dailyReminderPrefix = "com.liuyao.dailyReminder."
    
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

    /// 开关或时间变更时调用：重新触发预调度
    func scheduleDailyReminder() {
        guard isAuthorized else {
            requestAuthorization { [weak self] granted in
                if granted { self?.scheduleDailyReminder() }
            }
            return
        }
        // 重置预调度日期标记，让 refreshIfNeeded 重新执行
        UserDefaults.standard.removeObject(forKey: "notif_last_schedule_date")
        DailyNotificationContentService.shared.refreshIfNeeded()
    }

    /// 为指定日期调度一条一次性通知（由 DailyNotificationContentService 调用）
    func scheduleOnceFor(date: Date, title: String, body: String) {
        guard dailyReminderEnabled else { return }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd"
        let identifier = dailyReminderPrefix + fmt.string(from: date)

        let content = UNMutableNotificationContent()
        content.title    = title
        content.body     = body
        content.sound    = .default
        content.badge    = 1
        content.userInfo = ["type": "dailyReminder"]

        // 取用户设定的时分，拼上目标日期
        let timeParts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        var dc = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dc.hour   = timeParts.hour
        dc.minute = timeParts.minute
        dc.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        let request  = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // 先移除同一天旧的，再添加新的（用于 AI 替换预设）
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 调度通知失败(\(identifier)): \(error.localizedDescription)")
            } else {
                let fmt2 = DateFormatter(); fmt2.dateFormat = "MM-dd HH:mm"
                if let next = trigger.nextTriggerDate() {
                    print("✅ 通知已调度: \(title) → \(fmt2.string(from: next))")
                }
            }
        }
    }

    /// 取消所有每日提醒（前缀匹配）
    func cancelAllDailyReminders() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(self.dailyReminderPrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
            print("🗑️ 已取消 \(ids.count) 条旧提醒")
        }
    }

    /// 兼容旧调用（开关关闭时）
    func cancelDailyReminder() {
        cancelAllDailyReminders()
    }

    /// 获取下次提醒时间（取 pending 中最早触发的）
    func getNextReminderTime(completion: @escaping (Date?) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self else { completion(nil); return }
            let next = requests
                .filter { $0.identifier.hasPrefix(self.dailyReminderPrefix) }
                .compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
                .min()
            DispatchQueue.main.async { completion(next) }
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

