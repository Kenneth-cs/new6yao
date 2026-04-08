import SwiftUI
import Network

struct DivinationResultPageView: View {
    let question: String
    let tossResults: [Bool]
    let hexagramData: (name: String, description: String)
    let currentLocation: String
    let onDismiss: () -> Void
    @State private var aiInterpretation: String = ""
    @State private var hexagramAnalysis: String = ""
    @State private var questionInterpretation: String = ""
    @State private var guidanceAdvice: String = ""
    @State private var isLoading = true
    @State private var showSaveAlert = false
    @State private var divinationTime: Date = Date() // 静态分析时间
    @ObservedObject private var aiStore = AIRequestStateStore.shared
    @StateObject private var aiService = AIService.shared

    private var requestKey: String {
        let hexBinary = tossResults.map { $0 ? "1" : "0" }.joined()
        return "divination_\(hexBinary)_\(abs(question.hashValue))"
    }
    @StateObject private var dataService = DataService()
    @State private var networkMonitor = NWPathMonitor()
    @State private var isNetworkAvailable = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                // 顶部信息区域
                VStack(spacing: 16) {
                    // 标题和完成按钮
                    HStack {
                        Text("分析结果")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .indigo]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Spacer()
                        
                         Button(action: {
                             print("[DivinationResultPageView] 点击完成按钮")
                             aiStore.clearSlot(key: requestKey)
                             onDismiss()
                         }) {
                            Text("完成")
                                .font(.headline)
                                .foregroundColor(.purple)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // 问题显示
                    VStack(spacing: 8) {
                        Text("您的问题")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(question)
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // 分析信息区域 - 简洁白色背景布局
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("分析信息")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // 卦名
                            HStack {
                                Text("卦名")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .leading)
                                
                                Text(hexagramData.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            // 卦象描述
                            VStack(alignment: .leading, spacing: 4) {
                                Text("卦象")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(hexagramData.description)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            // 分析时间
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("分析时间")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(formatDate(divinationTime))
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            // 分析地点
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("分析地点")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(currentLocation.isEmpty ? "未知地点" : currentLocation)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 卦象显示 - 卡片样式居中显示
                    VStack(spacing: 16) {
                        Text("卦象")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        // 爻象显示卡片
                        VStack(spacing: 10) {
                            ForEach(Array(tossResults.enumerated().reversed()), id: \.offset) { index, result in
                                HStack {
                                    if result {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.purple, .indigo]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: 100, height: 8)
                                    } else {
                                        HStack(spacing: 8) {
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.purple, .indigo]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: 46, height: 8)
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.purple, .indigo]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: 46, height: 8)
                                        }
                                    }
                                    
                                    Text(result ? "阳" : "阴")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .frame(width: 30)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 2)
                        )
                        .frame(maxWidth: 260)
                    }
                    .padding(.horizontal, 20)
                }
                .background(Color(.systemBackground))
                .padding(.bottom, 20)
                
                // AI解读内容区域
                if isLoading {
                    VStack(spacing: 16) {
                        HStack {
                            ProgressView()
                                .scaleEffect(1.0)
                                .tint(.purple)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("大师正在解读卦象...")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("请稍候，正在为您分析卦象含义")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        // 改进的提示信息
                        VStack(spacing: 8) {
                            Text("💡 解读过程可能需要30-60秒")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            
                            Text("网络不佳时会自动重试，请耐心等待")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("取消解读") {
                            // 取消解读逻辑
                            isLoading = false
                            aiInterpretation = "解读已取消"
                        }
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                            .shadow(color: Color.primary.opacity(0.15), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .background(Color(.systemBackground))
                } else {
                    VStack(spacing: 20) {
                        // 检查是否有错误状态
                        if aiInterpretation.contains("解读失败") || aiInterpretation.contains("超时") || aiInterpretation.contains("网络") {
                            // 错误状态显示
                            VStack(spacing: 12) {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                Text("网络请求超时")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("请检查网络连接，或稍后重试")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("重新解读") {
                                    aiStore.clearSlot(key: requestKey)
                                    isLoading = true
                                    aiInterpretation = ""
                                    hexagramAnalysis = ""
                                    questionInterpretation = ""
                                    guidanceAdvice = ""
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        requestAIInterpretation()
                                    }
                                }
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .indigo]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 20)
                        } else {
                            // 卦象解析板块
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                    Text("卦象解析")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                
                                if !hexagramAnalysis.isEmpty {
                                    FormattedDivinationText(content: hexagramAnalysis)
                                } else {
                                    Text("正在解析卦象含义...")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue.opacity(0.08), .cyan.opacity(0.05)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                            
                            // 问题解读板块
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                    Text("问题解读")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    Spacer()
                                }
                                
                                if !questionInterpretation.isEmpty {
                                    FormattedDivinationText(content: questionInterpretation)
                                } else {
                                    Text("正在解读问题...")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.green.opacity(0.08), .mint.opacity(0.05)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                            
                            // 建议指导板块
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                    Text("建议指导")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    Spacer()
                                }
                                
                                if !guidanceAdvice.isEmpty {
                                    FormattedDivinationText(content: guidanceAdvice)
                                } else {
                                    Text("正在生成建议指导...")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.orange.opacity(0.08), .yellow.opacity(0.05)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 30)
                    .background(Color(.systemBackground))
                }
                
                // 底部功能按钮
                if !isLoading {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            // 保存记录按钮
                            Button(action: saveResult) {
                                Text("保存记录")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.purple, lineWidth: 1.5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 25)
                                                    .fill(Color(.systemBackground))
                                            )
                                    )
                            }
                            
                             // 重新分析按钮
                             Button(action: {
                                 print("[DivinationResultPageView] 点击重新分析按钮")
                                 aiStore.clearSlot(key: requestKey)
                                 onDismiss()
                             }) {
                                Text("重新分析")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.purple, .indigo]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(25)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .clipped()                          // 裁剪防止横向拖出空白
        .navigationTitle("分析结果")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .alert("保存成功", isPresented: $showSaveAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("分析结果已保存到历史记录中")
        }
        .onAppear {
            divinationTime = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                startNetworkMonitoring()
                if let slot = aiStore.slot(for: requestKey) {
                    switch slot.status {
                    case .loading:
                        // 请求还在后台跑，保持 spinner 等待 Task 完成
                        isLoading = true
                    case .success:
                        // 后台已拿到结果，直接渲染，不重新请求
                        aiInterpretation       = slot.result
                        hexagramAnalysis       = slot.hexagramAnalysis ?? ""
                        questionInterpretation = slot.questionInterpretation ?? ""
                        guidanceAdvice         = slot.guidanceAdvice ?? ""
                        isLoading = false
                    case .failed:
                        aiInterpretation = slot.result
                        isLoading = false
                    }
                } else {
                    requestAIInterpretation()
                }
            }
        }
        .onDisappear {
            stopNetworkMonitoring()
        }
    }
    
    // MARK: - 私有方法
    private func requestAIInterpretation() {
        print("[DivinationResultPageView] 开始请求AI解读")
        aiStore.markLoading(key: requestKey)
        
        // 检查网络连接
        if !isNetworkAvailable {
            print("[DivinationResultPageView] 网络不可用")
            aiInterpretation = "网络连接不可用，请检查网络设置后重试。"
            isLoading = false
            return
        }
        
        print("[DivinationResultPageView] 卦象信息: \(hexagramData.name)")
        
        Task {
            do {
                // 先测试API连接
                print("[DivinationResultPageView] 测试API连接...")
                let testResult = try await aiService.testAPIConnection()
                print("[DivinationResultPageView] API连接测试结果: \(testResult)")
                
                // 如果测试成功，进行正式解读
                print("[DivinationResultPageView] 调用AIService.interpretDivinationStream")
                let hexagramStruct = HexagramData(name: hexagramData.name, description: hexagramData.description)
                
                let interpretation = try await aiService.interpretDivinationStream(
                    question: question,
                    hexagram: hexagramStruct,
                    tossResults: tossResults,
                    divinationTime: divinationTime,
                    divinationLocation: currentLocation.isEmpty ? "未知地点" : currentLocation
                )
                
                print("[DivinationResultPageView] AI解读完成，长度: \(interpretation.count)")
                
                await MainActor.run {
                    self.aiInterpretation = interpretation
                    self.parseAIInterpretation(interpretation)
                    self.isLoading = false
                    print("[DivinationResultPageView] UI更新完成")
                    // parseAIInterpretation 内部有 DispatchQueue.main.async，
                    // 延迟一个 runloop 后再写入 store 确保三个子段已更新
                    DispatchQueue.main.async {
                        self.aiStore.markSuccess(
                            key: self.requestKey,
                            result: interpretation,
                            hexagramAnalysis: self.hexagramAnalysis,
                            questionInterpretation: self.questionInterpretation,
                            guidanceAdvice: self.guidanceAdvice
                        )
                    }
                }
            } catch {
                print("[DivinationResultPageView] AI解读失败: \(error.localizedDescription)")
                
                // 更详细的错误处理
                let errorMessage: String
                if let networkError = error as? NetworkError {
                    errorMessage = networkError.localizedDescription
                } else if let aiError = error as? AIServiceError {
                    errorMessage = aiError.localizedDescription
                } else {
                    errorMessage = "网络连接超时，请检查网络后重试"
                }
                
                await MainActor.run {
                    self.aiInterpretation = "解读失败：\(errorMessage)"
                    self.isLoading = false
                    self.aiStore.markFailed(key: self.requestKey, message: "解读失败：\(errorMessage)")
                }
            }
        }
    }
    
    private func saveResult() {
        dataService.saveDivinationRecord(
            question: question,
            tossResults: tossResults,
            aiInterpretation: aiInterpretation,
            advice: aiInterpretation
        )
        showSaveAlert = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func parseAIInterpretation(_ interpretation: String) {
        // 根据关键词分割内容到三个板块
        let lines = interpretation.components(separatedBy: .newlines)
        var hexagramContent = ""
        var questionContent = ""
        var guidanceContent = ""
        var currentSection = "hexagram" // 默认开始是卦象解析
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检查是否是问题解读的开始
            if trimmedLine.contains("问题解读") || trimmedLine.contains("问题分析") || trimmedLine.contains("你的问题") || trimmedLine.contains("问题含义") {
                currentSection = "question"
                continue
            }
            // 检查是否是建议指导的开始
            else if trimmedLine.contains("建议指导") || trimmedLine.contains("指导建议") || trimmedLine.contains("建议") || trimmedLine.contains("指导") {
                currentSection = "guidance"
                continue
            }
            // 检查是否是卦象解析的开始
            else if trimmedLine.contains("卦象解析") || trimmedLine.contains("卦象含义") || trimmedLine.contains("核心含义") {
                currentSection = "hexagram"
                continue
            }
            
            // 根据当前部分添加内容
            if currentSection == "hexagram" && !trimmedLine.isEmpty {
                if !hexagramContent.isEmpty {
                    hexagramContent += "\n"
                }
                hexagramContent += trimmedLine
            } else if currentSection == "question" && !trimmedLine.isEmpty {
                if !questionContent.isEmpty {
                    questionContent += "\n"
                }
                questionContent += trimmedLine
            } else if currentSection == "guidance" && !trimmedLine.isEmpty {
                if !guidanceContent.isEmpty {
                    guidanceContent += "\n"
                }
                guidanceContent += trimmedLine
            }
        }
        
        // 如果没有找到明确的分割，按长度分割成三部分
        if hexagramContent.isEmpty && questionContent.isEmpty && guidanceContent.isEmpty {
            let totalLength = interpretation.count
            let firstThird = totalLength / 3
            let secondThird = firstThird * 2
            
            hexagramContent = String(interpretation.prefix(firstThird))
            questionContent = String(interpretation.dropFirst(firstThird).prefix(firstThird))
            guidanceContent = String(interpretation.suffix(totalLength - secondThird))
        }
        
        // 更新状态 - 清理和格式化文本
        DispatchQueue.main.async {
            self.hexagramAnalysis = hexagramContent.isEmpty ? "暂无卦象解析" : self.cleanAndFormatText(hexagramContent)
            self.questionInterpretation = questionContent.isEmpty ? "暂无问题解读" : self.cleanAndFormatText(questionContent)
            self.guidanceAdvice = guidanceContent.isEmpty ? "暂无建议指导" : self.cleanAndFormatText(guidanceContent)
        }
    }
    
    // 清理和格式化文本
    private func cleanAndFormatText(_ text: String) -> String {
        var cleanedText = text
        
        // 1. 先统一换行符
        cleanedText = cleanedText.replacingOccurrences(of: "\r\n", with: "\n")
        cleanedText = cleanedText.replacingOccurrences(of: "\r", with: "\n")
        
        // 2. 移除Markdown标题符号（保留标题内容）
        // #### 标题 -> 标题
        // ### 标题 -> 标题
        // ## 标题 -> 标题
        // # 标题 -> 标题
        cleanedText = cleanedText.replacingOccurrences(of: "#{1,6} ", with: "", options: .regularExpression)
        // 移除可能没有空格的情况
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^#{1,6}", with: "", options: .regularExpression)
        
        // 3. 移除粗体和斜体符号（保留内容）
        // ***文本*** -> 文本
        cleanedText = cleanedText.replacingOccurrences(of: "\\*{3,}([^*]+)\\*{3,}", with: "$1", options: .regularExpression)
        // **文本** -> 文本
        cleanedText = cleanedText.replacingOccurrences(of: "\\*{2}([^*]+)\\*{2}", with: "$1", options: .regularExpression)
        // *文本* -> 文本
        cleanedText = cleanedText.replacingOccurrences(of: "\\*([^*\\n]+)\\*", with: "$1", options: .regularExpression)
        // 移除孤立的星号
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^\\*+$", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^\\*+ ", with: "", options: .regularExpression)
        
        // 4. 移除下划线符号
        cleanedText = cleanedText.replacingOccurrences(of: "__([^_]+)__", with: "$1", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "_([^_]+)_", with: "$1", options: .regularExpression)
        
        // 5. 移除删除线
        cleanedText = cleanedText.replacingOccurrences(of: "~~([^~]+)~~", with: "$1", options: .regularExpression)
        
        // 6. 移除代码块符号
        cleanedText = cleanedText.replacingOccurrences(of: "```[\\s\\S]*?```", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "`([^`]+)`", with: "$1", options: .regularExpression)
        
        // 7. 移除分隔线（使用多行模式）
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^---+$", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^___+$", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^\\*\\*\\*+$", with: "", options: .regularExpression)
        
        // 8. 移除方括号【】和特殊括号
        cleanedText = cleanedText.replacingOccurrences(of: "【", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "】", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "『", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "』", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "「", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "」", with: "")
        
        // 9. 处理列表符号
        // - 项目 -> 项目
        // * 项目 -> 项目
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^[\\-\\*] ", with: "", options: .regularExpression)
        
        // 10. 处理数字列表，保留数字但美化格式
        // 1. 项目 -> 1. 项目
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^([0-9]+)\\. ", with: "$1. ", options: .regularExpression)
        
        // 11. 在中文标点后适当换行
        // 句号后换行
        cleanedText = cleanedText.replacingOccurrences(of: "。(?!\\n)", with: "。\n", options: .regularExpression)
        // 问号后换行（但不在问号已经后面跟换行的情况）
        cleanedText = cleanedText.replacingOccurrences(of: "？(?!\\n)", with: "？\n", options: .regularExpression)
        // 感叹号后换行
        cleanedText = cleanedText.replacingOccurrences(of: "！(?!\\n)", with: "！\n", options: .regularExpression)
        
        // 12. 冒号后换行（用于要点说明）
        cleanedText = cleanedText.replacingOccurrences(of: "：(?!\\n)", with: "：\n", options: .regularExpression)
        
        // 13. 清理多余的空格
        // 多个空格变成一个
        cleanedText = cleanedText.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
        // 行首行尾空格
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^ +", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "(?m) +$", with: "", options: .regularExpression)
        
        // 14. 清理多余的空行
        // 三个以上换行变成两个
        cleanedText = cleanedText.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // 14.5. 移除只包含符号的行（更彻底）
        let lines = cleanedText.components(separatedBy: .newlines)
        cleanedText = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // 跳过空行
            if trimmed.isEmpty { return false }
            // 跳过只有符号的行
            if trimmed.range(of: "^[\\s\\*\\-_=#:：、。，！？•·]+$", options: .regularExpression) != nil {
                return false
            }
            // 跳过太短的行（少于2个字符）
            if trimmed.count < 2 { return false }
            return true
        }.joined(separator: "\n")
        
        // 15. 移除孤立的符号行
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^[\\*\\-_=#+]+$", with: "", options: .regularExpression)
        
        // 16. 移除引号符号（中英文）- 使用Unicode转义
        cleanedText = cleanedText.replacingOccurrences(of: "\u{201C}", with: "")  // "
        cleanedText = cleanedText.replacingOccurrences(of: "\u{201D}", with: "")  // "
        cleanedText = cleanedText.replacingOccurrences(of: "\u{2018}", with: "")  // '
        cleanedText = cleanedText.replacingOccurrences(of: "\u{2019}", with: "")  // '
        
        // 17. 移除可能残留的单个星号（不在句子中间的）
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^\\* ", with: "• ", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: " \\*$", with: "", options: .regularExpression)
        
        // 18. 处理可能残留的井号
        cleanedText = cleanedText.replacingOccurrences(of: "(?m)^#+ ", with: "", options: .regularExpression)
        
        // 19. 清理可能的HTML标签（如果有）
        cleanedText = cleanedText.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // 20. 清理连续的标点符号
        cleanedText = cleanedText.replacingOccurrences(of: "([，。！？]){2,}", with: "$1", options: .regularExpression)
        
        // 21. 清理首尾空白
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedText
    }
    
    private func startNetworkMonitoring() {
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
        
        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isNetworkAvailable = path.status == .satisfied
                print("[DivinationResultPageView] 网络状态: \(path.status == .satisfied ? "可用" : "不可用")")
            }
        }
    }
    
    private func stopNetworkMonitoring() {
          networkMonitor.cancel()
      }
}

