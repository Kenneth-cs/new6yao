import SwiftUI

// MARK: - 五行能量碰撞页（沉浸式深色 + 底部警告卡 + AI 实时分析）
struct ParticleCollisionView: View {
    let portrait:  EnergyPortraitResult   // 从 ScenarioSelectionView 传入
    let scenario:  DecisionScenario?
    let question:  String
    let options:   [String]               // 1~3 个决策选项

    // 便捷访问
    var optionA: String { options.first ?? "选项A" }
    var optionB: String { options.count > 1 ? options[1] : "选项B" }

    // ── 动画状态 ──
    @State private var phase: CollisionPhase = .idle
    @State private var progressText  = "解析五行属性..."
    @State private var progressValue: Double = 0.0
    @State private var centerPulse   = false
    @State private var showWarning   = false
    @State private var showCompletion = false
    @State private var warningPulse  = false
    @State private var navigateToResult = false
    @State private var floatingDots: [FloatingDot] = []

    // ── AI 分析状态 ──
    @State private var matrixResult: DecisionMatrixResult? = nil
    @State private var animationDone = false   // 动画进度完成标志

    // 五行生克关系浮标（静态定义）
    private let clashLabels: [(text: String, x: CGFloat, y: CGFloat, color: Color)] = [
        ("水生木",  -120, -90,  Color(red: 0.3, green: 0.8, blue: 0.6)),
        ("火克金",   120, -70,  Color(red: 0.95, green: 0.4, blue: 0.3)),
        ("木生火",  -130,  70,  Color(red: 0.4, green: 0.75, blue: 0.45)),
        ("土克水",   115,  90,  Color(red: 0.88, green: 0.68, blue: 0.18)),
    ]

    enum CollisionPhase { case idle, running, done }

    var body: some View {
        ZStack {
            cosmicBg
            orbitRing
            clashLabelLayer
            floatingDotsLayer
            centerPool
            topPanel

            // 底部：进度卡 or 熔断警告卡（固定底部，非 Sheet）
            VStack {
                Spacer()
                if showWarning {
                    warningCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if showCompletion {
                    completionCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    progressCard
                }
            }
            .animation(.spring(response: 0.5), value: showWarning)
            .animation(.spring(response: 0.5), value: showCompletion)
        }
        .navigationTitle("五行能量碰撞")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToResult) {
            MatrixResultView(
                scenario: scenario,
                question: question,
                options: options,
                matrixResult: matrixResult
            )
        }
        .onAppear {
            setupDots()
            startAnimation()
            startAIAnalysis()   // 与动画并行启动
        }
    }

