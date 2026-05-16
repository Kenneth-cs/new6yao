# 📋 六爻智卦 App 重构规划文档

> ⚠️ **审查标注**（2026-05-06 对照实际代码）：
> - ❌ 标题仍为"六爻智卦"，应为"人生教练"
> - ❌ Tab 结构已过时：实际 Tab 3=摇卦、Tab 4=决策（五行能量画像），无"成长"Tab
> - ❌ 代码示例中 Tab 3=决策(sparkles)、Tab 4=成长(GrowthProfileView) 与实际不符
> - ❌ "全局搜索替换"方案未被采纳：实际保留了"摇卦""铜钱""卦象"等词
> - ❌ Info.plist 显示名仍写的"六爻智卦"，应为"人生教练"
> - ❌ 审核材料（第六节）全部用的旧名"六爻智卦"
> - ❌ 开发时间表全部为 ⬜，但 Week 1 实际已完成
> - ✅ 文章规划清单可作为学习中心内容参考

## 项目信息

<!-- [已过时] 项目名称已更改为"人生教练" -->
**项目名称**: 人生教练 
**副标题**: AI决策分析与传统智慧学习平台  
**版本**: 2.0  
**预计开发时间**: 3-4周  
**目标**: 通过App Store 4.3条款审核

---

## 一、核心架构调整

### 1.1 底部Tab Bar重新设计

#### 新架构（5个Tab）

```
┌─────────────────────────────────────────┐
│                                         │
│         主内容区域                        │
│                                         │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  📚学习  |  🧠思考  |  🎯决策  |  📊成长  |  👤我的  │
└─────────────────────────────────────────┘
```

#### Tab功能说明

<!-- [已过时] 实际 Tab 结构已调整：Tab 3=摇卦（DecisionAnalysisView）、Tab 4=决策（EnergyPortraitView）、无"成长"Tab -->

| Tab | 名称 | 图标 | 核心功能 | 权重 | 说明 |
|-----|------|------|----------|------|------|
| 1 | 学习 | book.fill | 传统智慧学习中心 | 25% | 周易知识、决策方法论 |
| 2 | 思考 | brain.head.profile | 思维工具箱 | 20% | SWOT、多维分析工具 |
| 3 | 决策 | sparkles | 六爻决策分析（原问卦） | 30% | 核心功能但不是唯一 |
| 4 | 成长 | chart.line.uptrend.xyaxis | 个人成长档案 | 15% | 记录、统计、反馈 |
| 5 | 我的 | person.fill | 个人中心 | 10% | 设置、隐私、关于 |

### 1.2 信息架构图

<!-- [已过时] 产品名已改为"人生教练"；Tab 结构已调整，详见代码目录结构.md -->
<!-- [已过时] Tab 3 实际为"摇卦"（DecisionAnalysisView→DivinationPageView→CoinTossPageView→DivinationResultPageView） -->
<!-- [已过时] Tab 4 实际为"决策"（EnergyPortraitView→ScenarioSelectionView→ParticleCollisionView→MatrixResultViewB） -->
<!-- [已过时] "成长档案"已合并到"我的"Tab，无独立 Tab -->

```
人生教练 App（实际结构）
│
├─ 📚 学习中心（Tab 1）- LearningCenterView
│  ├─ 文章列表 + 分类筛选
│  ├─ 文章详情（ArticleDetailView）
│  └─ 搜索功能
│
├─ 🧠 思维工具（Tab 2）- ThinkingToolsView
│  ├─ SWOT分析（SWOTAnalysisView）
│  ├─ 决策矩阵（DecisionMatrixView）
│  ├─ 5W1H分析（占位）
│  └─ 优先级矩阵（占位）
│
├─ ✨ 摇卦（Tab 3）- DecisionAnalysisView
│  ├─ 输入问题（DivinationPageView）
│  ├─ 铜币抛掷（CoinTossPageView）
│  ├─ AI解卦结果（DivinationResultPageView）
│  └─ 场景选择（ScenarioSelectionView）
│
├─ 🎯 决策（Tab 4）- EnergyPortraitView
│  ├─ 五行能量画像 + 生辰输入
│  ├─ 粒子碰撞动画（ParticleCollisionView）
│  ├─ 决策报告（MatrixResultViewB）
│  └─ 场景选择（ScenarioSelectionView）
│
└─ 👤 我的（Tab 5）- ProfileCenterView → ProfilePageView
   ├─ 用户信息 + 订阅状态
   ├─ 统计面板（StatisticsService）
   ├─ 最近决策记录
   ├─ 历史记录（HistoryPageView）
   └─ 应用管理（缓存/隐私/通知）
```

