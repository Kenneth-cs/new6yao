import SwiftUI

// MARK: - 决策场景数据模型
struct DecisionScenario: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let englishName: String
    let icon: String
    let element: FiveElement
    let inputPlaceholder: String
}

// MARK: - 五行场景选择页
struct ScenarioSelectionView: View {
    let portrait: EnergyPortraitResult   // 从 EnergyPortraitView 传入
    @Environment(\.dismiss) private var dismiss

    @State private var selectedScenario: DecisionScenario? = nil
    @State private var optionInputs: [String] = [""]
    @State private var navigateToParticle = false

    let scenarios: [DecisionScenario] = [
        .init(name: "事业/学业", subtitle: "职位升迁 · 创业择业",
              englishName: "Career", icon: "graduationcap.fill",
              element: .wood, inputPlaceholder: "输入公司/学校名称"),
        .init(name: "投资/理财", subtitle: "股权 · 楼市 · 基金",
              englishName: "Wealth", icon: "dollarsign.circle.fill",
              element: .water, inputPlaceholder: "输入投资标的名称"),
        .init(name: "情感/人际", subtitle: "感情 · 合伙 · 社交",
              englishName: "Love", icon: "heart.fill",
              element: .fire, inputPlaceholder: "描述人际选项"),
        .init(name: "置业/生活", subtitle: "购房 · 装修 · 搬迁",
              englishName: "Living", icon: "house.fill",
              element: .earth, inputPlaceholder: "输入楼盘/地点名称"),
        .init(name: "出行/其他", subtitle: "旅行 · 移居 · 杂事",
              englishName: "Travel", icon: "airplane.departure",
              element: .metal, inputPlaceholder: "描述出行选项")
    ]

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.94, blue: 0.98).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    scenarioGrid
                    if selectedScenario != nil {
                        decisionOptionsCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedScenario?.id)
        }
        .navigationTitle("场景选择")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.purple)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToParticle) {
            ParticleCollisionView(
                portrait: portrait,
                scenario: selectedScenario,
                question: "",
                options: optionInputs.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
        }
    }

    // MARK: - 场景卡片网格（前4个2×2，第5个全宽）
    private var scenarioGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("选择决策场景")
                .font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)

            // 2×2 前4张
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(scenarios.prefix(4)) { scenario in
                    coloredScenarioCard(scenario)
                }
            }

            // 第5张：全宽，带"自定义场景"标签
            fullWidthScenarioCard(scenarios[4])
        }
    }

    // MARK: - 彩色渐变场景卡片
    private func coloredScenarioCard(_ scenario: DecisionScenario) -> some View {
        let isSelected = selectedScenario?.id == scenario.id
        return Button(action: {
            withAnimation(.spring(response: 0.3)) { selectedScenario = scenario }
        }) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                scenario.element.color.opacity(0.18),
                                scenario.element.color.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 晕染圆形装饰
                Circle()
                    .fill(scenario.element.color.opacity(0.15))
                    .frame(width: 70).blur(radius: 20)
                    .offset(x: 30, y: -20)

                // 内容
                VStack(alignment: .leading, spacing: 8) {
                    // 图标
                    Image(systemName: scenario.icon)
                        .font(.title2)
                        .foregroundColor(scenario.element.color)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.6))
                        .clipShape(Circle())

                    Spacer()

                    // 名称 + 英文+元素标签
                    VStack(alignment: .leading, spacing: 3) {
                        Text(scenario.name)
                            .font(.subheadline).fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("\(scenario.englishName) · [\(scenario.element.rawValue)]")
                            .font(.caption2)
                            .foregroundColor(scenario.element.color)
                    }
                }
                .padding(16)
            }
            .frame(height: 140)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? scenario.element.color.opacity(0.6) : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? scenario.element.color.opacity(0.25) : Color.black.opacity(0.05),
                    radius: isSelected ? 12 : 6, x: 0, y: 3)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 第5张全宽卡片
    private func fullWidthScenarioCard(_ scenario: DecisionScenario) -> some View {
        let isSelected = selectedScenario?.id == scenario.id
        return Button(action: {
            withAnimation(.spring(response: 0.3)) { selectedScenario = scenario }
        }) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.secondarySystemBackground))

                HStack(spacing: 14) {
                    Image(systemName: scenario.icon)
                        .font(.title2)
                        .foregroundColor(scenario.element.color)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.7))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(scenario.name)
                            .font(.subheadline).fontWeight(.bold)
                        Text("\(scenario.englishName) · [\(scenario.element.rawValue)]")
                            .font(.caption2).foregroundColor(scenario.element.color)
                    }

                    Spacer()

                    Text("自定义场景")
                        .font(.caption2).foregroundColor(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(10)
                }
                .padding(16)
            }
            .frame(height: 76)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? scenario.element.color.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 决策选项输入卡
    private var decisionOptionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 标题
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: 3, height: 18)
                    .cornerRadius(2)
                Text("决策选项")
                    .font(.headline).fontWeight(.bold)
            }

            // 已添加的选项输入框
            ForEach(optionInputs.indices, id: \.self) { i in
                optionInputRow(index: i)
            }

            // 添加对比项按钮（最多3个）
            if optionInputs.count < 3 {
                Button(action: { withAnimation { optionInputs.append("") } }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.purple)
                        Text("添加对比项 (\(optionInputs.count - 1)/3)")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundColor(Color.purple.opacity(0.35))
                    )
                }
            }

            // 开始分析按钮
            Button(action: { navigateToParticle = true }) {
                HStack(spacing: 8) {
                    Text("开始决策分析")
                        .font(.headline).fontWeight(.semibold)
                    Image(systemName: "sparkles")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.45, green: 0.3, blue: 0.85), Color(red: 0.6, green: 0.35, blue: 0.9)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .shadow(color: .purple.opacity(0.35), radius: 10, x: 0, y: 5)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 5)
    }

    private func optionInputRow(index: Int) -> some View {
        let chineseNums = ["一", "二", "三"]
        let label = "选项\(chineseNums[safe: index] ?? "\(index + 1)")"
        return HStack(spacing: 10) {
            Text(label)
                .font(.caption2).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.purple.opacity(0.75), in: Capsule())
            TextField(selectedScenario?.inputPlaceholder ?? "输入选项名称", text: $optionInputs[index])
                .font(.subheadline)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }
}

// MARK: - 单个场景卡片（复用组件，保留向后兼容）
struct ScenarioCard: View {
    let scenario: DecisionScenario
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: scenario.icon)
                        .font(.title2).foregroundColor(scenario.element.color)
                        .frame(width: 44, height: 44)
                        .background(scenario.element.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                    Text(scenario.element.rawValue)
                        .font(.caption2).fontWeight(.bold)
                        .foregroundColor(scenario.element.color)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(scenario.element.color.opacity(0.12)).cornerRadius(20)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(scenario.name).font(.subheadline).fontWeight(.bold).foregroundColor(.primary)
                    Text(scenario.subtitle).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? scenario.element.color.opacity(0.1) : Color.white.opacity(0.85),
                        in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? scenario.element.color.opacity(0.5) : Color.gray.opacity(0.1),
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04),
                    radius: isSelected ? 10 : 6, x: 0, y: 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 自定义场景卡片（保留向后兼容）
struct CustomScenarioCard: View {
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2).foregroundColor(.purple)
                    .frame(width: 44, height: 44)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text("自定义场景").font(.subheadline).fontWeight(.bold).foregroundColor(.primary)
                    Text("其他未分类决策").font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundColor(Color.purple.opacity(0.3))
                    )
            )
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack { ScenarioSelectionView(portrait: .mock) }
}
