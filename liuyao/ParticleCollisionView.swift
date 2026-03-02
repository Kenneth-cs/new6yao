import SwiftUI

// MARK: - 五行能量碰撞页（沉浸式深色 + 粒子轨道动效）
struct ParticleCollisionView: View {
    let portrait:  EnergyPortraitResult
    let scenario:  DecisionScenario?
    let question:  String
    let options:   [String]

    var optionA: String { options.first ?? "选项A" }
    var optionB: String { options.count > 1 ? options[1] : "选项B" }

    // ── 流程状态 ──
    @State private var phase: CollisionPhase = .idle
    @State private var progressText  = "解析五行属性..."
    @State private var progressValue: Double = 0.0
    @State private var showWarning   = false
    @State private var showCompletion = false
    @State private var navigateToResult = false

    // ── 轨道动效 ──
    @State private var orbitAngle: Double = 0    // 粒子公转驱动角（0 → 2π×100）
    @State private var ring1Angle: Double = 0    // 外环旋转
    @State private var ring2Angle: Double = 0    // 中环旋转（反向）
    @State private var ring3Angle: Double = 0    // 内环旋转
    @State private var centerPulse: Double = 1.0 // 中心呼吸
    @State private var starPhase:   Double = 0   // 星星闪烁相位
    @State private var starRot1:    Double = 0   // 近景星层旋转（顺）
    @State private var starRot2:    Double = 0   // 远景星层旋转（逆）

    // ── 粒子吸收 ──
    @State private var particlesAbsorbed = false

    // ── 警告特效 ──
    @State private var redVignette: Double = 0
    @State private var shakeOffset: CGFloat = 0

    // ── AI 状态 ──
    @State private var matrixResultV2: DecisionMatrixResultV2? = nil
    @State private var animationDone = false

    // 五行轨道粒子定义：(element, 轨道半径, 速度倍率, 初始相位°, 粒子直径)
    // 速度倍率须为 0.1 的整数倍，保证 100 圈后连续无跳变
    private let orbitDefs: [(FiveElement, CGFloat, Double, Double, CGFloat)] = [
        (.wood,  108, 1.3,  0,    10),
        (.fire,  118, 0.8, 72,     9),
        (.earth, 100, 1.1, 144,   11),
        (.metal, 122, 0.7, 216,    9),
        (.water, 112, 1.5, 288,   10),
    ]

    // 生克关系标签
    private let clashLabels: [(String, CGFloat, CGFloat, Color)] = [
        ("水生木", -118, -88, Color(red: 0.30, green: 0.80, blue: 0.60)),
        ("火克金",  118, -68, Color(red: 0.95, green: 0.40, blue: 0.30)),
        ("木生火", -128,  68, Color(red: 0.40, green: 0.75, blue: 0.45)),
        ("土克水",  112,  88, Color(red: 0.88, green: 0.68, blue: 0.18)),
    ]

    enum CollisionPhase { case idle, running, done }

