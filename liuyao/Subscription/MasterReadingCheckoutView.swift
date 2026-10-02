import SwiftUI

// MARK: - 大师解读结算卡
// 盖在摇卦结果页上的弹层，不是新页面。次数判断和购买后续再接。

struct MasterReadingCheckoutView: View {
    var onClose: () -> Void
    var onPurchased: (() -> Void)? = nil

    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showProUpgrade = false
    @State private var purchaseError: String?

    private let chapters = [
        "核心结论",
        "卦象档案",
        "专业排盘",
        "核心断语",
        "卦眼点睛",
        "卦象释读",
        "方位解析",
        "局势剖析",
        "卦理溯源",
        "关键信号",
        "时间提示",
        "问题复盘",
        "行动指引",
        "风险警示"
    ]

    private let audiences: [(String, String)] = [
        ("scope", "重大决策"),
        ("briefcase.fill", "职业发展"),
        ("heart.fill", "感情关系"),
        ("banknote.fill", "财富规划")
    ]

    private let buyColor = Color(red: 124.0 / 255, green: 78.0 / 255, blue: 232.0 / 255)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)

                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 36, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                    FittingScroll(maxHeight: proxy.size.height - 120) {
                        VStack(spacing: 14) {
                            introCard
                            previewCard
                            audienceCard
                            followUpCard
                            purchaseBar
                            membershipLink
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, bottomSafeInset + 8)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(pageBackground)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ProfilePalette.ink)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.9), in: Circle())
                    }
                    .padding(.top, 22)
                    .padding(.trailing, 16)
                }
                .shadow(color: Color.black.opacity(0.18), radius: 18, y: -4)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
        .alert("购买未完成", isPresented: Binding(
            get: { purchaseError != nil },
            set: { if !$0 { purchaseError = nil } }
        )) {
            Button("确定", role: .cancel) { purchaseError = nil }
        } message: {
            Text(purchaseError ?? "")
        }
    }

    /// 弹层铺到屏幕底边后，GeometryReader 不再带底部安全区，改从窗口读取。
    private var bottomSafeInset: CGFloat {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let height = scene?.keyWindow?.safeAreaInsets.bottom
            ?? scene?.windows.first?.safeAreaInsets.bottom
            ?? 0
        return height > 0 ? height : 34
    }

    private var pageBackground: some View {
        Image("ProfileHeaderMountains")
            .resizable()
            .scaledToFill()
            .overlay(Color.white.opacity(0.18))
    }

    private var introCard: some View {
        HStack(spacing: 14) {
            Image("YinyangOrb")
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 58)
                .clipShape(Circle())
                .shadow(color: buyColor.opacity(0.28), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 6) {
                Text("大师解读 × 1")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                Text("15段深度报告 · 专业视角 · 全面解析")
                    .font(.system(size: 13))
                    .foregroundColor(ProfilePalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(cardBackground)
    }

    private var previewCard: some View {
        HStack(alignment: .center, spacing: 8) {
            reportArtwork
                .frame(width: 108, height: 148)
            chapterColumn(0..<7)
            chapterColumn(7..<14)
        }
        .padding(12)
        .background(cardBackground)
    }

    private func chapterColumn(_ range: Range<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(range, id: \.self) { index in
                HStack(spacing: 4) {
                    Text("\(index + 1)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(buyColor.opacity(0.9), in: Circle())
                    Text(chapters[index])
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ProfilePalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reportArtwork: some View {
        ZStack {
            reportSheet(width: 78, height: 108)
                .rotationEffect(.degrees(-12))
                .offset(x: -12, y: 6)
            reportSheet(width: 78, height: 108)
                .rotationEffect(.degrees(9))
                .offset(x: 14, y: 5)
            VStack(spacing: 6) {
                Text("命盘解读报告")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(buyColor)
                Text("洞察玄机 · 指引方向")
                    .font(.system(size: 7))
                    .foregroundColor(ProfilePalette.faint)
                ZStack {
                    Circle()
                        .stroke(buyColor.opacity(0.25), lineWidth: 5)
                        .frame(width: 40, height: 40)
                    Circle()
                        .trim(from: 0, to: 0.5)
                        .fill(buyColor.opacity(0.85))
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                        .offset(y: -4)
                    Circle()
                        .fill(buyColor)
                        .frame(width: 4, height: 4)
                        .offset(y: 4)
                }
                VStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(buyColor.opacity(0.16))
                            .frame(width: 44, height: 2)
                    }
                }
            }
            .frame(width: 86, height: 118)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: buyColor.opacity(0.16), radius: 8, y: 4)
            )
        }
    }

    private func reportSheet(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.95),
                        Color(red: 0.93, green: 0.90, blue: 0.99)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: height)
            .shadow(color: buyColor.opacity(0.08), radius: 6, y: 3)
    }

    private var audienceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(buyColor)
                Text("适合人群")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
            }
            HStack(spacing: 8) {
                ForEach(audiences, id: \.1) { item in
                    HStack(spacing: 4) {
                        Image(systemName: item.0)
                            .font(.system(size: 11, weight: .semibold))
                        Text(item.1)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundColor(buyColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(buyColor.opacity(0.08), in: Capsule())
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var followUpCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(buyColor.opacity(0.9), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("再回溯深一点？")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                Text("购买后可享「66次」追问，帮你深入理解主题")
                    .font(.system(size: 12))
                    .foregroundColor(ProfilePalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(cardBackground)
    }

    private var purchaseBar: some View {
        HStack(spacing: 14) {
            Text("¥12")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(buyColor)
            Button {
                purchase()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("立即购买")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.62, blue: 0.28),
                            Color(red: 0.96, green: 0.36, blue: 0.40)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .shadow(color: Color(red: 0.95, green: 0.40, blue: 0.28).opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private var membershipLink: some View {
        Button {
            showProUpgrade = true
        } label: {
            Text("或开通会员，每月赠 1 次大师解读 →")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(buyColor)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func purchase() {
        Task {
            do {
                let ok = try await subscriptionService.purchaseConsumable(SubscriptionConfig.master1ProductID)
                if ok {
                    onPurchased?()
                } else if let message = subscriptionService.purchaseError, !message.isEmpty {
                    purchaseError = message
                }
            } catch {
                purchaseError = error.localizedDescription
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.94))
            .shadow(color: ProfilePalette.cardShadow, radius: 10, y: 4)
    }
}

/// 内容不够高时卡片跟着收短，超出时才在弹层里滚动。
private struct FittingScroll<Content: View>: View {
    let maxHeight: CGFloat
    @ViewBuilder var content: () -> Content
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content()
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(key: CheckoutContentHeightKey.self, value: proxy.size.height)
                    }
                }
                .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .onPreferenceChange(CheckoutContentHeightKey.self) { contentHeight = $0 }
        .frame(height: min(max(contentHeight, 1), maxHeight))
        .clipped()
    }
}

private struct CheckoutContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    MasterReadingCheckoutView(onClose: {})
}
