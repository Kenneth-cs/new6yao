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

    // 命局画像（nil = 未设置生辰 / 未曾分析）
    @State private var portrait: EnergyPortraitResult? = nil

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

    // 便于在 body 中判断是否已设置生辰
    private var hasBirthday: Bool { BirthInfoStore.shared.hasSetBirthday }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.95, green: 0.94, blue: 0.98).ignoresSafeArea()

            if hasBirthday || portrait != nil {
                // ── 已设置生辰：主内容 ──────────────────────────
                if isAnalyzing {
                    // 空占位，加载蒙层由外层 ZStack 统一覆盖
                    Color.clear
                } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        birthdayCard
                        if let p = portrait {
                            FiveElementDiagram(portrait: p)
                                .frame(height: 320)
                        }
                        if let p = portrait {
                            diagnosticCard(p)
                        }
                        Spacer(minLength: 110)
                    }
                    .padding(.top, 8)
                }
                }

                // ── 悬浮底部 CTA（分析中隐藏）─────────────────────
                if !isAnalyzing {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.94, blue: 0.98).opacity(0),
                            Color(red: 0.95, green: 0.94, blue: 0.98)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 32)
                    .allowsHitTesting(false)

                    VStack(spacing: 8) {
                        if let p = portrait {
                            NavigationLink(destination: ScenarioSelectionView(portrait: p)) {
                                stickyDecisionButton(p)
                            }
                            .padding(.horizontal, 20)
                            .disabled(isAnalyzing)
                        }
                        Text("基于你的八字命局，AI 为你分析最优选项")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.75))
                            .padding(.bottom, 8)
                    }
                    .background(Color(red: 0.95, green: 0.94, blue: 0.98))
                }
                } // end if !isAnalyzing
            } else {
                // ── 未设置生辰：引导空状态 ──────────────────────
                emptyStateView
            }
        }
        .navigationTitle("五行能量画像")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if hasBirthday {
                    Button(action: {
                        tempBirthday = selectedBirthday
                        tempHour     = selectedHour
                        showBirthdayPicker = true
                    }) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .sheet(isPresented: $showBirthdayPicker) {
            birthdayPickerSheet
        }
        .onAppear { loadOnAppear() }
        // ── 加载蒙层：无论哪个状态都能正确覆盖 ──────────────────
        .overlay {
            if isAnalyzing {
                simpleLoadingOverlay
            }
        }
    }

    // MARK: - 启动时加载逻辑
    private func loadOnAppear() {
        guard hasBirthday else { return }   // 未设置生辰，显示空状态
        selectedBirthday = BirthInfoStore.shared.birthday
        selectedHour     = BirthInfoStore.shared.birthHour

        if let cached = BirthInfoStore.shared.loadPortrait() {
            // 命中缓存，直接显示，无需请求 AI
            portrait = cached
        } else {
            // 有生辰但无缓存，自动触发分析
            analyzePortrait()
        }
    }

    // MARK: - 生辰日期卡（可点击修改，含时辰）
    private var birthdayCard: some View {
        Button(action: {
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
                        Text("\(selectedHour.rawValue) · \(selectedHour.timeRange)")
                            .font(.caption2).fontWeight(.medium)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.purple.opacity(0.10))
                            .foregroundColor(.purple).cornerRadius(16)
                    }
                    Text(BaziEngine.shared.getBaziString(date: selectedBirthday, hour: selectedHour))
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundColor(.primary.opacity(0.8))
                        .padding(.vertical, 2)
                    if let p = portrait, !p.dayMaster.isEmpty {
                        Text("日主：\(p.dayMaster)  |  喜：\(p.favorableElements.joined(separator: "/"))  忌：\(p.unfavorableElements.joined(separator: "/"))")
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

    // MARK: - 加载蒙层（简单，叠在最外层保证可见）
    private var simpleLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.6)
                    .tint(.white)
                Text("大师推算命局中...")
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundColor(.white)
                Text("约需 10～20 秒，请稍候")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.18, green: 0.12, blue: 0.32).opacity(0.95))
            )
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: isAnalyzing)
    }


    // MARK: - 能量诊断卡
    private func diagnosticCard(_ p: EnergyPortraitResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("能量诊断", systemImage: "sparkles")
                    .font(.headline).fontWeight(.bold)
                Spacer()
                // 缓存角标
                Label("已缓存", systemImage: "checkmark.icloud.fill")
                    .font(.caption2).foregroundColor(.purple.opacity(0.6))
            }

            Text(p.diagnosis)
                .font(.body).foregroundColor(.secondary).lineSpacing(5)

            if let err = analyzeError {
                Label(err, systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundColor(.orange)
            }

            Divider()

            let rem = p.remedyFiveElement
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
                VStack(alignment: .trailing, spacing: 4) {
                    Text("喜用神").font(.caption2).foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        ForEach(p.favorableFiveElements, id: \.rawValue) { el in
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

    // MARK: - 悬浮决策按钮
    private func stickyDecisionButton(_ p: EnergyPortraitResult) -> some View {
        HStack(spacing: 0) {
            let el = p.favorableFiveElements.first
            Image(systemName: el?.icon ?? "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 46, height: 46)
                .background(Color.white.opacity(0.15), in: Circle())
                .padding(.leading, 8)

            Spacer()

            VStack(spacing: 3) {
                Text("开始五行决策分析")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text("喜\(p.favorableElements.joined(separator: "/")) · 忌\(p.unfavorableElements.joined(separator: "/"))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.75))
            }

            Spacer()

            ZStack {
                Circle().fill(Color.white.opacity(0.2)).frame(width: 36, height: 36)
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .heavy)).foregroundColor(.white)
            }
            .padding(.trailing, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.40, green: 0.25, blue: 0.82),
                         Color(red: 0.62, green: 0.32, blue: 0.92)],
                startPoint: .leading, endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .shadow(color: Color.purple.opacity(0.42), radius: 16, x: 0, y: 8)
    }

    // MARK: - 空状态引导页（未设置生辰）
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // 图形区
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.08))
                        .frame(width: 140, height: 140)
                    Circle()
                        .fill(Color.purple.opacity(0.06))
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.crop.circle.badge.clock")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.45, green: 0.3, blue: 0.85),
                                         Color(red: 0.6,  green: 0.35, blue: 0.9)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }

                // 文案区
                VStack(spacing: 10) {
                    Text("输入生辰，解锁你的五行命局")
                        .font(.title3).fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text("AI 将根据你的出生日期和时辰\n推算八字五行能量分布，生成专属命局画像")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // 要点列表
                VStack(alignment: .leading, spacing: 12) {
                    emptyStateFeatureRow(icon: "chart.pie.fill",    color: .purple,
                                         text: "五行能量比例可视化图")
                    emptyStateFeatureRow(icon: "sparkles",          color: .orange,
                                         text: "AI 智能诊断你的命局特质")
                    emptyStateFeatureRow(icon: "arrow.triangle.branch", color: .teal,
                                         text: "个性化决策喜忌神指引")
                }
                .padding(.horizontal, 24)
                .padding(16)
                .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)

                // 主按钮
                Button(action: {
                    tempBirthday = selectedBirthday
                    tempHour     = selectedHour
                    showBirthdayPicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                        Text("立即输入生辰")
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
                    .cornerRadius(16)
                    .shadow(color: Color.purple.opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    private func emptyStateFeatureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body).foregroundColor(color)
                .frame(width: 28)
            Text(text)
                .font(.subheadline).foregroundColor(.primary.opacity(0.75))
        }
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
                    selectedBirthday = tempBirthday
                    selectedHour     = tempHour
                    BirthInfoStore.shared.save(birthday: tempBirthday, hour: tempHour)
                    BirthInfoStore.shared.clearPortraitCache()  // 生辰变更，清除旧缓存
                    portrait = nil                               // 清空当前显示
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

    // MARK: - 调用 AI 分析生辰（携带时辰），成功后写缓存
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
                    portrait    = result
                    isAnalyzing = false
                    BirthInfoStore.shared.savePortrait(result)  // 写入本地缓存
                }
            } catch {
                await MainActor.run {
                    // 失败时加载旧缓存；若无缓存则展示 mock 并标注错误
                    if portrait == nil {
                        portrait = BirthInfoStore.shared.loadPortrait() ?? .mock
                    }
                    analyzeError = "AI 推算暂时失败，已显示上次结果"
                    isAnalyzing  = false
                }
                print("[EnergyPortraitView] AI 分析失败: \(error)")
            }
        }
    }
}

