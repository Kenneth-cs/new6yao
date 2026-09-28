import Foundation

enum QuestionCategoryResolver {
    /// 题库原文 → 引擎类别。空字符串表示手标为未分类，不走关键词。
    static let catalog: [String: String] = {
        var table: [String: String] = [:]
        let grouped: [(String, [String])] = [
            ("事业", [
                "我现在适合换工作吗？",
                "留在现在的公司还有发展空间吗？",
                "我该争取晋升，还是考虑跳槽？",
                "这份新 Offer 值得接受吗？",
                "我现在适合转行吗？",
                "我现在适合裸辞吗？",
                "未来半年我的职业重点应该放在哪里？",
                "我目前最大的职业瓶颈是什么？",
                "我该继续深耕主业，还是发展副业？"
            ]),
            ("姻缘", [
                "这段感情还值得继续吗？",
                "我们之间还有进一步发展的可能吗？",
                "我现在适合主动联系对方吗？",
                "这段关系的问题到底出在哪里？",
                "我们现在更适合继续磨合，还是分开？",
                "我应该接受这段关系的现状吗？",
                "对这段感情，我还应该继续投入吗？",
                "我们之间还有重新开始的机会吗？",
                "我该主动推进这段关系吗？",
                "我现在应该等待，还是做出改变？"
            ]),
            ("考试", [
                "我应该继续读研吗？",
                "我现在适合考研还是先工作？",
                "我应该坚持现在的专业方向吗？",
                "我现在适合出国读书吗？",
                "我该继续备考，还是换一个方向？",
                "我现在最应该提升哪方面的能力？",
                "我应该把时间投入专业能力还是副业技能？",
                "这次考试我应该继续冲一把吗？"
            ]),
            ("事业", [
                "我现在适合开始创业吗？",
                "这个项目值得我继续投入吗？",
                "我应该继续坚持这个项目，还是及时止损？",
                "现在是扩大投入的好时机吗？",
                "这个副业值得我长期发展吗？",
                "我现在应该先赚钱，还是继续打磨产品？"
            ]),
            ("财运", [
                "我现在适合做一笔较大的投资吗？",
                "我现在适合扩大自己的事业投入吗？",
                "我现在应该更积极赚钱，还是先控制支出？",
                "这笔大额消费现在值得做吗？",
                "我该把更多精力放在主业收入还是副业收入？"
            ]),
            ("谋望", [
                "现在这个机会我应该抓住吗？",
                "面对两个选择，我应该更看重稳定还是成长？",
                "我现在适合主动改变现状吗？",
                "这件事我应该继续推进，还是先等等？",
                "未来三个月，我最应该把精力放在哪里？"
            ])
        ]
        for (category, questions) in grouped {
            for question in questions {
                table[question] = category
            }
        }
        let unclassified = [
            "我现在最需要解决的问题是什么？",
            "我最近为什么总感觉找不到方向？"
        ]
        for question in unclassified {
            table[question] = ""
        }
        table["我现在适合买房吗？"] = "搬迁"
        table["我该继续打工，还是尝试创业？"] = "谋望"
        table["我该独立做，还是找合伙人一起做？"] = "合作"
        table["这个合作机会值得接受吗？"] = "合作"
        table["我应该留在现在的城市，还是去新的地方发展？"] = "搬迁"
        return table
    }()

    private static let parentMap: [String: String?] = [
        "职业": "事业",
        "感情": "姻缘",
        "财富": "财运",
        "创业": "事业",
        "学习": "考试",
        "成长": nil,
        "人生选择": "谋望"
    ]

    /// 创业是冲突桶，不是引擎类别。单独命中时落到事业。
    private static let keywordBuckets: [(name: String, words: [String])] = [
        ("事业", ["换工作", "跳槽", "离职", "裸辞", "晋升", "升职", "上司", "同事", "转行", "加班", "裁员", "求职面试", "offer"]),
        ("姻缘", ["恋爱", "分手", "复合", "结婚", "离婚", "对象", "男朋友", "女朋友", "老公", "老婆", "相亲"]),
        ("财运", ["投资", "理财", "股票", "亏钱", "赚钱", "工资", "回款", "借款"]),
        ("搬迁", ["买房", "卖房", "租房", "搬家", "置业", "装修"]),
        ("考试", ["考研", "高考", "考试", "证书", "备考面试"]),
        ("创业", ["创业", "融资", "项目", "合伙人", "副业"]),
        ("合作", ["合作", "合伙", "合同", "签约"]),
        ("健康", ["身体", "生病", "住院", "手术", "体检"]),
        ("出行", ["出行", "旅游", "出差"]),
        ("失物", ["丢了", "失物", "找不到"])
    ]

    private static let mouwangWords = ["两个选择", "A还是B", "该不该抓住这个机会"]

    static func resolve(question: String, hint: String?) -> (category: String?, source: CategorySource) {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        if let stored = catalog[text] {
            return (stored.isEmpty ? nil : stored, .catalog)
        }
        if let hint, parentMap.keys.contains(hint) {
            return (parentMap[hint].flatMap { $0 }, .catalog)
        }
        return keywordResolve(text)
    }

    static func suggestedLiuQin(for category: String?) -> String? {
        guard let category else { return nil }
        if LiuYaoAnalysis.yingAsYongShen.contains(category) { return "应爻为纲" }
        return LiuYaoAnalysis.categoryToYongShen[category]
    }

    private static func keywordResolve(_ text: String) -> (category: String?, source: CategorySource) {
        var hits = Set<String>()
        for bucket in keywordBuckets {
            if bucket.words.contains(where: { containsKeyword(text, $0) }) {
                hits.insert(bucket.name)
            }
        }
        applyInterviewRule(text, hits: &hits)

        if hits.contains("创业") && hits.contains("合作") {
            return (nil, .unclassified)
        }
        if hits.count >= 2 {
            return (nil, .unclassified)
        }
        if hits.isEmpty {
            if mouwangWords.contains(where: { text.contains($0) }) {
                return ("谋望", .keyword)
            }
            return (nil, .unclassified)
        }
        let only = hits.first!
        if only == "创业" {
            return ("事业", .keyword)
        }
        return (only, .keyword)
    }

    private static func applyInterviewRule(_ text: String, hits: inout Set<String>) {
        guard text.contains("面试") else { return }
        let lowered = text.lowercased()
        let job = text.contains("求职") || text.contains("工作") || lowered.contains("offer")
        let exam = text.contains("备考") || text.contains("考研") || text.contains("考试") || text.contains("高考")
        if job && !exam {
            hits.insert("事业")
        } else if exam && !job {
            hits.insert("考试")
        } else if !text.contains("求职面试") && !text.contains("备考面试") {
            hits.insert("事业")
            hits.insert("考试")
        }
    }

    private static func containsKeyword(_ text: String, _ keyword: String) -> Bool {
        if keyword.lowercased() == "offer" {
            return text.lowercased().contains("offer")
        }
        if keyword == "合伙" {
            return text.replacingOccurrences(of: "合伙人", with: "").contains("合伙")
        }
        if keyword == "找不到" {
            let stripped = text
                .replacingOccurrences(of: "找不到方向", with: "")
                .replacingOccurrences(of: "找不到感觉", with: "")
            return stripped.contains("找不到")
        }
        return text.contains(keyword)
    }
}