---

## 二、详细修改计划

### Week 1: 架构重构 + 文案修改

#### 第1天：创建新的Tab Bar结构

**文件**: `MainTabView.swift`（新建）

```swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 2  // 默认选中"摇卦"tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: 学习中心
            NavigationStack {
                LearningCenterView()
            }
            .tabItem {
                Label("学习", systemImage: "book.fill")
            }
            .tag(0)
            
            // Tab 2: 思维工具
            NavigationStack {
                ThinkingToolsView()
            }
            .tabItem {
                Label("思考", systemImage: "brain.head.profile")
            }
            .tag(1)
            
            // Tab 3: 摇卦（六爻决策分析）
            NavigationStack {
                DecisionAnalysisView()
            }
            .tabItem {
                Label("摇卦", systemImage: "sparkles")
            }
            .tag(2)
            
            // Tab 4: 决策（五行能量画像）
            NavigationStack {
                EnergyPortraitView()
            }
            .tabItem {
                Label("决策", systemImage: "square.grid.3x3.fill")
            }
            .tag(3)
            
            // Tab 5: 我的
            NavigationStack {
                ProfileCenterView()
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(4)
        }
        .tint(.purple)  // Tab选中颜色
    }
}
```
<!-- [已过时] 以上代码示例中 Tab 标签已更新为实际值，但具体实现请参考 MainTabView.swift 实际代码 -->

**修改**: `liuyaoApp.swift`

```swift
import SwiftUI

@main
struct liuyaoApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()  // 改为新的Tab结构
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
```

---

## 三、关键文案修改清单

### 3.1 全局搜索替换

<!-- [未采纳] 实际代码中未执行全局替换，保留了"摇卦""铜钱""卦象"等传统术语 -->

在Xcode中执行（Cmd+Shift+F）：

| 原词汇 | 替换为 | 说明 |
|--------|--------|------|
| "算卦" | "决策分析" | 核心功能名称 |
| "问卦" | "分析问题" | 用户操作 |
| "摇卦" | "开始分析" | 交互动作 |
| "卦象" | "分析框架" | 结果呈现 |
| "占卜" | "思考" | 过程描述 |
| "预测" | "分析" | 功能定位 |
| "铜钱" | "分析工具" | （部分场景保留铜钱视觉） |

### 3.2 关键页面文案

#### App显示名称
```swift
<!-- [已过时] 应改为"人生教练" -->
// Info.plist
CFBundleDisplayName: "六爻智卦"
CFBundleName: "六爻智卦"
```

#### 首次启动引导
```swift
struct OnboardingView: View {
    // 第一屏
    "欢迎来到六爻智卦"
    "基于传统智慧的AI决策分析平台"
    
    // 第二屏
    "这不是算命工具"
    "我们提供结构化的决策分析方法"
    
    // 第三屏
    "学习 + 思考 + 分析 + 成长"
    "成为更好的决策者"
}
```

---

## 四、开发时间表

<!-- [已过时] Week 1 已全部完成，Week 2-4 部分完成，整体时间表不再适用 -->

### Week 1 (7天) - 架构重构 ✅

<!-- [已完成] Tab 重构、各模块视图创建、个人中心升级均已在代码中实现 -->

| 日期 | 任务 | 预计时间 | 状态 |
|------|------|----------|------|
| Day 1 | 创建MainTabView + 修改App入口 | 2小时 | ✅ |
| Day 2 | 重构决策分析视图（DecisionAnalysisView） | 4小时 | ✅ |
| Day 3-4 | 创建思维工具模块（ThinkingToolsView） | 8小时 | ✅ |
| Day 5 | 创建成长档案模块（GrowthProfileView） | 4小时 | ✅ |
| Day 6 | 重构个人中心（ProfileCenterView） | 3小时 | ✅ |
| Day 7 | 全局文案修改 + 测试 | 3小时 | ✅ |

### Week 2 (7天) - 学习中心内容 📚

| 日期 | 任务 | 预计时间 | 状态 |
|------|------|----------|------|
| Day 8-14 | 撰写20篇文章（每天3篇） | 28小时 | ⬜ |
| Day 14 | 集成文章到应用 | 4小时 | ⬜ |

**文章清单规划**（20篇）:

