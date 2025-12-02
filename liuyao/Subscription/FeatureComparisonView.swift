//
//  FeatureComparisonView.swift
//  人生教练
//
//  功能对比表格视图
//

import SwiftUI

struct FeatureComparisonView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Text("功能对比")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // 对比表格
            VStack(spacing: 12) {
                // 表头
                HStack {
                    Text("功能")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("免费版")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 80)
                    
                    Text("专业版")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                        .frame(width: 80)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // 功能列表
                ForEach(FeatureComparisonItem.allFeatures, id: \.name) { feature in
                    FeatureRow(feature: feature)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 功能行
struct FeatureRow: View {
    let feature: FeatureComparisonItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 功能名称和图标
            HStack(spacing: 8) {
                Image(systemName: feature.icon)
                    .foregroundColor(.purple)
                    .frame(width: 20)
                
                Text(feature.name)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 免费版描述
            Text(feature.freeDescription)
                .font(.caption)
                .foregroundColor(feature.isAvailableForFree ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .frame(width: 80)
            
            // 专业版描述
            Text(feature.proDescription)
                .font(.caption)
                .fontWeight(feature.proDescription.hasPrefix("✅") ? .semibold : .regular)
                .foregroundColor(feature.isAvailableForPro ? .purple : .secondary)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Preview
struct FeatureComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            FeatureComparisonView()
                .padding()
        }
    }
}

