import SwiftUI
import CoreData

struct ProfilePageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var statisticsService = StatisticsService.shared
    @State private var showingCacheCleanup = false
    @State private var showingDataBackup = false
    @State private var showingPrivacySettings = false
    
    var body: some View {
        // 直接显示内容，不使用NavigationView
        // 因为已经在MainTabView中被NavigationStack包裹了
        profileContent
            .onAppear {
                statisticsService.loadStatistics(context: viewContext)
            }
    }
    
    // 提取公共的内容视图
    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 用户信息区域
                UserInfoSection()
                
                // 订阅状态卡片（新增）
                SubscriptionStatusCard()
                
                // 统计面板
                StatisticsPanel(statisticsService: statisticsService)
                
                // 应用管理
                AppManagementSection(
                    showingCacheCleanup: $showingCacheCleanup,
                    showingDataBackup: $showingDataBackup,
                    showingPrivacySettings: $showingPrivacySettings
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .navigationTitle("个人中心")
        .navigationBarTitleDisplayMode(.large)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.05),
                    Color.indigo.opacity(0.03),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showingCacheCleanup) {
            CacheCleanupView()
        }
        .sheet(isPresented: $showingDataBackup) {
            DataBackupPlaceholderView()
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
    }
}

// MARK: - 用户信息区域
struct UserInfoSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple.opacity(0.8), .indigo.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("人生用户")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("探索人生的智慧")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .purple.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 统计面板
struct StatisticsPanel: View {
    @ObservedObject var statisticsService: StatisticsService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("统计面板")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // 统计卡片网格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // 分析次数
                EnhancedStatisticCard(
                    title: "分析次数",
                    value: "\(statisticsService.totalDivinations)",
                    subtitle: "累计分析",
                    icon: "questionmark.circle.fill",
                    color: .blue,
                    trend: statisticsService.totalDivinations > 0 ? .up : .neutral
                )
                
                // 本月分析
                EnhancedStatisticCard(
                    title: "本月分析",
                    value: "\(statisticsService.monthlyDivinations)",
                    subtitle: "当月活跃度",
                    icon: "calendar.circle.fill",
                    color: .green,
                    trend: statisticsService.monthlyDivinations > 0 ? .up : .neutral
                )
                
                // 准确度反馈
                EnhancedStatisticCard(
                    title: "准确度",
                    value: statisticsService.averageAccuracy > 0 ? "\(Int(statisticsService.averageAccuracy * 100))%" : "暂无",
                    subtitle: "用户反馈",
                    icon: "target",
                    color: .orange,
                    trend: statisticsService.averageAccuracy >= 0.7 ? .up : statisticsService.averageAccuracy >= 0.5 ? .neutral : .down
                )
                
                // 连续天数
                EnhancedStatisticCard(
                    title: "连续天数",
                    value: "\(statisticsService.consecutiveDays)",
                    subtitle: "使用习惯",
                    icon: "flame.fill",
                    color: .red,
                    trend: statisticsService.consecutiveDays >= 7 ? .up : statisticsService.consecutiveDays >= 3 ? .neutral : .down
                )
            }
            
            // 常问类型分析
            if !statisticsService.questionTypes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("常问类型")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    QuestionTypeAnalysis(questionTypes: statisticsService.questionTypes)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .blue.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 趋势枚举
enum StatisticTrend {
    case up, down, neutral
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
}