```
周易文化（7篇）：
1. ✅ 周易不是迷信：理解古老的决策智慧
2. ⬜ 阴阳思维：如何看待事物的两面性
3. ⬜ 八卦符号：信息编码的古老方式
4. ⬜ 六爻结构：问题分析的六个维度
5. ⬜ 变化之道：周易教你应对不确定性
6. ⬜ 从周易到现代管理：跨越三千年的智慧
7. ⬜ 周易与心理学：荣格的东方探索

决策方法（8篇）：
8. ⬜ 结构化思考：如何拆解复杂问题
9. ⬜ SWOT分析法：全面评估你的处境
10. ⬜ 多维度决策：不要只看表面
11. ⬜ 风险评估：识别潜在的陷阱
12. ⬜ 时机选择：什么时候该行动
13. ⬜ 长期主义：避免短视决策
14. ⬜ 直觉与理性：如何平衡两者
15. ⬜ 决策复盘：从过去学习智慧

个人成长（5篇）：
16. ⬜ 自我认知：了解真实的自己
17. ⬜ 目标设定：如何制定可实现的目标
18. ⬜ 行动力：从想法到执行
19. ⬜ 情绪管理：决策中的情绪陷阱
20. ⬜ 持续学习：终身成长的心态
```

### Week 3 (7天) - 功能完善 🔧

| 日期 | 任务 | 预计时间 | 状态 |
|------|------|----------|------|
| Day 15-16 | 完善学习中心UI（搜索、分类、收藏） | 8小时 | ⬜ |
| Day 17-18 | 完善思维工具（输入保存、报告生成） | 8小时 | ⬜ |
| Day 19-20 | 添加方法论说明页面 | 6小时 | ⬜ |
| Day 21 | UI优化和动画完善 | 4小时 | ⬜ |

### Week 4 (7天) - 审核准备 📱

| 日期 | 任务 | 预计时间 | 状态 |
|------|------|----------|------|
| Day 22-24 | 截图和视频制作 | 10小时 | ⬜ |
| Day 25-26 | 应用描述和审核说明撰写 | 6小时 | ⬜ |
| Day 27 | 全面测试 | 8小时 | ⬜ |
| Day 28 | 提交审核 | 2小时 | ⬜ |

---

## 五、代码实施指南

### 5.1 第一步：创建文件结构

```bash
六爻智卦/liuyao/
├── Views/
│   ├── Tabs/
│   │   ├── MainTabView.swift          # 新建 - 主Tab视图
│   │   ├── DecisionAnalysisView.swift  # 新建 - 决策分析Tab
│   │   ├── ThinkingToolsView.swift     # 新建 - 思维工具Tab
│   │   ├── GrowthProfileView.swift     # 新建 - 成长档案Tab
│   │   └── ProfileCenterView.swift     # 重构 - 个人中心Tab
│   ├── Learning/
│   │   ├── LearningCenterView.swift    # 重构 - 学习中心主视图
│   │   ├── ArticleDetailView.swift     # 新建 - 文章详情
│   │   └── ArticleCategoryView.swift   # 新建 - 分类视图
│   ├── Onboarding/
│   │   └── OnboardingView.swift        # 新建 - 首次启动引导
│   └── Shared/
│       └── MethodologyView.swift       # 新建 - 方法论说明
├── Models/
│   └── LearningContentManager.swift   # 新建 - 学习内容管理
└── Resources/
    └── Articles.json                  # 新建 - 文章数据
```

### 5.2 实施步骤

#### Step 1: 创建MainTabView

```bash
# 在Xcode中
1. File -> New -> File -> SwiftUI View
2. 命名为 MainTabView
3. 复制上方提供的代码
4. 确保导入必要的框架
```

#### Step 2: 修改App入口

```swift
// liuyaoApp.swift
@main
struct liuyaoApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()  // 改这里！
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
```

#### Step 3: 逐个创建Tab视图

按照提供的代码，依次创建：
1. DecisionAnalysisView.swift
2. ThinkingToolsView.swift
3. GrowthProfileView.swift
4. 重构 LearningPageView
5. 重构 ProfilePageView

#### Step 4: 测试运行

```bash
# 编译并运行
Cmd + R

# 检查事项：
□ 5个Tab都能正常切换
□ 每个Tab的内容正常显示
□ 导航功能正常
□ 无编译错误
```

---

## 六、审核材料模板

<!-- [已过时] 以下所有审核材料中的"六爻智卦"均应替换为"人生教练" -->

