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
}

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