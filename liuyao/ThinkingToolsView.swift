//
//  ThinkingToolsView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  思维工具箱 - Tab 2
//

import SwiftUI

struct ThinkingToolsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部说明
                headerSection
                
                // 工具网格
                toolsGrid
            }
            .padding()
        }
        .navigationTitle("思维工具")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("结构化思维工具箱")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("用科学方法分析问题")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }
    
    private var toolsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // SWOT分析
            NavigationLink(destination: SWOTAnalysisView()) {
                ToolCard(
                    title: "SWOT分析",
                    icon: "square.grid.2x2.fill",
                    color: .blue,
                    description: "优势劣势机会威胁"
                )
            }
            
            // 决策矩阵
            NavigationLink(destination: DecisionMatrixView()) {
                ToolCard(
                    title: "决策矩阵",
                    icon: "square.grid.3x3.fill",
                    color: .green,
                    description: "多方案对比评估"
                )
            }
            
            // 5W1H分析（占位）
            ToolCard(
                title: "5W1H分析",
                icon: "questionmark.circle.fill",
                color: .orange,
                description: "全面问题拆解"
            )
            .opacity(0.5)
            
            // 优先级矩阵（占位）
            ToolCard(
                title: "优先级矩阵",
                icon: "chart.bar.fill",
                color: .purple,
                description: "重要紧急排序"
            )
            .opacity(0.5)
        }
    }
}

// MARK: - ToolCard Component

struct ToolCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    NavigationStack {
        ThinkingToolsView()
    }
}

