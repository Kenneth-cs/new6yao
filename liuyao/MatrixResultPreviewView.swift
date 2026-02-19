import SwiftUI

// MARK: - 1. 数据模型 (对应 JSON 结构)

struct MatrixResultData: Codable {
    let step1: Step1Data
    let step2: Step2Data
    let step3: Step3Data
    let step4: Step4Data
    let step5: Step5Data
}

struct Step1Data: Codable {
    let title: String
    let summary: String
    let needs: [FiveElementNeed]
}

struct FiveElementNeed: Codable, Identifiable {
    var id: String { element + action }
    let element: String
    let action: String
    let desc: String
}

struct Step2Data: Codable {
    let title: String
    let options: [OptionAttributes]
}

struct OptionAttributes: Codable, Identifiable {
    var id: String { name }
    let name: String
    let attributes: [AttributeTag]
}

struct AttributeTag: Codable, Identifiable {
    var id: String { factor + value }
    let factor: String
    let value: String
    let element: String
}

struct Step3Data: Codable {
    let title: String
    let evaluations: [OptionEvaluation]
}

struct OptionEvaluation: Codable, Identifiable {
    var id: String { optionName }
    let optionName: String
    let score: Double
    let result: String
    let details: [EvaluationDetail]
}

struct EvaluationDetail: Codable, Identifiable {
    var id: String { desc }
    let type: String // "benefit" or "harm"
    let desc: String
    let isMatch: Bool
}

struct Step4Data: Codable {
    let title: String
    let suggestions: [SuggestionItem]
}

struct SuggestionItem: Codable, Identifiable {
    var id: String { category }
    let category: String
    let content: String
}

struct Step5Data: Codable {
    let title: String
    let content: String
}

// MARK: - 2. Mock 数据生成器

