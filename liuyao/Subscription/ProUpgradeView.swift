import SwiftUI

// MARK: - 升级专业版

private enum ProUpgradePlan: String, CaseIterable {
    case monthly
    case yearly

    var title: String {
        switch self {
        case .monthly: return "月度"
        case .yearly: return "年度"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "¥9.9"
        case .yearly: return "¥99"
        }
    }

    var unit: String {
        switch self {
        case .monthly: return "/月"
        case .yearly: return "/年"
        }
    }

    var buttonPrice: String {
        switch self {
        case .monthly: return "¥9.90 /月"
        case .yearly: return "¥99.00 /年"
        }
    }
}

struct ProUpgradeView: View {
    var prefersYearly: Bool = true
    var onPurchased: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedPlan: ProUpgradePlan = .yearly
    @State private var purchaseError: String?
    @State private var showMasterDetail = false
    @State private var showDeductionDetail = false
    @State private var isStartingPlanPurchase = false

    init(prefersYearly: Bool = true, onPurchased: (() -> Void)? = nil) {
        self.prefersYearly = prefersYearly
        self.onPurchased = onPurchased
        _selectedPlan = State(initialValue: prefersYearly ? .yearly : .monthly)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                navBar
                    .padding(.top, topInset)

                VStack(spacing: 18) {
                    statusBanner
                    planSection
                    couponSection
                    comparisonSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
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
        .fullScreenCover(isPresented: $showMasterDetail) {
            MasterReadingDetailView()
        }
        .fullScreenCover(isPresented: $showDeductionDetail) {
            DeductionCouponView()
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
            .frame(height: 280)
            Image("ProfileHeaderMountains")
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .mask(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        }
    }

    // MARK: - 导航

    private var navBar: some View {
        ZStack {
            Text("升级专业版")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ProfilePalette.ink)
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
        .padding(.bottom, 6)
    }

    // MARK: - 状态 Banner
    // 背景用清晰的山水横图，按卡片高度裁切，不放大糊图。身份文案用矢量绘制。

    private var statusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [ProfilePalette.accentSoft, ProfilePalette.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("当前状态")
                    .font(.system(size: 12))
                    .foregroundColor(ProfilePalette.muted)
                Text(statusTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                Text(statusSubtitle)
                    .font(.system(size: 12))
                    .foregroundColor(ProfilePalette.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 72)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .background {
            Image("ProUpgradeBanner")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: ProfilePalette.cardShadow, radius: 12, y: 5)
    }

    // MARK: - 会员方案

    private var planSection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 11, weight: .bold))
                    Text("选择你的使用方式")
                        .font(.system(size: 16, weight: .bold))
                    Image(systemName: "sparkle")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(ProfilePalette.accent)
                Text("不同需求 · 不同选择")
                    .font(.system(size: 12))
                    .foregroundColor(ProfilePalette.faint)
            }

