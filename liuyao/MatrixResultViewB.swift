import SwiftUI

// ============================================================
// MARK: - 五行决策报告（STEP 结构 + 矩阵表格 + 落地手册）
// ============================================================
struct MatrixResultViewB: View {
    let scenario:     DecisionScenario?
    let question:     String
    let options:      [String]
    let matrixResult: DecisionMatrixResultV2?

    @Environment(\.dismiss) private var dismiss

    private var result: DecisionMatrixResultV2 { matrixResult ?? .mock }

    // ── Design Token ────────────────────────────────────────────
    // 背景：极淡冷灰白，不刺眼
    private let bg        = Color(red: 0.973, green: 0.976, blue: 0.984)
    // 卡片：纯白
    private let card      = Color.white
    // 正文：Slate-900 近黑
    private let ink       = Color(red: 0.059, green: 0.090, blue: 0.165)
    // 次要文字：Slate-500
    private let muted     = Color(red: 0.392, green: 0.455, blue: 0.545)
    // 主强调：Indigo-600（深靛蓝）
    private let indigo    = Color(red: 0.306, green: 0.275, blue: 0.898)
    // 浅靛蓝背景色：Indigo-50
    private let indigoBg  = Color(red: 0.933, green: 0.933, blue: 0.992)
    // 语义：补益 Emerald-600
    private let emerald   = Color(red: 0.020, green: 0.588, blue: 0.412)
    // 语义：消耗 Amber-600
    private let amber     = Color(red: 0.855, green: 0.537, blue: 0.145)
    // 语义：忌神 Red-600
    private let danger    = Color(red: 0.863, green: 0.196, blue: 0.196)
    // ────────────────────────────────────────────────────────────

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    verdictHeader
                    stepDivider(tag: "STEP 1", title: "决策评分总览")
                    scoreCards
                    if result.hasFatalRisk {
                        stepDivider(tag: "警告", title: "一票否决")
                        fatalRiskCard
                    }
                    stepDivider(tag: "STEP 2", title: "五行矩阵打分")
                    matrixTable
                    stepDivider(tag: "STEP 3", title: "决策延伸分析")
                    extensionsSection
                    stepDivider(tag: "STEP 4", title: "落地建议手册")
                    actionPlanSection
                    stepDivider(tag: "✦", title: "命理底层逻辑")
                    fiveElementNote
                    Spacer(minLength: 60)
                }
            }
        }
        .navigationTitle("决策报告")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(indigo)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(indigo)
                }
            }
        }
    }

    // MARK: - 顶部头图（深靛蓝夜色渐变）
    private var verdictHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // 深靛蓝渐变背景 — 高级感
            LinearGradient(
                colors: [
                    Color(red: 0.118, green: 0.106, blue: 0.294),
                    Color(red: 0.239, green: 0.216, blue: 0.561)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // 高光晕
            Circle()
                .fill(Color(red: 0.514, green: 0.490, blue: 1.0).opacity(0.18))
                .frame(width: 220).blur(radius: 55)
                .offset(x: 220, y: -50)

            VStack(alignment: .leading, spacing: 18) {
                // 场景标签（毛玻璃感）
                if let scene = scenario {
                    Label(scene.name, systemImage: scene.icon)
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 11).padding(.vertical, 5)
                        .background(.ultraThinMaterial.opacity(0.6), in: Capsule())
                }

                // 主结论行
                HStack(alignment: .center, spacing: 14) {
                    // 对勾圆圈
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                            .frame(width: 48)
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(result.verdict)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.white)
                        Text(result.verdictReason)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.72))
                            .lineSpacing(3)
                            .lineLimit(2)
                    }
                    Spacer()
                    // 奖杯
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.12).opacity(0.2))
                            .frame(width: 50)
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.22))
                    }
                }

                // 选项标签行
                HStack(spacing: 8) {
                    ForEach(result.options) { opt in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(opt.labelColor)
                                .frame(width: 6)
                            Text(opt.label)
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(opt.labelColor)
                            Text(String(opt.name.prefix(6)))
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.white.opacity(0.08), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                }
            }
            .padding(22)
        }
        .frame(minHeight: 220)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color(red: 0.118, green: 0.106, blue: 0.294).opacity(0.40), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 18).padding(.top, 8)
    }

    // MARK: - Step 标题分隔符
    private func stepDivider(tag: String, title: String) -> some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(indigo)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(indigoBg, in: Capsule())
            Text(title)
                .font(.subheadline).fontWeight(.bold).foregroundColor(ink)
            Spacer()
            Rectangle()
                .fill(indigo.opacity(0.15))
                .frame(height: 1)
                .frame(width: 50)
                .cornerRadius(1)
        }
        .padding(.horizontal, 18)
        .padding(.top, 30)
        .padding(.bottom, 14)
    }

    // MARK: - 矩阵打分表
    private var matrixTable: some View {
        VStack(spacing: 0) {
            // 表头
            HStack(spacing: 0) {
                Text("维度")
                    .font(.caption2).fontWeight(.semibold).foregroundColor(muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 14)

                ForEach(result.options) { opt in
                    Text(String(opt.name.prefix(6)))
                        .font(.caption2).fontWeight(.semibold).foregroundColor(muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.vertical, 10)
            .background(Color(red: 0.953, green: 0.957, blue: 0.969))  // Slate-100

            ForEach(result.dimensions.indices, id: \.self) { i in
                matrixRow(dimIdx: i)
                if i < result.dimensions.count - 1 {
                    Rectangle()
                        .fill(Color(red: 0.925, green: 0.929, blue: 0.941))
                        .frame(height: 1)
                        .padding(.leading, 14)
                }
            }
        }
        .background(card, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 18)
    }

    private func matrixRow(dimIdx: Int) -> some View {
        HStack(spacing: 0) {
            Text(result.dimensions[dimIdx])
                .font(.caption).fontWeight(.medium).foregroundColor(ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 14).padding(.vertical, 16)

            ForEach(result.options) { opt in
                let row = dimIdx < opt.matrixRows.count ? opt.matrixRows[dimIdx] : nil
                VStack(spacing: 5) {
                    if let r = row {
                        // 彩色状态图标替换 emoji
                        Image(systemName: r.statusIcon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(r.statusColor)
                        Text(r.label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(r.statusColor)
                        Text(r.detail)
                            .font(.system(size: 9))
                            .foregroundColor(muted)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - 评分卡
    private var scoreCards: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(result.options) { opt in
                scoreCard(opt)
            }
        }
        .padding(.horizontal, 18)
    }

    private func scoreCard(_ opt: DecisionOptionV2) -> some View {
        let isWinner = opt.label == "优选"
        return VStack(spacing: 10) {
            // 顶部标签
            Text(opt.label)
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(opt.labelColor)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(opt.labelColor.opacity(0.10), in: Capsule())

            // 大分数
            Text("\(opt.score)")
                .font(.system(size: 46, weight: .heavy))
                .foregroundColor(isWinner ? indigo : muted)

            Text(opt.verdict)
                .font(.caption).fontWeight(.bold)
                .foregroundColor(opt.verdictColor)
                .padding(.horizontal, 10).padding(.vertical, 3)
                .background(opt.verdictColor.opacity(0.08), in: Capsule())

            // 横向细分割线
            Rectangle()
                .fill(Color(red: 0.922, green: 0.929, blue: 0.941))
                .frame(height: 1).padding(.vertical, 2)

            // 补益/消耗/忌神 三格统计
            HStack(spacing: 0) {
                statCell(count: opt.benefitCount, label: "补益", color: emerald)
                statCell(count: opt.consumeCount, label: "消耗", color: amber)
                statCell(count: opt.dangerCount,  label: "忌神", color: danger)
            }

            // 五行属性标签
            HStack(spacing: 4) {
                ForEach(opt.elements, id: \.self) { el in
                    Text(el)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(FiveElement(rawValue: el)?.color ?? muted)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background((FiveElement(rawValue: el)?.color ?? muted).opacity(0.1), in: Capsule())
                }
            }

            Text(opt.summary)
                .font(.system(size: 11))
                .foregroundColor(muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isWinner ? indigo.opacity(0.30) : Color.clear, lineWidth: 1.5)
        )
        .shadow(
            color: isWinner ? indigo.opacity(0.14) : Color.black.opacity(0.04),
            radius: isWinner ? 14 : 8, x: 0, y: 4
        )
    }

    private func statCell(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 20, weight: .heavy)).foregroundColor(color)
            Text(label)
                .font(.system(size: 9)).foregroundColor(muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 一票否决
    private var fatalRiskCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.title3).foregroundColor(danger)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 5) {
                Text("一票否决 · 高风险警告")
                    .font(.subheadline).fontWeight(.bold).foregroundColor(danger)
                Text(result.fatalRiskDetail)
                    .font(.caption).foregroundColor(ink).lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(danger.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(danger.opacity(0.25), lineWidth: 1.5))
        .padding(.horizontal, 18)
    }

    // MARK: - 决策延伸
    private var extensionsSection: some View {
        VStack(spacing: 10) {
            ForEach(result.extensions.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 12) {
                    // 序号圆
                    Text("\(i + 1)")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(indigo)
                        .frame(width: 26, height: 26)
                        .background(indigoBg, in: Circle())
                    Text(result.extensions[i])
                        .font(.subheadline).foregroundColor(ink).lineSpacing(5)
                    Spacer()
                }
                .padding(14)
                .background(card, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 18)
    }

    // MARK: - 落地建议手册
    private var actionPlanSection: some View {
        let plan = result.actionPlan
        return VStack(spacing: 10) {
            planCard(icon: "calendar.badge.clock",    color: indigo,                         title: "最佳时机", content: plan.timing)
            planCard(icon: "arrow.forward.circle.fill", color: emerald,                      title: "行动方式", content: plan.approach)
            planCard(icon: "shield.slash.fill",        color: danger,                        title: "需要规避", content: plan.avoid)
            planCard(icon: "sparkles",                 color: Color(red: 0.56, green: 0.30, blue: 0.90),
                                                                                             title: "五行补偿", content: plan.compensation)
        }
        .padding(.horizontal, 18)
    }

    private func planCard(icon: String, color: Color, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // 彩色图标块
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption).fontWeight(.bold).foregroundColor(muted)
                Text(content)
                    .font(.subheadline).foregroundColor(ink).lineSpacing(5)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(card, in: RoundedRectangle(cornerRadius: 14))
        // 左侧彩条
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3)
                .padding(.vertical, 10)
                .padding(.leading, 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - 命理底层逻辑
    private var fiveElementNote: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(indigo)
                    .frame(width: 3, height: 16)
                    .cornerRadius(2)
                Text("五行决策逻辑")
                    .font(.caption).fontWeight(.bold).foregroundColor(muted)
            }

            Text(result.fiveElementAnalysis)
                .font(.subheadline).foregroundColor(ink)
                .lineSpacing(7)

            HStack {
                Spacer()
                Text("— 五行决策矩阵")
                    .font(.caption2).foregroundColor(muted.opacity(0.7))
            }
        }
        .padding(18)
        .background(indigoBg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(indigo.opacity(0.10), lineWidth: 1))
        .padding(.horizontal, 18)
    }
}

// MARK: - DecisionOptionV2 Identifiable
extension DecisionOptionV2: Identifiable {
    var id: String { name }
}

#Preview {
    NavigationStack {
        MatrixResultViewB(
            scenario: nil,
            question: "买哪套房更好？",
            options: ["湖畔花园", "阳光金融"],
            matrixResult: .mock
        )
    }
}
