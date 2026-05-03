//
//  ArticleDetailView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  文章详情视图
//

import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    @State private var showRelated = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 文章头部
                headerSection
                
                // 文章内容
                contentSection
                
                // 关键要点
                keyPointsSection
                
                // 行动建议
                actionItemsSection
                
                // 相关文章
                if !article.relatedArticles.isEmpty {
                    relatedArticlesSection
                }
            }
            .padding()
        }
        .navigationTitle("文章详情")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AnalyticsManager.shared.trackLearningViewArticle(articleId: "\(article.id)")
        }
        // 分享功能暂时隐藏
        // .toolbar {
        //     ToolbarItem(placement: .navigationBarTrailing) {
        //         ShareLink(item: article.title) {
        //             Image(systemName: "square.and.arrow.up")
        //         }
        //     }
        // }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 分类标签
            HStack {
                Image(systemName: article.category.icon)
                    .font(.caption)
                Text(article.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(article.category.color)
            .cornerRadius(12)
            
            // 标题
            Text(article.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // 副标题
            Text(article.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 元信息
            HStack(spacing: 16) {
                Label(article.formattedReadTime, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(formatDate(article.publishDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FormattedTextView(segments: formatAIText(article.content))
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var keyPointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("关键要点")
                    .font(.headline)
            }
            
            ForEach(Array(article.keyPoints.enumerated()), id: \.offset) { index, point in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(article.category.color)
                        .clipShape(Circle())
                    
                    Text(point)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("行动建议")
                    .font(.headline)
            }
            
            ForEach(article.actionItems, id: \.self) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.green)
                    
                    Text(item)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var relatedArticlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(.blue)
                Text("相关阅读")
                    .font(.headline)
            }
            
            ForEach(article.relatedArticles.compactMap { ArticleDataSource.shared.article(by: $0) }) { relatedArticle in
                NavigationLink(destination: ArticleDetailView(article: relatedArticle)) {
                    RelatedArticleCard(article: relatedArticle)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - RelatedArticleCard

struct RelatedArticleCard: View {
    let article: Article
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: article.category.icon)
                .font(.title2)
                .foregroundColor(article.category.color)
                .frame(width: 50, height: 50)
                .background(article.category.color.opacity(0.1))
                .cornerRadius(10)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(article.formattedReadTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: ArticleDataSource.shared.allArticles[0])
    }
}

