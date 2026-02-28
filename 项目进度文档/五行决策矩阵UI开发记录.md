# 五行决策矩阵 UI 开发记录

> 开发时间：2026年02月20日
> 关联文档：`项目核心文档/五行决策矩阵核心功能方案.md` · `项目核心文档/五行决策矩阵UI_UX落地方案.md`

---

## 一、开发背景

将原"成长"Tab 合并进"我的"Tab 后，空出一个 Tab 位置，用于承接**五行决策矩阵**这一核心差异化功能。本次开发按照用户提供的5张 UI 设计稿，从零完成了完整的 4 页面链路。

**完整导航链路：**
```
决策 Tab（能量画像首页）
    → [开始决策] → 五行场景选择页
    → [开始五行分析] → 五行能量碰撞页（加载动画）
    → [查看详情 / 查看结果] → 决策结果报告页
```

---

## 二、新增文件清单

| 文件 | 对应页面 | 行数 |
|------|---------|------|
| `liuyao/EnergyPortraitView.swift` | 决策 Tab 首页 · 能量画像 | ~220 行 |
| `liuyao/ScenarioSelectionView.swift` | 二级页 · 场景选择 | ~280 行 |
| `liuyao/ParticleCollisionView.swift` | 三级页 · 粒子碰撞动画 | ~280 行 |
| `liuyao/MatrixResultView.swift` | 结果页 · 决策报告 + 对比矩阵 | ~260 行 |

**修改文件：**
- `liuyao/MainTabView.swift`：将决策 Tab 的根视图从 `MatrixPlaceholderView` 替换为 `EnergyPortraitView`
- `liuyao/MatrixAlgorithmDemo.swift`：修复 `hasFatalRisk` 变量赋值警告

---

## 三、页面开发详情

### 页面 1：五行能量画像 (`EnergyPortraitView`)

**对应设计稿**：图一（决策 Tab 首页）

#### 核心组件：`FluidEnergyRing`

**版本迭代历史**：

| 版本 | 实现方式 | 问题 |
|------|---------|------|
| v1 | `AngularGradient` 五等分均匀渐变圆环 | 每个五行占相同面积，无法体现能量强弱 |
| v2 | 五层 `Circle().trim()` + `.blendMode(.multiply)` 水墨叠加 | 正片叠底导致颜色偏暗、对比度不足 |
| v3 ✅ | 按能量值比例计算每段 `trim(from:to:)` 的起止点 | **最终版**，与设计稿一致 |

**最终实现要点：**
```swift
// 核心算法：按能量值比例计算每段圆弧的起止位置
private var segments: [(element: FiveElement, start: Double, end: Double)] {
    let total = max(elementOrder.reduce(0.0) { $0 + (values[$1] ?? 0) }, 0.001)
    var cumulative = 0.0
    return elementOrder.map { el in
        let frac = (values[el] ?? 0.001) / total
        defer { cumulative += frac }
        return (el, cumulative, cumulative + frac)
    }
}
```

**视觉细节：**
- 各段之间保留 `0.006` 的小间隙，形成分段感
- 能量值 < 0.08 的元素使用虚线（`dash: [6, 5]`）表示"缺失/干涸"
- 标签位置按各段中点角度动态计算，跟随实际比例布局
- 最强元素有呼吸发光效果（`shadow` + `opacity` 动画）

**FiveElement 扩展**（定义在此文件，供全局使用）：
- `color: Color` — 高饱和度清晰色系
- `englishName: String` — 英文名
- `icon: String` — SF Symbol 图标名

---

### 页面 2：五行场景选择 (`ScenarioSelectionView`)

**对应设计稿**：图二

#### 主要功能模块

**① 搜索框 + AI 实体识别标签**
- 用户输入关键词（如 "Tencent"）时，延迟 0.6s 后显示模拟 AI 识别结果标签
- 标签格式：`🔥 互联网 · 木/火`，带 × 关闭按钮
- 实际接入 AI API 后，将替换为真实的五行归类

**② 场景卡片布局**
- 前 4 张：`LazyVGrid` 2×2 布局，各带彩色渐变背景
- 第 5 张：全宽单行卡片，右上角带"自定义场景"标签
- 每张卡片背景色取自对应五行元素色（透明度 8%~18%）