// ============================================================
// MARK: - 五行五星图（参考图一：节点 + 生弧 + 克星线 + 日主圆心）
// ============================================================
struct FiveElementDiagram: View {
    let portrait: EnergyPortraitResult
    @State private var appeared = false
    @State private var pulse    = false

    // 五角形方位顺时针从顶部：火→土→金→水→木
    // 对应五行相生顺序：木生火→火生土→土生金→金生水→水生木
    private let elements: [FiveElement] = [.fire, .earth, .metal, .water, .wood]

    // 解析日主所属五行（"丁火" → .fire）
    private var dayMasterEl: FiveElement? {
        let dm = portrait.dayMaster
        if dm.contains("木") { return .wood  }
        if dm.contains("火") { return .fire  }
        if dm.contains("土") { return .earth }
        if dm.contains("金") { return .metal }
        if dm.contains("水") { return .water }
        return nil
    }

    private func pct(_ el: FiveElement) -> Int {
        Int(round((portrait.values[el] ?? 0) * 100))
    }

    // 五角形节点位置（index 0 = 顶部，顺时针）
    private func nodePos(i: Int, cx: CGFloat, cy: CGFloat, R: CGFloat) -> CGPoint {
        let a = Double(i) * (2 * .pi / 5) - .pi / 2
        return CGPoint(x: cx + R * CGFloat(cos(a)), y: cy + R * CGFloat(sin(a)))
    }

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            let cx = W / 2
            let cy = H / 2
            let R  = min(W, H) * 0.36          // 节点轨道半径
            let arcR = R + 22                   // 生-弧半径（稍外）

