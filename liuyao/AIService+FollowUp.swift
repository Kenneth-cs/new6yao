import Foundation

enum FollowUpEntryMode: Equatable {
    case fromQuestion(preset: String)
    case fromIcon
}

struct HexagramContext {
    let question: String
    let hexagramName: String
    let hexagramDescription: String
    let oneSentenceConclusion: String
    let castTime: Date
    let location: String
    /// 核心结论 + 建议指导，超过 300 字已截断。
    let interpretationSummary: String
    let liuYaoChart: LiuYaoReading?
    let yaoLines: [YaoXiang]
    let followUpSuggestions: [String]
}

enum InterpretationTrailer {
    struct Split {
        var body: String
        var conclusion: String
        /// 原文里出现了【追问建议】时才为 true。缺失时 suggestions 为空，由调用方决定是否用备用问题。
        var foundSuggestions: Bool
        var suggestions: [String]
    }

    static let defaultSuggestions = [
        "这个卦对我有什么启示？",
        "现在适合采取行动吗？",
        "后续会有什么变化？"
    ]

    static func split(_ text: String) -> Split {
        let markers = ["【一句话结论】", "【追问建议】"]
        var cut = text.endIndex
        for marker in markers {
            if let range = text.range(of: marker), range.lowerBound < cut {
                cut = range.lowerBound
            }
        }
        let tail = String(text[cut...])
        let found = tail.contains("【追问建议】")
        return Split(
            body: trimmedBody(String(text[..<cut])),
            conclusion: parseConclusion(from: tail),
            foundSuggestions: found,
            suggestions: found ? parseSuggestions(from: tail) : []
        )
    }

    static func padded(_ suggestions: [String]) -> [String] {
        var list = suggestions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        var index = 0
        while list.count < 3, index < defaultSuggestions.count {
            let item = defaultSuggestions[index]
            if !list.contains(item) {
                list.append(item)
            }
            index += 1
        }
        return Array(list.prefix(3))
    }