class MockDataManager {
    static func getMockData() -> MatrixResultData {
        let jsonString = """
        {
          "step1": {
            "title": "明确买房的核心五行需求",
            "summary": "你的八字财多身弱 (土旺木弱)，需通过住房风水调候。",
            "needs": [
              {"element": "水", "action": "补水", "desc": "增强智慧、稳定性"},
              {"element": "木", "action": "补木", "desc": "提升合作运、健康"},
              {"element": "土", "action": "耗土", "desc": "消耗过旺财星，避免贪婪反噬"}
            ]
          },
          "step2": {
            "title": "将买房要素转化为五行标签",
            "options": [
              {
                "name": "城北临湖小区",
                "attributes": [
                  {"factor": "地理位置", "value": "近水/城北", "element": "水"},
                  {"factor": "楼层", "value": "8楼", "element": "木"},
                  {"factor": "户型", "value": "朝东", "element": "木"}
                ]
              },
              {
                "name": "市中心金融区",
                "attributes": [
                  {"factor": "地理位置", "value": "金融区", "element": "金"},
                  {"factor": "楼层", "value": "25楼", "element": "土"},
                  {"factor": "装修", "value": "豪华大理石", "element": "土"}
                ]
              }
            ]
          },
          "step3": {
            "title": "用矩阵评估选项",
            "evaluations": [
              {
                "optionName": "城北临湖小区",
                "score": 9.0,
                "result": "优选",
                "details": [
                  {"type": "benefit", "desc": "临湖+朝东 (水木相生)", "isMatch": true},
                  {"type": "benefit", "desc": "8楼 (木数) + 绿化高", "isMatch": true},
                  {"type": "harm", "desc": "无忌神冲突", "isMatch": false}
                ]
              },
              {
                "optionName": "市中心金融区",
                "score": -2.0,
                "result": "淘汰",
                "details": [
                  {"type": "benefit", "desc": "无水属性，朝南耗水", "isMatch": false},
                  {"type": "harm", "desc": "豪华装修 (土金旺)", "isMatch": true},
                  {"type": "harm", "desc": "土金极旺 (财多身弱大忌)", "isMatch": true}
                ]
              }
            ]
          },
          "step4": {
            "title": "落地建议 (如何买)",
            "suggestions": [
              {"category": "地理位置", "content": "最佳：城市北部(水)或东部(木)，小区名带'霖'、'森'等水木字根。"},
              {"category": "楼层选择", "content": "吉层：1, 6 (水), 3, 8 (木)。忌层：5, 10, 4, 9。"},
              {"category": "财务策略", "content": "首付比例 30%-40% (土为财，过度杠杆易反噬)。"}
            ]
          },
          "step5": {
            "title": "终极心法",
            "content": "买房不是终点，而是五行调候的开始。入住后建议每年捐1%房款给环保组织(耗土生水)。"
          }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        return try! decoder.decode(MatrixResultData.self, from: jsonData)
    }
}

// MARK: - 3. 主视图

struct MatrixResultPreviewView: View {
    @State private var resultData: MatrixResultData?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                if let data = resultData {
                    // STEP 1
                    Step1Card(data: data.step1)
                    
                    // STEP 2
                    Step2Card(data: data.step2)
                    
                    // STEP 3
                    Step3Card(data: data.step3)
                    
                    // STEP 4
                    Step4Card(data: data.step4)
                    
                    // STEP 5
                    Step5Card(data: data.step5)
                    
                } else {
                    ProgressView("AI分析生成中...")
                        .padding(.top, 50)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // 模拟 API 延迟加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    self.resultData = MockDataManager.getMockData()
                }
            }
        }
    }
}

// MARK: - 4. UI 组件

// --- Step 1: 核心需求 ---
struct Step1Card: View {
    let data: Step1Data
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(step: "STEP 1", title: data.title)
            
            Text(data.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(data.needs) { need in
                    HStack(spacing: 12) {
                        Text(need.element)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(elementColor(need.element))
                            .frame(width: 40, height: 40)
                            .background(elementColor(need.element).opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(need.action)
                                .font(.headline)
                            Text(need.desc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// --- Step 2: 标签转化 ---
struct Step2Card: View {
    let data: Step2Data
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(step: "STEP 2", title: data.title)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(data.options) { option in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(option.name)
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            ForEach(option.attributes) { attr in
                                HStack {
                                    Text(attr.factor)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(attr.value)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(attr.element)
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(elementColor(attr.element))
                                        .cornerRadius(4)
                                }
                                Divider()
                            }
                        }
                        .padding()
                        .frame(width: 200)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 10) // Shadow space
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// --- Step 3: 矩阵评估 ---
struct Step3Card: View {
    let data: Step3Data
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(step: "STEP 3", title: data.title)
            
            ForEach(data.evaluations) { eval in
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Text(eval.optionName)
                            .font(.headline)
                        Spacer()
                        Text(eval.result)
                            .font(.headline)
                            .foregroundColor(resultColor(eval.result))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(resultColor(eval.result).opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // Details
                    ForEach(eval.details) { detail in
                        HStack(alignment: .top) {
                            Image(systemName: detail.isMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(detail.isMatch ? .green : .red)
                            
                            Text(detail.desc)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// --- Step 4: 落地建议 ---
struct Step4Card: View {
    let data: Step4Data
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(step: "STEP 4", title: data.title)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(data.suggestions) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.category)
                                .font(.subheadline)
                                .fontWeight(.bold)
                            
                            Text(item.content)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// --- Step 5: 终极心法 ---
struct Step5Card: View {
    let data: Step5Data
    
    var body: some View {
        VStack(spacing: 16) {
            Text(data.title)
                .font(.headline)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.bottom, 4)
            
            Text(data.content)
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.5)) // Ink color
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// --- Common Components ---

struct HeaderView: View {
    let step: String
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(step)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(4)
            
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
        }
    }
}

// Helpers
func elementColor(_ element: String) -> Color {
    switch element {
    case "木": return .green
    case "火": return .red
    case "土": return .orange // Brownish
    case "金": return .yellow // Gold
    case "水": return .blue
    default: return .gray
    }
}

func resultColor(_ result: String) -> Color {
    switch result {
    case "优选": return .green
    case "可行": return .blue
    case "慎重": return .orange
    case "淘汰": return .red
    default: return .gray
    }
}

#Preview {
    MatrixResultPreviewView()
}
