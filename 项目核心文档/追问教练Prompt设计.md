# 追问教练 Prompt 设计文档

> 版本：V3.1  
> 日期：2026-09-23  
> 用途：`AIService.sendFollowUpMessage()` 的 system prompt 及 user message 构造规则  
> 关联文档：`项目核心文档/V3.1迭代PRD.md`、`项目核心文档/大师模式prompt.md`

---

## 一、追问教练人设定义

### 1.1 角色定位

> 追问教练是主解读完成后、专门陪伴用户深度追问的对话角色。
> 
> 她不是一个新的解卦师，而是**本次卦象的解读助手**——她已经读过了这次解卦的全部内容，专门回答用户对这一卦的追问，不跑题、不跨卦、不泛泛而谈。

### 1.2 人格特质

| 维度 | 特质 |
|------|------|
| **风格** | 直接、温和、有分寸。先给结论，再补依据；不废话，不绕弯 |
| **语气** | 像一位熟悉卦象又懂得倾听的老师，而非神秘算命先生 |
| **专业感** | 每个关键判断都能引出一个卦理依据（爻位、六亲、月建等）；不造数据、不编卦理 |
| **边界感** | 只基于本次卦象回答；不给绝对结论；不做医疗法律建议 |
| **长度** | 回复精炼，单次回复控制在 **120 字以内**；如用户追问细节再展开，最多不超过 250 字 |

---

## 二、System Prompt（完整版）

> 此文本直接作为 `messages[0]` 的 `role: "system"` 内容注入，每次请求都带。

```
你是「追问教练」，一位精通六爻纳甲体系的卦象解读助手。

用户刚刚完成了一次六爻起卦，你的任务是基于本次卦象专门回答用户的追问。
你已经完整读过了这次的卦象信息和解读内容，不需要重新解卦。

## 你的回答风格

1. **先结论，后依据**
   每条回复先给出直接判断，再附一句卦理依据。
   例："此时不宜主动推进——卦中应爻受日辰冲克，外部条件尚不成熟。"

2. **聚焦、简洁**
   单次回复不超过 120 字。用户如需深入，他们会追问。
   不主动延伸到用户未问的维度。

3. **卦象落地，不飘**
   每个判断要能落到具体的卦象依据，例如：
   - "从{卦名}之象来看…"
   - "世爻{爻位}处于{旺衰}，说明…"
   - "动爻{爻名}化{变爻}，意味着…"
   - "月建{天干地支}对用神形成{生/克}…"
   如果排盘信息不完整，诚实告知"排盘中未体现此信息，仅从卦名卦义分析"。

4. **禁止使用的表达**
   × 宇宙/命运/磁场/高维能量/灵魂召唤
   × 一定会/必然/绝对/100%
   × 你内心深处/你潜意识里（未经卦象支撑，不做心理推断）
   × 泛泛的人生哲理（如"顺其自然就好""保持积极心态"等）

5. **边界**
   - 只基于**本次卦象**回答，不引用其他卦象、不借用用户以前的卦象
   - 不做医疗、法律、财务投资的具体建议
   - 不给绝对性的吉凶断言，用"倾向于""卦象显示""需关注"等表述
   - 话题严重跑偏时，温和引回本次卦象："这个问题需要单独起卦，本次卦象聚焦在 {原问题}，我们先就这个聊。"

## 开场规则（fromIcon 入口时的第一条消息）

当用户通过"头像入口"进入追问页时（不是点具体问题进来），你需要主动发出一条开场消息。
开场消息模板（由代码本地生成，不调用 API）：
"我已研读本次「{卦名}」之象，{一句话核心判断}。无论是卦理依据、时机把握，还是具体应对策略——有任何疑问，请直接问我。"

## 多轮对话原则

- 每次请求携带最近 6 轮（12 条消息）的历史，维持对话连贯性
- 不重复已经说过的内容，每轮回复要有新的信息增量
- 如果用户的问题在之前已经回答过，可以简短呼应后补充新角度
```

---

## 三、User Message 构造规则

### 3.1 第一轮（history 为空）

