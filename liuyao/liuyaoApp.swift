//
//  liuyaoApp.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/8/25.
//

import SwiftUI

@main
struct liuyaoApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()  // 改为新的Tab架构
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
