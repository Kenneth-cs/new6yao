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
        if !UserDefaults.standard.bool(forKey: "analytics_consent_has_set") {
            UserDefaults.standard.set(true, forKey: "analytics_consent")
            UserDefaults.standard.set(true, forKey: "analytics_consent_has_set")
        }
        AnalyticsManager.shared.initialize()
        
        // 触发一次 CloudKit 配置拉取
        _ = ConfigManager.shared
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
                AIRequestStateStore.shared.clearDeliveredAINotifications()
                AnalyticsManager.shared.updateDaysSinceInstall()
            }
        }
    }
    
    private func setupNotifications() {
        let hasAskedForNotification = UserDefaults.standard.bool(forKey: "hasAskedForNotification")
        
        if !hasAskedForNotification {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                NotificationManager.shared.requestAuthorization { granted in
                    UserDefaults.standard.set(true, forKey: "hasAskedForNotification")
                    if granted {
                        NotificationManager.shared.dailyReminderEnabled = true
                    }
                }
            }
        } else {
            NotificationManager.shared.checkAuthorizationStatus()
        }
    }
}