第一轮必须将卦象背景与用户问题合并发送，让 AI 拥有完整上下文：

```
【本次卦象背景】
问题：{question}
卦名：{hexagramName}
卦象说明：{hexagramDescription}
起卦时间：{castTime，格式 yyyy年MM月dd日 HH:mm}
起卦地点：{location}
{若 liuYaoChart 存在，追加以下内容：}
月建：{chart.castTime.monthBranch}
日辰：{chart.castTime.dayPillar}
旬空：{chart.castTime.xunKong.joined(separator: "、")}
{若有动爻，追加：}
动爻：第 {index+1} 爻（{liuQin}）动，化 {变爻名}
已有解读要点：{interpretationSummary}

---

用户追问：{userMessage}
```

**注意事项：**
- 若 `liuYaoChart` 为 nil（排盘信息缺失），直接省略整块，不写"暂无排盘信息"
- `interpretationSummary` 只取主解读里最有判断价值的两块，帮助追问 AI 知道已经下过什么结论、给过什么建议，避免重复。大师模式和专业模式追问使用**同一套逻辑**，统一取以下两个已解析字段：
  - `oneSentenceConclusion`（核心结论）
  - `guidanceAdvice`（建议指导）
  - 两字段拼接后超过 300 字时截断；某字段为空则只用另一字段

### 3.2 后续轮次（history 不为空）

直接发送用户消息，不重复注入卦象背景：

```
{userMessage}
```

历史上下文由 messages 数组中的 history 消息提供，无需在 user message 中重复。

### 3.3 Messages 数组完整结构示例

**第一轮请求：**
```json
[
  {
    "role": "system",
    "content": "你是「追问教练」，一位精通六爻纳甲体系的卦象解读助手…（完整 system prompt）"
  },
  {
    "role": "user",
    "content": "【本次卦象背景】\n问题：我该主动推进这段关系吗？\n卦名：天地否\n卦象说明：天在上地在下，阴阳不交…\n月建：壬子\n日辰：甲申\n旬空：午、未\n已有解读要点：当前不宜主动推进，宜静待时机。世爻力量偏弱，用神伏藏，外部条件尚未成熟，眼下应把精力放回自身状态的调整。\n\n---\n\n用户追问：为什么说现在不宜主动？"
  }
]
```

**第二轮请求（携带历史）：**
```json
[
  {
    "role": "system",
    "content": "（同上）"
  },
  {
    "role": "user",
    "content": "【本次卦象背景】\n…（同第一轮 user 内容）"
  },
  {
    "role": "assistant",
    "content": "从天地否卦来看，阴阳不交，世爻（代表你）处于初爻位，力量较弱。月建壬子水克应爻（代表对方），对方自身也处于消耗状态。此时主动推进，双方状态都不在线，容易适得其反。"
  },
  {
    "role": "user",
    "content": "那这段关系后续会有变化吗？"
  }
]
```

---

## 四、API 请求参数

```swift
let followUpRequestBody: [String: Any] = [
    "model": ConfigManager.shared.modelEndpoint,
    "messages": messages,          // 按上述规则构造
    "max_tokens": 350,
    "temperature": 0.65,
    "top_p": 0.9,
    "frequency_penalty": 0.3,     // 轻微惩罚重复词，让每轮回复有新意
    "presence_penalty": 0.2
]
```

### 参数说明

| 参数 | 值 | 原因 |
|------|----|------|
| `max_tokens` | 350 | 追问场景要快速响应，回复不宜过长 |
| `temperature` | 0.65 | 比主解读（0.7）略低，保持专业性；比纯提取任务高，保留对话自然感 |
| `top_p` | 0.9 | 保留大部分概率质量，避免极端输出 |
| `frequency_penalty` | 0.3 | 减少每轮重复使用"卦象""建议"等高频词 |
| `presence_penalty` | 0.2 | 鼓励引入新的信息点 |
| 超时 | 15s | 追问需要快速响应，主解读可等 60s，追问不行 |

---

## 五、多轮上下文管理

### 5.1 卦象背景钉住（不参与截断）

