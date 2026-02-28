import SwiftUI

// ============================================================
// MARK: - 维度状态（本地 UI 用）
// ============================================================
enum DimensionStatus {
    case benefit, consume, danger

    var color: Color {
        switch self {
        case .benefit: return Color(red: 0.1,  green: 0.72, blue: 0.55)
        case .consume: return Color(red: 0.85, green: 0.55, blue: 0.15)
        case .danger:  return Color(red: 0.9,  green: 0.2,  blue: 0.2)
        }
    }
    var bgColor: Color {
        switch self {
        case .benefit: return Color(red: 0.88, green: 0.97, blue: 0.93)
        case .consume: return Color(red: 0.99, green: 0.94, blue: 0.85)
        case .danger:  return Color(red: 1.0,  green: 0.9,  blue: 0.88)
        }
    }
    var icon: String {
        switch self {
        case .benefit: return "arrow.up.circle.fill"
        case .consume: return "arrow.down.circle.fill"
        case .danger:  return "exclamationmark.triangle.fill"
        }
    }
}

struct DecisionDimension: Identifiable {
    let id = UUID()
    let name:        String
    let weight:      Int
    let optionAData: DimensionData
    let optionBData: DimensionData
}

struct DimensionData {
    let title:  String
    let detail: String
    let tags:   [String]
    let icon:   String
    let status: DimensionStatus
}

// ============================================================
// MARK: - 决策结果报告（接收 AI 数据，兜底 Mock）
// ============================================================
struct MatrixResultView: View {
    let scenario:     DecisionScenario?
    let question:     String
    let options:      [String]                // 1~3 个决策选项名称
    let matrixResult: DecisionMatrixResult?   // nil 时使用 mock

    // 使用 AI 结果，若为 nil 则用 mock
    private var result: DecisionMatrixResult { matrixResult ?? .mock }

    private var winnerOption: DecisionOptionResult {
        result.recommendedOption ?? result.options.first ?? .init(
            name: "选项A", score: 85, verdict: "大吉",
            remedyPower: 75, ailmentPower: 16,
            elements: ["水", "木"], tags: ["补益"], summary: ""
        )
    }

    private var optionA: String { options.first ?? winnerOption.name }
    private var optionB: String { options.count > 1 ? options[1] : (result.options.count > 1 ? result.options[1].name : "选项B") }

    // 将 AI 维度数据转换为 UI 用结构
    private var dimensions: [DecisionDimension] {
        result.dimensions.map { dim in
            let a = dim.optionDetails.count > 0 ? dim.optionDetails[0] : MatrixOptionResultDetail(type: "neutral",     elements: "—", description: "—")
            let b = dim.optionDetails.count > 1 ? dim.optionDetails[1] : MatrixOptionResultDetail(type: "neutral",     elements: "—", description: "—")
            return DecisionDimension(
                name: dim.name, weight: dim.weight,
                optionAData: makeDimensionData(from: a),
                optionBData: makeDimensionData(from: b)
            )
        }
    }

