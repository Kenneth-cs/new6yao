import Foundation

class AIService: ObservableObject {
    static let shared = AIService()
    
    private init() {}
    
    func interpretDivination(
        question: String,
        tossResults: [Bool],
        divinationTime: Date,
        divinationLocation: String
    ) async throws -> DivinationResult {
        
        // 获取卦象信息
        let hexagramBinary = tossResults.map { $0 ? "1" : "0" }.joined()
        let hexagramInfo = HexagramData.getHexagram(for: hexagramBinary)
        let hexagramYinYang = tossResults.map { $0 ? "阳" : "阴" }.joined(separator: "-")
        
        // 构建AI提示词
        let prompt = buildPrompt(
            question: question,
            hexagramName: hexagramInfo.name,
            hexagramDescription: hexagramInfo.description,
            hexagramYinYang: hexagramYinYang,
            tossResults: tossResults,
            divinationTime: divinationTime,
            divinationLocation: divinationLocation
        )
        
        let requestBody: [String: Any] = [
            "model": "deepseek-v3-250324",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        do {
            let response = try await NetworkService.shared.sendRequest(
                body: requestBody,
                responseType: AIResponse.self
            )
            
            if let content = response.choices.first?.message.content {
                let parsed = parseAIResponse(content)
                return DivinationResult(
                    question: question,
                    tossResults: tossResults,
                    hexagramName: hexagramInfo.name,
                    hexagramDescription: hexagramInfo.description,
                    aiInterpretation: parsed.interpretation,
                    advice: parsed.advice,
                    timestamp: Date(),
                    divinationTime: divinationTime,
                    divinationLocation: divinationLocation
                )
            } else {
                throw AIServiceError.noResponse
            }
        } catch {
            throw AIServiceError.requestFailed(error)
        }
    }
    
    func interpretDivinationStream(
        question: String,
        tossResults: [Bool],
        divinationTime: Date,
        divinationLocation: String,
        onUpdate: @escaping (String) -> Void
    ) async throws -> DivinationResult {
        
        // 获取卦象信息
        let hexagramBinary = tossResults.map { $0 ? "1" : "0" }.joined()
        let hexagramInfo = HexagramData.getHexagram(for: hexagramBinary)
        let hexagramYinYang = tossResults.map { $0 ? "阳" : "阴" }.joined(separator: "-")
        
        // 构建AI提示词
        let prompt = buildPrompt(
            question: question,
            hexagramName: hexagramInfo.name,
            hexagramDescription: hexagramInfo.description,
            hexagramYinYang: hexagramYinYang,
            tossResults: tossResults,
            divinationTime: divinationTime,
            divinationLocation: divinationLocation
        )
        
        let requestBody: [String: Any] = [
            "model": "deepseek-v3-250324",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        do {
            let response = try await NetworkService.shared.sendRequest(
                body: requestBody,
                responseType: AIResponse.self
            )
            
            if let content = response.choices.first?.message.content {
                let parsed = parseAIResponse(content)
                onUpdate(parsed.interpretation)
                
                return DivinationResult(
                    question: question,
                    tossResults: tossResults,
                    hexagramName: hexagramInfo.name,
                    hexagramDescription: hexagramInfo.description,
                    aiInterpretation: parsed.interpretation,
                    advice: parsed.advice,
                    timestamp: Date(),
                    divinationTime: divinationTime,
                    divinationLocation: divinationLocation
                )
            } else {
                throw AIServiceError.noResponse
            }
        } catch {
            throw AIServiceError.requestFailed(error)
        }
    }
    
    // 添加简化的测试方法
    func testAPIConnection() async throws -> String {
        let testBody: [String: Any] = [
            "model": "deepseek-v3-250324",
            "messages": [
                [
                    "role": "user",
                    "content": "简单测试，请回复'连接成功'"
                ]
            ],
            "max_tokens": 50,
            "temperature": 0.1
        ]
        
        let response = try await NetworkService.shared.sendRequest(
            body: testBody,
            responseType: AIResponse.self
        )
        
        return response.choices.first?.message.content ?? "测试失败"
    }
    
    // 添加新的流式解读方法，接受HexagramData参数
    func interpretDivinationStream(
        question: String,
        hexagram: HexagramData,
        tossResults: [Bool],
        divinationTime: Date = Date(),
        divinationLocation: String = "未知地点"
    ) async throws -> String {
        
        let hexagramYinYang = tossResults.map { $0 ? "阳" : "阴" }.joined(separator: "-")
        
        // 构建AI提示词
        let prompt = buildPrompt(
            question: question,
            hexagramName: hexagram.name,
            hexagramDescription: hexagram.description,
            hexagramYinYang: hexagramYinYang,
            tossResults: tossResults,
            divinationTime: divinationTime,
            divinationLocation: divinationLocation
        )
        
        let requestBody: [String: Any] = [
            "model": "deepseek-v3-250324",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        do {
            print("[AIService] 开始发送AI请求...")
            print("[AIService] 请求体大小: \(requestBody.description.count) 字符")
            
            let response = try await NetworkService.shared.sendRequest(
                body: requestBody,
                responseType: AIResponse.self
            )
            
            print("[AIService] 收到AI响应")
            
            if let content = response.choices.first?.message.content {
                print("[AIService] AI响应内容长度: \(content.count) 字符")
                return content
            } else {
                print("[AIService] 错误: AI响应为空")
                throw AIServiceError.noResponse
            }
        } catch {
            print("[AIService] 请求失败: \(error.localizedDescription)")
            if let networkError = error as? NetworkError {
                print("[AIService] 网络错误详情: \(networkError.localizedDescription)")
            }
            throw AIServiceError.requestFailed(error)
        }
    }
    
    private func buildPrompt(
        question: String,
        hexagramName: String,
        hexagramDescription: String,
        hexagramYinYang: String,
        tossResults: [Bool],
        divinationTime: Date,
        divinationLocation: String
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        let timeString = formatter.string(from: divinationTime)
        
        let hour = Calendar.current.component(.hour, from: divinationTime)
        let chineseHour = getChineseHour(from: hour)
        
        return """
        作为一位专业的决策分析师，请运用六爻框架为以下问题提供决策分析（当前是2025年乙巳年，9月乙酉月）：
        
        问题：\(question)
        
        分析框架信息：
        - 框架名称：\(hexagramName)
        - 框架描述：\(hexagramDescription)
        - 维度组合：\(hexagramYinYang)
        - 分析时间：\(timeString)（\(chineseHour)）
        - 分析地点：\(divinationLocation)
        
        请按以下格式提供分析：
        
        【框架解析】
        [结合分析时间、地点，详细分析框架的含义和象征]
        
        【问题分析】
        [针对具体问题的多维度分析和解答]
        
        【建议指导】
        [基于分析结果，给出具体的行动建议和注意事项]
        
        请用专业而通俗易懂的语言进行分析。注意：六爻是一套传统的决策分析框架，通过阴阳二元和六个维度来帮助理清思路，而非预测未来。分析应该基于当前形势、个人能力和客观规律，提供理性建议。
        """
    }
    
    private func parseAIResponse(_ content: String) -> (interpretation: String, advice: String) {
        let lines = content.components(separatedBy: .newlines)
        var interpretation = ""
        var advice = ""
        var currentSection = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.contains("【卦象解析】") || trimmedLine.contains("【问题解读】") {
                currentSection = "interpretation"
            } else if trimmedLine.contains("【建议指导】") {
                currentSection = "advice"
            } else if !trimmedLine.isEmpty && !trimmedLine.hasPrefix("【") {
                if currentSection == "interpretation" {
                    interpretation += trimmedLine + "\n"
                } else if currentSection == "advice" {
                    advice += trimmedLine + "\n"
                }
            }
        }
        
        // 如果解析失败，使用原始内容
        if interpretation.isEmpty {
            interpretation = content
        }
        if advice.isEmpty {
            advice = "请根据卦象指引，谨慎行事，顺应天时。"
        }
        
        return (interpretation.trimmingCharacters(in: .whitespacesAndNewlines),
                advice.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    private func getChineseHour(from hour: Int) -> String {
        let hours = ["子时", "丑时", "寅时", "卯时", "辰时", "巳时",
                    "午时", "未时", "申时", "酉时", "戌时", "亥时"]
        let index = (hour + 1) / 2 % 12
        return hours[index]
    }
    
    // MARK: - Simple AI Response (for thinking tools)
    
    /// 简单的AI响应方法，用于思维工具等场景
    func getSimpleAIResponse(prompt: String) async throws -> String {
        let requestBody: [String: Any] = [
            "model": "deepseek-v3-250324",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        do {
            let response = try await NetworkService.shared.sendRequest(
                body: requestBody,
                responseType: AIResponse.self
            )
            
            if let content = response.choices.first?.message.content {
                return content
            } else {
                throw AIServiceError.noResponse
            }
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.requestFailed(error)
        }
    }
    // MARK: - 五行矩阵 AI 分析（复用火山方舟 API）
    
    // ── System Prompt：锁定 AI 角色 + 强制纯 JSON 输出 ────────────
    private let portraitSystemPrompt = """
    你是一个专业的命理分析引擎，专注于八字五行能量计算。
    你的唯一职责是：根据输入的生辰信息，输出精确的五行能量分析 JSON。
    【铁律】：
    1. 只输出一个合法 JSON 对象，绝对不输出任何解释、前缀、后缀、markdown 代码块
    2. 不使用"忌神""日主""喜用神"等专业术语出现在 diagnosis 和 remedy 字段
    3. 五行数值（wood/fire/earth/metal/water）之和必须等于 1.0
    """

    private let matrixSystemPrompt = """
    你是一个专业的五行决策分析引擎，基于"中和为贵"原则进行决策量化评分。
    你的唯一职责是：根据用户命局和决策选项，输出精确的决策矩阵 JSON。
    【铁律】：
    1. 只输出一个合法 JSON 对象，绝对不输出任何解释、前缀、后缀、markdown 代码块
    2. score 必须是 0~100 的整数，所有选项分数不能完全相同
    3. optionDetails 中 type 只能是：benefit / consumption / danger / neutral
    4. dimensions 数组必须包含且仅包含 3 个维度
    """
    // ─────────────────────────────────────────────────────────────

    /// 根据生日 + 时辰分析五行能量画像，返回 EnergyPortraitResult
    func analyzeEnergyPortrait(
        birthday:  Date,
        birthHour: ChineseHour = .wu,
        gender:    String = "未知"
    ) async throws -> EnergyPortraitResult {
        // 1. 本地算法计算精确五行分值
        let localScores = BaziEngine.shared.calculateEnergy(date: birthday, hour: birthHour)
        let localDayMaster = BaziEngine.shared.getDayMaster(date: birthday, hour: birthHour)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        let birthdayStr = formatter.string(from: birthday)

        let prompt = """
        请分析以下用户的五行能量分布：

        出生信息：
        - 日期：\(birthdayStr)
        - 时辰：\(birthHour.rawValue)（\(birthHour.timeRange)）
        - 性别：\(gender)
        
        【本地算法参考数据】：
        - 日主：\(localDayMaster)
        - 五行能量（已归一化）：
          木：\(String(format: "%.2f", localScores[.wood] ?? 0))
          火：\(String(format: "%.2f", localScores[.fire] ?? 0))
          土：\(String(format: "%.2f", localScores[.earth] ?? 0))
          金：\(String(format: "%.2f", localScores[.metal] ?? 0))
          水：\(String(format: "%.2f", localScores[.water] ?? 0))

        分析要求：
        1. 必须优先采纳【本地算法参考数据】中的五行数值和日主，确保数学计算准确
        2. 根据月令、日主旺衰，判断整体命局格局
        3. 确定最需补充的五行（weakElement）和需要规避的五行
        4. diagnosis：50~80字，用"你是..."开头，通俗比喻，不使用专业术语
        5. remedy：30~50字，具体建议选择什么类型的环境/机会

        输出 JSON（无任何额外内容）：
        {"wood":0.15,"fire":0.45,"earth":0.25,"metal":0.10,"water":0.05,"dayMaster":"丁火","dominantElement":"火","weakElement":"水","favorableElements":["水","木"],"unfavorableElements":["土","金"],"diagnosis":"你是...","remedy":"宜..."}
        """

        let rawContent = try await getMatrixAIResponse(system: portraitSystemPrompt, prompt: prompt)
        return try parseMatrixJSON(from: rawContent, as: EnergyPortraitResult.self)
    }

    /// 根据命局画像 + 决策选项，分析决策矩阵，返回 DecisionMatrixResult
    func analyzeDecisionMatrix(
        portrait: EnergyPortraitResult,
        options:  [String],
        scenario: String,
        question: String
    ) async throws -> DecisionMatrixResult {
        let labels = ["A", "B", "C", "D", "E"]
        let optionList = options.enumerated()
            .map { "选项\(labels[$0.offset])：\($0.element)" }
            .joined(separator: "\n")

        // 根据场景动态生成三才维度说明
        // let dims = scenarioDimensions(for: scenario)
        // let dimInstruction = dims.map {
        //     "「\($0.name)」权重\($0.weight)%：分析要素 \($0.keywords)"
        // }.joined(separator: "\n")
        // let dimJsonTemplate = dims.map {
        //     "{\"name\":\"\($0.name)\",\"weight\":\($0.weight),\"optionDetails\":[{\"type\":\"benefit\",\"elements\":\"[X]\",\"description\":\"简短描述\"},{\"type\":\"consumption\",\"elements\":\"[Y]\",\"description\":\"简短描述\"}]}"
        // }.joined(separator: ",")

        let prompt = """
        用户命局：
        - 日主：\(portrait.dayMaster)
        - 能量之药（喜用）：\(portrait.favorableElements.joined(separator: "、"))
        - 能量之病（忌）：\(portrait.unfavorableElements.joined(separator: "、"))
        - 命局摘要：\(portrait.diagnosis)

        决策背景：
        - 场景分类：\(scenario)
        - 具体问题：\(question)
        
        待分析选项：
        \(optionList)

        评分规则：满分100分，大吉≥85，小吉70~84，平50~69，小凶30~49，大凶<30
        一票否决：若某选项核心属性直接命中"忌"，hasFatalRisk=true，fatalRiskOption=该选项0-based索引

        三才维度（重要）：
        请根据用户的具体问题，动态生成 3 个最相关的对比维度（不要使用固定的“地利/人和/天时”模板，除非它们确实最贴切）。
        例如：
        - 比较股票：维度可以是“行业属性”、“资金流动性”、“入场时机”
        - 比较工作：维度可以是“企业文化”、“业务方向”、“团队氛围”
        - 比较房产：维度可以是“地理位置”、“楼层户型”、“装修风格”
        
        请确保生成的维度名称能准确反映问题核心。JSON 中的 name 字段直接填写维度名称即可。

        输出 JSON（无任何额外内容）：
        {"options":[{"name":"选项A","score":85,"verdict":"大吉","remedyPower":75,"ailmentPower":20,"elements":["水","木"],"tags":["补益","顺势"],"summary":"30字内分析"}],"recommendation":0,"hasFatalRisk":false,"fatalRiskOption":-1,"fatalRiskReason":"","dimensions":[{"name":"维度1名称","weight":40,"optionDetails":[{"type":"benefit","elements":"[X]","description":"简短描述"},{"type":"consumption","elements":"[Y]","description":"简短描述"}]},{"name":"维度2名称","weight":30,"optionDetails":[{"type":"benefit","elements":"[X]","description":"简短描述"},{"type":"consumption","elements":"[Y]","description":"简短描述"}]},{"name":"维度3名称","weight":30,"optionDetails":[{"type":"benefit","elements":"[X]","description":"简短描述"},{"type":"consumption","elements":"[Y]","description":"简短描述"}]}]}
        """

        let rawContent = try await getMatrixAIResponse(system: matrixSystemPrompt, prompt: prompt)
        return try parseMatrixJSON(from: rawContent, as: DecisionMatrixResult.self)
    }

    // MARK: - 场景 → 三才维度映射
    private struct DimSpec { let name: String; let weight: Int; let keywords: String }

    private func scenarioDimensions(for scenario: String) -> [DimSpec] {
        // 匹配场景名称中的关键字
        if scenario.contains("事业") || scenario.contains("学业") || scenario.contains("职") || scenario.contains("工作") {
            return [
                DimSpec(name: "公司文化 (氛围)",   weight: 40, keywords: "企业五行属性、行业能量场、团队氛围"),
                DimSpec(name: "业务方向 (赛道)",   weight: 30, keywords: "岗位五行归属、行业发展性、竞争格局"),
                DimSpec(name: "入职时机 (天时)",   weight: 30, keywords: "入职季节、合同签署时机、当年运势")
            ]
        } else if scenario.contains("投资") || scenario.contains("理财") || scenario.contains("股") || scenario.contains("基金") {
            return [
                DimSpec(name: "标的属性 (行业)",   weight: 40, keywords: "行业五行、主营业务能量场"),
                DimSpec(name: "资金规模 (仓位)",   weight: 30, keywords: "入资比例、风险敞口、流动性"),
                DimSpec(name: "入场时机 (时机)",   weight: 30, keywords: "市场周期、入场节点、大运流年")
            ]
        } else if scenario.contains("情感") || scenario.contains("人际") || scenario.contains("感情") || scenario.contains("婚") {
            return [
                DimSpec(name: "能量匹配 (合缘)",   weight: 40, keywords: "双方五行互补程度、合局与冲克"),
                DimSpec(name: "相处模式 (人和)",   weight: 30, keywords: "生活习惯、沟通方式、性格契合"),
                DimSpec(name: "缘分时机 (天时)",   weight: 30, keywords: "相识时间、确定关系节点、流年支持")
            ]
        } else if scenario.contains("置业") || scenario.contains("生活") || scenario.contains("房") || scenario.contains("购") {
            return [
                DimSpec(name: "地理位置 (地利)",   weight: 40, keywords: "方位风水、水系、周边五行环境"),
                DimSpec(name: "房屋属性 (人和)",   weight: 30, keywords: "楼层数理、装修风格、户型格局"),
                DimSpec(name: "购买时机 (天时)",   weight: 30, keywords: "入住季节、装修时间、楼市周期")
            ]
        } else if scenario.contains("出行") || scenario.contains("旅") || scenario.contains("移") {
            return [
                DimSpec(name: "目的地 (方位)",     weight: 40, keywords: "地域方向、五行属性、当地气候"),
                DimSpec(name: "出行伙伴 (人和)",   weight: 30, keywords: "同行人员五行、相处格局"),
                DimSpec(name: "出行时机 (天时)",   weight: 30, keywords: "日期选择、季节因素、流年支持")
            ]
        } else {
            // 通用默认三才
            return [
                DimSpec(name: "地利 (环境/空间)",  weight: 40, keywords: "地理位置、物理环境、五行方位"),
                DimSpec(name: "人和 (人际/组织)",  weight: 30, keywords: "相关人员、组织氛围、合作关系"),
                DimSpec(name: "天时 (时机/节点)",  weight: 30, keywords: "时机选择、季节因素、流年运势")
            ]
        }
    }

    // MARK: - 带 System 消息的请求（temperature 0.3，提升 JSON 一致性）
    private func getMatrixAIResponse(system: String, prompt: String) async throws -> String {
        let requestBody: [String: Any] = [
            "model": "deepseek-v3-250324",
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": prompt]
            ],
            "max_tokens": 2000,
            "temperature": 0.3    // 低温度 → JSON 输出更稳定
        ]
        let response = try await NetworkService.shared.sendRequest(
            body: requestBody,
            responseType: AIResponse.self
        )
        if let content = response.choices.first?.message.content {
            return content
        }
        throw AIServiceError.noResponse
    }

    // MARK: - JSON 解析辅助（自动提取 ```json...``` 代码块）
    private func parseMatrixJSON<T: Codable>(from content: String, as type: T.Type) throws -> T {
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // 尝试提取 ```json...``` 代码块
        if let startRange = jsonString.range(of: "```json"),
           let endRange = jsonString.range(of: "```", range: startRange.upperBound..<jsonString.endIndex) {
            jsonString = String(jsonString[startRange.upperBound..<endRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // 否则提取第一个 { ... } 块
        else if let firstBrace = jsonString.firstIndex(of: "{"),
                let lastBrace  = jsonString.lastIndex(of: "}") {
            jsonString = String(jsonString[firstBrace...lastBrace])
        }

        guard let data = jsonString.data(using: .utf8) else {
            print("[AIService] Matrix: 无法将字符串转为 Data")
            throw AIServiceError.noResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("[AIService] Matrix JSON解析失败: \(error)")
            print("[AIService] 原始内容前800字: \(content.prefix(800))")
            
            // 如果解析失败，尝试打印更详细的信息以便调试
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[AIService] 提取的 JSON 字符串: \(jsonString)")
            }
            
            throw AIServiceError.requestFailed(error)
        }
    }
}

// ============================================================
enum AIServiceError: Error, LocalizedError {
    case noResponse
    case requestFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "AI未返回有效响应"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        }
    }
}