    var body: some View {
        ZStack {
            cosmicBackground
            orbitRings
            orbitingParticlesLayer
            clashLabelLayer
            centerPool
            // 红色警告晕（熔断时）
            if showWarning {
                RadialGradient(
                    colors: [.clear, Color.red.opacity(redVignette)],
                    center: .center, startRadius: 80, endRadius: 420
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                Spacer()
                Group {
                    if showWarning {
                        warningCard.transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if showCompletion {
                        completionCard.transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        progressCard
                    }
                }
                .padding(.bottom, 24)
            }
            .animation(.spring(response: 0.5), value: showWarning)
            .animation(.spring(response: 0.5), value: showCompletion)
        }
        .offset(x: shakeOffset)
        .navigationTitle("五行能量碰撞")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $navigateToResult) {
            MatrixResultViewB(
                scenario: scenario,
                question: question,
                options: options,
                matrixResult: matrixResultV2
            )
        }
        .onAppear {
            startOrbitAnimations()
            startAnimation()
            startAIAnalysis()
        }
    }

    // MARK: - 宇宙背景（深空 + 星云 + 闪烁星点）
    private var cosmicBackground: some View {
        ZStack {
            // 纯黑深空底色
            Color(red: 0.01, green: 0.01, blue: 0.05).ignoresSafeArea()

            // 中央星云光晕（稍增强）
            RadialGradient(
                colors: [
                    Color(red: 0.20, green: 0.08, blue: 0.50).opacity(0.60),
                    Color(red: 0.08, green: 0.03, blue: 0.22).opacity(0.25),
                    .clear,
                ],
                center: .center, startRadius: 0, endRadius: 300
            ).ignoresSafeArea()

            // 远景星群（偶数索引，慢速顺转）
            ZStack {
                ForEach(starData.indices.filter { $0 % 2 == 0 }, id: \.self) { i in
                    let s = starData[i]
                    let brightness = s.baseOpacity * (0.65 + 0.35 * sin(starPhase * s.speed + s.phase))
                    ZStack {
                        // 大星发光晕
                        if s.size >= 3 {
                            Circle()
                                .fill(Color.white.opacity(brightness * 0.25))
                                .frame(width: s.size * 3)
                                .blur(radius: s.size)
                        }
                        Circle()
                            .fill(Color.white)
                            .frame(width: s.size)
                    }
                    .position(x: s.x, y: s.y)
                    .opacity(brightness)
                }
            }
            .rotationEffect(.degrees(starRot1))

            // 近景星群（奇数索引，逆转，视差）
            ZStack {
                ForEach(starData.indices.filter { $0 % 2 == 1 }, id: \.self) { i in
                    let s = starData[i]
                    let brightness = s.baseOpacity * (0.70 + 0.30 * sin(starPhase * s.speed + s.phase))
                    ZStack {
                        if s.size >= 3 {
                            Circle()
                                .fill(Color.white.opacity(brightness * 0.30))
                                .frame(width: s.size * 3)
                                .blur(radius: s.size)
                        }
                        Circle()
                            .fill(Color.white)
                            .frame(width: s.size + 0.5)
                    }
                    .position(x: s.x, y: s.y)
                    .opacity(brightness)
                }
            }
            .rotationEffect(.degrees(-starRot2))
        }
    }

    // MARK: - 三层旋转轨道环
    private var orbitRings: some View {
        ZStack {
            // 外层渐变椭圆环（顺时针慢转）
            Ellipse()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.30, green: 0.55, blue: 0.90).opacity(0.04),
                            Color(red: 0.50, green: 0.35, blue: 0.95).opacity(0.30),
                            Color(red: 0.30, green: 0.70, blue: 0.90).opacity(0.10),
                            Color(red: 0.30, green: 0.55, blue: 0.90).opacity(0.04),
                        ],
                        center: .center
                    ),
                    lineWidth: 1.0
                )
                .frame(width: 262, height: 244)
                .rotationEffect(.degrees(ring1Angle))

            // 中层虚线环（逆时针中速转）
            Circle()
                .stroke(
                    style: StrokeStyle(lineWidth: 0.8, dash: [4, 10])
                )
                .foregroundColor(Color(red: 0.55, green: 0.40, blue: 0.90).opacity(0.20))
                .frame(width: 206, height: 206)
                .rotationEffect(.degrees(-ring2Angle))

            // 内层光晕环（顺时针较快转）
            Ellipse()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.20, green: 0.85, blue: 0.70).opacity(0.04),
                            Color(red: 0.20, green: 0.85, blue: 0.70).opacity(0.35),
                            Color(red: 0.20, green: 0.85, blue: 0.70).opacity(0.04),
                        ],
                        center: .center
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 152, height: 142)
                .rotationEffect(.degrees(ring3Angle))
        }
        .opacity(phase == .idle ? 0 : 1)
        .animation(.easeIn(duration: 1.2), value: phase)
    }

    // MARK: - 五行轨道粒子（公转 + 吸收动画）
    private var orbitingParticlesLayer: some View {
        ZStack {
            ForEach(orbitDefs.indices, id: \.self) { i in
                let def    = orbitDefs[i]
                let phase0 = def.3 * .pi / 180.0
                let speed  = def.2
                let angle  = orbitAngle * speed + phase0
                let radius: CGFloat = particlesAbsorbed ? 0 : def.1

                ZStack {
                    // 光晕
                    Circle()
                        .fill(def.0.color.opacity(0.22))
                        .frame(width: def.4 + 12)
                        .blur(radius: 6)
                    // 粒子核心
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [def.0.color, def.0.color.opacity(0.55)],
                                center: .center,
                                startRadius: 0,
                                endRadius: def.4 / 2
                            )
                        )
                        .frame(width: def.4)
                        .shadow(color: def.0.color.opacity(0.85), radius: 7)
                    // 元素标签
                    Text(def.0.rawValue)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .offset(y: def.4 / 2 + 7)
                }
                .offset(
                    x: cos(angle) * radius,
                    y: sin(angle) * radius
                )
                .scaleEffect(particlesAbsorbed ? 0.05 : 1.0)
                .opacity(phase == .idle ? 0 : (particlesAbsorbed ? 0 : 1))
                .animation(.easeIn(duration: Double(i) * 0.12 + 0.5), value: phase)
                .animation(.spring(response: 0.55, dampingFraction: 0.65), value: particlesAbsorbed)
            }
        }
    }

    // MARK: - 生克关系浮标
    private var clashLabelLayer: some View {
        ZStack {
            ForEach(clashLabels, id: \.0) { item in
                Text(item.0)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(item.3.opacity(0.80))
                    .offset(x: item.1, y: item.2)
            }
        }
        .opacity(phase == .running || phase == .done ? 1 : 0)
        .animation(.easeIn(duration: 1.0).delay(1.3), value: phase)
    }

    // MARK: - 中心命局池（黑洞）
    private var centerPool: some View {
        ZStack {
            // 外脉冲光晕
            Circle()
                .fill(
                    showWarning
                    ? Color.red.opacity(0.12)
                    : Color(red: 0.25, green: 0.40, blue: 0.90).opacity(0.10)
                )
                .frame(width: 192)
                .scaleEffect(centerPulse)
                .blur(radius: 10)

            // 中层光环
            Circle()
                .stroke(
                    showWarning
                    ? Color.red.opacity(0.40)
                    : Color(red: 0.30, green: 0.70, blue: 1.00).opacity(0.30),
                    lineWidth: 1.5
                )
                .frame(width: 142)
                .scaleEffect(centerPulse * 0.96)

            // 主体黑洞
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.07, green: 0.06, blue: 0.16),
                            Color(red: 0.04, green: 0.03, blue: 0.10),
                        ],
                        center: .center, startRadius: 0, endRadius: 55
                    )
                )
                .frame(width: 110)
                .overlay(
                    Circle().stroke(
                        showWarning
                        ? Color.red.opacity(0.55)
                        : Color(red: 0.25, green: 0.42, blue: 0.70).opacity(0.50),
                        lineWidth: 1.5
                    )
                )
                .shadow(
                    color: showWarning
                    ? Color.red.opacity(0.45)
                    : Color(red: 0.20, green: 0.50, blue: 1.00).opacity(0.35),
                    radius: 18
                )

            // 中心火球
            Circle()
                .fill(
                    RadialGradient(
                        colors: showWarning
                        ? [Color(red: 1.0, green: 0.18, blue: 0.08), Color(red: 0.65, green: 0.0, blue: 0.0)]
                        : [Color(red: 1.0, green: 0.52, blue: 0.10), Color(red: 0.85, green: 0.20, blue: 0.10)],
                        center: .center, startRadius: 0, endRadius: 30
                    )
                )
                .frame(width: 60)
                .shadow(
                    color: showWarning ? Color.red.opacity(0.75) : Color.orange.opacity(0.55),
                    radius: 14
                )
                .scaleEffect(centerPulse * (showWarning ? 1.08 : 1.0))

            Image(systemName: showWarning ? "exclamationmark.triangle.fill" : "flame.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .animation(.easeInOut(duration: 0.4), value: showWarning)
    }

    // MARK: - 顶部选项面板
    private var topPanel: some View {
        VStack {
            HStack(spacing: 14) {
                optionBadge(name: optionA, color: Color(red: 0.20, green: 0.80, blue: 0.65))
                Image(systemName: "bolt.fill").foregroundColor(.yellow).font(.caption)
                optionBadge(name: optionB, color: Color(red: 1.00, green: 0.50, blue: 0.20))
            }
            .padding(.top, 12)
            Spacer()
        }
    }

    private func optionBadge(name: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7)
            Text(name)
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(color).lineLimit(1)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.12)).cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.30), lineWidth: 1))
    }

    // MARK: - 底部进度区（无矩形背景，文案居中在进度条上方）
    private var progressCard: some View {
        VStack(spacing: 10) {
            // 文案 + 百分比居中
            HStack(spacing: 8) {
                Text(progressText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.75))
                Text("\(Int(progressValue * 100))%")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.45))
            }
            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 4)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.85, blue: 0.70),
                                    Color(red: 0.35, green: 0.55, blue: 1.00),
                                ],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * progressValue), height: 4)
                        .shadow(color: Color(red: 0.20, green: 0.70, blue: 0.90).opacity(0.7), radius: 6)
                        .animation(.easeInOut(duration: 0.6), value: progressValue)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - 完成卡
    private var completionCard: some View {
        let winner  = matrixResultV2?.recommendedOption
        let score   = winner?.score  ?? 0
        let verdict = winner?.verdict ?? "吉"

        return VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Color(red: 0.20, green: 0.80, blue: 0.65))
                    .font(.title3)
                Text("五行契合度分析完成")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
            }

            if let w = winner {
                HStack(spacing: 6) {
                    Text("优选").font(.caption).foregroundColor(Color.white.opacity(0.5))
                    Text(w.name)
                        .font(.title3).fontWeight(.bold).foregroundColor(.white)
                    Text("·").foregroundColor(Color.white.opacity(0.3))
                    Text("\(score)分")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.20, green: 0.80, blue: 0.65))
                    Text("(\(verdict))").font(.caption).foregroundColor(Color.white.opacity(0.55))
                }
            }

            Button(action: { navigateToResult = true }) {
                HStack(spacing: 8) {
                    Text("查看完整报告")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                    Image(systemName: "arrow.right")
                        .font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.white).cornerRadius(14)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.06, green: 0.09, blue: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(red: 0.20, green: 0.80, blue: 0.65).opacity(0.55), lineWidth: 1.5)
                )
        )
        .shadow(color: Color(red: 0.20, green: 0.80, blue: 0.65).opacity(0.20), radius: 24)
        .padding(.horizontal, 20).padding(.bottom, 34)
    }

    // MARK: - 熔断警告卡
    private var warningCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red).font(.title3)
                Text("⚡ 高风险冲突检测！")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
            }
            Text(
                matrixResultV2?.fatalRiskDetail.isEmpty == false
                ? matrixResultV2!.fatalRiskDetail
                : "检测到强力冲突，动摇根基，需谨慎抉择。\n建议暂缓行动或寻求化解方案。"
            )
            .font(.subheadline).foregroundColor(Color.white.opacity(0.75))
            .multilineTextAlignment(.center).lineSpacing(4)

            Button(action: { navigateToResult = true }) {
                Text("查看详情")
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.white).cornerRadius(14)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.10, green: 0.06, blue: 0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.red.opacity(0.55), lineWidth: 1.5)
                )
        )
        .shadow(color: Color.red.opacity(0.30), radius: 24)
        .padding(.horizontal, 20).padding(.bottom, 34)
    }

    // MARK: - 启动所有轨道动效
    private func startOrbitAnimations() {
        // 粒子公转：20s/圈，共100圈后重置（cos/sin 连续无跳变）
        withAnimation(.linear(duration: 2000).repeatForever(autoreverses: false)) {
            orbitAngle = 2 * .pi * 100
        }
        // 外环：28s 顺转
        withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
            ring1Angle = 360
        }
        // 中环：18s 逆转
        withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
            ring2Angle = 360
        }
        // 内环：11s 顺转
        withAnimation(.linear(duration: 11).repeatForever(autoreverses: false)) {
            ring3Angle = 360
        }
        // 中心呼吸
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            centerPulse = 1.15
        }
        // 星星闪烁
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            starPhase = 2 * .pi
        }
        // 远景星群：70s 顺时针一圈
        withAnimation(.linear(duration: 70).repeatForever(autoreverses: false)) {
            starRot1 = 360
        }
        // 近景星群：45s 逆时针一圈（视差）
        withAnimation(.linear(duration: 45).repeatForever(autoreverses: false)) {
            starRot2 = 360
        }
    }

    // MARK: - 动画进度流程
    private func startAnimation() {
        let steps: [(Double, String, Double)] = [
            (0.3,  "解析五行属性...", 0.15),
            (1.0,  "计算命局强弱...", 0.38),
            (2.0,  "模拟粒子碰撞...", 0.58),
            (3.0,  "分析五行生克...", 0.78),
            (3.8,  "生成决策报告...", 0.92),
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            phase = .running
        }
        for (delay, text, val) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    progressText  = text
                    progressValue = val
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            withAnimation { progressValue = 1.0; phase = .done }
            animationDone = true
            tryNavigateToResult()
        }
    }

    // MARK: - AI 分析（与动画并行）
    private func startAIAnalysis() {
        let scenarioName = scenario?.name ?? "通用决策"
        let validOptions = options.isEmpty ? [optionA, optionB] : options
        Task {
            do {
                let result = try await AIService.shared.analyzeDecisionMatrixV2(
                    portrait: portrait, options: validOptions,
                    scenario: scenarioName, question: question
                )
                await MainActor.run {
                    matrixResultV2 = result
                    // 扣除本次使用次数
                    PermissionManager.shared.incrementFiveElementDecisionCount()
                    // 保存历史记录
                    let record = MatrixDecisionRecord(
                        scenario: scenario, question: question,
                        options: validOptions, result: result
                    )
                    MatrixHistoryStore.shared.save(record)
                    tryNavigateToResult()
                }
            } catch {
                await MainActor.run {
                    matrixResultV2 = .mock
                    tryNavigateToResult()
                }
            }
        }
    }

    // MARK: - 动画 + AI 双完成后触发结果
    private func tryNavigateToResult() {
        guard animationDone, matrixResultV2 != nil else { return }

        if matrixResultV2?.hasFatalRisk == true {
            withAnimation { progressText = "⚡ 检测到强力冲突！" }
            withAnimation(.spring(response: 0.5)) { showWarning = true }
            triggerWarningEffects()
        } else {
            withAnimation { progressText = "✅ 分析完成" }
            // 粒子先飞向中心，再浮出完成卡
            withAnimation(.spring(response: 0.55)) { particlesAbsorbed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.5)) { showCompletion = true }
            }
        }
    }

    // MARK: - 屏幕震动 + 红晕（熔断）
    private func triggerWarningEffects() {
        // 屏幕震动序列
        let offsets: [CGFloat] = [0, -14, 14, -10, 10, -7, 7, -4, 4, -2, 2, 0]
        for (i, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.055) {
                withAnimation(.interactiveSpring(response: 0.1)) { shakeOffset = offset }
            }
        }
        // 红晕脉冲
        withAnimation(.easeInOut(duration: 0.5).repeatCount(5, autoreverses: true)) {
            redVignette = 0.14
        }
    }

    // MARK: - 星点数据（x, y, baseOpacity, size, twinkleSpeed, twinklePhase）
    private let starData: [StarPoint] = [
        // 亮星（size≥3，会产生光晕）
        .init( 50,  80, 0.90, 3.5, 1.2, 0.0), .init(280,  90, 0.85, 4.0, 1.5, 2.2),
        .init(320, 150, 0.80, 3.0, 1.0, 1.8), .init( 40, 350, 0.85, 3.5, 0.9, 0.9),
        .init(120, 450, 0.80, 3.0, 0.7, 1.4), .init(160, 520, 0.85, 3.5, 1.4, 0.3),
        .init(380, 100, 0.80, 3.0, 0.6, 3.3), .init(360, 360, 0.75, 3.5, 1.3, 0.6),
        .init(230,  60, 0.80, 3.0, 0.7, 2.0), .init( 70, 320, 0.78, 3.5, 0.9, 0.4),
        // 中等星
        .init(150,  40, 0.70, 2.5, 0.8, 1.1), .init( 80, 200, 0.65, 2.5, 0.6, 0.5),
        .init(200, 300, 0.68, 2.5, 1.3, 3.1), .init(350, 280, 0.60, 2.0, 1.6, 2.5),
        .init(300, 420, 0.65, 2.5, 1.1, 3.5), .init(380, 380, 0.62, 2.0, 0.5, 2.8),
        .init( 60, 550, 0.68, 2.5, 1.7, 1.6), .init(240, 480, 0.70, 2.5, 0.8, 0.8),
        .init(340, 520, 0.62, 2.0, 1.2, 4.0), .init(100, 600, 0.68, 2.5, 1.0, 2.1),
        .init( 20, 160, 0.60, 2.0, 1.5, 1.7), .init(190, 180, 0.58, 2.0, 0.9, 2.9),
        .init( 10,  40, 0.65, 2.5, 1.1, 1.3), .init(400, 220, 0.60, 2.0, 1.4, 3.8),
        .init(250, 140, 0.65, 2.5, 1.2, 2.7), .init(310,  50, 0.70, 2.5, 0.8, 1.5),
        // 密集小星（填充感）
        .init( 30, 120, 0.55, 1.5, 1.0, 2.3), .init(200,  50, 0.50, 1.5, 1.3, 0.7),
        .init(420, 320, 0.52, 1.5, 0.9, 3.0), .init(140, 280, 0.55, 1.5, 1.6, 1.9),
        .init(370, 480, 0.50, 1.5, 1.1, 4.2), .init( 90, 400, 0.55, 1.5, 0.7, 0.2),
        .init(260, 560, 0.52, 1.5, 1.4, 2.6), .init(430,  80, 0.50, 1.5, 0.6, 1.0),
        .init( 15, 480, 0.55, 1.5, 1.2, 3.6), .init(170, 370, 0.50, 1.5, 0.8, 1.4),
        .init(310, 240, 0.52, 1.5, 1.5, 0.8), .init( 80,  30, 0.55, 1.5, 1.0, 2.9),
        .init(200, 610, 0.50, 1.5, 1.3, 1.8), .init(420, 560, 0.52, 1.5, 0.7, 3.4),
    ]
}

// MARK: - 星点数据模型
private struct StarPoint {
    let x, y: CGFloat
    let baseOpacity: Double
    let size: CGFloat
    let speed, phase: Double
    init(_ x: CGFloat, _ y: CGFloat, _ o: Double, _ s: CGFloat, _ sp: Double, _ ph: Double) {
        self.x = x; self.y = y; self.baseOpacity = o
        self.size = s; self.speed = sp; self.phase = ph
    }
}

// MARK: - 兼容性辅助（其他文件可能引用）
struct FloatingDot: Identifiable {
    let id    = UUID()
    let color: Color
    let size:  CGFloat
    let x, y:  CGFloat
    let delay: Double
}

struct ParticleItem: Identifiable {
    let id = UUID()
    var originX, originY, targetX, targetY: CGFloat
    var color: Color
    var size: CGFloat
    var element: FiveElement
    var launched = false
}

#Preview {
    NavigationStack {
        ParticleCollisionView(
            portrait: .mock,
            scenario: nil,
            question: "去腾讯还是阿里？",
            options: ["腾讯", "阿里"]
        )
    }
}
