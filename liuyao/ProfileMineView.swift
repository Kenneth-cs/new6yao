import SwiftUI
import StoreKit

// MARK: - 个人中心配色（对齐「我的」设计稿）

enum ProfilePalette {
    static let page = Color(red: 0.965, green: 0.949, blue: 0.992)
    static let ink = Color(red: 0.16, green: 0.13, blue: 0.27)
    static let muted = Color(red: 0.40, green: 0.37, blue: 0.52)
    static let faint = Color(red: 0.56, green: 0.52, blue: 0.68)
    static let accent = Color(red: 0.49, green: 0.36, blue: 0.86)
    static let accentSoft = Color(red: 0.64, green: 0.50, blue: 0.97)
    static let cardShadow = Color(red: 0.42, green: 0.32, blue: 0.68).opacity(0.08)
    static let luck = Color(red: 0.13, green: 0.62, blue: 0.42)
}

/// 新 UI 先按设计稿假数据展示。改为 false 后，身份次数走真实订阅，历史走 RecentDecisionsSection，统计走 StatisticsService。
let profileUsesMockData = false

extension View {
    /// iOS 26 会在滚动视图顶部盖一层浅色边缘，把头图裁成一条白边。
    @ViewBuilder
    func profileHidesTopScrollEdge() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectHidden(true, for: .top)
        } else {
            self
        }
    }
}

// MARK: - 顶部 Header

struct ProfileHeaderSection: View {
    var usesPreviewData: Bool = true

    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @AppStorage("dev_mode_enabled") private var devModeEnabled = false
    @State private var showDevSheet = false
    @State private var tapCount: Int = 0
    @State private var lastTapTime: Date = .distantPast

    private var remainingCount: Int {
        permissionManager.getDailyDivinationRemaining()
    }

    private var displayName: String {
        if devModeEnabled { return "DEV模式" }
        if usesPreviewData { return "免费版" }
        return subscriptionService.isPro ? "会员" : "免费版"
    }

    private var displaySubtitle: String {
        if usesPreviewData { return "每天 1 次专业解读" }
        switch permissionManager.currentTier {
        case .free:
            return "每天 1 次专业解读"
        case .proMonthly:
            return "每月 66次专业解读"
        case .proYearly:
            return "每月 88次专业解读"
        }
    }

    private var displayRemaining: Int {
        if usesPreviewData { return 1 }
        if permissionManager.currentTier.isPro {
            return permissionManager.monthlyReadingRemaining()
        }
        return remainingCount
    }

    private var remainingTitle: String {
        permissionManager.currentTier.isPro && !usesPreviewData ? "本月剩余" : "今日剩余"
    }