    private func makeDimensionData(from detail: MatrixOptionResultDetail) -> DimensionData {
        let status: DimensionStatus
        switch detail.type {
        case "benefit": status = .benefit
        case "danger":  status = .danger
        default:        status = .consume
        }
        return DimensionData(
            title:  detail.elements,
            detail: detail.description,
            tags:   detail.elements
                        .components(separatedBy: CharacterSet(charactersIn: "/[]"))
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty },
            icon:   status.icon,
            status: status
        )
    }

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.94, blue: 0.98).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    verdictBanner
                    comparisonSection
                    scoreBreakdownSection
                    adviceSection
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("决策结果报告")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up").foregroundColor(.primary)
                }
            }
        }
    }

    // MARK: - 顶部定论 Banner
    private var verdictBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.65, blue: 0.72),
                         Color(red: 0.1,  green: 0.45, blue: 0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.2)).frame(width: 52)
                        Image(systemName: "checkmark")
                            .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("优选：\(optionA)")
                            .font(.title3).fontWeight(.bold).foregroundColor(.white)
                        HStack(spacing: 10) {
                            Text("\(winnerOption.score)分")
                                .font(.system(size: 28, weight: .heavy)).foregroundColor(.white)
                            Text("(\(winnerOption.verdict))")
                                .font(.subheadline).foregroundColor(.white.opacity(0.85))
                        }
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.82, blue: 0.1).opacity(0.25))
                            .frame(width: 56)
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                    }
                }
                .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 14)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20).padding(.top, 8)
        .shadow(color: Color(red: 0.1, green: 0.45, blue: 0.75).opacity(0.35), radius: 16, x: 0, y: 8)
    }

    // MARK: - 对比分析（三才维度，横向 A vs B）
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            comparisonHeader
            ForEach(dimensions) { dim in
                dimensionRow(dim)
            }
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    private var comparisonHeader: some View {
        HStack {
            Label("对比分析", systemImage: "arrow.left.arrow.right")
                .font(.headline).fontWeight(.bold)
            Spacer()
            HStack(spacing: 16) {
                Text("A (\(shortName(optionA)))")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.1, green: 0.72, blue: 0.55))
                Text("B (\(shortName(optionB)))")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.85, green: 0.55, blue: 0.15))
            }
        }
    }

    private func dimensionRow(_ dim: DecisionDimension) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dim.name).font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("权重\(dim.weight)%")
                    .font(.caption2).foregroundColor(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(10)
            }
            HStack(spacing: 10) {
                dimCard(dim.optionAData)
                dimCard(dim.optionBData)
            }
        }
        .padding(.bottom, 4)
    }

    private func dimCard(_ data: DimensionData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: data.status.icon)
                    .font(.caption2).foregroundColor(data.status.color)
                Text(data.title)
                    .font(.caption).fontWeight(.semibold).foregroundColor(data.status.color)
            }
            Text(data.detail)
                .font(.caption2).foregroundColor(.secondary).lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(data.status.bgColor, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    data.status.color.opacity(data.status == .danger ? 0.4 : 0.12),
                    lineWidth: data.status == .danger ? 1.5 : 1
                )
        )
    }

    // MARK: - 得分拆解
    private var scoreBreakdownSection: some View {
        let optA = result.options.count > 0 ? result.options[0] : nil
        let optB = result.options.count > 1 ? result.options[1] : nil

        return VStack(alignment: .leading, spacing: 16) {
            Label("得分拆解", systemImage: "chart.bar.fill")
                .font(.headline).fontWeight(.bold).foregroundColor(.purple)

            if let a = optA {
                scoreBarRow(
                    label: "选项A (\(shortName(optionA)))",
                    sideLabel: a.remedyPower > a.ailmentPower ? "补益 > 损耗" : "损耗 > 补益",
                    ratio: a.remedyRatio,
                    barColors: [Color(red: 0.15, green: 0.75, blue: 0.6), Color(red: 0.2, green: 0.55, blue: 0.95)],
                    elementLabel: "● 药力：\(a.elements.joined(separator: "、"))",
                    elementColor: Color(red: 0.2, green: 0.7, blue: 0.9)
                )
            }

            if let b = optB {
                scoreBarRow(
                    label: "选项B (\(shortName(optionB)))",
                    sideLabel: b.ailmentPower > b.remedyPower ? "损耗 > 补益" : "补益 > 损耗",
                    ratio: b.ailmentRatio,
                    barColors: [Color(red: 0.2, green: 0.55, blue: 0.95), Color(red: 0.92, green: 0.5, blue: 0.15)],
                    elementLabel: "● 病灶：\(b.elements.joined(separator: "、"))",
                    elementColor: Color(red: 0.92, green: 0.5, blue: 0.15)
                )
            }
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    private func scoreBarRow(
        label: String, sideLabel: String,
        ratio: Double, barColors: [Color],
        elementLabel: String, elementColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text(sideLabel).font(.caption2).foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5)).frame(height: 10)
                    Capsule()
                        .fill(LinearGradient(colors: barColors,
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * ratio, height: 10)
                }
            }
            .frame(height: 10)
            Text(elementLabel).font(.caption2).fontWeight(.medium).foregroundColor(elementColor)
        }
    }

    // MARK: - 落地建议
    private var adviceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("落地建议", systemImage: "lightbulb.fill")
                .font(.headline).fontWeight(.bold)

            // AI 生成的优选选项 summary
            if !winnerOption.summary.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.7, blue: 0.9))
                        .frame(width: 7).padding(.top, 6)
                    Text(winnerOption.summary)
                        .font(.subheadline).foregroundColor(.primary)
                }
            }

            // 场景具体建议（如有）
            if let scene = scenario {
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(scene.element.color)
                        .frame(width: 7).padding(.top, 6)
                    Text("场景「\(scene.name)」：宜选取与\(winnerOption.elements.joined(separator: "/"))五行相符的时机与方向。")
                        .font(.subheadline).foregroundColor(.primary)
                }
            }

            // 调候物推荐卡片（基于 AI 结果的 elements）
            remedyItemCard
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    private var remedyItemCard: some View {
        let el = winnerOption.remedyElements.first ?? .water
        return HStack(spacing: 12) {
            Image(systemName: el.icon)
                .font(.title3).foregroundColor(el.color)
                .frame(width: 44, height: 44)
                .background(el.color.opacity(0.1))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("调候物推荐").font(.caption).foregroundColor(.secondary)
                Text("增补 \(el.rawValue)元素 (\(el.englishName))")
                    .font(.subheadline).fontWeight(.semibold)
            }
            Spacer()
            Button(action: {}) {
                HStack(spacing: 3) {
                    Text("去商城").font(.caption).fontWeight(.semibold)
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.purple)
            }
        }
        .padding(14)
        .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple.opacity(0.1), lineWidth: 1))
    }

    // 截取选项名前 4 个字符
    private func shortName(_ name: String) -> String { String(name.prefix(4)) }
}

// MARK: - DecisionOptionResult 补充属性
extension DecisionOptionResult {
    var remedyElements: [FiveElement] {
        elements.compactMap { FiveElement(rawValue: $0) }
    }
}

#Preview {
    NavigationStack {
        MatrixResultView(
            scenario: nil,
            question: "在哪里置业更好？",
            options: ["湖畔花园", "阳光金融"],
            matrixResult: .mock
        )
    }
}