            ZStack {
                // ── 淡色背景圆 ──────────────────────────────
                Circle()
                    .fill(Color(red: 0.98, green: 0.96, blue: 0.94).opacity(0.8))
                    .frame(width: R * 2 + 90, height: R * 2 + 90)

                // ── 克-星形线（连接间隔1的节点，形成五芒星）──
                ForEach(0..<5, id: \.self) { i in
                    let p1 = nodePos(i: i,       cx: cx, cy: cy, R: R - 26)
                    let p2 = nodePos(i: (i+2)%5, cx: cx, cy: cy, R: R - 26)
                    Path { path in
                        path.move(to: p1)
                        path.addLine(to: p2)
                    }
                    .stroke(
                        elements[i].color.opacity(0.22),
                        style: StrokeStyle(lineWidth: 1, lineCap: .round)
                    )
                }

                // ── 克 标签（分散在圆心附近四角）────────────
                let keOffsets: [(CGFloat, CGFloat)] = [(0,-12),(10,4),(-10,4),(0,14),(-12,-4)]
                ForEach(0..<5, id: \.self) { i in
                    Text("克")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(elements[i].color.opacity(0.50))
                        .position(x: cx + keOffsets[i].0, y: cy + keOffsets[i].1)
                }

                // ── 生-弧线（顺时针弧，从节点 i 到 i+1）────
                ForEach(0..<5, id: \.self) { i in
                    generationArc(i: i, cx: cx, cy: cy, arcR: arcR)
                }

                // ── 元素节点 ───────────────────────────────
                ForEach(0..<5, id: \.self) { i in
                    nodeView(i: i, cx: cx, cy: cy, R: R)
                }

                // ── 圆心：日主 ─────────────────────────────
                dayMasterCenter
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.88)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    // MARK: - 生-弧（圆弧段 + "生"标签 + 箭头）
    private func generationArc(i: Int, cx: CGFloat, cy: CGFloat, arcR: CGFloat) -> some View {
        let startDeg = Double(i) * 72.0 - 90.0 + 13.0     // 留出节点间隙
        let endDeg   = Double((i+1)%5) * 72.0 - 90.0 - 13.0
        // endDeg 可能小于 startDeg（如 i=4 时 endDeg=-103, startDeg=211）
        // 需要加 360 后再取中点，否则标签会跑到对面
        let normEnd  = endDeg < startDeg ? endDeg + 360.0 : endDeg
        let midDeg   = (startDeg + normEnd) / 2.0
        let midRad   = midDeg * .pi / 180.0
        let endRad   = endDeg * .pi / 180.0
        let labelR   = arcR + 13

        // 箭头尖端
        let tipX = cx + arcR * CGFloat(cos(endRad))
        let tipY = cy + arcR * CGFloat(sin(endRad))
        // 顺时针切线方向 (−sinθ, cosθ)
        let tx = CGFloat(-sin(endRad))
        let ty = CGFloat( cos(endRad))
        let wLen: CGFloat = 5.5
        let wAngle = 0.45  // ~26°
        let cw = CGFloat(cos(wAngle)), sw = CGFloat(sin(wAngle))
        let w1 = CGPoint(x: tipX + wLen * ((-tx)*cw - (-ty)*sw), y: tipY + wLen * ((-tx)*sw + (-ty)*cw))
        let w2 = CGPoint(x: tipX + wLen * ((-tx)*cw + (-ty)*sw), y: tipY + wLen * (-(-tx)*sw + (-ty)*cw))

        let arcColor = Color(red: 0.55, green: 0.45, blue: 0.38).opacity(0.55)

        return ZStack {
            // 弧线
            Path { p in
                p.addArc(center: CGPoint(x: cx, y: cy), radius: arcR,
                         startAngle: .degrees(startDeg),
                         endAngle:   .degrees(endDeg),
                         clockwise: false)
            }
            .stroke(arcColor, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))

            // 箭头
            Path { p in
                p.move(to: w1)
                p.addLine(to: CGPoint(x: tipX, y: tipY))
                p.addLine(to: w2)
            }
            .stroke(arcColor, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))

