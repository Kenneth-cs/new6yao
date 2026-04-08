//
//  liuyaoApp.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/8/25.
//

import SwiftUI
import UserNotifications

@main
struct liuyaoApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(notificationManager)
                .onAppear {
                    setupNotifications()
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                UIApplication.shared.applicationIconBadgeNumber = 0
                // App 回到前台：清除已推送的 AI 结果通知（用户已看到）
                AIRequestStateStore.shared.clearDeliveredAINotifications()
            }
        }
    }
    
    private func setupNotifications() {
        // 检查是否已经请求过通知权限
        let hasAskedForNotification = UserDefaults.standard.bool(forKey: "hasAskedForNotification")
        
        if !hasAskedForNotification {
            // 延迟请求，让用户先体验App
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                NotificationManager.shared.requestAuthorization { granted in
                    UserDefaults.standard.set(true, forKey: "hasAskedForNotification")
                    if granted {
                        // 默认开启每日提醒
                        NotificationManager.shared.dailyReminderEnabled = true
                    }
                }
            }
        } else {
            // 已经询问过，只检查状态
            NotificationManager.shared.checkAuthorizationStatus()
        }
    }
}
