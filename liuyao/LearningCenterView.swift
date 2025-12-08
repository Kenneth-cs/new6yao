//
//  LearningCenterView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  学习中心 - Tab 1
//

import SwiftUI

struct LearningCenterView: View {
    @State private var selectedCategory: ArticleCategory? = nil
    @State private var searchText = ""
    @State private var showSearch = false
    
    private let dataSource = ArticleDataSource.shared
    
    private var filteredArticles: [Article] {
        var articles = dataSource.allArticles
        
        // 按分类筛选
        if let category = selectedCategory {
            articles = articles.filter { $0.category == category }
        }
        
        // 搜索筛选
        if !searchText.isEmpty {
            articles = articles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.subtitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return articles
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部横幅
                headerBanner
                
                // 分类选择
                categorySelector
                
                // 搜索栏
                if showSearch {
                    searchBar
                }
                
                // 文章列表
                articlesSection
            }
            .padding()
        }
        .navigationTitle("学习中心")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        showSearch.toggle()
                    }
                }) {
                    Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var headerBanner: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("传统智慧 × 现代方法")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("学习决策智慧，提升思维能力")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "book.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.purple.opacity(0.6))
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            
            // 统计信息
            HStack(spacing: 20) {
                StatItem(icon: "doc.text.fill", value: "\(dataSource.allArticles.count)", label: "篇文章")
                StatItem(icon: "folder.fill", value: "\(ArticleCategory.allCases.count)", label: "个分类")
                StatItem(icon: "clock.fill", value: "5-8", label: "分钟/篇")
            }
        }
    }
    
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择分类")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // "全部"选项
                    CategoryChip(
                        title: "全部",
                        icon: "square.grid.2x2",
                        color: .gray,
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    // 分类选项
                    ForEach(ArticleCategory.allCases) { category in
                        CategoryChip(
                            title: category.rawValue,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索文章...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let category = selectedCategory {
                Text(category.rawValue)
                    .font(.headline)
            } else if !searchText.isEmpty {
                Text("搜索结果 (\(filteredArticles.count))")
                    .font(.headline)
            } else {
                Text("所有文章")
                    .font(.headline)
            }
            
            if filteredArticles.isEmpty {
                EmptyArticlesView(searchText: searchText)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredArticles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            ArticleCard(article: article)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// MARK: - StatItem Component

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - CategoryChip Component

struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

// MARK: - ArticleCard Component

struct ArticleCard: View {
    let article: Article
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            VStack {
                Image(systemName: article.category.icon)
                    .font(.title2)
                    .foregroundColor(article.category.color)
                    .frame(width: 60, height: 60)
                    .background(article.category.color.opacity(0.1))
                    .cornerRadius(12)
                
                Spacer()
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 8) {
                // 分类标签
                Text(article.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(article.category.color)
                
                // 标题
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // 副标题
                Text(article.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 元信息
                HStack(spacing: 12) {
                    Label(article.formattedReadTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 右侧箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - EmptyArticlesView Component

struct EmptyArticlesView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty ? "暂无文章" : "未找到相关文章")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Text("试试其他关键词")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    NavigationStack {
        LearningCenterView()
    }
}