            VStack(spacing: 14) {
                planHeader
                planPicker
                benefitRow
                upgradeButton
            }
            .padding(14)
            .background(proCardBackground)
        }
    }

    private var planHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.45), Color.white.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text("专业版会员")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text("解锁全部核心能力，陪你长期成长")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
        }
    }

    private var planPicker: some View {
        HStack(spacing: 10) {
            planCard(.monthly)
            planCard(.yearly)
        }
    }

    private func planCard(_ plan: ProUpgradePlan) -> some View {
        let selected = selectedPlan == plan
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { selectedPlan = plan }
        } label: {
            VStack(spacing: 6) {
                Text(plan.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selected ? Color(red: 0.72, green: 0.42, blue: 0.12) : ProfilePalette.muted)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(plan.price)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(selected ? Color(red: 0.85, green: 0.45, blue: 0.12) : ProfilePalette.ink)
                    Text(plan.unit)
                        .font(.system(size: 12))
                        .foregroundColor(selected ? Color(red: 0.72, green: 0.42, blue: 0.12) : ProfilePalette.faint)
                }
                if plan == .yearly {
                    Text("立省¥19.8")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.22))
                    Text("≈¥8.25/月")
                        .font(.system(size: 11))
                        .foregroundColor(ProfilePalette.faint)
                } else {
                    Text("一杯奶茶钱，换清晰发展方向")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.62, green: 0.60, blue: 0.68))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected
                          ? Color(red: 1.0, green: 0.97, blue: 0.90)
                          : Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color(red: 0.93, green: 0.72, blue: 0.28) : Color.white.opacity(0.4), lineWidth: selected ? 1.5 : 0)
            )
            .overlay(alignment: .topTrailing) {
                if plan == .yearly {
                    Text("热门")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.45, blue: 0.28),
                                    Color(red: 0.96, green: 0.32, blue: 0.38)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .offset(x: 4, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var benefitRow: some View {
        HStack(spacing: 0) {
            benefitItem(icon: "infinity", title: "月66次/年88次", subtitle: "专业解读")
            benefitItem(icon: "bubble.left.and.bubble.right.fill", title: "66次追问", subtitle: "每卦深度追问")
            benefitItem(icon: "bookmark.fill", title: "无限保存", subtitle: "珍贵内容不丢失")
            benefitItem(
                icon: "circle.lefthalf.filled",
                title: selectedPlan == .yearly ? "每月2次" : "每月1次",
                subtitle: "大师解读"
            )
        }
    }

    private func benefitItem(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.18), in: Circle())
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var selectedProductID: String {
        selectedPlan == .monthly
            ? SubscriptionConfig.proMonthlyProductID
            : SubscriptionConfig.proYearlyProductID
    }

    private var upgradeButtonBusy: Bool {
        isStartingPlanPurchase || subscriptionService.purchasingProductID == selectedProductID
    }

    private var upgradeButton: some View {
        Button {
            purchaseSelectedPlan()
        } label: {
            Group {
                if upgradeButtonBusy {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("升级到专业版  \(selectedPlan.buttonPrice)")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.62, blue: 0.28),
                        Color(red: 0.96, green: 0.38, blue: 0.42)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .shadow(color: Color(red: 0.95, green: 0.40, blue: 0.28).opacity(0.45), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(upgradeButtonBusy || subscriptionService.isPurchasing)
    }

    private var proCardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.62, green: 0.48, blue: 0.98),
                        Color(red: 0.48, green: 0.36, blue: 0.90),
                        Color(red: 0.55, green: 0.42, blue: 0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 3) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 9))
                    Text("更划算")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color(red: 0.55, green: 0.32, blue: 0.08))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(red: 1.0, green: 0.86, blue: 0.45), in: Capsule())
                .padding(12)
            }
            .shadow(color: ProfilePalette.accent.opacity(0.28), radius: 16, y: 8)
    }

    // MARK: - 点券（假数据，入口后续再接）

    private var couponSection: some View {
        VStack(spacing: 10) {
            Button {
                showMasterDetail = true
            } label: {
                couponRowLabel(
                    icon: "star.fill",
                    colors: [Color(red: 0.62, green: 0.48, blue: 0.98), ProfilePalette.accent],
                    title: "大师解读点券",
                    subtitle: "本卦大师解读 15 段报告 · 兑换大师解读（本卦内）",
                    price: "¥12",
                    unit: "/次"
                )
            }
            .buttonStyle(.plain)
            Button {
                showDeductionDetail = true
            } label: {
                couponRowLabel(
                    icon: "point.3.connected.trianglepath.dotted",
                    colors: [Color(red: 184.0 / 255, green: 75.0 / 255, blue: 231.0 / 255), Color(red: 150.0 / 255, green: 42.0 / 255, blue: 198.0 / 255)],
                    title: "推演点券",
                    subtitle: "三路推演报告",
                    price: "¥8",
                    unit: "/次"
                )
            }
            .buttonStyle(.plain)
            couponRow(
                icon: "gift.fill",
                colors: [Color(red: 0.96, green: 0.45, blue: 0.62), Color(red: 0.90, green: 0.32, blue: 0.55)],
                title: "套餐",
                subtitle: "大师解读 + 三路推演 + 每卦 66次追问",
                price: "¥18",
                unit: ""
            )
        }
    }

    /// 图二「去看看」按钮色
    private static let lookColor = Color(red: 148.0 / 255, green: 79.0 / 255, blue: 230.0 / 255)

    private func couponRow(icon: String, colors: [Color], title: String, subtitle: String, price: String, unit: String) -> some View {
        Button {
            Task { await purchaseProduct(SubscriptionConfig.bundleProductID) }
        } label: {
            couponRowLabel(icon: icon, colors: colors, title: title, subtitle: subtitle, price: price, unit: unit)
        }
        .buttonStyle(.plain)
    }

    private func couponRowLabel(icon: String, colors: [Color], title: String, subtitle: String, price: String, unit: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ProfilePalette.ink)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(ProfilePalette.faint)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 4)
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ProfilePalette.ink)
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundColor(ProfilePalette.muted)
                }
                Text("去看看")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Self.lookColor, in: Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: ProfilePalette.cardShadow, radius: 10, y: 4)
        )
    }

    // MARK: - 权益对比（假数据）

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ProfilePalette.accent)
                Text("服务权益对比")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
            }

            VStack(spacing: 0) {
                compareHeader
                ForEach(Array(compareRows.enumerated()), id: \.offset) { index, row in
                    compareLine(row)
                    if index < compareRows.count - 1 {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: ProfilePalette.cardShadow, radius: 10, y: 4)
            )
        }
    }

    private var compareHeader: some View {
        HStack(spacing: 0) {
            Text("服务内容")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("免费用户")
                .frame(width: 62)
            Text("会员")
                .frame(width: 62)
            Text("点券")
                .frame(width: 78)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(ProfilePalette.muted)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(red: 0.95, green: 0.93, blue: 0.99))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
    }

    private func compareLine(_ row: ProCompareRow) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: row.icon)
                    .font(.system(size: 11))
                    .foregroundColor(ProfilePalette.accent)
                    .frame(width: 14)
                Text(row.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ProfilePalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.free)
                .font(.system(size: 11))
                .foregroundColor(ProfilePalette.muted)
                .frame(width: 62)

            Text(row.member)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ProfilePalette.accent)
                .frame(width: 62)

            Text(row.ticket)
                .font(.system(size: 10))
                .foregroundColor(ProfilePalette.faint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(width: 78)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private var compareRows: [ProCompareRow] {
        [
            .init(icon: "sparkles", name: "专业解读", free: "1次/天", member: "66/88次", ticket: "按需购买"),
            .init(icon: "clock.arrow.circlepath", name: "历史保存", free: "3条", member: "无限", ticket: "按需购买"),
            .init(icon: "bubble.left.fill", name: "提问次数", free: "3轮", member: "66次/卦", ticket: "大师点券可用"),
            .init(icon: "star.fill", name: "大师解读", free: "—", member: "1-2次/月", ticket: "¥12/次"),
            .init(icon: "point.3.connected.trianglepath.dotted", name: "三路推演", free: "—", member: "—", ticket: "¥8/次")
        ]
    }

    private var statusTitle: String {
        switch permissionManager.currentTier {
        case .free: return "免费用户"
        case .proMonthly: return "月度会员"
        case .proYearly: return "年度会员"
        }
    }

    private var statusSubtitle: String {
        switch permissionManager.currentTier {
        case .free:
            return "体验基础功能，开启人生探索之旅"
        case .proMonthly:
            return "每月 66次专业解读 · 每月赠 1次大师解读"
        case .proYearly:
            return "每月 88次专业解读 · 每月赠 2次大师解读"
        }
    }

    private func purchaseSelectedPlan() {
        guard !subscriptionService.isPurchasing, !isStartingPlanPurchase else { return }
        isStartingPlanPurchase = true
        let productID = selectedProductID
        Task {
            defer { isStartingPlanPurchase = false }
            let succeeded = await purchaseProduct(productID, consumable: false)
            if succeeded { finishPurchase() }
        }
    }

    private func finishPurchase() {
        if let onPurchased {
            onPurchased()
            return
        }
        ToastManager.shared.showPurchaseSuccess {
            dismiss()
        }
    }

    @discardableResult
    private func purchaseProduct(_ productID: String, consumable: Bool = true) async -> Bool {
        do {
            if consumable {
                let ok = try await subscriptionService.purchaseConsumable(productID)
                if ok {
                    finishPurchase()
                } else if let message = subscriptionService.purchaseError, !message.isEmpty {
                    purchaseError = message
                }
                return ok
            }
            if subscriptionService.products.first(where: { $0.id == productID }) == nil {
                await subscriptionService.loadProducts()
            }
            guard let product = subscriptionService.products.first(where: { $0.id == productID }) else {
                purchaseError = "商品暂不可用，请稍后重试"
                return false
            }
            let transaction = try await subscriptionService.purchase(product)
            if transaction == nil {
                if let message = subscriptionService.purchaseError, !message.isEmpty {
                    purchaseError = message
                }
                return false
            }
            return true
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }
}

private struct ProCompareRow {
    let icon: String
    let name: String
    let free: String
    let member: String
    let ticket: String
}

#Preview {
    NavigationStack {
        ProUpgradeView()
    }
}
