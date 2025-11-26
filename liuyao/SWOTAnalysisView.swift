//
//  SWOTAnalysisView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  SWOT分析工具
//

import SwiftUI

struct SWOTAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var problemTitle = ""
    @State private var strengths = ""
    @State private var weaknesses = ""
    @State private var opportunities = ""
    @State private var threats = ""
    @State private var showResult = false
    @State private var aiAnalysis = ""
    @State private var isLoadingAI = false
    
    private let titleMaxLength = 100
    private let fieldMaxLength = 300
    
    private var canAnalyze: Bool {
        !problemTitle.isEmpty && (
            !strengths.isEmpty || !weaknesses.isEmpty ||
            !opportunities.isEmpty || !threats.isEmpty
        )
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 顶部说明
                    headerSection
                    
                    // 问题标题输入
                    titleSection
                    
                    // 四象限输入
                    quadrantSection
                    
                    // 分析按钮
                    analyzeButton
                    
                    // AI分析结果
                    if showResult {
                        resultSection
                            .id("aiResult")
                    }
                }
                .padding()
            }
            .onChange(of: isLoadingAI) { newValue in
                // 当AI分析完成时，滚动到结果区域
                if newValue == false && showResult {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo("aiResult", anchor: .top)
                        }
                    }
                }
            }
        }
        .navigationTitle("SWOT分析")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("SWOT分析工具")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("系统分析优势、劣势、机会、威胁")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("""
            SWOT分析是一种战略规划工具，通过四个维度：
            • Strengths (优势) - 你的优势是什么？
            • Weaknesses (劣势) - 你的不足在哪里？
            • Opportunities (机会) - 有什么外部机会？
            • Threats (威胁) - 面临什么风险？
            """)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分析主题")
                .font(.headline)
            
            TextField("例如：要不要换工作？创业是否可行？", text: $problemTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var quadrantSection: some View {
        VStack(spacing: 16) {
            // Strengths
            QuadrantInput(
                title: "优势 (Strengths)",
                icon: "star.fill",
                color: .green,
                placeholder: "我的优势、资源、能力...",
                text: $strengths
            )
            
            // Weaknesses
            QuadrantInput(
                title: "劣势 (Weaknesses)",
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                placeholder: "我的不足、限制、短板...",
                text: $weaknesses
            )
            
            // Opportunities
            QuadrantInput(
                title: "机会 (Opportunities)",
                icon: "arrow.up.right.circle.fill",
                color: .blue,
                placeholder: "外部机会、趋势、可能性...",
                text: $opportunities
            )
            
            // Threats
            QuadrantInput(
                title: "威胁 (Threats)",
                icon: "exclamationmark.shield.fill",
                color: .red,
                placeholder: "外部风险、竞争、障碍...",
                text: $threats
            )
        }
    }
    
    private var analyzeButton: some View {
        Button(action: {
            analyzeWithAI()
        }) {
            HStack(spacing: 8) {
                if isLoadingAI {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("AI正在分析")
                } else {
                    Image(systemName: "sparkles")
                    Text("AI深度分析")
                    Image(systemName: "sparkles")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!canAnalyze || isLoadingAI)
        .opacity((!canAnalyze || isLoadingAI) ? 0.6 : 1.0)
    }
    
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("AI分析结果")
                    .font(.headline)
            }
            
            if isLoadingAI {
                HStack {
                    ProgressView()
                    Text("正在分析...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                FormattedTextView(segments: formatAIText(aiAnalysis))
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Methods
    
    private func analyzeWithAI() {
        isLoadingAI = true
        showResult = true
        
        Task {
            do {
                let prompt = """
                你是一位资深的决策分析师，请对以下SWOT分析进行专业解读：
                
                【分析主题】\(problemTitle)
                
                【四象限分析】
                优势(Strengths)：\(strengths.isEmpty ? "未明确" : strengths)
                劣势(Weaknesses)：\(weaknesses.isEmpty ? "未明确" : weaknesses)
                机会(Opportunities)：\(opportunities.isEmpty ? "未明确" : opportunities)
                威胁(Threats)：\(threats.isEmpty ? "未明确" : threats)
                
                【分析要求】
                1. 相互关系分析：SO/WO/ST/WT四种策略组合
                2. 关键因素识别：找出最核心的优势和最大的威胁
                3. 优先级排序：哪些事最重要、最紧急
                4. 行动建议：短期(1个月)和中期(3-6个月)的具体行动
                
                【输出格式】请使用markdown格式，包含标题(###)、加粗(**重点**)、列表(-)等，便于阅读。
                """
                
                let result = try await AIService.shared.getSimpleAIResponse(prompt: prompt)
                
                await MainActor.run {
                    aiAnalysis = result
                    isLoadingAI = false
                }
            } catch {
                await MainActor.run {
                    aiAnalysis = "分析失败：\(error.localizedDescription)"
                    isLoadingAI = false
                }
            }
        }
    }
}

// MARK: - QuadrantInput Component

struct QuadrantInput: View {
    let title: String
    let icon: String
    let color: Color
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            TextEditor(text: $text)
                .frame(height: 80)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                        }
                    }
                )
        }
    }
}

#Preview {
    NavigationStack {
        SWOTAnalysisView()
    }
}

