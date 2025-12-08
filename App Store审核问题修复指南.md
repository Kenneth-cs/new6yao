# App Store审核问题修复指南

## 📋 问题描述

苹果审核拒绝原因：
```
Guideline 3.1.2 - Business - Payments - Subscriptions

缺少用户协议(Terms of Use/EULA)链接
```

## ✅ 已完成的工作

1. ✅ 创建用户协议页面 (`terms.html`)
2. ✅ 创建隐私政策页面 (`privacy.html`)
3. ✅ 创建导航页面 (`index.html`)
4. ✅ 上传到GitHub Pages

## 🔗 你的链接地址

### 主页（导航页）
```
https://zhangshaocong6.github.io/6yao/
```

### 隐私政策
```
https://zhangshaocong6.github.io/6yao/privacy.html
```

### 用户协议（EULA）
```
https://zhangshaocong6.github.io/6yao/terms.html
```

---

## 🚀 操作步骤

### 步骤1：验证链接可用性（5分钟后）

等待5-10分钟，GitHub Pages需要时间部署。然后在浏览器中打开以下链接验证：

1. **主页**: https://zhangshaocong6.github.io/6yao/
2. **隐私政策**: https://zhangshaocong6.github.io/6yao/privacy.html
3. **用户协议**: https://zhangshaocong6.github.io/6yao/terms.html

✅ 确保三个页面都能正常访问

---

### 步骤2：在App Store Connect中添加链接

#### 2.1 登录App Store Connect

1. 访问：https://appstoreconnect.apple.com
2. 登录你的Apple开发者账号
3. 点击"我的App"
4. 选择"六爻"应用

---

#### 2.2 添加隐私政策URL（如果还没添加）

```
位置：App Store Connect → 我的App → 六爻 → App隐私

步骤：
1. 在左侧菜单选择"App隐私"
2. 找到"隐私政策URL"字段
3. 输入：https://zhangshaocong6.github.io/6yao/privacy.html
4. 点击"保存"
```

---

#### 2.3 添加用户协议（EULA）⭐ 关键步骤

有**两种方式**添加EULA，选择其中一种即可：

##### 方式1：在App描述中添加链接（推荐，简单）

```
位置：App Store Connect → 我的App → 六爻 → App信息

步骤：
1. 在左侧菜单选择"App信息"
2. 找到"App Store"部分
3. 在"描述"字段的**末尾**添加以下内容：

用户协议：https://zhangshaocong6.github.io/6yao/terms.html
隐私政策：https://zhangshaocong6.github.io/6yao/privacy.html

4. 点击右上角"保存"
```

**完整描述示例：**
```
【原有描述内容】

六爻是一款基于中国传统周易六爻理论的智能决策工具...
（你原有的描述内容）

---

用户协议：https://zhangshaocong6.github.io/6yao/terms.html
隐私政策：https://zhangshaocong6.github.io/6yao/privacy.html
```

---

##### 方式2：使用自定义EULA（可选）

```
位置：App Store Connect → 我的App → 六爻 → 定价与销售范围

步骤：
1. 在左侧菜单选择"定价与销售范围"
2. 向下滚动找到"最终用户许可协议(EULA)"
3. 选择"自定义最终用户许可协议"
4. 点击"上传新文件"
5. 上传包含用户协议内容的PDF文件

注意：这种方式需要将terms.html转换为PDF格式
```

---

#### 2.4 确认订阅产品配置

```
位置：App Store Connect → 我的App → 六爻 → 订阅

步骤：
1. 在左侧菜单选择"订阅"
2. 检查你的订阅组和产品：
   - 专业版月度订阅（¥30/月）
   - 专业版年度订阅（¥258/年）
   
3. 确认每个订阅产品包含以下信息：
   ✅ 订阅名称
   ✅ 订阅时长
   ✅ 价格
   ✅ 描述
```

---

### 步骤3：重新提交审核

#### 3.1 在App Store Connect中回复审核团队

```
位置：App Store Connect → 我的App → 六爻 → App审核

步骤：
1. 找到审核拒绝的消息
2. 点击"回复"或"解决中心"
3. 输入以下回复内容（中英文均可）：
```

**回复模板（英文）：**
```
Dear App Review Team,

Thank you for your feedback. I have addressed the issue by adding the required Terms of Use (EULA) link.

The Terms of Use is now available at:
https://zhangshaocong6.github.io/6yao/terms.html

I have also added this link to the app description in App Store Connect.

Privacy Policy:
https://zhangshaocong6.github.io/6yao/privacy.html

Both links are functional and accessible. Please review the updated submission.

Thank you for your consideration.

Best regards
```

**回复模板（中文）：**
```
尊敬的审核团队：

感谢您的反馈。我已经解决了缺少用户协议链接的问题。

用户协议现已可用：
https://zhangshaocong6.github.io/6yao/terms.html

我也已经在App Store Connect的应用描述中添加了此链接。

隐私政策：
https://zhangshaocong6.github.io/6yao/privacy.html

两个链接均可正常访问。请重新审核。

谢谢！
```