// MARK: - 格式化文本显示组件
struct FormattedDivinationText: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(formatTextContent(content), id: \.id) { segment in
                HStack(alignment: .top, spacing: 10) {
                    if segment.isBulletPoint {
                        // 要点样式 - 圆点标记
                        VStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue.opacity(0.8), .blue.opacity(0.5)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 7, height: 7)
                                .padding(.top, 9)
                            Spacer()
                        }
                        
                        Text(segment.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if segment.isImportant {
                        // 重要信息样式 - 高亮背景
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                            
                            Text(segment.text)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineSpacing(8)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange.opacity(0.12),
                                            Color.orange.opacity(0.08)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    } else {
                        // 普通文本样式 - 更好的行间距
                        Text(segment.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    private func formatTextContent(_ text: String) -> [TextSegment] {
        var segments: [TextSegment] = []
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行
            if trimmedLine.isEmpty { continue }
            
            // 跳过只包含符号的行（扩展符号集）
            if trimmedLine.range(of: "^[\\s\\*\\-_=#:：、。，！？]+$", options: .regularExpression) != nil {
                continue
            }
            
            // 跳过只包含少量字符的行（可能是残留符号）
            if trimmedLine.count < 2 {
                continue
            }
            
            // 判断是否是数字列表项
            let isNumberedList = trimmedLine.range(of: "^[0-9]+\\.", options: .regularExpression) != nil
            
            // 判断是否是要点（包含特定关键词或短句）
            let isBulletPoint = isNumberedList ||
                               trimmedLine.hasPrefix("•") ||
                               trimmedLine.hasPrefix("·") ||
                               trimmedLine.hasPrefix("⭐") ||
                               trimmedLine.hasPrefix("✓") ||
                               (trimmedLine.contains("：") && trimmedLine.count < 50)
            
            // 判断是否是重要信息/标题
            let isImportant = !isBulletPoint && (
                               trimmedLine.contains("核心") ||
                               trimmedLine.contains("关键") ||
                               trimmedLine.contains("重要") ||
                               trimmedLine.contains("注意") ||
                               trimmedLine.contains("记住") ||
                               trimmedLine.contains("总结") ||
                               trimmedLine.contains("小结") ||
                               trimmedLine.contains("结论") ||
                               trimmedLine.contains("要点") ||
                               trimmedLine.contains("提醒") ||
                               trimmedLine.contains("提示") ||
                               // 短句且包含冒号（可能是小标题）
                               (trimmedLine.count < 30 && trimmedLine.contains("："))
            )
            
            // 处理行内容
            var cleanLine = trimmedLine
            
            // 如果是数字列表，保留数字
            if isNumberedList {
                // 不做额外处理，保持 "1. 内容" 的格式
            }
            
            // 移除可能残留的符号
            cleanLine = cleanLine.replacingOccurrences(of: "^[•·\\-\\*] *", with: "", options: .regularExpression)
            
            // 移除行首的井号和冒号
            cleanLine = cleanLine.replacingOccurrences(of: "^[#:]+ *", with: "", options: .regularExpression)
            
            // 移除行首行尾的星号
            cleanLine = cleanLine.replacingOccurrences(of: "^\\*+ *", with: "", options: .regularExpression)
            cleanLine = cleanLine.replacingOccurrences(of: " *\\*+$", with: "", options: .regularExpression)
            
            // 移除方括号
            cleanLine = cleanLine.replacingOccurrences(of: "[【】『』「」]", with: "", options: .regularExpression)
            
            // 确保行不为空
            cleanLine = cleanLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanLine.isEmpty { continue }
            if cleanLine.count < 2 { continue }  // 跳过太短的行
            
            segments.append(TextSegment(
                id: index,
                text: cleanLine,
                isBulletPoint: isBulletPoint,
                isImportant: isImportant
            ))
        }
        
        return segments
    }
}

struct TextSegment {
    let id: Int
    let text: String
    let isBulletPoint: Bool
    let isImportant: Bool
}

#Preview {
    NavigationStack {
        let hexagramInfo = HexagramData.getHexagram(for: [true, false, true, false, true, false].map { $0 ? "1" : "0" }.joined())
        DivinationResultPageView(
            question: "我的事业发展如何？",
            tossResults: [true, false, true, false, true, false],
            hexagramData: (name: hexagramInfo.name, description: hexagramInfo.description),
            currentLocation: "北京市",
            onDismiss: {}
        )
    }
}