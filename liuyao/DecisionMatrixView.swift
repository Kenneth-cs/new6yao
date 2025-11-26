//
//  DecisionMatrixView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  决策矩阵工具
//

import SwiftUI

struct DecisionMatrixView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var problemTitle = ""
    @State private var options: [DecisionOption] = []
    @State private var showAddOption = false
    @State private var showAIAnalysis = false
    @State private var aiAnalysis = ""
    @State private var isLoadingAI = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 顶部说明
                    headerSection
                    
                    // 问题标题输入
                    titleSection
                    
                    // 选项列表
                    optionsSection
                    
                    // 添加选项按钮
                    addOptionButton
                    
                    // AI分析按钮
                    if options.count >= 2 {
                        analyzeButton
                    }
                    
                    // AI分析结果
                    if showAIAnalysis {
                        resultSection
                            .id("aiResult")
                    }
                }
                .padding()
            }
            .onChange(of: isLoadingAI) { newValue in
                // 当AI分析完成时，滚动到结果区域
                if newValue == false && showAIAnalysis {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo("aiResult", anchor: .top)
                        }
                    }
                }
            }
        }
        .navigationTitle("决策矩阵")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddOption) {
            AddOptionView(options: $options)
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("决策矩阵工具")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("多方案对比评估")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("""
            适用场景：
            • 有多个选择方案
            • 需要综合多个维度评估
            • 希望量化比较不同选项
            
            使用方法：
            1. 输入待决策的问题
            2. 添加至少2个选项
            3. 为每个选项打分（1-10分）
            4. AI帮你综合分析
            """)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("决策问题")
                .font(.headline)
            
            TextField("例如：选择哪个工作offer？", text: $problemTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("待选方案 (\(options.count))")
                .font(.headline)
            
            if options.isEmpty {
                Text("还没有添加方案，点击下方按钮添加")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            } else {
                ForEach(options.indices, id: \.self) { index in
                    OptionCard(option: $options[index], onDelete: {
                        options.remove(at: index)
                    })
                }
            }
        }
    }
    
    private var addOptionButton: some View {
        Button(action: {
            showAddOption = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("添加方案")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.green)
            .cornerRadius(12)
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
                    Text("AI综合分析")
                    Image(systemName: "sparkles")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.green, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(problemTitle.isEmpty || options.count < 2 || isLoadingAI)
        .opacity((problemTitle.isEmpty || options.count < 2 || isLoadingAI) ? 0.6 : 1.0)
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
        showAIAnalysis = true
        
        Task {
            do {
                let optionsText = options.enumerated().map { index, option in
                    """
                    方案\(index + 1)：\(option.name)
                    - 优势：\(option.pros)
                    - 劣势：\(option.cons)
                    - 综合评分：\(option.score)/10
                    """
                }.joined(separator: "\n\n")
                
                let prompt = """
                请对以下决策进行综合分析：
                
                决策问题：\(problemTitle)
                
                待选方案：
                \(optionsText)
                
                请提供：
                1. 各方案对比分析
                2. 推荐方案及理由
                3. 需要注意的风险点
                4. 决策建议
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

// MARK: - Data Models

struct DecisionOption: Identifiable {
    let id = UUID()
    var name: String
    var pros: String
    var cons: String
    var score: Double
}

// MARK: - OptionCard Component

struct OptionCard: View {
    @Binding var option: DecisionOption
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(option.name)
                    .font(.headline)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("✅ 优势：\(option.pros)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("⚠️ 劣势：\(option.cons)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("评分：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f", option.score))
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text("/10")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - AddOptionView

struct AddOptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var options: [DecisionOption]
    
    @State private var name = ""
    @State private var pros = ""
    @State private var cons = ""
    @State private var score: Double = 5.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("方案名称") {
                    TextField("例如：A公司offer", text: $name)
                }
                
                Section("优势") {
                    TextEditor(text: $pros)
                        .frame(height: 80)
                }
                
                Section("劣势") {
                    TextEditor(text: $cons)
                        .frame(height: 80)
                }
                
                Section("综合评分") {
                    HStack {
                        Slider(value: $score, in: 1...10, step: 0.5)
                        Text(String(format: "%.1f", score))
                            .font(.headline)
                            .foregroundColor(.green)
                            .frame(width: 40)
                    }
                }
            }
            .navigationTitle("添加方案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let newOption = DecisionOption(
                            name: name,
                            pros: pros,
                            cons: cons,
                            score: score
                        )
                        options.append(newOption)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DecisionMatrixView()
    }
}

