import SwiftUI

// 1. 基础模型定义
enum FiveElement: String, CaseIterable {
    case wood = "木", fire = "火", earth = "土", metal = "金", water = "水"
}

// 用户命局画像（简化版）
struct UserEnergyProfile {
    let name: String
    let favorable: [FiveElement] // 喜用神（药）
    let unfavorable: [FiveElement] // 忌神（病）
}

// 决策选项
struct MatrixDecisionOption {
    let name: String
    let attributes: [(element: FiveElement, type: String)] // (五行, 来源类型)
}

// 2. 核心算法引擎 (参考你的文档公式)
class MatrixEngine {
    static func analyze(user: UserEnergyProfile, option: MatrixDecisionOption) -> String {
        var score = 0.0
        var log: [String] = []
        
        log.append("👤 用户：\(user.name) | 喜：\(user.favorable.map{$0.rawValue}) | 忌：\(user.unfavorable.map{$0.rawValue})")
        log.append("📍 选项：\(option.name)")
        log.append("--------------------------------")
        
        // 一票否决标志：当行业本质命中忌神时触发
        var hasFatalRisk = false
        
        for attr in option.attributes {
            let baseScore: Double
            let reason: String
            
            if user.favorable.contains(attr.element) {
                baseScore = 1.5 // 喜用神加权
                reason = "✅ \(attr.element.rawValue) (\(attr.type)) 为喜用"
            } else if user.unfavorable.contains(attr.element) {
                baseScore = -1.5 // 忌神扣分
                reason = "❌ \(attr.element.rawValue) (\(attr.type)) 为忌神"
                
                // 一票否决：行业本质命中忌神，直接淘汰
                if attr.type == "行业本质" {
                    hasFatalRisk = true
                }
            } else {
                baseScore = 0.5 // 平和略吉
                reason = "⚪ \(attr.element.rawValue) (\(attr.type)) 平和"
            }
            
            score += baseScore
            log.append("\(reason) | 得分: \(String(format: "%.1f", baseScore))")
        }
        
        log.append("--------------------------------")
        
        // 结论判定
        let result: String
        if hasFatalRisk {
            result = "🚫 淘汰 (触犯核心忌神，一票否决)"
        } else if score >= 3.0 {
            result = "🏆 优选 (大吉，顺势而为)"
        } else if score > 0 {
            result = "✅ 可行 (小吉，利大于弊)"
        } else {
            result = "⚠️ 慎重 (能量耗损，需补救)"
        }
        
        log.append("📊 总分：\(String(format: "%.1f", score))")
        log.append("📝 结论：\(result)")
        
        return log.joined(separator: "\n")
    }
}

// 3. 测试视图
struct AlgorithmTestView: View {
    @State private var outputText = "点击按钮开始测试..."
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("五行矩阵算法实验室")
                    .font(.title2).bold()
                
                Button("运行模拟测试") {
                    runSimulation()
                }
                .buttonStyle(.borderedProminent)
                
                Text(outputText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
    
    func runSimulation() {
        // 模拟场景：张三，喜木火，忌金水
        let user = UserEnergyProfile(
            name: "张三",
            favorable: [.wood, .fire],
            unfavorable: [.metal, .water]
        )
        
        // 选项A：去北京（水）做互联网（火）
        let optionA = MatrixDecisionOption(name: "去北京做互联网大厂", attributes: [
            (.fire, "行业本质"), // 互联网属火
            (.water, "方位/城市") // 北方属水
        ])
        
        // 选项B：去深圳（火）做互联网（火）
        let optionB = MatrixDecisionOption(name: "去深圳做互联网大厂", attributes: [
            (.fire, "行业本质"), // 互联网属火
            (.fire, "方位/城市") // 南方属火
        ])
        
        // 选项C：去老家做银行柜员（金）
        let optionC = MatrixDecisionOption(name: "回老家进银行", attributes: [
            (.metal, "行业本质"), // 金融属金
            (.earth, "方位/城市") // 本地/中土
        ])
        
        let resultA = MatrixEngine.analyze(user: user, option: optionA)
        let resultB = MatrixEngine.analyze(user: user, option: optionB)
        let resultC = MatrixEngine.analyze(user: user, option: optionC)
        
        outputText = [resultA, resultB, resultC].joined(separator: "\n\n====================\n\n")
    }
}

#Preview {
    AlgorithmTestView()
}
