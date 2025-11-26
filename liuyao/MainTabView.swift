//
//  MainTabView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  六爻智卦 2.0 - 主Tab视图
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0  // 默认选中"学习"tab
    
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
            
            // Tab 3: 决策分析（原问卦功能）
            NavigationStack {
                DecisionAnalysisView()
            }
            .tabItem {
                Label("决策", systemImage: "sparkles")
            }
            .tag(2)
            
            // Tab 4: 成长档案
            NavigationStack {
                GrowthProfileView()
            }
            .tabItem {
                Label("成长", systemImage: "chart.line.uptrend.xyaxis")
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