    private var creditSummary: String? {
        guard !usesPreviewData else { return nil }
        var parts: [String] = []
        let master = permissionManager.usageStats.masterCredits
        let deduction = permissionManager.usageStats.deductionCredits
        let gift = permissionManager.monthlyMasterGiftRemaining()
        if master > 0 { parts.append("大师 ×\(master)") }
        if deduction > 0 { parts.append("推演 ×\(deduction)") }
        if gift > 0 { parts.append("大师解卦赠\(gift)次/月") }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            identityRow
                .padding(.top, 16)
                .padding(.bottom, 18)
        }
        .padding(.top, topInset)
        .background(alignment: .top) {
            headerBackdrop
                .padding(.top, -topInset)
                .ignoresSafeArea(edges: .top)
        }
        .sheet(isPresented: $showDevSheet) {
            DeveloperModeSheet(isEnabled: $devModeEnabled)
        }
    }

    /// 状态栏高度。滚动视图忽略顶部安全区后，用它把标题留在原位，背景再向上铺满。
    private var topInset: CGFloat {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let height = scene?.keyWindow?.safeAreaInsets.top
            ?? scene?.windows.first?.safeAreaInsets.top
            ?? 0
        return height > 0 ? height : 54
    }

    private var headerBackdrop: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [
                    Color(red: 0.84, green: 0.80, blue: 0.98),
                    Color(red: 0.90, green: 0.86, blue: 0.99),
                    ProfilePalette.page
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Image("ProfileHeaderMountains")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.55), location: 0.0),
                            .init(color: .white, location: 0.35),
                            .init(color: .white.opacity(0.35), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.7), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        }
    }

    private var headerBar: some View {
        ZStack {
            VStack(spacing: 4) {
                Text("我的")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ProfilePalette.ink)
                Capsule()
                    .fill(ProfilePalette.accent)
                    .frame(width: 18, height: 3)
            }
            HStack {
                Spacer()
                NavigationLink(destination: SubscriptionManagementView()) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle().fill(
                                LinearGradient(
                                    colors: [ProfilePalette.accentSoft, ProfilePalette.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .shadow(color: ProfilePalette.accent.opacity(0.28), radius: 6, y: 2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var identityRow: some View {
        HStack(alignment: .center, spacing: 12) {
            avatarView
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(ProfilePalette.ink)
                        .lineLimit(1)
                    Text("当前身份")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ProfilePalette.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ProfilePalette.accent.opacity(0.12), in: Capsule())
                        .fixedSize()
                }
                Text(displaySubtitle)
                    .font(.system(size: 13))
                    .foregroundColor(ProfilePalette.muted)
                    .lineLimit(1)
                if let creditSummary {
                    Text(creditSummary)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ProfilePalette.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("点击起卦后可用")
                        .font(.system(size: 11))
                        .foregroundColor(ProfilePalette.faint)
                        .lineLimit(1)
                }
                Text("愿你在探索中，遇见更好的自己 ✦")
                    .font(.system(size: 11))
                    .foregroundColor(ProfilePalette.faint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 4)
            remainingBadge
        }
        .padding(.horizontal, 16)
    }

    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("ProfileAvatar")
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: ProfilePalette.accent.opacity(0.16), radius: 8, y: 3)
            if devModeEnabled {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.orange, in: Circle())
                    .offset(x: 2, y: 2)
            }
        }
        .onTapGesture { handleAvatarTap() }
    }

    private var remainingBadge: some View {
        VStack(spacing: 0) {
            Text(remainingTitle)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(ProfilePalette.accent)
            Text("\(displayRemaining)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ProfilePalette.accent)
                .padding(.vertical, -1)
            Text("次")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ProfilePalette.accent.opacity(0.85))
        }
        .frame(width: 74, height: 74)
        .background(
            Circle()
                .fill(Color.white.opacity(0.78))
                .shadow(color: ProfilePalette.accent.opacity(0.14), radius: 10, y: 3)
        )
        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
    }

    private func handleAvatarTap() {
        let now = Date()
        if now.timeIntervalSince(lastTapTime) > 2 { tapCount = 0 }
        tapCount += 1
        lastTapTime = now
        if tapCount >= 11 {
            tapCount = 0
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            showDevSheet = true
        }
    }
}

// MARK: - 解锁更高级功能

