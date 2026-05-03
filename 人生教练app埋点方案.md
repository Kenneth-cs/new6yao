# 人生教练 (Life Coach) App 数据埋点与运营分析方案

## 一、 埋点目标与核心指标 (North Star Metrics)

作为一款融合易经六爻与五行命理的「决策辅助」App，我们的运营目标是**验证核心决策工具（摇卦、五行矩阵、SWOT）的有效性**，以及**提升用户的长线留存与订阅付费转化率**。

**核心监控指标：**
1. **激活率**：下载 App 后，完成第一次「摇卦」或「五行决策矩阵」分析的用户占比。
2. **核心工具渗透率**：活跃用户中，使用「五行决策矩阵」和「SWOT分析」的比例（验证新功能是否受欢迎）。
3. **留存率（次日/七日/次月）**：决策类工具的生命线，观察多维度的分析工具是否有效提升了留存。
4. **订阅转化率**：免费用户转化为「专业版」（月付/年付）付费用户的比例。

---

## 二、 用户标识与基础指标 (User ID & DAU/Retention)

在接入数据 SDK（如友盟、Firebase、神策等）后，自动获得以下核心运营数据：

### 1. 独立用户 ID (Device ID / Account ID)
- **未登录状态**：SDK 自动为设备生成「设备 ID (Device ID)」，1 台设备 = 1 个独立用户 (UV)。
- **登录/iCloud状态**：如果未来接入账号或强绑定 iCloud，可调用 SDK 的 `setUserId("账号ID")`，实现跨设备数据互通。

### 2. 每日活跃用户 (DAU - Daily Active Users)
- **无需手动埋点**：SDK 自动监听 App 的「启动」和「退到后台」事件。
- **你能看到什么**：按日期查看 DAU、WAU（周活）和 MAU（月活）折线图。

### 3. 用户留存率 (Retention)
- **无需手动埋点**：后台自动根据「首次启动」和「后续启动」计算留存漏斗（如次日留存、7日留存）。

---

## 三、 隐私与合规原则（极其重要）

由于本产品涉及用户的个人决策、八字命局及隐私问题，必须严格遵守以下底线：
- **绝不上报具体决策内容与八字隐私**：用户输入的具体困惑、选项名称、出生年月日时坚决不上报。
- **脱敏处理**：只上报行为事件（如：点击了分析按钮、选择了某个场景标签）和脱敏后的分类名称（如：职场、感情）。
- **合规弹窗**：首次启动时必须弹出《隐私政策》和《用户协议》同意弹窗，用户明确授权后才初始化 SDK。

---

## 四、 核心埋点事件设计 (Event Tracking Plan)

事件命名规范采用：`模块_动作_对象`（如 `divination_click_start`）。

### 4.1 核心动作一：六爻摇卦 (Divination)
分析用户最基础的起卦决策功能使用情况。

| 事件 ID | 事件名称 | 触发时机 | 核心参数 (Parameters) |
| :--- | :--- | :--- | :--- |
| `divination_click_start` | 点击起卦 | 在摇卦 Tab 点击开始起卦时 | 无 |
| `divination_toss_coin` | 掷铜钱 | 用户摇动手机或点击掷币时 | `toss_count` (第几次掷币，1-6) |
| `divination_view_result` | 查看卦象结果 | AI生成解卦结果并展示时 | `hexagram_name` (本卦名称，如：乾为天)<br>`wait_time_ms` (AI生成耗时)<br>`daily_current_count` (这是该用户今天的第几次摇卦) |

### 4.2 核心动作二：五行决策矩阵 (Five Elements Matrix)
分析 V2.x 核心主打功能的使用深度与场景偏好。

| 事件 ID | 事件名称 | 触发时机 | 核心参数 (Parameters) |
| :--- | :--- | :--- | :--- |
| `decision_input_birthday` | 输入生辰日期 | 在决策 Tab 修改生辰弹窗点击「确认并AI推算命局」时 | 无 |
| `decision_click_recalculate` | 重新推算 | 在决策 Tab 点击「重新推算」按钮时 | 无 |
| `decision_click_decide` | 点击告诉我纠结 | 在决策 Tab 点击「告诉我你在纠结什么」进入场景选择时 | 无 |
| `matrix_click_new` | 发起矩阵分析 | 在决策 Tab 点击新建矩阵分析时 | `scenario` (职场/投资/置业/情感/自定义) |
| `matrix_submit` | 提交选项分析 | 录入完选项，点击开始计算时 | `options_count` (对比的选项数量) |
| `matrix_view_result` | 查看矩阵结果 | 动画结束，展示最终得分与建议时 | `has_veto` (true/false，是否触发一票否决/熔断)<br>`top_score_level` (最高分区间，如：大吉/小吉/凶) |