    /// 把「这不是一卦叫你……，而是一卦提醒你」收成直接陈述，避免概述读起来像在否定这卦。
    static func readableOverview(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let patterns = [
            #"这不是一卦叫你[^，。；\n]{1,24}[，,]而是一卦提醒你[：:]"#,
            #"不是一卦叫你[^，。；\n]{1,24}[，,]而是一卦提醒你[：:]"#,
            #"这不是一卦[^，。；\n]{0,24}[，,]而是一卦提醒你[：:]"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                range: range,
                withTemplate: "这卦是在提醒你："
            )
        }
        return result
    }

    private static func trimmedBody(_ text: String) -> String {
        var lines = text.components(separatedBy: .newlines)
        while let last = lines.last {
            let trimmed = last.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.allSatisfy({ $0 == "-" || $0 == "—" }) {
                lines.removeLast()
            } else {
                break
            }
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseConclusion(from text: String) -> String {
        guard let range = text.range(of: "【一句话结论】") else { return "" }
        let after = text[range.upperBound...]
        let end = after.range(of: "【")?.lowerBound ?? after.endIndex
        let block = String(after[..<end])
        for line in block.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("[") || trimmed.hasPrefix("（") { continue }
            return trimmed
        }
        return ""
    }

    private static func parseSuggestions(from text: String) -> [String] {
        guard let range = text.range(of: "【追问建议】") else { return [] }
        let block = String(text[range.upperBound...])
        var suggestions: [String] = []
        for line in block.components(separatedBy: .newlines).prefix(10) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let first = trimmed.first, first == "Q" || first == "q" else { continue }
            guard let colon = trimmed.firstIndex(where: { $0 == ":" || $0 == "：" }) else { continue }
            let content = String(trimmed[trimmed.index(after: colon)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty { suggestions.append(content) }
            if suggestions.count >= 3 { break }
        }
        return padded(suggestions)
    }
}

private let followUpSystemPrompt = """
你是「追问教练」，一位精通六爻纳甲体系的卦象解读助手。

用户刚刚完成了一次六爻起卦，你的任务是基于本次卦象专门回答用户的追问。
你已经完整读过了这次的卦象信息和解读内容，不需要重新解卦。

## 你的回答风格

1. **先结论，后依据**
   每条回复先给出直接判断，再附一句卦理依据。
   例："此时不宜主动推进——卦中应爻受日辰冲克，外部条件尚不成熟。"

2. **聚焦、简洁**
   单次回复不超过 120 字。用户如需深入，他们会追问。
   不主动延伸到用户未问的维度。

3. **卦象落地，不飘**
   每个判断要能落到具体的卦象依据，例如：
   - "从{卦名}之象来看…"
   - "世爻{爻位}处于{旺衰}，说明…"
   - "动爻{爻名}化{变爻}，意味着…"
   - "月建{天干地支}对用神形成{生/克}…"
   如果排盘信息不完整，诚实告知"排盘中未体现此信息，仅从卦名卦义分析"。

4. **禁止使用的表达**
   × 宇宙/命运/磁场/高维能量/灵魂召唤
   × 一定会/必然/绝对/100%
   × 你内心深处/你潜意识里（未经卦象支撑，不做心理推断）
   × 泛泛的人生哲理（如"顺其自然就好""保持积极心态"等）

5. **边界**
   - 只基于**本次卦象**回答，不引用其他卦象、不借用用户以前的卦象
   - 不做医疗、法律、财务投资的具体建议
   - 不给绝对性的吉凶断言，用"倾向于""卦象显示""需关注"等表述
   - 话题严重跑偏时，温和引回本次卦象："这个问题需要单独起卦，本次卦象聚焦在 {原问题}，我们先就这个聊。"

## 开场规则（fromIcon 入口时的第一条消息）

当用户通过"头像入口"进入追问页时（不是点具体问题进来），你需要主动发出一条开场消息。
开场消息由代码本地生成，不调用 API，也不要在回复里重复卦象概述原文。
需要强调某个短句时，只用 **短句** 标记，不要使用标题、列表或代码块。

## 多轮对话原则

- 每次请求携带最近 6 轮（12 条消息）的历史，维持对话连贯性
- 不重复已经说过的内容，每轮回复要有新的信息增量
- 如果用户的问题在之前已经回答过，可以简短呼应后补充新角度
"""

extension AIService {
    func sendFollowUpMessage(
        context: HexagramContext,
        history: [FollowUpChatMessage],
        userMessage: String
    ) async throws -> String {
        let messages = buildFollowUpMessages(context: context, history: history, userMessage: userMessage)
        let body: [String: Any] = [
            "model": ConfigManager.shared.modelEndpoint,
            "messages": messages,
            "max_tokens": 350,
            "temperature": 0.65,
            "top_p": 0.9,
            "frequency_penalty": 0.3,
            "presence_penalty": 0.2
        ]
        let response = try await NetworkService.shared.sendRequest(
            body: body,
            responseType: AIResponse.self,
            maxRetries: 1,
            timeout: 15
        )
        let content = response.choices.first?.message.content
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.isEmpty else { throw AIServiceError.noResponse }
        return content
    }

    func buildFollowUpMessages(
        context: HexagramContext,
        history: [FollowUpChatMessage],
        userMessage: String
    ) -> [[String: Any]] {
        var messages: [[String: Any]] = []
        messages.append(["role": "system", "content": followUpSystemPrompt])
        messages.append(["role": "user", "content": buildPinnedContext(context)])
        messages.append(["role": "assistant", "content": "好的，我已了解本次卦象的全部信息，请开始追问。"])

        var recent = Array(history.suffix(12))
        while recent.count >= 2, estimatedTokens(recent) > 900 {
            recent.removeFirst(2)
        }
        if recent.count == 1, estimatedTokens(recent) > 900, let only = recent.first {
            recent = [
                FollowUpChatMessage(
                    role: only.role,
                    text: String(only.text.prefix(900)),
                    time: only.time
                )
            ]
        }
        for message in recent {
            messages.append([
                "role": message.role == .user ? "user" : "assistant",
                "content": message.text
            ])
        }
        messages.append(["role": "user", "content": userMessage])
        return messages
    }

    private func buildPinnedContext(_ context: HexagramContext) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        let time = formatter.string(from: context.castTime)
        let location = context.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let place = location.isEmpty ? "未记录" : location

        var lines = [
            "【本次卦象背景】",
            "问题：\(context.question)",
            "卦名：\(context.hexagramName)",
            "卦象说明：\(context.hexagramDescription)",
            "起卦时间：\(time)",
            "起卦地点：\(place)"
        ]

        if let chart = context.liuYaoChart {
            lines.append("月建：\(chart.castTime.monthBranch)")
            lines.append("日辰：\(chart.castTime.dayPillar)")
            lines.append("旬空：\(chart.castTime.xunKong.joined(separator: "、"))")
            let moving = movingLineDescriptions(chart)
            if !moving.isEmpty {
                lines.append(contentsOf: moving)
            }
        }

        let summary = context.interpretationSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summary.isEmpty {
            lines.append("已有解读要点：\(summary)")
        }
        return lines.joined(separator: "\n")
    }

    private func movingLineDescriptions(_ chart: LiuYaoReading) -> [String] {
        chart.primary.lines.enumerated().compactMap { index, line in
            guard line.moving != nil else { return nil }
            let changedName: String
            if let changed = chart.changed, changed.lines.indices.contains(index) {
                let changedLine = changed.lines[index]
                changedName = "\(changedLine.liuQin)\(changedLine.naJia.gan)\(changedLine.naJia.zhi)"
            } else {
                changedName = line.moving ?? "变爻"
            }
            return "动爻：第 \(line.position) 爻（\(line.liuQin)）动，化 \(changedName)"
        }
    }

    private func estimatedTokens(_ messages: [FollowUpChatMessage]) -> Int {
        messages.reduce(0) { $0 + $1.text.count }
    }
}