            // "生" 标签
            Text("生")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.38).opacity(0.7))
                .position(
                    x: cx + labelR * CGFloat(cos(midRad)),
                    y: cy + labelR * CGFloat(sin(midRad))
                )
        }
    }

    // MARK: - 元素节点
    private func nodeView(i: Int, cx: CGFloat, cy: CGFloat, R: CGFloat) -> some View {
        let el    = elements[i]
        let pt    = nodePos(i: i, cx: cx, cy: cy, R: R)
        let isDM  = el == dayMasterEl
        let v     = portrait.values[el] ?? 0

        return ZStack {
            // 日主外光环（脉冲）
            if isDM {
                Circle()
                    .stroke(el.color.opacity(pulse ? 0.35 : 0.12), lineWidth: 2)
                    .frame(width: 68, height: 68)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)
            }
            // 节点圆
            Circle()
                .fill(
                    LinearGradient(
                        colors: [el.color.opacity(v > 0.22 ? 1.0 : 0.68),
                                 el.color.opacity(v > 0.22 ? 0.78 : 0.48)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .shadow(color: el.color.opacity(0.25), radius: 6, x: 0, y: 3)

            // 元素字 + 百分比
            VStack(spacing: 1) {
                Text(el.rawValue)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.white)
                Text("\(pct(el))%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.88))
            }

            // 日主 Badge
            if isDM {
                Text("日主")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color(red: 0.08, green: 0.60, blue: 0.42), in: Capsule())
                    .offset(y: 38)
            }
        }
        .position(pt)
    }

    // MARK: - 圆心：日主
    private var dayMasterCenter: some View {
        let el = dayMasterEl
        let ringColor = el?.color ?? Color.purple
        return ZStack {
            // 外柔光晕
            Circle()
                .fill(ringColor.opacity(pulse ? 0.12 : 0.05))
                .frame(width: 90, height: 90)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)

            // 白底圆
            Circle()
                .fill(Color.white)
                .frame(width: 72, height: 72)
                .shadow(color: ringColor.opacity(0.18), radius: 10)

            // 彩色描边
            Circle()
                .stroke(ringColor, lineWidth: 2.2)
                .frame(width: 72, height: 72)

            // 日主文字
            VStack(spacing: 2) {
                if portrait.dayMaster.isEmpty {
                    Text("命局")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.purple)
                } else {
                    Text(portrait.dayMaster)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(ringColor)
                    Text("日主")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
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
