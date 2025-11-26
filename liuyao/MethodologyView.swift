//
//  MethodologyView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  方法论说明页面
//

import SwiftUI

struct MethodologyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 顶部说明
                    headerSection
                    
                    // 方法论说明
                    MethodSection(
                        title: "1. 六爻作为分析框架",
                        content: """
                        六爻不是"算命"，而是一套决策分析框架：
                        
                        • 阴阳二元：事物的两面性
                        • 动静变化：形势的发展趋势
                        • 六个维度：问题的多角度分析
                        
                        类似于现代的：
                        • SWOT分析（优劣势机会威胁）
                        • 决策树模型
                        • 场景规划法
                        """
                    )
                    
                    MethodSection(
                        title: "2. AI深度分析",
                        content: """
                        我们使用先进的AI技术：
                        
                        • 理解问题的深层含义
                        • 结合六爻框架提供多维洞察
                        • 生成个性化的建议
                        
                        不是简单的数据库查询，
                        而是真正的智能分析。
                        """
                    )
                    
                    MethodSection(
                        title: "3. 理性使用建议",
                        content: """
                        ⚠️ 重要提醒：
                        
                        • 这是辅助决策的工具，不是"预测未来"
                        • AI建议仅供参考，最终决策权在你
                        • 重大决策请结合实际情况和专业咨询
                        • 我们反对迷信，提倡理性思考
                        """
                    )
                }
                .padding()
            }
            .navigationTitle("方法论说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 50))
                .foregroundColor(.purple)
            
            Text("我们的分析方法")
                .font(.title)
                .fontWeight(.bold)
            
            Text("理性、科学、实用")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct MethodSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

#Preview {
    MethodologyView()
}