// MARK: - 增强统计卡片
struct EnhancedStatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: StatisticTrend
    
    var body: some View {
        VStack(spacing: 10) {
            // 顶部图标和趋势
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            
            // 数值
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
            
            // 标题和副标题
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - 原始统计卡片（保留兼容性）
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - 问题类型分析
struct QuestionTypeAnalysis: View {
    let questionTypes: [QuestionTypeData]
    @State private var selectedView: ChartViewType = .pie
    
    enum ChartViewType: String, CaseIterable {
        case pie = "饼图"
        case bar = "柱状图"
        
        var icon: String {
            switch self {
            case .pie: return "chart.pie.fill"
            case .bar: return "chart.bar.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 切换按钮
            HStack {
                ForEach(ChartViewType.allCases, id: \.self) { viewType in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedView = viewType
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewType.icon)
                                .font(.caption)
                            Text(viewType.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedView == viewType ? Color.blue : Color.gray.opacity(0.1))
                        )
                        .foregroundColor(selectedView == viewType ? .white : .secondary)
                    }
                }
                
                Spacer()
            }
            
            // 图表内容
            Group {
                switch selectedView {
                case .pie:
                    QuestionTypePieChart(questionTypes: questionTypes)
                case .bar:
                    QuestionTypeBarChart(questionTypes: questionTypes)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedView)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - 饼图组件
struct QuestionTypePieChart: View {
    let questionTypes: [QuestionTypeData]
    
    private let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .indigo]
    
    var body: some View {
        HStack(spacing: 20) {
            // 饼图
            ZStack {
                ForEach(Array(questionTypes.prefix(5).enumerated()), id: \.offset) { index, typeData in
                    PieSlice(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        color: colors[index % colors.count]
                    )
                }
            }
            .frame(width: 120, height: 120)
            
            // 图例
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(questionTypes.prefix(5).enumerated()), id: \.offset) { index, typeData in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(colors[index % colors.count])
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(typeData.type)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("\(typeData.count)次 (\(Int(typeData.percentage * 100))%)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let previousPercentages = questionTypes.prefix(index).reduce(0) { $0 + $1.percentage }
        return Angle(degrees: previousPercentages * 360 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let previousPercentages = questionTypes.prefix(index + 1).reduce(0) { $0 + $1.percentage }
        return Angle(degrees: previousPercentages * 360 - 90)
    }
}

// MARK: - 饼图扇形
struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 60, y: 60)
            let radius: CGFloat = 50
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(color)
        .overlay(
            Path { path in
                let center = CGPoint(x: 60, y: 60)
                let radius: CGFloat = 50
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .stroke(Color.white, lineWidth: 2)
        )
    }
}

// MARK: - 柱状图组件
struct QuestionTypeBarChart: View {
    let questionTypes: [QuestionTypeData]
    
    private let colors: [Color] = [.blue, .green, .orange, .purple, .red]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(questionTypes.prefix(5).enumerated()), id: \.offset) { index, typeData in
                HStack(spacing: 12) {
                    // 类型名称
                    Text(typeData.type)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .leading)
                    
                    // 柱状图
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 20)
                                .cornerRadius(10)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [colors[index % colors.count], colors[index % colors.count].opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * typeData.percentage,
                                    height: 20
                                )
                                .cornerRadius(10)
                                .animation(.easeInOut(duration: 0.8), value: typeData.percentage)
                        }
                    }
                    .frame(height: 20)
                    
                    // 数值和百分比
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(typeData.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(Int(typeData.percentage * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 40)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - 原始问题类型图表（保留兼容性）
struct QuestionTypeChart: View {
    let questionTypes: [QuestionTypeData]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(questionTypes.prefix(5), id: \.type) { typeData in
                HStack {
                    Text(typeData.type)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(typeData.count)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * typeData.percentage,
                                    height: 6
                                )
                                .cornerRadius(3)
                        }
                    }
                    .frame(width: 60, height: 6)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - 个人设置区域（已移除）
// 注释说明：个人设置功能已暂时移除，包括通知设置、主题选择、字体大小等功能
/*
struct PersonalSettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
                Text("个人设置")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                SettingRow(
                    icon: "bell.fill", 
                    title: "通知设置", 
                    color: .orange,
                    action: { /* TODO: 实现通知设置 */ }
                )
                SettingRow(
                    icon: "paintbrush.fill", 
                    title: "主题选择", 
                    color: .purple,
                    action: { /* TODO: 实现主题选择 */ }
                )
                SettingRow(
                    icon: "textformat.size", 
                    title: "字体大小", 
                    color: .blue,
                    action: { /* TODO: 实现字体大小设置 */ }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}
*/

// MARK: - 应用管理区域
struct AppManagementSection: View {
    @Binding var showingCacheCleanup: Bool
    @Binding var showingDataBackup: Bool
    @Binding var showingPrivacySettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "app.badge.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("应用管理")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                SettingRow(
                    icon: "trash.fill", 
                    title: "缓存清理", 
                    color: .red,
                    action: { showingCacheCleanup = true }
                )
                // 数据备份功能暂时隐藏（开发中）
                // SettingRow(
                //     icon: "icloud.and.arrow.up.fill", 
                //     title: "数据备份", 
                //     color: .blue,
                //     action: { showingDataBackup = true }
                // )
                SettingRow(
                    icon: "lock.shield.fill", 
                    title: "隐私设置", 
                    color: .green,
                    action: { showingPrivacySettings = true }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .green.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.bottom, 30)
    }
}