struct UnlockFeaturesSection: View {
    @State private var redeemError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProfileSectionIcon(systemName: "lock.open.fill", tint: ProfilePalette.accent)
                Text("解锁更高级功能")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                Spacer()
                NavigationLink(destination: ProUpgradeView()) {
                    ProfileSeeAllLabel()
                }
            }

            VStack(spacing: 10) {
                NavigationLink(destination: ProUpgradeView()) {
                    membershipRow
                }
                .buttonStyle(.plain)

                Button {
                    Task { await presentOfferCodeRedeem() }
                } label: {
                    redeemRow
                }
                .buttonStyle(.plain)
            }
        }
        .alert("兑换失败", isPresented: Binding(
            get: { redeemError != nil },
            set: { if !$0 { redeemError = nil } }
        )) {
            Button("确定") { redeemError = nil }
        } message: {
            if let redeemError { Text(redeemError) }
        }
    }

    private var membershipRow: some View {
        HStack(spacing: 12) {
            ProfileGlyphBox(
                systemName: "crown.fill",
                fill: LinearGradient(
                    colors: [ProfilePalette.accentSoft, ProfilePalette.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("会员与点券")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ProfilePalette.ink)
                    Text("推荐")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.96, green: 0.42, blue: 0.38),
                                    Color(red: 0.98, green: 0.58, blue: 0.28)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                }
                Text("开通会员，或按次购买大师解读、推演点券")
                    .font(.system(size: 12))
                    .foregroundColor(ProfilePalette.muted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.75, green: 0.73, blue: 0.82))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(membershipBackground)
    }

    private var membershipBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(red: 0.96, green: 0.94, blue: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(alignment: .trailing) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 78, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                ProfilePalette.accent.opacity(0.16),
                                ProfilePalette.accentSoft.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(x: 10, y: 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: ProfilePalette.cardShadow, radius: 12, y: 5)
    }

    private var redeemRow: some View {
        HStack(spacing: 12) {
            ProfileGlyphBox(
                systemName: "gift.fill",
                fill: LinearGradient(
                    colors: [ProfilePalette.accentSoft, ProfilePalette.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            VStack(alignment: .leading, spacing: 4) {
                Text("兑换码")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ProfilePalette.ink)
                Text("输入兑换码，解锁专属权益")
                    .font(.system(size: 12))
                    .foregroundColor(ProfilePalette.muted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.75, green: 0.73, blue: 0.82))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: ProfilePalette.cardShadow, radius: 12, y: 5)
        )
    }

    private func presentOfferCodeRedeem() async {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            redeemError = "无法获取当前窗口"
            return
        }
        do {
            try await AppStore.presentOfferCodeRedeemSheet(in: scene)
        } catch {
            redeemError = "兑换码无法使用，请确认后重试"
        }
    }
}

// MARK: - 历史记录（设计稿假数据）

private struct ProfileMockHistory: Identifiable {
    enum Kind { case yao, matrix }
    let id = UUID()
    let kind: Kind
    let title: String
    let badge: String
    let meta: String
    let date: String
    let score: String?
    let verdict: String?
}

private let profileMockHistory: [ProfileMockHistory] = [
    .init(kind: .yao, title: "这个项目值得我继续投入吗？", badge: "六爻预测", meta: "", date: "2026/09/28", score: nil, verdict: nil),
    .init(kind: .yao, title: "我现在最应提升哪方面的能力？", badge: "六爻预测", meta: "", date: "2026/09/28", score: nil, verdict: nil),
    .init(kind: .yao, title: "我应该接受这段关系的现状吗？", badge: "六爻预测", meta: "", date: "2026/09/28", score: nil, verdict: nil),
    .init(kind: .matrix, title: "事业选择", badge: "五行决策", meta: "投资 / 理财", date: "2026/08/27", score: "88", verdict: "大吉"),
    .init(kind: .matrix, title: "事业选择", badge: "五行决策", meta: "投资 / 理财", date: "2026/08/27", score: "88", verdict: "大吉")
]

struct ProfilePreviewHistorySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProfileSectionIcon(systemName: "clock.arrow.circlepath", tint: ProfilePalette.accent)
                Text("历史记录")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                Spacer()
                NavigationLink(destination: HistoryPageView()) {
                    ProfileSeeAllLabel()
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(profileMockHistory.enumerated()), id: \.element.id) { index, item in
                    ProfileMockHistoryRow(item: item)
                    if index < profileMockHistory.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: ProfilePalette.cardShadow, radius: 12, y: 5)
            )
        }
    }
}