---

#### 3.2 提交新版本（如果需要）

如果当前版本状态是"被拒绝"：

```
步骤：
1. 在"App Store"标签下
2. 找到被拒绝的版本
3. 点击"将此版本提交以供审核"
4. 回答出口合规性问题（选择"否"）
5. 点击"提交"
```

如果需要上传新版本：
```
1. 使用Xcode重新上传build（版本号需要增加）
2. 在App Store Connect中选择新的build
3. 提交审核
```

---

## 📱 在App内添加链接（可选，但推荐）

为了更好的用户体验，建议在App内也添加这些链接：

### 在ProfilePageView中添加

打开 `liuyao/ProfilePageView.swift`，在"关于"或"设置"部分添加：

```swift
// 在"关于"部分添加
Link(destination: URL(string: "https://zhangshaocong6.github.io/6yao/terms.html")!) {
    HStack {
        Text("用户协议")
        Spacer()
        Image(systemName: "chevron.right")
            .foregroundColor(.gray)
    }
}

Link(destination: URL(string: "https://zhangshaocong6.github.io/6yao/privacy.html")!) {
    HStack {
        Text("隐私政策")
        Spacer()
        Image(systemName: "chevron.right")
            .foregroundColor(.gray)
    }
}
```

---

## ✅ 检查清单

在重新提交审核前，确保：

- [ ] 用户协议链接可以正常访问：https://zhangshaocong6.github.io/6yao/terms.html
- [ ] 隐私政策链接可以正常访问：https://zhangshaocong6.github.io/6yao/privacy.html
- [ ] 在App Store Connect的"App信息" → "描述"中添加了用户协议链接
- [ ] 在App Store Connect的"App隐私"中添加了隐私政策链接
- [ ] 订阅产品配置完整（包含名称、时长、价格）
- [ ] 已回复审核团队的消息
- [ ] 重新提交了审核

---

## 📊 预期审核时间

- **回复后重新审核**：1-3个工作日
- **提交新版本审核**：3-5个工作日

---

## ⚠️ 常见问题

### Q1: 链接打不开怎么办？

**A:** 等待5-10分钟，GitHub Pages需要部署时间。如果还是打不开：
```bash
# 检查GitHub Pages设置
1. 访问：https://github.com/Kenneth-cs/new6yao
2. 点击"Settings" → "Pages"
3. 确认"Source"设置为"Deploy from a branch"
4. 确认"Branch"设置为"main"和"/(root)"
```

### Q2: 是否需要更新App内的代码？

**A:** 
- **最低要求**：不需要，只需在App Store Connect中添加链接即可
- **推荐做法**：在App内也添加链接，提供更好的用户体验

### Q3: 苹果是否会检查用户协议的内容？

**A:** 
- 会的，审核团队会查看用户协议内容
- 已创建的用户协议包含了所有必需信息：
  - ✅ 订阅类型和价格
  - ✅ 自动续费说明
  - ✅ 取消订阅方法
  - ✅ 退款政策
  - ✅ 免责声明

### Q4: 链接是否必须是HTTPS？

**A:** 
- 是的，苹果要求所有外部链接必须使用HTTPS
- GitHub Pages自动提供HTTPS，所以没问题

### Q5: 是否可以使用Apple的标准EULA？

**A:** 
- 可以，但不推荐
- 自定义EULA可以更好地说明订阅细节
- 如果使用Apple标准EULA，需在描述中说明

---

## 📞 需要帮助？

如果遇到问题：

1. **查看苹果官方文档**：
   - [订阅指南](https://developer.apple.com/app-store/subscriptions/)
   - [App Store审核指南](https://developer.apple.com/app-store/review/guidelines/)

2. **联系苹果审核团队**：
   - 在App Store Connect的"解决中心"回复消息
   - 详细说明你的问题

3. **检查配置**：
   - 确保所有链接都可以访问
   - 确保订阅产品配置完整
   - 确保App描述中包含链接

---

## 🎯 快速操作总结

1. **验证链接**（5分钟后）
   - 访问：https://zhangshaocong6.github.io/6yao/terms.html
   - 访问：https://zhangshaocong6.github.io/6yao/privacy.html

2. **添加到App Store Connect**（10分钟）
   - 进入"App信息" → "描述"
   - 在描述末尾添加用户协议和隐私政策链接
   - 保存

3. **回复审核团队**（5分钟）
   - 使用上面提供的回复模板
   - 说明已添加用户协议链接
   - 重新提交审核

4. **等待审核结果**（1-3天）
   - 检查邮件通知
   - 查看App Store Connect状态

---

## 🎉 完成后

审核通过后，你的App将：
- ✅ 符合苹果订阅政策
- ✅ 拥有完整的法律文档
- ✅ 可以正常上架App Store

祝你顺利通过审核！🚀