    // MARK: - 宇宙背景
    private var cosmicBg: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.14).ignoresSafeArea()
            RadialGradient(
                colors: [Color(red: 0.15, green: 0.12, blue: 0.35).opacity(0.7), .clear],
                center: .center, startRadius: 20, endRadius: 200
            ).ignoresSafeArea()
            ForEach(starData.indices, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(starData[i].2))
                    .frame(width: starData[i].3)
                    .position(x: starData[i].0, y: starData[i].1)
            }
            if showWarning {
                Color.red.opacity(warningPulse ? 0.08 : 0.02)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: warningPulse)
            }
        }
    }

    // MARK: - 虚线轨道环
    private var orbitRing: some View {
        Circle()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 6]))
            .foregroundColor(Color(red: 0.3, green: 0.55, blue: 0.8).opacity(0.35))
            .frame(width: 260, height: 260)
    }

    // MARK: - 五行生克浮标
    private var clashLabelLayer: some View {
        ZStack {
            ForEach(clashLabels, id: \.text) { item in
                Text(item.text)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(item.color)
                    .offset(x: item.x, y: item.y)
            }
        }
        .opacity(phase == .running || phase == .done ? 1 : 0)
        .animation(.easeIn(duration: 0.8).delay(1.0), value: phase)
    }

    // MARK: - 散布五行小点
    private var floatingDotsLayer: some View {
        ZStack {
            ForEach(floatingDots) { dot in
                Circle()
                    .fill(dot.color)
                    .frame(width: dot.size)
                    .shadow(color: dot.color.opacity(0.6), radius: 4)
                    .offset(x: dot.x, y: dot.y)
                    .opacity(phase == .idle ? 0 : 1)
                    .animation(.easeIn(duration: 0.6).delay(dot.delay), value: phase)
            }
        }
    }

    // MARK: - 中心命局池
    private var centerPool: some View {
        ZStack {
            Circle()
                .fill(showWarning
                      ? Color.red.opacity(0.15)
                      : Color(red: 0.2, green: 0.35, blue: 0.75).opacity(0.12))
                .frame(width: 180)
                .scaleEffect(centerPulse ? 1.12 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: centerPulse)

            Circle()
                .fill(Color(red: 0.06, green: 0.06, blue: 0.1))
                .frame(width: 110)
                .overlay(Circle().stroke(Color(red: 0.2, green: 0.3, blue: 0.5).opacity(0.5), lineWidth: 1.5))
                .shadow(color: Color.blue.opacity(0.3), radius: 15)

            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 1.0, green: 0.45, blue: 0.1),
                             Color(red: 0.85, green: 0.2, blue: 0.1)],
                    center: .center, startRadius: 0, endRadius: 30
                ))
                .frame(width: 60)
                .shadow(color: Color.orange.opacity(0.5), radius: 12)

            Image(systemName: showWarning ? "exclamationmark.triangle.fill" : "flame.fill")
                .font(.title3).foregroundColor(.white)
        }
        .animation(.easeInOut(duration: 0.4), value: showWarning)
    }

    // MARK: - 顶部信息面板
    private var topPanel: some View {
        VStack {
            if !question.isEmpty || !optionA.isEmpty {
                VStack(spacing: 8) {
                    if !question.isEmpty {
                        Text(question)
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(Color.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    HStack(spacing: 14) {
                        optionBadge(name: optionA, color: Color(red: 0.2,  green: 0.8, blue: 0.65))
                        Image(systemName: "bolt.fill").foregroundColor(.yellow).font(.caption)
                        optionBadge(name: optionB, color: Color(red: 1.0, green: 0.5,  blue: 0.2))
                    }
                }
                .padding(.top, 12).padding(.bottom, 10)
            }
            Spacer()
        }
    }

    private func optionBadge(name: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7)
            Text(name).font(.caption).fontWeight(.semibold).foregroundColor(color).lineLimit(1)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.12)).cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.25), lineWidth: 1))
    }

    // MARK: - 底部进度卡
    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(progressText).font(.caption).foregroundColor(Color.white.opacity(0.6))
                Spacer()
                Text("\(Int(progressValue * 100))%").font(.caption).foregroundColor(Color.white.opacity(0.4))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.2, green: 0.75, blue: 0.65),
                                     Color(red: 0.2, green: 0.5,  blue: 0.95)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * progressValue, height: 4)
                        .animation(.easeInOut(duration: 0.5), value: progressValue)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 30).padding(.vertical, 16).padding(.bottom, 20)
    }

    // MARK: - 底部完成提示卡（固定，非弹出层）
    private var completionCard: some View {
        let winner = matrixResult?.recommendedOption ?? matrixResult?.options.first
        let score = winner?.score ?? 0
        let verdict = winner?.verdict ?? "吉"
        
        return VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.65))
                    .font(.title3)
                Text("五行契合度分析完成")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
            }
            
            if let w = winner {
                Text("优选：\(w.name)  |  \(score)分 (\(verdict))")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Button(action: { navigateToResult = true }) {
                Text("查看完整报告")
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.white).cornerRadius(14)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.06, green: 0.1, blue: 0.15))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(red: 0.2, green: 0.8, blue: 0.65).opacity(0.5), lineWidth: 1.5))
        )
        .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.65).opacity(0.25), radius: 20)
        .padding(.horizontal, 20).padding(.bottom, 34)
    }

    // MARK: - 底部熔断警告卡（固定，非弹出层）
    private var warningCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red).font(.title3)
                Text("冲突检测！高风险！")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
            }
            Text(matrixResult?.fatalRiskReason.isEmpty == false
                 ? matrixResult!.fatalRiskReason
                 : "在订：强力冲突，动摇根基，需谨慎抉择非吉之灶。\n建议暂缓行动或寻求化解方案。")
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
                .fill(Color(red: 0.1, green: 0.06, blue: 0.12))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.red.opacity(0.5), lineWidth: 1.5))
        )
        .shadow(color: Color.red.opacity(0.25), radius: 20)
        .padding(.horizontal, 20).padding(.bottom, 34)
    }

    // MARK: - 动画流程（UI 时序）
    private func startAnimation() {
        let steps: [(Double, String, Double)] = [
            (0.3,  "解析五行属性...",  0.15),
            (1.0,  "计算命局强弱...",  0.38),
            (2.0,  "模拟粒子碰撞...",  0.58),
            (3.0,  "分析五行生克...",  0.78),
            (3.8,  "生成决策报告...",  0.92)
        ]
        for (delay, text, val) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    progressText = text
                    progressValue = val
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            phase = .running
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                centerPulse = true
            }
        }
        // 动画 4.3s 后标记完成，再等 AI 结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            withAnimation { progressValue = 1.0; phase = .done }
            animationDone = true
            tryNavigateToResult()
        }
    }

    // MARK: - 后台启动 AI 分析（与动画并行）
    private func startAIAnalysis() {
        let scenarioName = scenario?.name ?? "通用决策"
        let validOptions = options.isEmpty ? [optionA, optionB] : options

        Task {
            do {
                let result = try await AIService.shared.analyzeDecisionMatrix(
                    portrait: portrait,
                    options: validOptions,
                    scenario: scenarioName,
                    question: question
                )
                await MainActor.run {
                    matrixResult = result
                    print("[ParticleCollisionView] AI 分析完成，推荐: \(result.recommendation)")
                    tryNavigateToResult()
                }
            } catch {
                await MainActor.run {
                    print("[ParticleCollisionView] AI 分析失败，使用 Mock: \(error)")
                    matrixResult = .mock
                    tryNavigateToResult()
                }
            }
        }
    }

    // MARK: - 等待动画 + AI 都完成后跳转
    private func tryNavigateToResult() {
        guard animationDone, matrixResult != nil else { return }

        let hasFatal = matrixResult?.hasFatalRisk ?? false
        if hasFatal {
            withAnimation { progressText = "⚡ 检测到强力冲突！" }
            withAnimation(.spring(response: 0.5)) { showWarning = true }
            warningPulse = true
            // 警告展示 3s 后允许用户自行点击或自动跳转
        } else {
            withAnimation { progressText = "✅ 分析完成" }
            withAnimation(.spring(response: 0.5)) { showCompletion = true }
            // 移除自动跳转，等待用户点击
            // DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            //    navigateToResult = true
            // }
        }
    }

    private func setupDots() {
        let dotData: [(FiveElement, CGFloat, CGFloat, CGFloat)] = [
            (.water,  -95, -130,  8),
            (.wood,    85, -110, 10),
            (.fire,  -110,   60,  7),
            (.earth,  100,   75,  9),
            (.metal,  -30,  125,  8),
            (.water,   60, -155,  6),
            (.fire,   135,  -20,  7),
        ]
        floatingDots = dotData.enumerated().map { i, d in
            FloatingDot(color: d.0.color, size: d.3, x: d.1, y: d.2, delay: Double(i) * 0.15 + 0.5)
        }
    }

    // 固定星点数据
    private let starData: [(CGFloat, CGFloat, Double, CGFloat)] = [
        (50, 80, 0.3, 2),   (150, 40, 0.2, 1.5),  (280, 90, 0.35, 2.5),
        (80, 200, 0.15, 1.5),(320, 150, 0.25, 2),  (200, 300, 0.2, 1.5),
        (40, 350, 0.3, 2),  (350, 280, 0.15, 1),   (120, 450, 0.25, 2),
        (300, 420, 0.2, 1.5),(160, 520, 0.3, 2),   (380, 380, 0.1, 1),
        (60, 550, 0.2, 1.5),(240, 480, 0.25, 2),   (340, 520, 0.15, 1.5),
        (100, 600, 0.2, 2), (380, 100, 0.3, 1.5),  (20, 160, 0.15, 1),
        (360, 360, 0.25, 2),(190, 180, 0.1, 1.5)
    ]
}

// MARK: - 辅助数据模型
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