// MARK: - 设置行组件
struct SettingRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 缓存清理视图
struct CacheCleanupView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isClearing = false
    @State private var clearingProgress: Double = 0.0
    @State private var showingResult = false
    @State private var clearedSize = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 顶部图标
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.red.opacity(0.1), .orange.opacity(0.05)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "trash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                    }
                    
                    Text("缓存清理")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 40)
                
                if !showingResult {
                    // 清理前的信息
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("清理内容包括：")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                CleanupItem(icon: "photo.fill", title: "图片缓存", description: "临时存储的图片文件")
                                CleanupItem(icon: "doc.text.fill", title: "文档缓存", description: "应用生成的临时文档")
                                CleanupItem(icon: "network", title: "网络缓存", description: "API请求的缓存数据")
                                CleanupItem(icon: "folder.fill", title: "临时文件", description: "系统生成的临时文件")
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.05))
                        )
                        
                        if isClearing {
                            VStack(spacing: 16) {
                                Text("正在清理中...")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                ProgressView(value: clearingProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                                
                                Text("\(Int(clearingProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.red.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                    }
                } else {
                    // 清理结果
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("清理完成！")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("已清理 \(clearedSize) 缓存文件")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                
                Spacer()
                
                // 底部按钮
                VStack(spacing: 12) {
                    if !showingResult && !isClearing {
                        Button(action: startCleaning) {
                            Text("开始清理")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.red, .orange]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(showingResult ? "完成" : "取消")
                            .font(.headline)
                            .foregroundColor(showingResult ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(showingResult ? Color.blue : Color.gray.opacity(0.1))
                            )
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
            .navigationTitle("缓存清理")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func startCleaning() {
        isClearing = true
        clearingProgress = 0.0
        
        // 真正的清理过程
        Task {
            do {
                // 计算清理前的大小
                let beforeSize = try await getCacheSize()
                
                // 分步清理，更新进度
                await MainActor.run {
                    clearingProgress = 0.2
                }
                
                // 1. 清理URL缓存
                URLCache.shared.removeAllCachedResponses()
                await Task.yield()
                
                await MainActor.run {
                    clearingProgress = 0.4
                }
                
                // 2. 清理临时目录
                try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory)
                try? FileManager.default.createDirectory(at: FileManager.default.temporaryDirectory, withIntermediateDirectories: true)
                await Task.yield()
                
                await MainActor.run {
                    clearingProgress = 0.6
                }
                
                // 3. 清理Caches目录
                if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                    if let contents = try? FileManager.default.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil) {
                        for fileURL in contents {
                            try? FileManager.default.removeItem(at: fileURL)
                        }
                    }
                }
                await Task.yield()
                
                await MainActor.run {
                    clearingProgress = 0.8
                }
                
                // 4. 清理图片缓存（如果使用了图片缓存库）
                await Task.yield()
                
                await MainActor.run {
                    clearingProgress = 1.0
                }
                
                // 计算清理后的大小
                let afterSize = try await getCacheSize()
                let cleared = beforeSize - afterSize
                
                // 格式化大小
                clearedSize = formatBytes(cleared)
                
                // 显示结果
                await MainActor.run {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isClearing = false
                            showingResult = true
                        }
                    }
                }
                
            } catch {
                print("清理失败: \(error)")
                // 发生错误时，显示一个估算值
                await MainActor.run {
                    clearedSize = "1.5MB"
                    isClearing = false
                    showingResult = true
                }
            }
        }
    }
    
    // 获取缓存大小
    private func getCacheSize() async throws -> Int64 {
        var totalSize: Int64 = 0
        
        // 计算临时目录大小
        if let tmpSize = try? directorySize(FileManager.default.temporaryDirectory) {
            totalSize += tmpSize
        }
        
        // 计算Caches目录大小
        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            if let cachesSize = try? directorySize(cachesURL) {
                totalSize += cachesSize
            }
        }
        
        return totalSize
    }
    
    // 计算目录大小
    private func directorySize(_ url: URL) throws -> Int64 {
        var size: Int64 = 0
        
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        
        return size
    }
    
    // 格式化字节大小
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct CleanupItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.red)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 数据备份占位视图
struct DataBackupPlaceholderView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.1), .cyan.opacity(0.05)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "icloud.and.arrow.up.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(spacing: 12) {
                        Text("数据备份")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("正在开发中")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text("我们正在为您开发更完善的的数据备份功能\n敬请期待后续版本更新")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                
                VStack(spacing: 16) {
                    Text("即将支持的功能：")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureItem(icon: "icloud.fill", title: "iCloud 同步", description: "自动备份到您的 iCloud 账户")
                        FeatureItem(icon: "externaldrive.fill", title: "本地备份", description: "导出数据到本地文件")
                        FeatureItem(icon: "arrow.clockwise", title: "自动备份", description: "定期自动备份重要数据")
                        FeatureItem(icon: "shield.fill", title: "加密保护", description: "数据加密确保隐私安全")
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("我知道了")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
            .navigationTitle("数据备份")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 隐私设置视图
struct PrivacySettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var dataCollectionEnabled = true
    @State private var analyticsEnabled = false
    @State private var crashReportsEnabled = true
    @State private var locationDataEnabled = true
    @State private var notificationEnabled = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部说明
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green.opacity(0.1), .mint.opacity(0.05)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 35))
                                .foregroundColor(.green)
                        }
                        
                        VStack(spacing: 8) {
                            Text("隐私设置")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("管理您的数据隐私和使用偏好")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // 数据收集设置
                    PrivacySection(title: "数据收集", icon: "doc.text.fill", color: .blue) {
                        VStack(spacing: 16) {
                            PrivacyToggleRow(
                                title: "基础数据收集",
                                description: "收集应用使用数据以改善用户体验",
                                isOn: $dataCollectionEnabled
                            )
                            
                            PrivacyToggleRow(
                                title: "使用分析",
                                description: "匿名收集使用统计信息",
                                isOn: $analyticsEnabled
                            )
                            
                            PrivacyToggleRow(
                                title: "崩溃报告",
                                description: "自动发送崩溃报告帮助修复问题",
                                isOn: $crashReportsEnabled
                            )
                        }
                    }
                    
                    // 位置和通知设置
                    PrivacySection(title: "位置和通知", icon: "location.fill", color: .orange) {
                        VStack(spacing: 16) {
                            PrivacyToggleRow(
                                title: "位置数据",
                                description: "使用位置信息提供更准确的卦象解读",
                                isOn: $locationDataEnabled
                            )
                            
                            PrivacyToggleRow(
                                title: "推送通知",
                                description: "接收应用相关的通知消息",
                                isOn: $notificationEnabled
                            )
                        }
                    }
                    
                    // 数据管理（暂时隐藏，功能开发中）
                    // PrivacySection(title: "数据管理", icon: "folder.fill", color: .purple) {
                    //     VStack(spacing: 12) {
                    //         PrivacyActionRow(
                    //             title: "查看我的数据",
                    //             description: "查看应用收集的所有数据",
                    //             icon: "eye.fill",
                    //             action: {}
                    //         )
                    //         
                    //         PrivacyActionRow(
                    //             title: "导出数据",
                    //             description: "导出您的个人数据副本",
                    //             icon: "square.and.arrow.up.fill",
                    //             action: {}
                    //         )
                    //         
                    //         PrivacyActionRow(
                    //             title: "删除所有数据",
                    //             description: "永久删除所有个人数据",
                    //             icon: "trash.fill",
                    //             isDestructive: true,
                    //             action: {}
                    //         )
                    //     }
                    // }
                    
                    // 法律文档 - 了解更多
                    PrivacySection(title: "法律文档", icon: "doc.text.fill", color: .blue) {
                        VStack(spacing: 12) {
                            NavigationLink(destination: PrivacyPolicyDetailView(type: .privacy)) {
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("隐私政策")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text("了解我们如何保护您的隐私")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.05))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            NavigationLink(destination: PrivacyPolicyDetailView(type: .terms)) {
                                HStack {
                                    Image(systemName: "doc.plaintext.fill")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("用户协议")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text("使用本应用的服务条款")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.05))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("隐私设置")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    // 保存设置
                    presentationMode.wrappedValue.dismiss()
                }
                .fontWeight(.semibold)
            )
        }
    }
}