| 场景 | 五行 | 背景色系 |
|------|------|---------|
| 事业/学业 | 木 | 翠绿渐变 |
| 投资/理财 | 水 | 宝蓝渐变 |
| 情感/人际 | 火 | 赤红渐变 |
| 置业/生活 | 土 | 橙黄渐变 |
| 出行/其他 | 金 | 灰银（全宽） |

**③ 决策选项输入**
- 点击场景卡片后以弹出动画展示
- 支持 1~3 个选项（`Option 1 / 2 / 3`），通过"添加对比项"按钮动态增减
- 不同于旧版固定 A/B 输入，更符合设计稿的交互方式

**数据模型：**
```swift
struct DecisionScenario: Identifiable {
    let id: UUID
    let name: String        // 中文名
    let subtitle: String    // 副标题
    let englishName: String // 英文名
    let icon: String        // SF Symbol
    let element: FiveElement
    let inputPlaceholder: String
}
```

---

### 页面 3：五行能量碰撞 (`ParticleCollisionView`)

**对应设计稿**：图三

#### 视觉构成

| 层级 | 内容 | 实现方式 |
|------|------|---------|
| 背景 | 深宇宙色 + 星点 + 星云光晕 | 固定坐标数组 + `RadialGradient` |
| 轨道环 | 虚线圆形轨道 | `Circle().stroke(style: StrokeStyle(dash: [8, 6]))` |
| 生克标签 | 水生木、火克金 等浮标 | 固定偏移量 `offset(x:y:)` |
| 散布点 | 五行颜色小圆点 | `FloatingDot` 数组 + 延迟出现动画 |
| 中心池 | 黑色外环 + 橙色火焰圆 | ZStack 叠加 + `RadialGradient` |
| 底部卡片 | 熔断警告（固定底部） | `VStack { Spacer(); warningCard }` |

#### 动画时序

```
0.2s  → 开始显示进度条
0.3s  → "解析五行属性..." (15%)
1.0s  → "计算命局强弱..." (38%)
2.0s  → "模拟粒子碰撞..." (58%)，中心开始脉冲
3.0s  → "分析五行生克..." (78%)，生克标签淡入
3.8s  → "生成决策报告..." (92%)
4.3s  → 完成 → 若触发熔断：底部警告卡滑入；否则直接跳转结果页
```

#### 重要设计决策：底部固定卡 vs 弹出层
- **旧版**：使用 SwiftUI Sheet 弹出层 → 与设计稿图三不符
- **新版**：使用 `VStack { Spacer(); warningCard }` 固定在底部 → 与设计稿一致
- 熔断时同时触发红色背景脉冲动画（全屏 `Color.red.opacity` 呼吸）

---

### 页面 4：决策结果报告 (`MatrixResultView`)

**对应设计稿**：图四、图五

#### 布局结构（单页滚动，移除旧版 Tab 切换）

```
┌─────────────────────────────────┐
│  顶部定论 Banner（青蓝渐变）        │
│  ✓ 优选：选项A   85分 (大吉)  🏆  │
├─────────────────────────────────┤
│  对比分析                         │
│  地利(环境) 权重40%               │
│  [临水聚气·补益] [靠山稍远·消耗]   │
│  人和(楼层) 权重30%               │
│  [8层(金)·补益]  [4层(木)·消耗]   │
│  天时(装修) 权重30%               │
│  [精装现房·补益] [毛坯需改·消耗]   │
├─────────────────────────────────┤
│  得分拆解                         │
│  选项A ██████████░░  药力：水木   │
│  选项B ██████░░░░░░  病灶：土金   │
├─────────────────────────────────┤
│  落地建议（如何买）                │
│  ● 楼层选择：优先 1，3，6，8 层   │
│  ● 布局调整：厨房(水)在北方       │
│  [🛒 调候物推荐 · 佩戴黑曜石手链] │
└─────────────────────────────────┘
```

#### 三才维度框架

采用中国哲学"三才"（天地人）框架组织对比维度：

| 维度 | 命理对应 | 权重 |
|------|---------|------|
| 地利（环境） | 地理位置、风水格局 | 40% |
| 人和（楼层） | 层数数理、邻里关系 | 30% |
| 天时（装修） | 入住时机、装修五行 | 30% |

#### 得分拆解进度条

