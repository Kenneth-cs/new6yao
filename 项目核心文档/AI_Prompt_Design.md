# 五行决策矩阵 AI Prompt 设计方案

## 1. 核心目标
将用户的非结构化决策输入（问题+选项），通过大模型转化为结构化的五行分析报告，用于前端渲染“五步法”决策界面。

## 2. API 调用结构

### 系统角色 (System Prompt)
```markdown
你是一位精通易经五行与现代决策科学的"人生教练"。你的任务是根据用户的【八字命局】和【决策事项】，利用"五行决策矩阵"方法论进行深度分析。
输出必须为严格的 JSON 格式，不要包含 Markdown 代码块标记（```json），直接输出 JSON 字符串。
```

### 用户输入 (User Prompt)
```markdown
# User Context
- 决策问题：[用户输入，例如：买房决策]
- 用户八字喜用：[例如：水、木]
- 用户八字忌神：[例如：土、金]
- 待选方案列表：
  1. [选项A名称 + 描述]
  2. [选项B名称 + 描述]
  (若只有一个选项，则分析该选项的优劣)

# Analysis Requirements (5 Steps)
请严格按照以下步骤分析：

Step 1: 明确核心需求
分析命局在当前场景下的五行需求（补什么、耗什么）。

Step 2: 要素转化标签
提取每个选项的关键要素（方位、数字、颜色、行业等），转化为五行属性。

Step 3: 矩阵评估
对比选项属性与用户喜忌。
- 评分逻辑：喜用(+1.5), 忌神(-1.5), 平和(+0.5)。
- 判定逻辑：触犯核心忌神为"淘汰"，高分且无大忌为"优选"。

Step 4: 落地建议
给出具体的风水布局、行动时机或补救措施。

Step 5: 终极心法
一句高维度的哲学指引。

# Output Data Structure (JSON)
{
  "step1": {
    "title": "明确核心五行需求",
    "summary": "你的八字财多身弱...",
    "needs": [
      {"element": "水", "action": "补水", "desc": "增强智慧与流动性"},
      {"element": "木", "action": "补木", "desc": "提升生发之气"}
    ]
  },
  "step2": {
    "title": "要素转化为五行标签",
    "options": [
      {
        "name": "选项A",
        "attributes": [
          {"factor": "方位", "value": "城北", "element": "水"},
          {"factor": "楼层", "value": "8楼", "element": "木"}
        ]
      }
    ]
  },
  "step3": {
    "title": "矩阵评估结果",
    "evaluations": [
      {
        "optionName": "选项A",
        "score": 8.5,
        "result": "优选",
        "details": [
          {"type": "benefit", "desc": "临湖+朝北 (水旺)", "isMatch": true},
          {"type": "harm", "desc": "无明显忌神", "isMatch": false}
        ]
      }
    ]
  },
  "step4": {
    "title": "落地建议",
    "suggestions": [
      {"category": "楼层", "content": "首选 1, 6, 3, 8 层"},
      {"category": "时机", "content": "避开辰戌丑未月"}
    ]
  },
  "step5": {
    "title": "终极心法",
    "content": "买房不是终点，而是五行调候的开始..."
  }
}
```

## 3. Mock 数据示例 (用于前端开发)

```json
{
  "step1": {
    "title": "明确买房的核心五行需求",
    "summary": "你的八字财多身弱 (土旺木弱)，需通过住房风水调候。",
    "needs": [
      {"element": "水", "action": "补水", "desc": "增强智慧、稳定性"},
      {"element": "木", "action": "补木", "desc": "提升合作运、健康"},
      {"element": "土", "action": "耗土", "desc": "消耗过旺财星，避免贪婪反噬"}
    ]
  },
  "step2": {
    "title": "将买房要素转化为五行标签",
    "options": [
      {
        "name": "城北临湖小区",
        "attributes": [
          {"factor": "地理位置", "value": "近水/城北", "element": "水"},
          {"factor": "楼层", "value": "8楼", "element": "木"},
          {"factor": "户型", "value": "朝东", "element": "木"}
        ]
      },
      {
        "name": "市中心金融区",
        "attributes": [
          {"factor": "地理位置", "value": "金融区", "element": "金"},
          {"factor": "楼层", "value": "25楼", "element": "土"},
          {"factor": "装修", "value": "豪华大理石", "element": "土"}
        ]
      }
    ]
  },
  "step3": {
    "title": "用矩阵评估选项",
    "evaluations": [
      {
        "optionName": "城北临湖小区",
        "score": 9.0,
        "result": "优选",
        "details": [
          {"type": "benefit", "desc": "临湖+朝东 (水木相生)", "isMatch": true},
          {"type": "benefit", "desc": "8楼 (木数) + 绿化高", "isMatch": true},
          {"type": "harm", "desc": "无", "isMatch": false}
        ]
      },
      {
        "optionName": "市中心金融区",
        "score": -2.0,
        "result": "淘汰",
        "details": [
          {"type": "benefit", "desc": "无水属性，朝南耗水", "isMatch": false},
          {"type": "harm", "desc": "豪华装修 (土金旺)", "isMatch": true},
          {"type": "harm", "desc": "土金极旺 (财多身弱大忌)", "isMatch": true}
        ]
      }
    ]
  },
  "step4": {
    "title": "落地建议 (如何买)",
    "suggestions": [
      {"category": "地理位置", "content": "最佳：城市北部(水)或东部(木)，小区名带'霖'、'森'等水木字根。"},
      {"category": "楼层选择", "content": "吉层：1, 6 (水), 3, 8 (木)。忌层：5, 10, 4, 9。"},
      {"category": "财务策略", "content": "首付比例 30%-40% (土为财，过度杠杆易反噬)。"}
    ]
  },
  "step5": {
    "title": "终极心法",
    "content": "买房不是终点，而是五行调候的开始。入住后建议每年捐1%房款给环保组织(耗土生水)。"
  }
}
```