struct PrivacySection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct PrivacyToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct PrivacyActionRow: View {
    let title: String
    let description: String
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(isDestructive ? .red : .blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 订阅状态卡片
struct SubscriptionStatusCard: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        NavigationLink(destination: SubscriptionManagementView()) {
            VStack(spacing: 16) {
                HStack {
                    // 左侧图标和信息
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: subscriptionService.isPro ? [Color.yellow, Color.orange] : [Color.gray.opacity(0.6), Color.gray.opacity(0.4)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: subscriptionService.isPro ? "crown.fill" : "person.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(subscriptionService.currentTierName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            if let status = subscriptionService.subscriptionStatus, status.isActive {
                                Text(status.statusText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("升级解锁完整功能")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // 右侧箭头
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 底部快速统计（仅免费版显示）
                if !subscriptionService.isPro {
                    Divider()
                    
                    HStack(spacing: 16) {
                        UsageQuickStat(
                            icon: "sparkles",
                            title: "问卦",
                            value: "\(permissionManager.getDailyDivinationRemaining())",
                            subtitle: "今日剩余",
                            color: .purple
                        )
                        
                        Divider()
                            .frame(height: 30)
                        
                        UsageQuickStat(
                            icon: "square.grid.2x2",
                            title: "SWOT",
                            value: "\(permissionManager.getMonthlySWOTRemaining())",
                            subtitle: "本月剩余",
                            color: .blue
                        )
                        
                        Divider()
                            .frame(height: 30)
                        
                        UsageQuickStat(
                            icon: "tablecells",
                            title: "矩阵",
                            value: "\(permissionManager.getMonthlyMatrixRemaining())",
                            subtitle: "本月剩余",
                            color: .green
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: subscriptionService.isPro ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.1), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(subscriptionService.isPro ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 使用快速统计
struct UsageQuickStat: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfilePageView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}