//
//  DecisionAnalysisView.swift
//  liuyao
//
//  Created by zhangshaocong6 on 2025/11/24.
//  决策分析 - Tab 3（原问卦功能）
//

import SwiftUI
import CoreLocation
import UIKit
import CoreData

struct DecisionAnalysisView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var currentTime = Date()
    @StateObject private var locationManager = LocationManager()
    @State private var showMethodology = false
    @State private var displayedQuestions: [CommonQuestion] = []
    
    // 最近推演记录
    @State private var recentRecords: [DivinationRecord] = []
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        return formatter
    }()
    
    private let historyTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    // iPad适配
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    var body: some View {
        ZStack {
            // 背景渐变（支持深色模式）
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.15),
                    Color.indigo.opacity(0.1),
                    Color(.systemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: isIPad ? 40 : 16) {
                    // 标题区域
                    headerSection
                    
                    // 中央决策分析区域（原问卦区域）
                    analysisSection
                    
                    // 快捷场景（原示例问题）
                    quickScenariosSection
                    
                    // 最近的推演
                    recentHistorySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 0)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 左上角：定位信息
            ToolbarItem(placement: .navigationBarLeading) {
                locationToolbarItem
            }
            
            // 右上角：方法论图标
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showMethodology = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.purple)
                }
            }
        }
        .sheet(isPresented: $showMethodology) {
            MethodologyView()
        }
        .onAppear {
            // 首次启动或缓存无效时才定位
            locationManager.requestLocation()
            if displayedQuestions.isEmpty {
                displayedQuestions = Array(commonQuestions.shuffled().prefix(4))
            }
            fetchRecentRecords()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private func fetchRecentRecords() {
        let request: NSFetchRequest<DivinationRecord> = DivinationRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DivinationRecord.createdAt, ascending: false)]
        request.fetchLimit = 3 // 取最近3条历史记录
        
        do {
            recentRecords = try viewContext.fetch(request)
        } catch {
            print("获取最近推演记录失败: \(error)")
        }
    }
    
    // MARK: - 左上角定位信息
    
    private var locationToolbarItem: some View {
        Button(action: {
            // 点击强制刷新定位
            locationManager.forceRefreshLocation()
        }) {
            HStack(spacing: 4) {
                // 图标（根据状态显示不同图标）
                if locationManager.isLocating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.purple)
                } else if locationManager.locationError != nil {
                    Image(systemName: "location.slash.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                } else {
                    Image(systemName: "location.fill")
                        .foregroundColor(.purple)
                        .font(.caption)
                }
                
                Text(locationManager.currentCity)
                    .font(.caption)
                    .foregroundColor(locationManager.locationError != nil ? .orange : .purple)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - 子视图
    
    private var headerSection: some View {
        VStack(spacing: isIPad ? 24 : 10) {
            Text("人生教练")
                .font(isIPad ? .system(size: 48, weight: .bold) : .largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .indigo]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("基于六爻框架的AI分析")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            // 时间信息
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.purple.opacity(0.7))
                        .font(.caption)
                    Text("起卦时辰")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    Text("(时间节点影响卦象解读)")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                        .italic()
                }
                
                Text(timeFormatter.string(from: currentTime))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.purple.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                            )
                    )
            }
            
            Text("看见自己、理解当下、顺势而为")
                .font(.title3)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
    
    private var analysisSection: some View {
        VStack(spacing: 16) {
            NavigationLink(destination: DivinationPageView(
                currentTime: currentTime,
                locationManager: locationManager
            )) {
                VStack(spacing: 16) {
                    // 分析图标（改用紫色系，淡化铜钱概念）
                    ZStack {
                        // 外圈光晕
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.3),
                                        Color.indigo.opacity(0.1)
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        // 主图标
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.purple.opacity(0.9),
                                            Color.indigo.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: isIPad ? 110 : 80, height: isIPad ? 110 : 80)
                                .shadow(color: .purple.opacity(0.4), radius: 8, x: 2, y: 4)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: isIPad ? 40 : 32))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text("遇事不决 摇一摇")
                        .font(isIPad ? .title : .title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("基于六爻框架 × AI智能分析")
                        .font(isIPad ? .body : .caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, isIPad ? 40 : 22)
                .padding(.horizontal, isIPad ? 60 : 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .purple.opacity(0.2), radius: 15, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple.opacity(0.3), .indigo.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var quickScenariosSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("大家常问")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        displayedQuestions = Array(commonQuestions.shuffled().prefix(4))
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("换一批")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(displayedQuestions) { question in
                    NavigationLink(destination: DivinationPageView(
                        currentTime: currentTime,
                        locationManager: locationManager,
                        defaultQuestion: question.text,
                        categoryHint: question.category
                    )) {
                        HStack(alignment: .center, spacing: 6) {
                            // 带有兜底逻辑的图标展示
                            if UIImage(systemName: question.iconName) != nil {
                                Image(systemName: question.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(.purple)
                                    .frame(width: 20)
                            } else {
                                Image(systemName: "sparkles") // 兜底图标
                                    .font(.system(size: 16))
                                    .foregroundColor(.purple)
                                    .frame(width: 20)
                            }
                            
                            Text(question.text)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary.opacity(0.85))
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .purple.opacity(0.06), radius: 5, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - 最近的推演
    
    private var recentHistorySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("最近的推演")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink(destination: HistoryPageView()) {
                    HStack(spacing: 2) {
                        Text("查看全部")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.subheadline)
                    .foregroundColor(.purple)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
            
            if recentRecords.isEmpty {
                // 如果没有记录可以显示暂无
                Text("暂无推演记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .purple.opacity(0.06), radius: 5, x: 0, y: 2)
                    )
            } else {
                VStack(spacing: 10) {
                    ForEach(recentRecords) { record in
                        NavigationLink(destination: HistoryDetailView(record: record)) {
                            HStack(spacing: 12) {
                                // 左侧卦象Icon
                                Image("tab-hexagram")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.purple)
                                    .padding(8)
                                    .background(Color.purple.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                // 右侧文字
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(record.question ?? "无标题")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 4) {
                                        if let date = record.createdAt {
                                            Text(historyTimeFormatter.string(from: date))
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                        Text("·")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                        Text("分析已完成")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(.systemGray4))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .purple.opacity(0.06), radius: 5, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DecisionAnalysisView()
    }
}

// MARK: - Common Questions Data

struct CommonQuestion: Identifiable {
    let id = UUID()
    let category: String
    let iconName: String
    let text: String
}

let commonQuestions: [CommonQuestion] = [
    CommonQuestion(category: "职业", iconName: "briefcase.fill", text: "我现在适合换工作吗？"),
    CommonQuestion(category: "职业", iconName: "briefcase.fill", text: "留在现在的公司还有发展空间吗？"),
    CommonQuestion(category: "职业", iconName: "briefcase.fill", text: "我该争取晋升，还是考虑跳槽？"),
    CommonQuestion(category: "职业", iconName: "briefcase.fill", text: "这份新 Offer 值得接受吗？"),
    CommonQuestion(category: "职业", iconName: "briefcase.fill", text: "我现在适合转行吗？"),
    CommonQuestion(category: "职业", iconName: "briefcase.fill", text: "我现在适合裸辞吗？"),
    CommonQuestion(category: "职业", iconName: "briefcase.fill", text: "未来半年我的职业重点应该放在哪里？"),
    CommonQuestion(category: "职业", iconName: "briefcase.fill", text: "我该继续打工，还是尝试创业？"),
    CommonQuestion(category: "职业", iconName: "briefcase.fill", text: "我目前最大的职业瓶颈是什么？"),
    CommonQuestion(category: "职业", iconName: "briefcase.fill", text: "我该继续深耕主业，还是发展副业？"),
    CommonQuestion(category: "感情", iconName: "heart.fill", text: "这段感情还值得继续吗？"),
    CommonQuestion(category: "感情", iconName: "heart.fill", text: "我们之间还有进一步发展的可能吗？"),
    CommonQuestion(category: "感情", iconName: "heart.fill", text: "我现在适合主动联系对方吗？"),
    CommonQuestion(category: "感情", iconName: "heart.fill", text: "这段关系的问题到底出在哪里？"),
    CommonQuestion(category: "感情", iconName: "heart.fill", text: "我们现在更适合继续磨合，还是分开？"),
    CommonQuestion(category: "感情", iconName: "heart.fill", text: "我应该接受这段关系的现状吗？"),
    CommonQuestion(category: "感情", iconName: "heart.fill", text: "对这段感情，我还应该继续投入吗？"),
    CommonQuestion(category: "感情", iconName: "heart.fill", text: "我们之间还有重新开始的机会吗？"),
    CommonQuestion(category: "感情", iconName: "heart.fill", text: "我该主动推进这段关系吗？"),
    CommonQuestion(category: "感情", iconName: "heart.fill", text: "我现在应该等待，还是做出改变？"),
    CommonQuestion(category: "学习", iconName: "book.fill", text: "我应该继续读研吗？"),
    CommonQuestion(category: "学习", iconName: "book.fill", text: "我现在适合考研还是先工作？"),
    CommonQuestion(category: "学习", iconName: "book.fill", text: "我应该坚持现在的专业方向吗？"),
    CommonQuestion(category: "学习", iconName: "book.fill", text: "我现在适合出国读书吗？"),
    CommonQuestion(category: "学习", iconName: "book.fill", text: "我该继续备考，还是换一个方向？"),
    CommonQuestion(category: "学习", iconName: "book.fill", text: "我现在最应该提升哪方面的能力？"),
    CommonQuestion(category: "学习", iconName: "book.fill", text: "我应该把时间投入专业能力还是副业技能？"),
    CommonQuestion(category: "学习", iconName: "book.fill", text: "这次考试我应该继续冲一把吗？"),
    CommonQuestion(category: "成长", iconName: "leaf.fill", text: "我现在最需要解决的问题是什么？"),
    CommonQuestion(category: "成长", iconName: "leaf.fill", text: "我最近为什么总感觉找不到方向？"),
    CommonQuestion(category: "创业", iconName: "paperplane.fill", text: "我现在适合开始创业吗？"),
    CommonQuestion(category: "创业", iconName: "paperplane.fill", text: "这个项目值得我继续投入吗？"),
    CommonQuestion(category: "创业", iconName: "paperplane.fill", text: "我应该继续坚持这个项目，还是及时止损？"),
    CommonQuestion(category: "创业", iconName: "paperplane.fill", text: "现在是扩大投入的好时机吗？"),
    CommonQuestion(category: "创业", iconName: "paperplane.fill", text: "我该独立做，还是找合伙人一起做？"),
    CommonQuestion(category: "创业", iconName: "paperplane.fill", text: "这个副业值得我长期发展吗？"),
    CommonQuestion(category: "创业", iconName: "paperplane.fill", text: "我现在应该先赚钱，还是继续打磨产品？"),
    CommonQuestion(category: "创业", iconName: "paperplane.fill", text: "这个合作机会值得接受吗？"),
    CommonQuestion(category: "财富", iconName: "dollarsign.circle.fill", text: "我现在适合做一笔较大的投资吗？"),
    CommonQuestion(category: "财富", iconName: "dollarsign.circle.fill", text: "我现在应该更积极赚钱，还是先控制支出？"),
    CommonQuestion(category: "财富", iconName: "dollarsign.circle.fill", text: "这笔大额消费现在值得做吗？"),
    CommonQuestion(category: "财富", iconName: "dollarsign.circle.fill", text: "我该把更多精力放在主业收入还是副业收入？"),
    CommonQuestion(category: "财富", iconName: "dollarsign.circle.fill", text: "我现在适合买房吗？"),
    CommonQuestion(category: "财富", iconName: "dollarsign.circle.fill", text: "我现在适合扩大自己的事业投入吗？"),
    CommonQuestion(category: "人生选择", iconName: "safari.fill", text: "我应该留在现在的城市，还是去新的地方发展？"),
    CommonQuestion(category: "人生选择", iconName: "safari.fill", text: "现在这个机会我应该抓住吗？"),
    CommonQuestion(category: "人生选择", iconName: "safari.fill", text: "面对两个选择，我应该更看重稳定还是成长？"),
    CommonQuestion(category: "人生选择", iconName: "safari.fill", text: "我现在适合主动改变现状吗？"),
    CommonQuestion(category: "人生选择", iconName: "safari.fill", text: "这件事我应该继续推进，还是先等等？"),
    CommonQuestion(category: "人生选择", iconName: "safari.fill", text: "未来三个月，我最应该把精力放在哪里？")
]

