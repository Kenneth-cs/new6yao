import SwiftUI

// MARK: - FiveElement 扩展（全局）
extension FiveElement {
    var color: Color {
        switch self {
        case .wood:  return Color(red: 0.2,  green: 0.78, blue: 0.5)   // 翠绿
        case .fire:  return Color(red: 0.95, green: 0.35, blue: 0.3)   // 赤红
        case .earth: return Color(red: 0.88, green: 0.68, blue: 0.18)  // 橙黄
        case .metal: return Color(red: 0.9,  green: 0.75, blue: 0.2)   // 金色 (原银灰太像普通文本)
        case .water: return Color(red: 0.25, green: 0.52, blue: 0.95)  // 宝蓝
        }
    }

    var englishName: String {
        switch self {
        case .wood:  return "Wood"
        case .fire:  return "Fire"
        case .earth: return "Earth"
        case .metal: return "Metal"
        case .water: return "Water (水)"
        }
    }

    var icon: String {
        switch self {
        case .wood:  return "leaf.fill"
        case .fire:  return "flame.fill"
        case .earth: return "mountain.2.fill"
        case .metal: return "circle.hexagonpath.fill"
        case .water: return "drop.fill"
        }
    }
}

// ============================================================
// MARK: - 五行能量画像首页
// ============================================================
struct EnergyPortraitView: View {

    // 命局画像（默认 Mock，AI 分析后替换）
    @State private var portrait: EnergyPortraitResult = .mock

    // 生日 + 时辰（从本地存储读取初始值）
    @State private var selectedBirthday: Date = BirthInfoStore.shared.birthday
    @State private var selectedHour: ChineseHour = BirthInfoStore.shared.birthHour

    // Sheet 内临时值（取消时丢弃）
    @State private var tempBirthday: Date = BirthInfoStore.shared.birthday
    @State private var tempHour: ChineseHour = BirthInfoStore.shared.birthHour

    @State private var showBirthdayPicker = false

