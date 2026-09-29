import SwiftUI

// MARK: - 推演点券购买（设计稿假数据）
// 购买与底部说明入口后续再接。不改动已有的推演报告页。

struct DeductionCouponView: View {
    @Environment(\.dismiss) private var dismiss

    private let buyColor = Color(red: 148.0 / 255, green: 79.0 / 255, blue: 230.0 / 255)

    private let paths: [(String, String, String, String)] = [
        ("arrow.right", "进", "主动推进", "把握机会，积极行动"),
        ("shield.fill", "守", "暂守观望", "保持耐心，等待时机"),
        ("arrow.left", "退", "适时退让", "灵活调整，减少阻力")
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                navBar
                    .padding(.top, topInset)

                VStack(spacing: 14) {
                    introCard
                    analysisCard
                    planCard
                    DecisionBundleCard()
                    faqRow
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
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

    private var navBar: some View {
        ZStack {
            VStack(spacing: 2) {
                Text("推演点券购买")
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
        .padding(.bottom, 6)
    }

    private var introCard: some View {
        HStack(spacing: 14) {
            orb
            VStack(alignment: .leading, spacing: 6) {
                Text("推演点券")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                Text("三条推演路径 · 了解多种可能 · 需要综合本卦")
                    .font(.system(size: 13))
                    .foregroundColor(ProfilePalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var orb: some View {
        Image("YinyangOrb")
            .resizable()
            .scaledToFill()
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .shadow(color: ProfilePalette.accent.opacity(0.28), radius: 8, y: 3)
    }

    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ProfilePalette.accent)
                Text("推演解析")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
            }
            Text("对同一件事在三种不同应对路径下的可能发展进行推演：")
                .font(.system(size: 13))
                .foregroundColor(ProfilePalette.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ForEach(paths, id: \.1) { item in
                    pathCell(icon: item.0, title: item.1, name: item.2, detail: item.3)
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func pathCell(icon: String, title: String, name: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(buyColor, in: Circle())
            Text("\(title) | \(name)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ProfilePalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.system(size: 10))
                .foregroundColor(ProfilePalette.faint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.97, green: 0.96, blue: 0.99))
        )
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ProfilePalette.accent)
                Text("选择购买方案")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
            }

            skuRow(count: 1, unitPrice: nil, note: "三条推演路径（含通知）", price: "¥8")
            skuRow(count: 3, unitPrice: "约 9.3/次", note: "三条推演路径（含通知）· 更划算", price: "¥28")
            skuRow(count: 10, unitPrice: "约 6.3/次", note: "三条推演路径（含通知）· 重度用户首选", price: "¥68")
        }
        .padding(14)
        .background(cardBackground)
    }

    private func skuRow(count: Int, unitPrice: String?, note: String, price: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 184.0 / 255, green: 75.0 / 255, blue: 231.0 / 255),
                            Color(red: 150.0 / 255, green: 42.0 / 255, blue: 198.0 / 255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("推演点券 × \(count)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                    .lineLimit(1)
                if let unitPrice {
                    Text(unitPrice)
                        .font(.system(size: 11))
                        .foregroundColor(ProfilePalette.faint)
                        .lineLimit(1)
                }
                Text(note)
                    .font(.system(size: 11))
                    .foregroundColor(ProfilePalette.faint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(price)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(buyColor)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Button {
                // 购买后续再接
            } label: {
                Text("购买")
            }
            .buttonStyle(AccentBuyButtonStyle(compact: true))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.98, green: 0.97, blue: 1.0))
        )
    }

    private var faqRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(buyColor)
                .frame(width: 36, height: 36)
                .background(buyColor.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("为什么选择推演点券？")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ProfilePalette.ink)
                Text("你可以根据不同的事件，灵活选择推演次数，帮助你做出更好的决策。")
                    .font(.system(size: 12))
                    .foregroundColor(ProfilePalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ProfilePalette.faint)
        }
        .padding(14)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .shadow(color: ProfilePalette.cardShadow, radius: 10, y: 4)
    }
}

#Preview {
    NavigationStack {
        DeductionCouponView()
    }
}