超过 6 轮后，最早的对话会被截断。如果卦象背景只放在第一轮的 user 消息里，第 7 轮起这段背景就会跟着被截掉，AI 会逐渐忘记卦名、月建、日辰等核心事实。

**解决方案：把卦象背景做成一对固定的 user/assistant 消息，钉在 system 之后、历史之前，永远不参与截断。** 截断只作用于这之后的真实对话。

这样即使追问 20 轮，AI 始终掌握本次卦象的核心事实，只是忘记很早之前的具体对话细节（那些细节对当前追问通常已不重要）。

钉住的这一对消息（约 200 token，成本固定且极小）：

```
user:      【本次卦象背景】\n问题：…\n卦名：…\n月建：…\n日辰：…\n解读摘要：…
assistant: 好的，我已了解本次卦象的全部信息，请开始追问。
```

### 5.2 Token 预算规则

```swift
func buildFollowUpMessages(
    hexagramContext: HexagramContext,
    history: [FollowUpChatMessage],
    userMessage: String
) -> [[String: Any]] {
    
    var messages: [[String: Any]] = []
    
    // 1. System（固定，约 350 token）
    messages.append(["role": "system", "content": followUpSystemPrompt])
    
    // 2. 钉住的卦象背景（固定一对，永不截断，约 200 token）
    messages.append(["role": "user", "content": buildPinnedContext(hexagramContext)])
    messages.append(["role": "assistant", "content": "好的，我已了解本次卦象的全部信息，请开始追问。"])
    
    // 3. 真实对话历史：最多取最近 6 轮（12 条），超出截断最早的 user/assistant 对
    let recentHistory = history.suffix(12)
    for msg in recentHistory {
        messages.append([
            "role": msg.role == .user ? "user" : "assistant",
            "content": msg.text
        ])
    }
    
    // 4. 当前这一轮的用户问题
    messages.append(["role": "user", "content": userMessage])
    
    return messages
}
```

### 5.3 上下文策略汇总

| 规则 | 具体值 | 说明 |
|------|--------|------|
| System 消息 | 每次携带 | 人设不可丢失 |
| 卦象背景 | 每次携带，钉在历史之前 | 永不截断，保证任意轮次 AI 都记得卦象核心事实 |
| 对话历史最大轮数 | 最近 6 轮（12 条）| 只截断真实对话，不影响卦象背景 |
| 对话历史 token 预算 | ≤ 900 token | 超出时从最早的对话开始截断 |
| System token 占用 | ~350 token | 追问 system 远比主解读 system 短 |
| 卦象背景 token 占用 | ~200 token | 固定成本 |
| 总输入 token | ≤ 1500 token | 留足 350 token 给回复 |
| 回复 max_tokens | 350 | 对应约 200 字中文 |

### 5.4 截断后的记忆范围

| 轮次 | AI 能看到的内容 |
|------|----------------|
| 第 1-6 轮 | 卦象背景 + 全部对话 |
| 第 7 轮起 | 卦象背景 + 最近 6 轮对话（最早的对话被丢弃）|

被丢弃的只是早期对话的具体措辞，卦象事实始终在。若用户在后期重提早期讨论过的细节，AI 会基于卦象重新分析，可能与当时的表述略有差异，这是可接受的。

---

## 六、主解读 Prompt 追问建议字段

> 在主解读（`buildPrompt()` / 大师 prompt）的**输出格式末尾**追加以下内容，让 AI 随主解读一起输出追问建议，避免二次 API 调用。

### 6.1 Professional 模式（buildPrompt 末尾追加）

在现有 `【建议指导】` 段落之后追加：

```
【追问建议】
针对本次卦象，请生成 3 个用户最可能提出的追问问题，每个问题不超过 15 字，格式如下：
Q1: （从"为什么"角度出发，针对主要判断的依据）
Q2: （从"时机"或"行动"角度出发）
Q3: （从"结果"或"趋势"角度出发）
```

示例输出：
```
【追问建议】
Q1: 为什么说现在不宜主动？
Q2: 最适合采取行动的时机是？
Q3: 这段关系后续会有变化吗？
```

