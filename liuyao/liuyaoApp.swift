//
//  liuyaoApp.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/8/25.
//

import SwiftUI
import UIKit
import UserNotifications

@main
struct liuyaoApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        ChineseNavigationBack.install()
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        if !UserDefaults.standard.bool(forKey: "analytics_consent_has_set") {
            UserDefaults.standard.set(true, forKey: "analytics_consent")
            UserDefaults.standard.set(true, forKey: "analytics_consent_has_set")
        }
        AnalyticsManager.shared.initialize()
        
        // 触发一次 CloudKit 配置拉取，并立刻核对订阅，不等进入「我的」。
        _ = ConfigManager.shared
        Task { @MainActor in
            _ = SubscriptionService.shared
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.light)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(notificationManager)
                .onAppear {
                    setupNotifications()
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    Task { await CloudKitSyncManager.shared.syncOnLaunch() }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                UIApplication.shared.applicationIconBadgeNumber = 0
                AIRequestStateStore.shared.clearDeliveredAINotifications()
                AnalyticsManager.shared.updateDaysSinceInstall()
                Task { await CloudKitSyncManager.shared.syncOnLaunch() }
                Task { await SubscriptionService.shared.checkSubscriptionStatus() }
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

/// 上一页没有标题时，系统返回按钮会按开发语言显示。强制写成「返回」。
private enum ChineseNavigationBack {
    private static var didInstall = false

    static func install() {
        guard !didInstall else { return }
        didInstall = true
        let cls: AnyClass = UINavigationController.self
        let original = #selector(UINavigationController.pushViewController(_:animated:))
        let swizzled = #selector(UINavigationController.liuyao_pushViewController(_:animated:))
        guard let originalMethod = class_getInstanceMethod(cls, original),
              let swizzledMethod = class_getInstanceMethod(cls, swizzled) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension UINavigationController {
    @objc func liuyao_pushViewController(_ viewController: UIViewController, animated: Bool) {
        topViewController?.navigationItem.backButtonTitle = "返回"
        liuyao_pushViewController(viewController, animated: animated)
    }
}