### 4.3 核心动作三：SWOT 分析 (SWOT Analysis)
分析辅助思考工具的使用率。

| 事件 ID | 事件名称 | 触发时机 | 核心参数 (Parameters) |
| :--- | :--- | :--- | :--- |
| `swot_click_new` | 进入SWOT分析页 | 在思考 Tab 点击 SWOT 分析卡片，进入页面时 | 无 |
| `swot_submit` | 提交SWOT分析 | 填写四象限后，点击「AI深度分析」按钮时 | 无 |
| `swot_view_result` | 查看SWOT结果 | AI生成 SWOT 矩阵并展示时 | `wait_time_ms` (生成耗时) |

### 4.4 学习与个人中心 (Learning & Profile)

| 事件 ID | 事件名称 | 触发时机 | 核心参数 (Parameters) |
| :--- | :--- | :--- | :--- |
| `learning_view_article` | 浏览学习文章 | 在学习 Tab 点击进入某篇知识文章时 | `article_id` 或 `article_title` |
| `profile_view_history` | 查看历史记录 | 在我的 Tab 点击查看最近决策记录时 | `record_type` (摇卦/矩阵/SWOT) |

### 4.5 商业化与订阅 (Monetization)
追踪用户的付费意愿、次数限制拦截率和转化漏斗。

| 事件 ID | 事件名称 | 触发时机 | 核心参数 (Parameters) |
| :--- | :--- | :--- | :--- |
| `limit_reached_show` | 触发次数限制 | 免费用户达到每日/每月次数上限，弹出拦截页时 | `trigger_source` (摇卦/矩阵/SWOT) |
| `paywall_view` | 浏览订阅详情页 | 展示 SubscriptionDetailView 时 | `trigger_source` (限制拦截/个人中心/历史记录限制) |
| `paywall_click_buy` | 点击购买按钮 | 在订阅页点击具体的套餐时 | `plan_type` (monthly/yearly)<br>`price` (价格) |
| `paywall_pay_success` | 支付成功 | 苹果 StoreKit 回调支付成功时 | `plan_type` (套餐类型) |
| `paywall_restore` | 恢复购买 | 点击恢复购买按钮并成功时 | 无 |

---

## 五、 用户属性设置 (User Properties)

给用户打上「属性标签」，每次上报事件时自动携带，用于交叉分析（例如：订阅用户和免费用户在决策频率上的差异）。

| 属性名 (Property) | 说明 | 更新时机 |
| :--- | :--- | :--- |
| `subscription_status` | 订阅状态 | 购买成功或过期时更新 (free/pro_monthly/pro_yearly) |
| `total_divination_count` | 累计摇卦次数 | 每次成功完成摇卦后更新 (+1) |
| `total_matrix_count` | 累计矩阵分析次数 | 每次成功完成五行矩阵后更新 (+1) |
| `days_since_install` | 安装至今的天数 | 每日首次启动时计算更新 |

---

## 六、 运营分析场景举例 (如何使用这些数据？)

1. **免费额度与付费墙优化 (Paywall Optimization)**：
   - 观察 `divination_view_result` 中的 `daily_current_count` 参数分布。
   - 目的：目前免费版限制是**每天 3 次**。如果数据统计发现，95% 的免费用户每天只摇 1-2 次，说明目前的“每天 3 次”限制太宽松了，用户根本碰不到付费墙，自然不会买专业版。此时可以考虑在下个版本将免费额度降为“每天 2 次”，从而大幅提升 `limit_reached_show`（触发限制拦截）的曝光率，进而提升收入。
2. **商业化转化归因与漏斗分析**：
   - 漏斗：`limit_reached_show` -> `paywall_view` -> `paywall_click_buy` -> `paywall_pay_success`。
   - 目的：找出哪个功能点最容易触发用户购买（例如是「每日摇卦用尽」还是「每月矩阵用尽」），从而在后续版本中强化该转化路径。
3. **五行决策矩阵功能验证**：
   - 观察 `matrix_click_new` 的 `scenario` 参数分布。
   - 目的：了解用户最关心什么决策（职场 vs 投资 vs 情感），以便后续针对热门场景推出更深度的 AI Prompt 或专属调候物推荐。
4. **AI 生成耗时对留存的影响**：
   - 交叉分析：将 `divination_view_result` 和 `matrix_view_result` 中的 `wait_time_ms` 与用户的次日留存率进行对比。
   - 目的：如果发现等待时间超过 8 秒的用户留存率断崖式下跌，说明必须优化流式输出（Streaming）体验或增加更有趣的 Loading 动画（如五行粒子碰撞动画）。