import SwiftUI

// MARK: - 大师解读详情（设计稿假数据）
// 购买按钮后续再接到点券支付。不改动已有的 MasterReportView。

struct MasterReadingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var purchaseError: String?

    private let buyColor = Color(red: 148.0 / 255, green: 79.0 / 255, blue: 230.0 / 255)

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
        "风险警示",
        "全局结语"
    ]

    private let audiences: [(String, String)] = [
        ("scope", "重大决策"),
        ("briefcase.fill", "职业发展"),
        ("heart.fill", "感情关系"),
        ("banknote.fill", "财富规划")
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                navBar
                    .padding(.top, topInset)

                VStack(spacing: 14) {
                    introCard
                    previewCard
                    audienceCard
                    skuCard(
                        count: 1,
                        unitPrice: nil,
                        badge: "适合单次问题",
                        badgeStyle: .soft,
                        subtitle: "单次体验，快速获得专业解读",
                        price: "¥12"
                    )
                    skuCard(
                        count: 3,
                        unitPrice: "约 9.3/次",
                        badge: "更划算",
                        badgeStyle: .gold,
                        subtitle: "适合频繁使用，深度探索更多问题",
                        price: "¥28"
                    )
                    skuCard(
                        count: 10,
                        unitPrice: "约 6.8/次",
                        badge: "高性价比",
                        badgeStyle: .value,
                        subtitle: "重度用户首选，解锁更多可能",
                        price: "¥68"
                    )
                    DecisionBundleCard(onPurchased: finishPurchase)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity)
        }
        .clipped()
        .background(pageBackground.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .profileHidesTopScrollEdge()
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("购买未完成", isPresented: Binding(
            get: { purchaseError != nil },
            set: { if !$0 { purchaseError = nil } }
        )) {
            Button("确定", role: .cancel) { purchaseError = nil }
        } message: {
            Text(purchaseError ?? "")
        }
    }

    private var topInset: CGFloat {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let height = scene?.keyWindow?.safeAreaInsets.top
            ?? scene?.windows.first?.safeAreaInsets.top
            ?? 0
        return height > 0 ? height : 54
    }

    private var pageBackground: some View {
        ZStack(alignment: .top) {
            ProfilePalette.page
            LinearGradient(
                colors: [
                    Color(red: 0.86, green: 0.82, blue: 0.98),
                    Color(red: 0.94, green: 0.91, blue: 0.99),
                    ProfilePalette.page
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
            Image("ProfileHeaderMountains")
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .mask(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        }
    }

    private var navBar: some View {
        ZStack {
            VStack(spacing: 2) {
                Text("大师解读详情")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ProfilePalette.ink)
                Image(systemName: "sparkle")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(ProfilePalette.accent.opacity(0.7))
            }
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(ProfilePalette.ink)
                        .frame(width: 36, height: 36)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var introCard: some View {
            HStack(spacing: 14) {
            Image("YinyangOrb")
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 58)
                .clipShape(Circle())
                .shadow(color: ProfilePalette.accent.opacity(0.28), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 6) {
                Text("大师解读")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                Text("15段深度报告 · 专业视角解读 · 每卦可追问 66次")
                    .font(.system(size: 13))
                    .foregroundColor(ProfilePalette.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var previewCard: some View {
        HStack(alignment: .center, spacing: 8) {
            reportArtwork
                .frame(width: 128, height: 160)
            chapterColumn(0..<7)
            chapterColumn(7..<14)
        }
        .padding(14)
        .background(cardBackground)
    }

    private func chapterColumn(_ range: Range<Int>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(range, id: \.self) { index in
                HStack(spacing: 5) {
                    Text("\(index + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(buyColor.opacity(0.85), in: Circle())
                    Text(chapters[index])
                        .font(.system(size: 12, weight: .medium))
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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.7))
                .frame(width: 108, height: 140)
                .rotationEffect(.degrees(-8))
                .offset(x: -10, y: 6)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.93, green: 0.90, blue: 0.99))
                .frame(width: 108, height: 140)
                .rotationEffect(.degrees(6))
                .offset(x: 12, y: 4)
            VStack(spacing: 8) {
                Text("命盘解读报告")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ProfilePalette.accent)
                Text("洞察玄机 · 指引方向")
                    .font(.system(size: 8))
                    .foregroundColor(ProfilePalette.faint)
                ZStack {
                    Circle()
                        .stroke(ProfilePalette.accent.opacity(0.35), lineWidth: 1)
                        .frame(width: 54, height: 54)
                    Circle()
                        .trim(from: 0, to: 0.5)
                        .fill(ProfilePalette.accent.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .offset(y: -9)
                    Circle()
                        .fill(ProfilePalette.accent)
                        .frame(width: 8, height: 8)
                        .offset(y: 9)
                }
                VStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(ProfilePalette.accent.opacity(0.15))
                            .frame(width: 64, height: 3)
                    }
                }
            }
            .frame(width: 112, height: 148)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: ProfilePalette.accent.opacity(0.12), radius: 8, y: 4)
            )
        }
    }

    private var audienceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ProfilePalette.accent)
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
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(ProfilePalette.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(ProfilePalette.accent.opacity(0.08), in: Capsule())
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private enum BadgeStyle {
        case soft, gold, value
    }

    private func skuCard(
        count: Int,
        unitPrice: String?,
        badge: String,
        badgeStyle: BadgeStyle,
        subtitle: String,
        price: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("大师解读  × \(count)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ProfilePalette.ink)
                    if let unitPrice {
                        Text(unitPrice)
                            .font(.system(size: 12))
                            .foregroundColor(ProfilePalette.faint)
                    }
                }
                Spacer(minLength: 8)
                Text(badge)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(badgeForeground(badgeStyle))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeBackground(badgeStyle), in: Capsule())
            }
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(ProfilePalette.muted)
            HStack {
                Text(price)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(buyColor)
                Spacer()
                Button {
                    purchase(count: count)
                } label: {
                    Text("购买")
                }
                .buttonStyle(AccentBuyButtonStyle(
                    compact: false,
                    isLoading: subscriptionService.purchasingProductID == SubscriptionConfig.masterProductID(count: count)
                ))
                .disabled(subscriptionService.isPurchasing)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func badgeForeground(_ style: BadgeStyle) -> Color {
        switch style {
        case .soft: return buyColor
        case .gold: return Color(red: 0.62, green: 0.40, blue: 0.08)
        case .value: return Color(red: 0.55, green: 0.28, blue: 0.85)
        }
    }

    private func badgeBackground(_ style: BadgeStyle) -> Color {
        switch style {
        case .soft: return buyColor.opacity(0.10)
        case .gold: return Color(red: 1.0, green: 0.90, blue: 0.55)
        case .value: return Color(red: 0.93, green: 0.88, blue: 1.0)
        }
    }

    private func finishPurchase() {
        ToastManager.shared.showPurchaseSuccess {
            dismiss()
        }
    }

    private func purchase(count: Int) {
        guard let productID = SubscriptionConfig.masterProductID(count: count) else { return }
        Task {
            do {
                let ok = try await subscriptionService.purchaseConsumable(productID)
                if ok {
                    finishPurchase()
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
            .fill(Color.white.opacity(0.92))
            .shadow(color: ProfilePalette.cardShadow, radius: 10, y: 4)
    }
}

#Preview {
    NavigationStack {
        MasterReadingDetailView()
    }
}
