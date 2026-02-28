import Foundation
import SwiftUI

// ============================================================
// MARK: - 决策矩阵 V2 结果模型（丰富版，对应方案B展示页）
// ============================================================

/// 矩阵表格中单行数据（维度 × 选项）
struct MatrixRow: Codable {
    let dimension: String    // 维度名，如"行业属性"
    let type: String         // "benefit" | "consumption" | "danger" | "neutral"
    let label: String        // 简短标签，如"补水木"、"耗土"、"忌神"
    let detail: String       // 一句话说明

    var statusColor: Color {
        switch type {
        case "benefit":     return Color(red: 0.020, green: 0.588, blue: 0.412)  // Emerald-600
        case "danger":      return Color(red: 0.863, green: 0.196, blue: 0.196)  // Red-600
        case "consumption": return Color(red: 0.855, green: 0.537, blue: 0.145)  // Amber-600
        default:            return Color.secondary
        }
    }

    var statusIcon: String {
        switch type {
        case "benefit":     return "checkmark.circle.fill"
        case "danger":      return "xmark.octagon.fill"
        case "consumption": return "minus.circle.fill"
        default:            return "circle"
        }
    }

    var statusEmoji: String {
        switch type {
        case "benefit":     return "✅"
        case "danger":      return "❌"
        case "consumption": return "⚠️"
        default:            return "—"
        }
    }
}

/// V2 单个选项分析
struct DecisionOptionV2: Codable {
    let name: String           // 如"选项A（湖畔花园）"
    let score: Int             // 0~100
    let verdict: String        // 大吉 / 小吉 / 平 / 小凶 / 大凶
    let label: String          // "优选" / "可选" / "淘汰"
    let elements: [String]     // 主要五行属性，如["水","木"]
    let matrixRows: [MatrixRow]// 在每个维度上的表现
    let summary: String        // 30字内总结

    var verdictColor: Color {
        switch verdict {
        case "大吉": return Color(red: 0.020, green: 0.588, blue: 0.412)  // Emerald-600
        case "小吉": return Color(red: 0.306, green: 0.275, blue: 0.898)  // Indigo-600
        case "平":   return Color.secondary
        case "小凶": return Color(red: 0.855, green: 0.537, blue: 0.145)  // Amber-600
        case "大凶": return Color(red: 0.863, green: 0.196, blue: 0.196)  // Red-600
        default:     return Color.secondary
        }
    }

    var labelColor: Color {
        switch label {
        case "优选": return Color(red: 0.020, green: 0.588, blue: 0.412)  // Emerald-600
        case "可选": return Color(red: 0.306, green: 0.275, blue: 0.898)  // Indigo-600
        case "淘汰": return Color(red: 0.863, green: 0.196, blue: 0.196)  // Red-600
        default:     return Color.secondary
        }
    }

    var benefitCount: Int { matrixRows.filter { $0.type == "benefit"     }.count }
    var consumeCount: Int { matrixRows.filter { $0.type == "consumption" }.count }
    var dangerCount:  Int { matrixRows.filter { $0.type == "danger"      }.count }
}

/// 落地建议
struct ActionPlan: Codable {
    let timing:       String   // 时机
    let approach:     String   // 行动方式
    let avoid:        String   // 需要规避的
    let compensation: String   // 补偿/加强策略
}

/// V2 完整决策矩阵结果
struct DecisionMatrixResultV2: Codable {
    let verdict:             String              // "优选A" / "优选B"
    let verdictReason:       String              // 核心原因（30字内）
    let options:             [DecisionOptionV2]  // 各选项分析
    let dimensions:          [String]            // 维度列表
    let extensions:          [String]            // 决策延伸（2~3条）
    let actionPlan:          ActionPlan          // 落地建议
    let fiveElementAnalysis: String              // 命理说明（解释为何这样判断）
    let hasFatalRisk:        Bool
    let fatalRiskDetail:     String              // 一票否决说明

    var recommendedOption: DecisionOptionV2? {
        options.first { $0.label == "优选" } ?? options.first
    }

    // MARK: - Mock
    static let mock = DecisionMatrixResultV2(
        verdict: "优选A",
        verdictReason: "水木相生，顺应命局所需，整体补益远大于损耗",
        options: [
            DecisionOptionV2(
                name: "选项A（湖畔花园）",
                score: 87,
                verdict: "大吉",
                label: "优选",
                elements: ["水", "木"],
                matrixRows: [
                    MatrixRow(dimension: "地理位置", type: "benefit",     label: "补水",  detail: "临湖聚气，名带【霖】，北方水局"),
                    MatrixRow(dimension: "楼层户型", type: "benefit",     label: "补木",  detail: "8层（木数），朝东，绿化率40%"),
                    MatrixRow(dimension: "装修风格", type: "consumption", label: "中性",  detail: "简约现代，轻度金属结构")
                ],
                summary: "水木双补，整体顺应命局，性价比极高"
            ),
            DecisionOptionV2(
                name: "选项B（阳光金融）",
                score: 42,
                verdict: "小凶",
                label: "淘汰",
                elements: ["土", "金"],
                matrixRows: [
                    MatrixRow(dimension: "地理位置", type: "consumption", label: "无水",  detail: "金融区朝南，火属性偏旺"),
                    MatrixRow(dimension: "楼层户型", type: "danger",      label: "忌金",  detail: "25层（金数），大量金属结构克木"),
                    MatrixRow(dimension: "装修风格", type: "danger",      label: "补土金", detail: "豪华大理石+金饰，土金极旺")
                ],
                summary: "土金过重，直接命中忌神，长期压制水木运势"
            )
        ],
        dimensions: ["地理位置", "楼层户型", "装修风格"],
        extensions: [
            "即使选项B价格低10%，但五行属土金（你的忌神），易引发后续纠纷或资产贬值。",
            "若短期内只能选B，可通过门牌号补救（如801室，8为木，1为水），并在家中布置流水装置缓解金气。"
        ],
        actionPlan: ActionPlan(
            timing:       "宜在农历亥月（11月，水旺）签约，避开辰戌丑未月（土旺）",
            approach:     "重点谈判绿化承诺与北向景观保留，以合作共赢为核心策略",
            avoid:        "避免接受以金属材料为主要装修的补偿方案",
            compensation: "入住后家中常播流水声，客厅东侧放绿植（发财树/文竹）强化木气"
        ),
        fiveElementAnalysis: "你的命局水弱土旺，面对选择时容易被「豪华感」（土金）迷惑。选项A的水木格局是你命局的「药」，而选项B的土金格局是你命局的「病」——房子是你的第三层皮肤，选对了是改运法器，选错了是漫长内耗。",
        hasFatalRisk: false,
        fatalRiskDetail: ""
    )
}