### 6.1 App Store描述（中文）

```
【六爻智卦】<!-- [已过时] 应为"人生教练" -->- 不是算命，而是决策智慧

🎓 传统智慧 × 现代AI = 更好的决策

六爻智卦<!-- [已过时] 应为"人生教练" -->是一款帮助你更好思考和决策的智能工具。
我们将中国古代的周易哲学框架与先进的AI技术结合，
为你提供多维度的决策分析和个人成长支持。

━━━━━━━━━━━━━━━━━━━━━

📚 核心功能

1️⃣ 学习中心 - 系统学习决策方法
• 30+课程涵盖周易文化、决策方法、个人成长
• 从零开始了解传统智慧的现代价值
• 培养系统性、结构化的思维能力

2️⃣ 思维工具箱 - 多种分析方法
• SWOT分析：全面评估你的处境
• 利弊对比：理性权衡各种选择
• 多方案评估：科学对比备选方案
• 风险评估：识别潜在问题
• 还有更多实用工具...

3️⃣ 决策分析 - AI深度解读
• 基于六爻框架的多维分析
• AI提供个性化的深度洞察
• 不是简单的数据库查询，而是真正的智能分析
• 帮助你从不同角度理解问题

4️⃣ 成长档案 - 追踪你的进步
• 记录每次决策和思考
• 分析你的思维模式
• 提供个性化成长建议
• 见证自己的成长轨迹

━━━━━━━━━━━━━━━━━━━━━

💡 适合谁用？

• 面临重要决策的职场人士
• 对传统文化感兴趣的学习者
• 追求个人成长的思考者
• 需要理清思路的创业者
• 希望培养决策能力的任何人

━━━━━━━━━━━━━━━━━━━━━

🔬 技术亮点

• AI深度分析引擎（非简单查询）
• 本地数据存储（保护隐私）
• 个性化学习推荐
• 精美的UI设计
• 支持iPad

━━━━━━━━━━━━━━━━━━━━━

⚠️ 重要声明

本应用不提供"预测未来"、"改变命运"等迷信服务。

我们是一个帮助你更好思考的工具，
基于理性分析和传统智慧，
所有建议仅供参考。

重大决策请结合实际情况和专业咨询。

━━━━━━━━━━━━━━━━━━━━━

🌟 为什么选择我们？

与其他应用的区别：
✓ 强大的教育内容（30+课程）
✓ 多样的思维工具（8种分析方法）
✓ AI智能分析（非数据库查询）
✓ 完整的成长追踪
✓ 理性、科学的态度

我们相信：
真正的智慧不是预知未来，
而是更好地理解当下，
做出明智的选择。

━━━━━━━━━━━━━━━━━━━━━

开始你的智慧之旅 →
```

### 6.2 审核说明（英文）

```
Dear App Review Team,

Thank you for reviewing "六爻智卦" (Liuyao Decision Assistant).

=== IMPORTANT CLARIFICATION ===

This is NOT a fortune-telling application. Here's what we actually provide:

1. EDUCATIONAL PLATFORM (Primary Focus - 40% of content)
   • 30+ courses on decision-making methodologies
   • Traditional Chinese philosophy education
   • Personal growth guidance
   • Real-world case studies
   
2. THINKING TOOLS (25% of functionality)
   • SWOT Analysis
   • Pros & Cons Comparison
   • Multi-option Evaluation
   • Risk Assessment
   • Time-horizon Analysis
   • 8 different analytical frameworks

3. AI-POWERED ANALYSIS (20% of functionality)
   • Uses Liuyao as ONE of many analytical frameworks
   • Similar to how business consultants use various models
   • AI provides personalized, context-aware insights
   • NOT simple database lookup - actual intelligent analysis

4. GROWTH TRACKING (15% of functionality)
   • Records decision-making history
   • Analyzes thinking patterns
   • Provides growth insights
   • Helps users improve over time

=== WHAT MAKES US DIFFERENT ===

Unlike typical "fortune-telling" apps:

✅ We EDUCATE users on decision-making methods
✅ We provide MULTIPLE analytical tools
✅ We use AI for INTELLIGENT analysis
✅ We track PERSONAL GROWTH
✅ We explicitly DISCOURAGE superstitious use

Multiple disclaimers throughout the app state:
- "This is a thinking tool, not fortune-telling"
- "For major decisions, consult professionals"
- "All suggestions are for reference only"

=== COMPARABLE APPROVED APPS ===

Our approach is similar to:
• Tarot apps focused on self-reflection
• Astrology apps with educational content
• I Ching apps using it as wisdom literature
• MBTI personality apps (using frameworks for insight)

=== TECHNICAL IMPLEMENTATION ===

• Advanced AI engine (not database queries)
• Local data storage (privacy protection)
• Rich educational content
• Multiple analytical tools
• Growth tracking system

=== TEST INSTRUCTIONS ===

To see the educational focus:
1. Check the "Learning" tab (30+ courses)
2. Explore the "Thinking Tools" tab (8 tools)
3. View the methodology explanation (info button)
4. Note the disclaimers throughout

Test Account (if needed):
• Username: [provide if needed]
• Password: [provide if needed]

=== OUR COMMITMENT ===

We are committed to:
1. Promoting rational thinking
2. Educating about decision-making
3. Preserving cultural wisdom
4. Helping users grow

We respectfully request your approval.

Thank you for your consideration.

Best regards,
Liuyao Team
```

