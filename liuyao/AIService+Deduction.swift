import Foundation

extension AIService {
    func performDeduction(
        question: String,
        background: String,
        liuYaoChart: LiuYaoReading,
        castTime: Date,
        canonicalSummary: String
    ) async throws -> DeductionReport {
        let prompt = buildDeductionPrompt(
            question: question,
            background: background,
            chart: liuYaoChart,
            castTime: castTime,
            canonicalSummary: canonicalSummary
        )
        let requestBody: [String: Any] = [
            "model": ConfigManager.shared.modelEndpoint,
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 8000,
            "temperature": 0.5
        ]
        let response = try await NetworkService.shared.sendRequest(
            body: requestBody,
            responseType: AIResponse.self
        )
        guard let content = response.choices.first?.message.content else {
            throw AIServiceError.noResponse
        }
        return try parseDeductionReport(from: content)
    }

    private func buildDeductionPrompt(
        question: String,
        background: String,
        chart: LiuYaoReading,
        castTime: Date,
        canonicalSummary: String
    ) -> String {
        let trimmedBackground = background.trimmingCharacters(in: .whitespacesAndNewlines)
        let replacements = [
            "{{question}}": question,
            "{{background}}": trimmedBackground.isEmpty ? "无补充背景" : trimmedBackground,
            "{{divination_method}}": "三钱起卦",
            "{{divination_time}}": formattedDivinationTime(castTime, chart: chart),
            "{{original_hexagram_name}}": chart.primary.name,
            "{{changed_hexagram_name}}": chart.changed?.name ?? "无动爻，不变",
            "{{six_lines_raw_data}}": sixLinesJSON(chart.primary.lines),
            "{{divination_metadata}}": divinationMetadata(chart),
            "{{canonical_interpretation_summary}}": canonicalSummary
        ]
        var prompt = DeductionPromptTemplate.template
        for (key, value) in replacements {
            prompt = prompt.replacingOccurrences(of: key, with: value)
        }
        return prompt
    }

    private func formattedDivinationTime(_ castTime: Date, chart: LiuYaoReading) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        let clock = formatter.string(from: castTime)
        let ganZhi = chart.castTime.ganZhi
        return "\(clock)（\(ganZhi.year)年 \(ganZhi.month)月 \(ganZhi.day)日 \(ganZhi.hour)时）"
    }

    private func sixLinesJSON(_ lines: [LiuYaoLine]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(lines),
              let text = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return text
    }

    private func divinationMetadata(_ chart: LiuYaoReading) -> String {
        var lines: [String] = []
        lines.append("月建：\(chart.castTime.monthBranch)")
        lines.append("日辰：\(chart.castTime.dayPillar)")
        let xunKong = chart.castTime.xunKong.joined(separator: "、")
        lines.append("旬空：\(xunKong.isEmpty ? "无" : xunKong)")

        if let yongShen = chart.yongShen {
            lines.append("用神六亲：\(yongShen.liuQin)")
            let positions = yongShen.positions.map(String.init).joined(separator: "、")
            lines.append("用神位置：\(positions.isEmpty ? "未提供" : positions)")
            lines.append("伏藏：\(yongShen.fuCang ? "是" : "否")")
        } else {
            lines.append("用神：未提供")
        }

        if let yong = chart.assessment.yong {
            lines.append("用神旺衰：\(yong.wangShuai)")
            lines.append("得令：\(yong.deLing ? "是" : "否")")
            lines.append("用神旬空：\(yong.xunKong ? "是" : "否")")
            lines.append("月破：\(yong.yuePo ? "是" : "否")")
        } else {
            lines.append("用神旺衰：未提供")
        }

        let xing = chart.xingHai.xing.map { "\($0.zhi)刑\($0.targetZhi)" }
        lines.append("刑：\(xing.isEmpty ? "无" : xing.joined(separator: "、"))")
        let hai = chart.xingHai.hai.map { "\($0.zhi)害\($0.targetZhi)" }
        lines.append("害：\(hai.isEmpty ? "无" : hai.joined(separator: "、"))")

        let sanHe = chart.relations.sanHe.map { "\($0.wuXing)\($0.chengJu)" }
        lines.append("三合：\(sanHe.isEmpty ? "无" : sanHe.joined(separator: "、"))")
        lines.append("六合：\(chart.relations.liuHe ? "是" : "否")")
        lines.append("反吟：\(displayRelation(chart.relations.fanYin))")
        lines.append("伏吟：\(displayRelation(chart.relations.fuYin))")
        return lines.joined(separator: "\n")
    }

    private func displayRelation(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "无" : trimmed
    }

    private func parseDeductionReport(from content: String) throws -> DeductionReport {
        var json = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = json.range(of: "```json"),
           let end = json.range(of: "```", range: start.upperBound..<json.endIndex) {
            json = String(json[start.upperBound..<end.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let start = json.firstIndex(of: "{"),
                  let end = json.lastIndex(of: "}") {
            json = String(json[start...end])
        }
        guard let data = json.data(using: .utf8) else {
            throw AIServiceError.noResponse
        }
        let decoded: DeductionReport
        do {
            decoded = try JSONDecoder().decode(DeductionReport.self, from: data)
        } catch {
            print("[AIService] 推演 JSON 无法解析: \(error)")
            print("[AIService] 推演原文前800字: \(content.prefix(800))")
            throw AIServiceError.requestFailed(error)
        }
        guard let report = decoded.keepingDisplayablePaths() else {
            print("[AIService] 推演路径都没有可展示的总断")
            throw AIServiceError.noResponse
        }
        return report
    }
}