- 选项A：蓝→青绿渐变条（代表"药力"）+ 标注 `● 药力：水木`
- 选项B：蓝→橙渐变条（代表"病灶"）+ 标注 `● 病灶：土金`
- 实现：`GeometryReader` + `Capsule().fill(LinearGradient(...))`

#### 落地建议高亮文本

关键数字使用 `Text` 拼接实现颜色高亮：
```swift
Text("楼层选择：优先 ").foregroundColor(.primary)
+ Text("1，3，6，8").foregroundColor(.teal).fontWeight(.bold)
+ Text(" 层。").foregroundColor(.primary)
```

---

## 四、公共组件

| 组件名 | 所在文件 | 用途 |
|--------|---------|------|
| `MatrixPrimaryButton` | `EnergyPortraitView.swift` | 紫色渐变主按钮（全局复用）|
| `ScenarioCard` | `ScenarioSelectionView.swift` | 场景选择卡片（向后兼容）|
| `CustomScenarioCard` | `ScenarioSelectionView.swift` | 自定义场景卡片 |
| `FloatingDot` | `ParticleCollisionView.swift` | 粒子碰撞页散布小圆点模型 |

---

## 五、修复的 Bug 记录

| # | 文件 | 问题 | 修复方式 |
|---|------|------|---------|
| 1 | `EnergyPortraitView` | 圆环五等分，无法体现能量强弱 | 改用比例 `trim()` 分段 |
| 2 | `EnergyPortraitView` | 水墨叠加导致颜色偏脏 | 移除 `.blendMode(.multiply)`，回归高饱和色 |
| 3 | `ScenarioSelectionView` | 卡片白底无设计感 | 改为元素色彩渐变背景 |
| 4 | `ScenarioSelectionView` | 第5张卡与前4张混排 | 分离为 `LazyVGrid`（前4） + 全宽卡（第5） |
| 5 | `ParticleCollisionView` | 熔断警告是 Sheet 弹出层 | 改为 `VStack { Spacer(); card }` 固定底部 |
| 6 | `MatrixResultView` | Tab 切换导致结构分散 | 改为单页线性滚动，移除 Tab 组件 |
| 7 | `MatrixResultView` | 对比矩阵缺少权重信息 | 新增 `weight: Int` 字段，显示"权重40%"标签 |

---

## 六、当前数据状态（全部 Mock）

所有页面目前均使用静态 Mock 数据，待后续接入真实数据源：

| 数据 | Mock 位置 | 真实数据来源（待开发）|
|------|----------|-------------------|
| 五行能量值（0.15/0.45/0.25/0.10/0.05） | `EnergyPortraitView` | `BaziEngine.calculate()` |
| AI 诊断文案 | `EnergyPortraitView` | 字节豆包 API |
| AI 实体识别标签 | `ScenarioSelectionView` | 字节豆包 API |
| 熔断触发（hasFatalRisk = true） | `ParticleCollisionView` | `ScoreCalculator.checkFatalRisk()` |
| 对比矩阵维度数据 | `MatrixResultView` | AI API + BaziEngine |
| 得分（85分/52分）| `MatrixResultView` | `ScoreCalculator.score()` |

---

## 七、下一步开发计划

### Phase 2：算法引擎（Todo #6）

- [ ] 实现 `BaziEngine.swift`：根据生日推算八字、日主强弱、喜忌神
- [ ] 实现 `ScoreCalculator.swift`：计算各维度五行分值
- [ ] 替换 `EnergyPortraitView` 中的 Mock 能量值

### Phase 3：AI 接口接入（Todo #7）

- [ ] 复用项目现有字节豆包 API 请求模块
- [ ] 实现 `MatrixDecisionService.swift`：封装 AI 分析请求
- [ ] 替换 `EnergyPortraitView` 中的 Mock 诊断文案
- [ ] 实现场景关键词的 AI 五行归类（实体识别）

### Phase 4：数据持久化

- [ ] CoreData 新增 `MatrixDecision` 实体，保存决策记录
- [ ] 历史决策记录页面对接
- [ ] 与"我的"Tab 中的最近决策模块联动

---

> **文档维护说明**：本文档记录五行决策矩阵 UI 模块的开发全过程。每次迭代后请更新"Bug修复记录"和"下一步计划"章节。