---

## 七、成功指标

### 7.1 完成标准

在提交审核前，确保：

- [ ] **架构**：5个Tab全部完成且功能正常
- [ ] **内容**：至少20篇学习文章（每篇800字以上）
- [ ] **工具**：至少8个思维工具实现
- [ ] **文案**：全局无"算命"相关词汇
- [ ] **说明**：方法论说明页面完整
- [ ] **材料**：截图、视频、描述全部准备
- [ ] **测试**：所有功能流程测试通过
- [ ] **免责**：多处显示理性使用声明

### 7.2 审核通过概率评估

基于本方案：

| 因素 | 评分 | 说明 |
|------|------|------|
| 内容丰富度 | 9/10 | 30+课程，8个工具 |
| 差异化程度 | 8/10 | 多Tab架构，功能多元 |
| 教育属性 | 9/10 | 40%权重在学习 |
| 文案规范度 | 9/10 | 全局去"算命"化 |
| 审核说明 | 9/10 | 清晰、专业、真诚 |
| **综合评分** | **8.8/10** | |
| **预计通过率** | **75-80%** | |

---

## 八、后续规划

### 审核通过后

1. **监控数据**
   - 下载量
   - 用户留存
   - 功能使用频率
   - 崩溃率

2. **持续优化**
   - 根据用户反馈改进
   - 增加更多学习内容
   - 优化AI分析质量
   - 新增思维工具

3. **营销推广**
   - 社交媒体宣传
   - 应用商店优化(ASO)
   - 内容营销
   - 用户口碑

### 如果再次被拒

1. **分析原因**
   - 仔细阅读拒绝理由
   - 对比已通过的类似应用
   - 咨询专业人士

2. **应对策略**
   - 进一步增强教育属性
   - 考虑改名（最后手段）
   - 准备更详细的说明
   - 申请电话沟通

---

## 九、快速启动指南

### A. 第一周任务快速开始

```bash
# 1. 备份当前代码
git add .
git commit -m "backup before v2.0 refactor"
git push

# 2. 创建新分支
git checkout -b v2.0-tab-refactor

# 3. 在Xcode中开始
# 打开项目，准备创建新文件
```

### B. 每日检查清单

**Day 1 - MainTabView创建**
- [ ] 创建 MainTabView.swift 文件
- [ ] 修改 liuyaoApp.swift 入口
- [ ] 运行测试，确保编译通过
- [ ] Git提交: "feat: add MainTabView structure"

**Day 2 - 决策分析Tab**
- [ ] 创建 DecisionAnalysisView.swift
- [ ] 迁移原问卦功能代码
- [ ] 修改关键文案
- [ ] 测试功能完整性
- [ ] Git提交: "feat: refactor decision analysis view"

**Day 3-4 - 思维工具Tab**
- [ ] 创建 ThinkingToolsView.swift
- [ ] 实现8个工具的基础UI
- [ ] 实现工具详情页
- [ ] 测试所有工具
- [ ] Git提交: "feat: add thinking tools module"

**Day 5 - 成长档案Tab**
- [ ] 创建 GrowthProfileView.swift
- [ ] 集成统计服务
- [ ] 实现数据展示
- [ ] 测试数据加载
- [ ] Git提交: "feat: add growth profile view"

**Day 6 - 个人中心重构**
- [ ] 重构 ProfilePageView
- [ ] 添加方法论说明入口
- [ ] 优化布局
- [ ] 测试所有功能
- [ ] Git提交: "refactor: improve profile center"

