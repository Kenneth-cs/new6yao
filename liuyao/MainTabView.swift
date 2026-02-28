//
//  MainTabView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  人生教练 - 主Tab视图
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 2  // 默认选中"决策"tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: 学习中心
            NavigationStack {
                LearningCenterView()
            }
            .tabItem {
                Label("学习", systemImage: "book.fill")
            }
            .tag(0)
            
            // Tab 2: 思维工具
            NavigationStack {
                ThinkingToolsView()
            }
            .tabItem {
                Label("思考", systemImage: "brain.head.profile")
            }
            .tag(1)
            
            // Tab 3: 摇卦（原决策分析）
            NavigationStack {
                DecisionAnalysisView()
            }
            .tabItem {
                Label {
                    Text("摇卦")
                } icon: {
                    Image("tab-hexagram")
                }
            }
            .tag(2)
            
            // Tab 4: 决策矩阵
            NavigationStack {
                EnergyPortraitView()
            }
            .tabItem {
                Label {
                    Text("决策")
                } icon: {
                    Image("tab-yinyang")
                }
            }
            .tag(3)
            
            // Tab 5: 个人中心
            NavigationStack {
                ProfileCenterView()
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(4)
        }
        .tint(.purple)  // Tab选中颜色
    }
}

#Preview {
    MainTabView()
}

