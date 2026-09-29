import SwiftUI

// MARK: - 决策套餐（大师 + 推演）
// 大师解读、推演两个购买页共用。购买按钮后续再接。

struct DecisionBundleCard: View {
    private let buyColor = Color(red: 148.0 / 255, green: 79.0 / 255, blue: 230.0 / 255)

    private let includes = [
        "大师解读 × 1（15 段深度报告）",
        "推演解读 × 1（三路推演报告）",
        "无限追问（本卦内）"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(buyColor)
                Text("决策套餐（大师 + 推演）")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ProfilePalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text("推荐")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(buyColor, in: Capsule())
                Spacer(minLength: 0)
            }

            Text("大师报告 + 三路推演 + 无限追问（本卦内）")
                .font(.system(size: 13))
                .foregroundColor(ProfilePalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("决策套餐 × 1")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ProfilePalette.ink)
                        .lineLimit(1)
                    Spacer()
                    Text("热门")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.45, blue: 0.28),
                                    Color(red: 0.96, green: 0.32, blue: 0.45)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                }
                Text("深度剖析、多维对比，给出最优建议")
                    .font(.system(size: 13))
                    .foregroundColor(ProfilePalette.muted)
                HStack {
                    Text("¥18")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(buyColor)
                    Spacer()
                    Button {
                        // 套餐购买后续再接
                    } label: {
                        Text("购买")
                    }
                    .buttonStyle(AccentBuyButtonStyle(compact: false))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.93, blue: 1.0),
                                Color(red: 0.97, green: 0.94, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("套餐包含内容")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ProfilePalette.ink)
                ForEach(includes, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(buyColor)
                        Text(item)
                            .font(.system(size: 13))
                            .foregroundColor(ProfilePalette.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: ProfilePalette.cardShadow, radius: 10, y: 4)
        )
    }
}

struct AccentBuyButtonStyle: ButtonStyle {
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 15, weight: .bold))
            .foregroundColor(.white)
            .frame(width: compact ? 72 : 96, height: compact ? 34 : 40)
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
            .shadow(color: Color(red: 0.95, green: 0.40, blue: 0.28).opacity(configuration.isPressed ? 0.15 : 0.38), radius: 6, y: 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