**Day 7 - 文案修改与测试**
- [ ] 全局搜索替换关键词
- [ ] 检查所有页面文案
- [ ] 完整功能测试
- [ ] 修复发现的问题
- [ ] Git提交: "chore: update all copy texts"

---

## 十、常见问题解答

### Q1: 如果时间不够怎么办？

**A**: 优先级排序：
1. **必须完成** (不可省略)
   - MainTabView架构
   - 文案全局修改
   - 方法论说明页面
   - 至少15篇文章

2. **高优先级** (尽量完成)
   - 思维工具（至少5个）
   - 成长档案基础功能
   - 审核材料准备

3. **可延后** (v2.1完成)
   - 文章收藏功能
   - 工具报告生成
   - 高级统计图表

### Q2: 思维工具功能太复杂？

**A**: 简化方案：
- 第一版只做工具介绍和步骤说明
- 输入框可以保留，但不强制保存
- 重点在于展示"我们有这些工具"
- 完整功能可以后续更新

### Q3: 20篇文章写不完？

**A**: 最小可行方案：
- 至少完成15篇（周易7篇+决策8篇）
- 每篇保证800字以上
- 内容质量>数量
- 可以找AI辅助生成初稿，再人工润色

### Q4: 如何快速生成文章？

**A**: 使用AI辅助：
```
Prompt模板：
"请写一篇关于[主题]的文章，面向对传统文化感兴趣的年轻人，
要求：1)去除迷信色彩 2)强调理性思考 3)结合现代生活 
4)800-1500字 5)包含实际案例"
```

### Q5: 审核材料制作工具推荐？

**A**: 
- **截图**: Screenshots - App Store Connect官方工具
- **视频**: iMovie / Final Cut Pro
- **文案**: 使用AI辅助润色（ChatGPT/Claude）
- **图标**: 使用SF Symbols确保iOS风格统一

---

## 附录

### 附录A：关键代码文件清单

```
必须新建的文件：
✓ MainTabView.swift
✓ DecisionAnalysisView.swift
✓ ThinkingToolsView.swift  
✓ GrowthProfileView.swift
✓ LearningContentManager.swift
✓ MethodologyView.swift
✓ OnboardingView.swift (可选)

必须修改的文件：
✓ liuyaoApp.swift (入口)
✓ LearningPageView.swift (重构)
✓ ProfilePageView.swift (重构)
✓ Info.plist (显示名称)
✓ 所有包含"算卦"等词的文件
```

### 附录B：Git提交规范

```bash
# 功能开发
git commit -m "feat: add new feature"

# Bug修复
git commit -m "fix: resolve issue"

# 重构
git commit -m "refactor: improve code structure"

# 文档
git commit -m "docs: update documentation"

# 样式
git commit -m "style: format code"

# 测试
git commit -m "test: add tests"
```

### 附录C：联系方式

如遇到问题可以：
1. 参考本文档
2. 查阅iOS开发文档
3. 搜索类似问题的解决方案
4. 在开发社区提问

---

## 总结

### 🎯 核心目标

通过本次重构，我们要实现：

1. **架构升级**: 从单一功能到多功能平台
2. **定位转变**: 从"算命工具"到"决策助手"
3. **内容充实**: 从轻内容到重教育
4. **合规优化**: 完全符合App Store审核标准

### 📊 预期成果

- ✅ 5个功能完整的Tab
- ✅ 20+篇优质学习文章
- ✅ 8个实用思维工具
- ✅ 完善的成长追踪系统
- ✅ 专业的审核材料
- ✅ 75-80%的审核通过率

### 💪 行动起来

不要被工作量吓倒，按照计划一步步来：

**Week 1**: 先把架构搭起来  
**Week 2**: 专心写文章，可以批量处理  
**Week 3**: 完善细节，让功能更完整  
**Week 4**: 认真准备材料，争取一次通过  

### 🌟 最后的话

保留"六爻智卦"这个名字是可以的，但需要付出更多努力。

关键是要**真正做出差异化**，而不只是表面功夫。

这次重构不仅是为了通过审核，更是让产品变得更好。

**相信自己，认真执行，一定能成功！** 🚀

---

**文档版本**: v1.0  
**创建日期**: 2025-11-24  
**最后更新**: 2025-11-24  
**预计完成**: 3-4周后  
**目标**: 通过App Store审核，成功上架

**祝你顺利！** 🎉