    // AI 分析状态
    @State private var isAnalyzing = false
    @State private var analyzeError: String? = nil

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.94, blue: 0.98).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    birthdayCard
                    if isAnalyzing {
                        analyzeLoadingView
                    } else {
                        FluidEnergyRing(values: portrait.values)
                            .frame(height: 340)
                    }
                    diagnosticCard
                    NavigationLink(destination: ScenarioSelectionView(portrait: portrait)) {
                        startDecisionButton
                    }
                    .padding(.horizontal, 20)
                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("五行能量画像")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.purple)
                }
            }
        }
        .sheet(isPresented: $showBirthdayPicker) {
            birthdayPickerSheet
        }
    }

    // MARK: - 生辰日期卡（可点击修改，含时辰）
    private var birthdayCard: some View {
        Button(action: {
            // 打开 Sheet 时，用临时变量，不直接改正式值
            tempBirthday = selectedBirthday
            tempHour     = selectedHour
            showBirthdayPicker = true
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("生辰八字（点击修改）")
                        .font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        Text(birthdayDisplayString)
                            .font(.subheadline).fontWeight(.semibold)
                        // 时辰 Badge
                        Text("\(selectedHour.rawValue) · \(selectedHour.timeRange)")
                            .font(.caption2).fontWeight(.medium)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.purple.opacity(0.10))
                            .foregroundColor(.purple).cornerRadius(16)
                    }
                    // 八字排盘
                    Text(BaziEngine.shared.getBaziString(date: selectedBirthday, hour: selectedHour))
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundColor(.primary.opacity(0.8))
                        .padding(.vertical, 2)
                    
                    // 日主（AI 分析后显示）
                    if !portrait.dayMaster.isEmpty {
                        Text("日主：\(portrait.dayMaster)  |  喜：\(portrait.favorableElements.joined(separator: "/"))  忌：\(portrait.unfavorableElements.joined(separator: "/"))")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                Spacer()
                if isAnalyzing {
                    ProgressView().tint(.purple)
                } else {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2).foregroundColor(.purple)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private var birthdayDisplayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy年MM月dd日"
        return f.string(from: selectedBirthday)
    }

    // MARK: - 分析中占位
    private var analyzeLoadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2.0)
                .tint(.purple)
            Text("AI 正在推算命局中...")
                .font(.subheadline).foregroundColor(.secondary)
            Text("约需 5~10 秒，请稍候")
                .font(.caption).foregroundColor(.secondary.opacity(0.7))
        }
        .frame(height: 340)
    }

    // MARK: - 能量诊断卡
    private var diagnosticCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("能量诊断", systemImage: "sparkles")
                    .font(.headline).fontWeight(.bold)
                Spacer()
                if isAnalyzing {
                    Text("分析中...")
                        .font(.caption).foregroundColor(.purple)
                }
            }

            Text(portrait.diagnosis)
                .font(.body).foregroundColor(.secondary).lineSpacing(5)

            if let err = analyzeError {
                Label(err, systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundColor(.orange)
            }

            Divider()

            let rem = portrait.remedyFiveElement
            HStack(spacing: 12) {
                Image(systemName: rem.icon)
                    .font(.title2).foregroundColor(rem.color)
                    .frame(width: 46, height: 46)
                    .background(rem.color.opacity(0.1))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("急需补充").font(.caption).foregroundColor(.secondary)
                    Text("\(rem.rawValue)能量")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(rem.color)
                }
                Spacer()
                // 喜用神 Tag 行
                VStack(alignment: .trailing, spacing: 4) {
                    Text("喜用神").font(.caption2).foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        ForEach(portrait.favorableFiveElements, id: \.rawValue) { el in
                            Text(el.rawValue)
                                .font(.caption2).fontWeight(.semibold)
                                .foregroundColor(el.color)
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(el.color.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    // MARK: - 开始决策按钮
    private var startDecisionButton: some View {
        HStack(spacing: 10) {
            Text("开始决策")
                .font(.headline).fontWeight(.semibold)
            Image(systemName: "arrow.right")
                .font(.headline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [Color(red: 0.45, green: 0.3, blue: 0.85),
                         Color(red: 0.6,  green: 0.35, blue: 0.9)],
                startPoint: .leading, endPoint: .trailing
            ),
            in: Capsule()
        )
        .shadow(color: Color.purple.opacity(0.35), radius: 12, x: 0, y: 6)
    }

    // MARK: - 生日 + 时辰选择器 Sheet
    private var birthdayPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── 日期选择 ──
                VStack(alignment: .leading, spacing: 6) {
                    Label("出生日期", systemImage: "calendar")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                    DatePicker(
                        "",
                        selection: $tempBirthday,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 16)

                Divider().padding(.vertical, 8)

                // ── 时辰选择 ──
                VStack(alignment: .leading, spacing: 10) {
                    Label("出生时辰", systemImage: "clock.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)

                    // 时辰提示说明
                    Text("时辰影响时柱天干地支，影响五行比例约 10~20%")
                        .font(.caption).foregroundColor(.secondary)
                        .padding(.horizontal, 20)

                    // 滚轮选择器
                    Picker("时辰", selection: $tempHour) {
                        ForEach(ChineseHour.allCases, id: \.self) { h in
                            Text("\(h.rawValue)  (\(h.timeRange))")
                                .tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 140)
                    .clipped()
                }

                Spacer()

                // ── 确认按钮 ──
                Button(action: {
                    // 保存到本地 + 更新当前页状态
                    selectedBirthday = tempBirthday
                    selectedHour     = tempHour
                    BirthInfoStore.shared.save(birthday: tempBirthday, hour: tempHour)
                    showBirthdayPicker = false
                    analyzePortrait()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("确认并 AI 推算命局")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.45, green: 0.3, blue: 0.85),
                                     Color(red: 0.6,  green: 0.35, blue: 0.9)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("修改生辰")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { showBirthdayPicker = false }
                }
            }
        }
    }

    // MARK: - 调用 AI 分析生辰（携带时辰）
    private func analyzePortrait() {
        isAnalyzing = true
        analyzeError = nil
        Task {
            do {
                let result = try await AIService.shared.analyzeEnergyPortrait(
                    birthday:  selectedBirthday,
                    birthHour: selectedHour
                )
                await MainActor.run {
                    portrait = result
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    analyzeError = "AI 分析暂时失败，已显示示例数据"
                    isAnalyzing = false
                }
                print("[EnergyPortraitView] AI 分析失败: \(error)")
            }
        }
    }
}

// ============================================================
// MARK: - 动态流体圆环（比例色段版，最终版）
// ============================================================
struct FluidEnergyRing: View {
    let values: [FiveElement: Double]
    @State private var glowing = false

    // 五行相生顺序（从正上方顺时针）
    private let elementOrder: [FiveElement] = [.fire, .earth, .metal, .water, .wood]

    private var dominantElement: FiveElement {
        values.max(by: { $0.value < $1.value })?.key ?? .fire
    }

    // 计算每段的 trim 起止点（按能量值比例）
    private var segments: [(element: FiveElement, start: Double, end: Double)] {
        let total = max(elementOrder.reduce(0.0) { $0 + (values[$1] ?? 0) }, 0.001)
        var result: [(FiveElement, Double, Double)] = []
        var cumulative = 0.0
        for el in elementOrder {
            let frac = (values[el] ?? 0.001) / total
            result.append((el, cumulative, cumulative + frac))
            cumulative += frac
        }
        return result
    }

    // 根据段中点角度计算标签偏移
    private func labelOffset(start: Double, end: Double, radius: CGFloat = 150) -> CGSize {
        let mid = (start + end) / 2.0
        let angle = mid * 2.0 * .pi - (.pi / 2.0)
        return CGSize(width: radius * CGFloat(cos(angle)), height: radius * CGFloat(sin(angle)))
    }

    var body: some View {
        ZStack {
            // 1. 底层轨道
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 44)
                .padding(38)

            // 2. 主导元素柔光晕
            Circle()
                .stroke(dominantElement.color.opacity(glowing ? 0.22 : 0.06), lineWidth: 58)
                .padding(28)
                .blur(radius: 16)

            // 3. 比例色段（核心）
            ForEach(0..<segments.count, id: \.self) { i in
                segmentArc(index: i)
            }

            // 4. 方位标签（跟随各段中点）
            ForEach(0..<segments.count, id: \.self) { i in
                let seg = segments[i]
                let offset = labelOffset(start: seg.start, end: seg.end)
                elementLabelView(element: seg.element, offset: offset)
            }

            // 5. 中心文字
            centerLabel
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                glowing = true
            }
        }
    }

    // MARK: - 单段圆弧
    private func segmentArc(index: Int) -> some View {
        let seg = segments[index]
        let isWeak = (values[seg.element] ?? 0) < 0.08
        let gap = 0.006
        let from = seg.start + gap / 2
        let to   = max(seg.end - gap / 2, from + 0.001)

        return Circle()
            .trim(from: from, to: to)
            .stroke(
                seg.element.color.opacity(isWeak ? 0.3 : 1.0),
                style: StrokeStyle(
                    lineWidth: 44, lineCap: .butt,
                    dash: isWeak ? [6, 5] : []
                )
            )
            .rotationEffect(.degrees(-90))
            .padding(38)
            .shadow(
                color: (index == 0 ? seg.element.color.opacity(0.3) : .clear),
                radius: 8
            )
    }

    // MARK: - 元素标签
    private func elementLabelView(element: FiveElement, offset: CGSize) -> some View {
        let isDominant = element == dominantElement
        return Text(isDominant ? "\(element.rawValue) (\(element.englishName))" : element.rawValue)
            .font(isDominant ? .caption : .caption2)
            .fontWeight(.semibold)
            .foregroundColor(element.color)
            .offset(offset)
    }

    // MARK: - 中心
    private var centerLabel: some View {
        let isDominant = (values[dominantElement] ?? 0) > 0.3
        return VStack(spacing: 4) {
            Text(isDominant ? "强\(dominantElement.rawValue)" : "中和")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.purple)
            Text(isDominant ? "能量过旺" : "平衡佳境")
                .font(.caption).foregroundColor(.secondary)
        }
        .frame(width: 120, height: 120)
        .background(Color(.systemBackground).opacity(0.95))
        .clipShape(Circle())
        .shadow(color: dominantElement.color.opacity(0.15), radius: 10)
    }
}

// ============================================================
// MARK: - 通用主按钮（全局复用）
// ============================================================
struct MatrixPrimaryButton: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title).font(.headline)
            Image(systemName: icon)
        }
        .frame(maxWidth: .infinity).padding()
        .background(
            LinearGradient(
                colors: [Color(red: 0.45, green: 0.3, blue: 0.85),
                         Color(red: 0.6,  green: 0.35, blue: 0.9)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .foregroundColor(.white).cornerRadius(16)
        .shadow(color: Color.purple.opacity(0.35), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    NavigationStack { EnergyPortraitView() }
}
