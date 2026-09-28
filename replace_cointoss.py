import re

file_path = "liuyao/CoinTossPageView.swift"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Pattern to replace the entire body block
pattern = r'(var body: some View \{\n)(.*?)(^\s*\}\n\s*// MARK: - 私有方法)'

new_body = """        ZStack {
            // 背景（若用户有图则替换为Image("toss-bg")）
            GeometryReader { geo in
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.15, green: 0.05, blue: 0.25),
                        Color(red: 0.45, green: 0.2, blue: 0.55),
                        Color(red: 0.65, green: 0.4, blue: 0.75),
                        Color(red: 0.8, green: 0.6, blue: 0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // 可选背景图层 (预留给用户)
                if UIImage(named: "toss-bg") != nil {
                    Image("toss-bg")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                }
            }
            
            // 摇动检测
            ShakeDetector {
                if !hasStarted && !isAnimating {
                    startDivination()
                }
            }
            
            // 星点背景
            ForEach(0..<20, id: \.self) { index in
                let screenWidth = max(UIScreen.main.bounds.width, 1)
                let screenHeight = max(UIScreen.main.bounds.height, 1)
                
                let positions: [(CGFloat, CGFloat)] = [
                    (screenWidth * 0.1, screenHeight * 0.15),
                    (screenWidth * 0.3, screenHeight * 0.12),
                    (screenWidth * 0.7, screenHeight * 0.18),
                    (screenWidth * 0.9, screenHeight * 0.14),
                    (screenWidth * 0.2, screenHeight * 0.25),
                    (screenWidth * 0.8, screenHeight * 0.22),
                    (screenWidth * 0.15, screenHeight * 0.35),
                    (screenWidth * 0.5, screenHeight * 0.32),
                    (screenWidth * 0.85, screenHeight * 0.38),
                    (screenWidth * 0.25, screenHeight * 0.45),
                    (screenWidth * 0.75, screenHeight * 0.42),
                    (screenWidth * 0.1, screenHeight * 0.55),
                    (screenWidth * 0.4, screenHeight * 0.52),
                    (screenWidth * 0.9, screenHeight * 0.58),
                    (screenWidth * 0.3, screenHeight * 0.65),
                    (screenWidth * 0.6, screenHeight * 0.62),
                    (screenWidth * 0.2, screenHeight * 0.75),
                    (screenWidth * 0.7, screenHeight * 0.72),
                    (screenWidth * 0.45, screenHeight * 0.82),
                    (screenWidth * 0.8, screenHeight * 0.85)
                ]
                
                let position = positions[index % positions.count]
                let sizes: [CGFloat] = [1.0, 1.5, 2.0, 2.5, 3.0]
                let opacities: [Double] = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8]
                
                let starSize = max(sizes[index % sizes.count], 0.5)
                let starOpacity = max(opacities[index % opacities.count], 0.1)
                
                Circle()
                    .fill(Color.white.opacity(starOpacity))
                    .frame(width: starSize, height: starSize)
                    .position(x: max(position.0, 0), y: max(position.1, 0))
            }
            
            VStack(spacing: 0) {
                // 顶部文字与问题
                VStack(spacing: 16) {
                    if !hasStarted {
                        VStack(spacing: 8) {
                            Text("准备开始起卦")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text("专注当下 · 心诚则灵")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // 问题卡片（白色透明底）
                        Text("“\(question)”")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 30)
                    } else {
                        VStack(spacing: 12) {
                            Text("正在起卦")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text(question)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                Rectangle().fill(Color.white.opacity(0.3)).frame(width: 40, height: 1)
                                Text("心有所问，卦有所答")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Rectangle().fill(Color.white.opacity(0.3)).frame(width: 40, height: 1)
                            }
                        }
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // 硬币动画区域
                ZStack {
                    // 外圈 - 带动效
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.yellow.opacity(0.6), .orange.opacity(0.3)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 4
                        )
                        .frame(width: isIPad ? 160 : 120, height: isIPad ? 160 : 120)
                        .opacity(isAnimating ? 1.0 : 0.3)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // 硬币
                    ZStack {
                        // 外圆 - 铜钱主体
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.yellow.opacity(0.9),
                                        Color.orange.opacity(0.8),
                                        Color.yellow.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: isIPad ? 110 : 80, height: isIPad ? 110 : 80)
                            .shadow(color: .orange.opacity(0.4), radius: 8, x: 2, y: 4)
                        
                        // 内圈边框
                        Circle()
                            .stroke(Color.orange.opacity(0.8), lineWidth: 2)
                            .frame(width: isIPad ? 110 : 80, height: isIPad ? 110 : 80)
                        
                        // 中央方孔
                        RoundedRectangle(cornerRadius: isIPad ? 6 : 4)
                            .fill(Color.orange.opacity(0.9))
                            .frame(width: isIPad ? 32 : 24, height: isIPad ? 32 : 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: isIPad ? 6 : 4)
                                    .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
                            )
                        
                        // 古代文字装饰 (或阴阳)
                        if isAnimating {
                            // 翻转中...
                        } else if hasStarted && tossResults.count > 0 {
                            // 显示最新的结果
                            let lastResult = tossResults.last ?? true
                            VStack {
                                HStack {
                                    Text(lastResult ? "阴" : "阳")
                                        .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                                        .foregroundColor(.orange.opacity(0.8))
                                    Spacer()
                                }
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text(lastResult ? "阳" : "阴")
                                        .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                                        .foregroundColor(.orange.opacity(0.8))
                                }
                            }
                            .frame(width: isIPad ? 70 : 50, height: isIPad ? 70 : 50)
                        }
                    }
                    .scaleEffect(coinScale)
                    .rotationEffect(.degrees(rotationAngle))
                    .rotation3DEffect(
                        .degrees(isAnimating ? 180 : 0),
                        axis: (x: 1, y: 1, z: 0)
                    )
                }
                
                Spacer()
                
                // 底部状态区
                VStack(spacing: 24) {
                    // 抛掷次数和进度指示器
                    VStack(spacing: 12) {
                        Text(!hasStarted ? "第 1 次起卦 / 共 6 次" : "第 \(min(currentAnimationIndex + 1, 6)) 次抛掷")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        // 进度指示器
                        HStack(spacing: 10) {
                            ForEach(0..<6, id: \.self) { index in
                                Circle()
                                    .fill(index < tossResults.count ? 
                                          AnyShapeStyle(LinearGradient(
                                            gradient: Gradient(colors: [.yellow, .orange]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                          )) : 
                                          AnyShapeStyle(LinearGradient(
                                            gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.1)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                          ))
                                    )
                                    .frame(width: 12, height: 12)
                                    .scaleEffect(index == currentAnimationIndex && isAnimating ? 1.4 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: currentAnimationIndex)
                            }
                        }
                    }
                    
                    if !hasStarted {
                        // 提示卡片
                        HStack(spacing: 16) {
                            Image(systemName: "camera.macro") // 类似莲花的图标
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("放松身心，保持专注")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                Text("点击按钮或摇动手机开始")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 30)
                        
                        // 开始按钮
                        Button(action: {
                            startDivination()
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("开始起卦")
                                Image(systemName: "sparkles")
                            }
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]), // 参考图2渐变
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 30)
                    } else if tossResults.count < 6 || isAnimating {
                        // 进行中的结果显示卡片
                        VStack(spacing: 16) {
                            // 本次结果
                            VStack(spacing: 12) {
                                Text("本次结果")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                if tossResults.isEmpty {
                                    Text("抛掷中...")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(height: 30)
                                } else {
                                    HStack(spacing: 10) {
                                        ForEach(0..<tossResults.count, id: \.self) { index in
                                            Text(tossResults[index] ? "阳" : "阴")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(tossResults[index] ? .black : .white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(tossResults[index] ? 
                                                              AnyShapeStyle(LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .top, endPoint: .bottom)) : 
                                                              AnyShapeStyle(Color.white.opacity(0.15)))
                                                )
                                                .animation(.bouncy, value: tossResults.count)
                                        }
                                    }
                                    .frame(height: 30)
                                }
                                
                                Text("一阴一阳，变化中有机遇")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 30)
                            
                            // 提示语卡片
                            HStack(spacing: 16) {
                                Image(systemName: "camera.macro") // 类似莲花的图标
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("好事正在发生...")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Text("保持专注，让答案慢慢浮现")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("这是一个与自己对话的过程")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 30)
                        }
                    } else if tossResults.count >= 6 && !isAnimating, let hexagramData = hexagramInfo {
                        // 分析完成按钮
                        VStack(spacing: 16) {
                            Button(action: {
                                print("🔍 [CoinTossPageView] 结果按钮被点击")
                                print("📝 问题: \(question)")
                                print("🎲 抛掷结果: \(tossResults)")
                                print("📊 框架信息: \(hexagramData)")
                                
                                // 增加使用次数计数
                                permissionManager.incrementDivinationCount()
                                
                                // 延迟一点点再触发导航，确保UI更新完成
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showResultPage = true
                                    print("🚀 [CoinTossPageView] 设置showResultPage = true")
                                }
                            }) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                    Text("卦象解读")
                                    Image(systemName: "sparkles")
                                }
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.yellow, .orange]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: .yellow.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 30)
                            
                            // 调试信息显示
                            if showResultPage {
                                Text("正在跳转...")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .opacity(0.8)
                            }
                        }
                        // 使用fullScreenCover方式，确保完全独立的导航上下文
                        .fullScreenCover(isPresented: $showResultPage) {
                            DivinationResultPageView(
                                question: question,
                                tossResults: tossResults,
                                hexagramData: hexagramData,
                                currentLocation: locationManager.currentCity,
                                onDismiss: {
                                    print("[CoinTossPageView] 解卦结果页面请求关闭")
                                    showResultPage = false
                                    
                                    // 延迟一点后返回到根视图
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        dismiss()
                                        print("[CoinTossPageView] 已返回到根视图")
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
"""
content = re.sub(pattern, r'\1' + new_body + r'\n\3', content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
