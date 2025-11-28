//
//  DecisionAnalysisView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  决策分析 - Tab 3（原问卦功能）
//

import SwiftUI
import CoreLocation

struct DecisionAnalysisView: View {
    @State private var currentTime = Date()
    @StateObject private var locationManager = LocationManager()
    @State private var showMethodology = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        return formatter
    }()
    
    // iPad适配
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.15),
                    Color.indigo.opacity(0.1),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: isIPad ? 40 : 30) {
                    // 标题区域
                    headerSection
                    
                    // 中央决策分析区域（原问卦区域）
                    analysisSection
                    
                    // 快捷场景（原示例问题）
                    quickScenariosSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("决策分析")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showMethodology = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.purple)
                }
            }
        }
        .sheet(isPresented: $showMethodology) {
            MethodologyView()
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - 子视图
    
    private var headerSection: some View {
        VStack(spacing: isIPad ? 24 : 16) {
            Text("决策分析")
                .font(isIPad ? .system(size: 48, weight: .bold) : .largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .indigo]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("基于六爻框架的AI分析")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            // 时间和地点信息
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.purple.opacity(0.7))
                        .font(.caption)
                    Text("分析时刻")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    Text("(时间维度影响分析角度)")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                        .italic()
                }
                
                Text(timeFormatter.string(from: currentTime))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.purple.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                            )
                    )
            }
            
            // 地点显示
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .foregroundColor(.purple.opacity(0.6))
                    .font(.caption)
                Text(locationManager.currentCity)
                    .font(.caption)
                    .foregroundColor(.purple.opacity(0.8))
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.8))
                    .overlay(
                        Capsule()
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
            )
            .onTapGesture {
                locationManager.requestLocation()
            }
            
            Text("多维度分析 · 理性决策")
                .font(.title3)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
    
    private var analysisSection: some View {
        VStack(spacing: 24) {
            // 主要分析按钮
            NavigationLink(destination: DivinationPageView(
                currentTime: currentTime,
                locationManager: locationManager
            )) {
                VStack(spacing: 16) {
                    // 分析图标（改用紫色系，淡化铜钱概念）
                    ZStack {
                        // 外圈光晕
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.3),
                                        Color.indigo.opacity(0.1)
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        // 主图标
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.purple.opacity(0.9),
                                            Color.indigo.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: isIPad ? 110 : 80, height: isIPad ? 110 : 80)
                                .shadow(color: .purple.opacity(0.4), radius: 8, x: 2, y: 4)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: isIPad ? 40 : 32))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text("开始深度分析")
                        .font(isIPad ? .title : .title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("基于六爻框架 × AI智能分析")
                        .font(isIPad ? .body : .caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, isIPad ? 40 : 30)
                .padding(.horizontal, isIPad ? 60 : 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .purple.opacity(0.2), radius: 15, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple.opacity(0.3), .indigo.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var quickScenariosSection: some View {
        VStack(spacing: 12) {
            Text("常见决策场景")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach([
                    ("工作发展", "briefcase.fill", "我的职业发展如何规划？"),
                    ("感情问题", "heart.fill", "这段关系该如何处理？"),
                    ("学习成长", "book.fill", "当前的学习方向对吗？"),
                    ("投资理财", "dollarsign.circle.fill", "这个投资决策是否合适？")
                ], id: \.0) { scenario in
                    NavigationLink(destination: DivinationPageView(
                        currentTime: currentTime,
                        locationManager: locationManager,
                        defaultQuestion: scenario.2
                    )) {
                        HStack(spacing: 8) {
                            Image(systemName: scenario.1)
                                .foregroundColor(.purple)
                                .font(.body)
                            Text(scenario.0)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DecisionAnalysisView()
    }
}