private struct ProfileMockHistoryRow: View {
    let item: ProfileMockHistory

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 40, height: 40)
                Image(systemName: item.kind == .yao ? "envelope.fill" : "dollarsign")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(item.kind == .yao ? ProfilePalette.accent : .white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(ProfilePalette.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.badge)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ProfilePalette.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ProfilePalette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 4))
                    if !item.meta.isEmpty {
                        Text(item.meta)
                            .font(.system(size: 11))
                            .foregroundColor(ProfilePalette.faint)
                    }
                    Text(item.date)
                        .font(.system(size: 11))
                        .foregroundColor(ProfilePalette.faint)
                }
            }

            Spacer(minLength: 4)

            if let score = item.score, let verdict = item.verdict {
                VStack(spacing: 0) {
                    Text(score)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ProfilePalette.luck)
                    Text(verdict)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ProfilePalette.luck)
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.78, green: 0.76, blue: 0.84))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var iconBackground: Color {
        item.kind == .yao
            ? Color(red: 0.93, green: 0.90, blue: 0.99)
            : Color(red: 0.48, green: 0.38, blue: 0.90)
    }
}

// MARK: - 统计面板

struct ProfileStatsSection: View {
    @ObservedObject var statisticsService: StatisticsService
    var usesPreviewData: Bool = true

    private var items: [ProfileStatItem] {
        if usesPreviewData {
            return [
                .init(title: "分析次数", value: "8", subtitle: "累计分析", icon: "questionmark.circle.fill", tint: Color(red: 0.28, green: 0.55, blue: 0.95), card: Color(red: 0.90, green: 0.95, blue: 1.0), rising: true),
                .init(title: "本月分析", value: "5", subtitle: "当月活跃度", icon: "calendar", tint: Color(red: 0.16, green: 0.68, blue: 0.48), card: Color(red: 0.88, green: 0.97, blue: 0.93), rising: true),
                .init(title: "准确度", value: "暂无", subtitle: "用户反馈", icon: "target", tint: Color(red: 0.95, green: 0.55, blue: 0.22), card: Color(red: 1.0, green: 0.96, blue: 0.90), rising: false),
                .init(title: "连续天数", value: "0", subtitle: "使用习惯", icon: "flame.fill", tint: Color(red: 0.93, green: 0.32, blue: 0.32), card: Color(red: 1.0, green: 0.91, blue: 0.91), rising: false)
            ]
        }
        let accuracy = statisticsService.averageAccuracy
        return [
            .init(title: "分析次数", value: "\(statisticsService.totalAnalysis)", subtitle: "累计分析", icon: "questionmark.circle.fill", tint: Color(red: 0.28, green: 0.55, blue: 0.95), card: Color(red: 0.90, green: 0.95, blue: 1.0), rising: statisticsService.totalAnalysis > 0),
            .init(title: "本月分析", value: "\(statisticsService.monthlyAnalysis)", subtitle: "当月活跃度", icon: "calendar", tint: Color(red: 0.16, green: 0.68, blue: 0.48), card: Color(red: 0.88, green: 0.97, blue: 0.93), rising: statisticsService.monthlyAnalysis > 0),
            .init(title: "准确度", value: accuracy > 0 ? "\(Int(accuracy * 100))%" : "暂无", subtitle: "用户反馈", icon: "target", tint: Color(red: 0.95, green: 0.55, blue: 0.22), card: Color(red: 1.0, green: 0.96, blue: 0.90), rising: accuracy >= 0.7),
            .init(title: "连续天数", value: "\(statisticsService.consecutiveDays)", subtitle: "使用习惯", icon: "flame.fill", tint: Color(red: 0.93, green: 0.32, blue: 0.32), card: Color(red: 1.0, green: 0.91, blue: 0.91), rising: statisticsService.consecutiveDays >= 3)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProfileSectionIcon(systemName: "chart.bar.fill", tint: ProfilePalette.accent)
                Text("统计面板")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ProfilePalette.faint)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                ForEach(items) { item in
                    ProfileStatCard(item: item)
                }
            }
        }
    }
}

private struct ProfileStatItem: Identifiable {
    var id: String { title }
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color
    let card: Color
    let rising: Bool
}

