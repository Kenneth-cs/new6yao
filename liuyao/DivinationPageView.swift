import SwiftUI
import Foundation
import CoreLocation

struct DivinationPageView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var question = ""
    @State private var divinationStartTime: Date?
    @State private var showEmptyAlert = false
    @State private var showSubscriptionPrompt = false
    @State private var showLimitReached = false
    @State private var navigateToCoinToss = false
    let currentTime: Date
    let locationManager: LocationManager
    let defaultQuestion: String?
    
    private let maxLength = 500
    
    init(currentTime: Date, locationManager: LocationManager, defaultQuestion: String? = nil) {
        self.currentTime = currentTime
        self.locationManager = locationManager
        self.defaultQuestion = defaultQuestion
    }
    
    var body: some View {
        ZStack {
            // 背景 - 紫色主题
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.08),
                    Color.indigo.opacity(0.05),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 标题
                VStack(spacing: 8) {
                    Text("理清思路，明智决策")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .indigo]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("请输入你想要分析的问题")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // 问题输入区域
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("你的问题")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(question.count)/\(maxLength)")
                            .font(.caption)
                            .foregroundColor(question.count > maxLength * 9 / 10 ? .red : .secondary)
                    }
                    
                    TextField("例如：是否应该换工作？创业的时机到了吗？", text: $question, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                        .font(.body)
                        .onChange(of: question) { newValue in
                            if newValue.count > maxLength {
                                question = String(newValue.prefix(maxLength))
                            }
                        }
                    
                    if question.isEmpty {
                        Text("💡 提示：请输入你想要深入分析的决策问题")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 20)
                
                // 剩余次数提示（仅免费版显示）
                if !permissionManager.currentTier.isPro {
                    let remaining = permissionManager.getDailyDivinationRemaining()
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("今日还剩 \(remaining) 次免费分析")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: {
                            showSubscriptionPrompt = true
                        }) {
                            Text("升级")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                
                // 开始分析按钮
                Button(action: {
                    checkPermissionAndNavigate()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("开始分析")
                        Image(systemName: "sparkles")
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 40)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .indigo]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .disabled(question.isEmpty && defaultQuestion == nil)
                .opacity((question.isEmpty && defaultQuestion == nil) ? 0.6 : 1.0)
                .simultaneousGesture(TapGesture().onEnded {
                    divinationStartTime = Date()
                })
                
                Spacer()
                
                // 提示信息
                VStack(spacing: 8) {
                    Text("💡 提示")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("问题越具体，分析越准确\n建议以疑问句的形式提问")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("输入问题")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToCoinToss) {
            CoinTossPageView(
                question: question.isEmpty ? (defaultQuestion ?? "") : question,
                currentTime: divinationStartTime ?? currentTime,
                locationManager: locationManager
            )
        }
        .sheet(isPresented: $showSubscriptionPrompt) {
            SubscriptionPromptView(
                isPresented: $showSubscriptionPrompt,
                trigger: .dailyLimitReached
            )
        }
        .sheet(isPresented: $showLimitReached) {
            LimitReachedView(
                limitType: .dailyDivination,
                remaining: permissionManager.getDailyDivinationRemaining(),
                resetTime: Calendar.current.date(byAdding: .day, value: 1, to: Date())
            )
        }
        .alert("请输入问题", isPresented: $showEmptyAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("请输入你想要分析的问题后再开始")
        }
        .onAppear {
            if let defaultQ = defaultQuestion {
                question = defaultQ
            }
        }
    }
    
    // MARK: - 权限检查与导航
    
    private func checkPermissionAndNavigate() {
        // 检查问题是否为空
        if question.isEmpty && defaultQuestion == nil {
            showEmptyAlert = true
            return
        }
        
        // 检查使用权限
        if permissionManager.canUseDivination() {
            // 有权限，增加计数并导航
            navigateToCoinToss = true
        } else {
            // 无权限，显示限制提示
            showLimitReached = true
        }
    }
}