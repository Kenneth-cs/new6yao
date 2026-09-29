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
    let categoryHint: String?
    @State private var effectiveCategoryHint: String?
    
    private let maxLength = 500
    
    init(currentTime: Date, locationManager: LocationManager, defaultQuestion: String? = nil, categoryHint: String? = nil) {
        self.currentTime = currentTime
        self.locationManager = locationManager
        self.defaultQuestion = defaultQuestion
        self.categoryHint = categoryHint
        _effectiveCategoryHint = State(initialValue: categoryHint)
    }
    
    private let hotTopics: [(icon: String, title: String, question: String)] = [
        ("briefcase.fill", "事业发展", "我现在适合换工作吗？"),
        ("heart.fill", "感情关系", "这段感情还值得继续吗？"),
        ("banknote.fill", "财运状况", "我现在适合做一笔较大的投资吗？"),
        ("leaf.fill", "健康运势", "我最近的身体状况需要注意什么？")
    ]

    private let accent = Color(red: 168.0 / 255, green: 85.0 / 255, blue: 235.0 / 255)

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("心有所问，\n卦有所答")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(ProfilePalette.ink)
                        .lineSpacing(2)
                    Text("请输入你想咨询的问题")
                        .font(.system(size: 15))
                        .foregroundColor(ProfilePalette.muted)
                }
                .padding(.leading, 22)

                questionCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipped()
        .scrollDismissesKeyboard(.interactively)
        .profileHidesTopScrollEdge()
        .background {
            Image("QuestionBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .navigationTitle("输入问题")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToCoinToss) {
            CoinTossPageView(
                question: question.isEmpty ? (defaultQuestion ?? "") : question,
                currentTime: divinationStartTime ?? currentTime,
                locationManager: locationManager,
                categoryHint: effectiveCategoryHint
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
        .onChange(of: question) { newValue in
            if newValue.count > maxLength {
                question = String(newValue.prefix(maxLength))
                return
            }
            guard let original = defaultQuestion else { return }
            effectiveCategoryHint = newValue == original ? categoryHint : nil
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            questionEditor
            hotTopicSection
            if !permissionManager.currentTier.isPro {
                quotaRow
            }
            startButton
            tipRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: ProfilePalette.cardShadow, radius: 16, y: 6)
        )
    }

    private var questionEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accent)
                Text("你的问题")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                Spacer()
                Text("\(question.count)/\(maxLength)")
                    .font(.system(size: 12))
                    .foregroundColor(question.count > maxLength * 9 / 10 ? .red : ProfilePalette.faint)
            }

            ZStack(alignment: .topLeading) {
                if question.isEmpty {
                    Text("例如：我们这段感情会有结果吗？")
                        .font(.system(size: 15))
                        .foregroundColor(ProfilePalette.faint)
                        .lineSpacing(4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                TextField("", text: $question, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(ProfilePalette.ink)
                    .lineLimit(3...6)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
            }
            .frame(minHeight: 136, alignment: .topLeading)
            .background(Color(red: 0.97, green: 0.96, blue: 0.99), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                Button {
                    question = ""
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "eraser")
                            .font(.system(size: 11, weight: .semibold))
                        Text("清空")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(ProfilePalette.faint)
                }
                .buttonStyle(.plain)
                .padding(12)
            }
        }
    }

    private var hotTopicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ProfilePalette.faint)
                Text("不知道怎么问？试试这些热门问题")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ProfilePalette.faint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            HStack(spacing: 8) {
                ForEach(hotTopics, id: \.title) { topic in
                    Button {
                        question = topic.question
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: topic.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(topic.title)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(accent.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var quotaRow: some View {
        let remaining = permissionManager.getDailyDivinationRemaining()
        return HStack(spacing: 10) {
            Image("YinyangOrb")
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text("今日还剩 \(remaining) 次专业分析")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ProfilePalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(ProfilePalette.faint)
                }
                Text("解锁更深入的分析结果")
                    .font(.system(size: 12))
                    .foregroundColor(ProfilePalette.muted)
            }
            Spacer(minLength: 6)
            Button {
                showSubscriptionPrompt = true
            } label: {
                Text("升级")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var startButton: some View {
        Button(action: checkPermissionAndNavigate) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("开始摇卦")
                Image(systemName: "sparkles")
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 176.0 / 255, green: 112.0 / 255, blue: 245.0 / 255),
                        Color(red: 138.0 / 255, green: 72.0 / 255, blue: 224.0 / 255)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .shadow(color: accent.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(question.isEmpty && defaultQuestion == nil)
        .opacity((question.isEmpty && defaultQuestion == nil) ? 0.6 : 1)
        .simultaneousGesture(TapGesture().onEnded {
            divinationStartTime = Date()
            AnalyticsManager.shared.trackDivinationStart()
        })
    }

    private var tipRow: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 11, weight: .semibold))
                Text("小提示")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(accent.opacity(0.85))
            Text("问题越具体，分析越准确\n建议以疑问句的形式提问")
                .font(.system(size: 12))
                .foregroundColor(ProfilePalette.faint)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
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