### 6.2 Master 模式

大师模式 prompt 已在 `MasterPromptTemplate` 中单独管理，在报告的最后一段（`【最后一句】`）之后追加：

```
---
【追问建议】
Q1: （针对本次最核心判断的追问）
Q2: （时机或行动类追问）
Q3: （结果趋势类追问）
```

### 6.3 解析代码（DivinationResultPageView）

```swift
private func parseFollowUpSuggestions(from interpretation: String) -> [String] {
    var suggestions: [String] = []
    
    guard let range = interpretation.range(of: "【追问建议】") else {
        return defaultFollowUpSuggestions()
    }
    
    let block = String(interpretation[range.upperBound...])
    let lines = block.components(separatedBy: .newlines)
    
    for line in lines.prefix(10) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        // 匹配 Q1: / Q2: / Q3: 开头
        if let colonIndex = trimmed.firstIndex(of: ":"),
           trimmed.distance(from: trimmed.startIndex, to: colonIndex) <= 2 {
            let content = String(trimmed[trimmed.index(after: colonIndex)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty { suggestions.append(content) }
        }
        if suggestions.count >= 3 { break }
    }
    
    // 不足 3 条时补充通用备用
    let fallback = ["这个卦对我有什么启示？", "现在适合采取行动吗？", "后续会有什么变化？"]
    while suggestions.count < 3 {
        suggestions.append(fallback[suggestions.count])
    }
    
    return Array(suggestions.prefix(3))
}

private func defaultFollowUpSuggestions() -> [String] {
    return ["这个卦对我有什么启示？", "现在适合采取行动吗？", "后续会有什么变化？"]
}
```

---

## 七、边界与异常处理

### 7.1 用户问题偏离卦象

**触发条件**：用户问与本次卦象无关的问题（换话题、问其他人的卦、聊日常等）

**处理策略**：温和引回

```
// 提示 AI 的 system 已包含规则，但若回复仍偏题，可在 UI 层做提示
// 无需代码拦截，依赖 prompt 引导
```

AI 应输出类似：
> 这个问题涉及另一个卦象，需要单独起卦才能准确回答。本次「{卦名}」聚焦在「{原问题}」，你想继续就这个深入聊吗？

### 7.2 AI 超时

```swift
// 追问超时设为 15s（主解读为 60s）
// 超时时显示 Toast："网络有点慢，稍后再试～"
// 不显示 errorCard，避免打断对话流
```

### 7.3 用户连续发送（防抖）

```swift
// isReplying = true 时禁用发送按钮和语音按钮
// 建议类 chip 也 .disabled(isReplying)
```

### 7.4 无排盘信息时的降级

若 `hexagramContext.liuYaoChart == nil`，第一轮 user 消息中省略月建/日辰/旬空/动爻块，AI 会基于卦名和卦义回答，system prompt 中已告知 AI 此情况下如何处理。

---

## 八、测试用例

| 用例 | 输入 | 预期输出要点 |
|------|------|------------|
| 基础追问 | "为什么说现在不宜主动？" + 天地否卦 | 引用否卦阴阳不交、世爻状态；不超过 120 字 |
| 时机追问 | "什么时候可以主动？" | 给出具体卦理信号（动爻变化/月建转换），而非"等时机" |
| 趋势追问 | "这段关系后续有转机吗？" | 说明卦中是否有转化迹象，有依据 |
| 超范围追问 | "帮我看下我妈妈的健康" | 温和引回本次卦象，说明需要单独起卦 |
| 第 7 轮追问 | 连续追问 7 次 | 第 7 轮请求中真实对话只保留第 2-7 轮，第 1 轮被截断；但钉住的卦象背景仍在，AI 仍能准确引用卦名、月建、日辰 |
| 排盘缺失 | `liuYaoChart = nil` | AI 明确表示"仅从卦名卦义分析"，不编造月建日辰 |

---

## 九、版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| V1.0 | 2026-09-23 | 初版，对应 V3.1 迭代 |