private struct ProfileStatCard: View {
    let item: ProfileStatItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(item.tint)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
                MiniSparkline(rising: item.rising)
                    .stroke(item.tint.opacity(0.75), style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 36, height: 16)
                    .padding(.top, 4)
            }
            Text(item.value)
                .font(.system(size: item.value.count > 2 ? 22 : 26, weight: .bold))
                .foregroundColor(ProfilePalette.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ProfilePalette.ink)
                Text(item.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(ProfilePalette.faint)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(item.card)
        )
    }
}

private struct MiniSparkline: Shape {
    var rising: Bool

    func path(in rect: CGRect) -> Path {
        let samples: [CGFloat] = rising
            ? [0.78, 0.60, 0.68, 0.40, 0.48, 0.18]
            : [0.42, 0.55, 0.38, 0.60, 0.46, 0.64]
        var path = Path()
        for (index, sample) in samples.enumerated() {
            let x = rect.minX + rect.width * CGFloat(index) / CGFloat(samples.count - 1)
            let y = rect.minY + rect.height * sample
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

// MARK: - 应用管理

struct ProfileAppManagementSection: View {
    @Binding var showingCacheCleanup: Bool
    @Binding var showingPrivacySettings: Bool
    @State private var showingNotificationSettings = false
    @State private var showingHelpFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                ProfileSectionIcon(
                    systemName: "square.grid.2x2.fill",
                    tint: Color(red: 0.20, green: 0.70, blue: 0.48)
                )
                Text("应用管理")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                Spacer()
            }

            VStack(spacing: 0) {
                ProfileAppRow(
                    systemName: "bell.fill",
                    tint: Color(red: 0.95, green: 0.55, blue: 0.20),
                    background: Color(red: 1.0, green: 0.94, blue: 0.86),
                    title: "每日提醒"
                ) { showingNotificationSettings = true }

                Divider().padding(.leading, 62)

                ProfileAppRow(
                    systemName: "trash.fill",
                    tint: Color(red: 0.90, green: 0.28, blue: 0.28),
                    background: Color(red: 1.0, green: 0.90, blue: 0.90),
                    title: "缓存清理"
                ) { showingCacheCleanup = true }

                Divider().padding(.leading, 62)

                ProfileAppRow(
                    systemName: "shield.fill",
                    tint: Color(red: 0.18, green: 0.70, blue: 0.48),
                    background: Color(red: 0.88, green: 0.97, blue: 0.92),
                    title: "隐私设置"
                ) { showingPrivacySettings = true }

                Divider().padding(.leading, 62)

                ProfileAppRow(
                    systemName: "questionmark.bubble.fill",
                    tint: ProfilePalette.accent,
                    background: ProfilePalette.accent.opacity(0.12),
                    title: "帮助与反馈"
                ) { showingHelpFeedback = true }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: ProfilePalette.cardShadow, radius: 12, y: 5)
            )
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingHelpFeedback) {
            HelpFeedbackSheet()
        }
    }
}

private struct HelpFeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ProfilePalette.muted)
                        .frame(width: 30, height: 30)
                        .background(ProfilePalette.page, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            Text("遇到问题？联系小助手")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ProfilePalette.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            Text("添加微信时请备注：人生教练")
                .font(.system(size: 13))
                .foregroundColor(ProfilePalette.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            Image("WeChatAssistantQR")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 28)
                .padding(.top, 12)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct ProfileAppRow: View {
    let systemName: String
    let tint: Color
    let background: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 34, height: 34)
                    .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(ProfilePalette.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.78, green: 0.76, blue: 0.84))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 共用小组件

private struct ProfileSectionIcon: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(tint)
    }
}

private struct ProfileSeeAllLabel: View {
    var body: some View {
        HStack(spacing: 2) {
            Text("查看全部")
                .font(.system(size: 13))
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(ProfilePalette.faint)
    }
}

private struct ProfileGlyphBox: View {
    let systemName: String
    let fill: LinearGradient

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 46, height: 46)
            .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
