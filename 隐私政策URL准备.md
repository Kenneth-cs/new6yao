# 🔒 隐私政策URL准备指南

**重要性**：⭐⭐⭐⭐⭐（必需）  
**App Store审核要求**：必须提供可公开访问的隐私政策URL

---

## 🎯 问题

App Store Connect要求提供隐私政策URL，但你的隐私政策目前只在App内显示。

**需要：** 将隐私政策发布到一个公开可访问的网址

---

## 📝 解决方案

### 方案1：使用GitHub Pages（推荐，免费）

**优点：**
- ✅ 完全免费
- ✅ 简单快速
- ✅ 可靠稳定
- ✅ 支持HTTPS

**步骤：**

**1. 创建HTML文件**

在项目根目录创建 `privacy-policy.html`：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>隐私政策 - 人生教练</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        h1 {
            color: #7C3AED;
            border-bottom: 2px solid #7C3AED;
            padding-bottom: 10px;
        }
        h2 {
            color: #5B21B6;
            margin-top: 30px;
        }
        h3 {
            color: #6D28D9;
        }
        .last-updated {
            color: #666;
            font-style: italic;
        }
        ul {
            padding-left: 20px;
        }
        li {
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <h1>隐私政策</h1>
    <p class="last-updated">最后更新：2025年12月</p>

    <h2>1. 引言</h2>
    <p>欢迎使用人生教练！我们深知您的隐私对您的重要性，因此我们制定了本隐私政策，以透明的方式向您说明我们如何收集、使用、存储和保护您的个人信息。</p>
    
    <h2>2. 信息收集</h2>
    
    <h3>2.1 我们收集的信息</h3>
    <ul>
        <li><strong>位置信息</strong>：仅收集您的城市级别位置信息，用于提供基于时空的决策分析参考。我们不会收集或存储您的精确位置坐标。</li>
        <li><strong>使用数据</strong>：为了提供更好的服务，我们会记录您的决策分析记录、SWOT分析记录和决策矩阵记录。这些数据完全存储在您的设备本地。</li>
        <li><strong>订阅信息</strong>：如果您订阅了专业版，我们会通过Apple的StoreKit记录您的订阅状态，用于提供相应的服务权限。</li>
    </ul>

    <h3>2.2 我们不收集的信息</h3>
    <ul>
        <li>不收集您的姓名、身份证号、电话号码等个人身份信息</li>
        <li>不收集您的精确位置坐标（GPS坐标）</li>
        <li>不收集您的通讯录、相册等敏感权限</li>
        <li>不收集您的设备标识符（IDFA）</li>
        <li>不收集您的浏览历史或其他App使用数据</li>
    </ul>

    <h2>3. 信息使用</h2>
    
    <p>我们使用收集的信息用于以下目的：</p>
    <ul>
        <li><strong>提供服务</strong>：使用位置信息提供基于时空的决策分析</li>
        <li><strong>改进服务</strong>：分析使用模式以优化App功能和用户体验</li>
        <li><strong>权限管理</strong>：根据您的订阅状态提供相应的功能权限</li>
        <li><strong>用户支持</strong>：响应您的反馈和技术支持请求</li>
    </ul>

    <h2>4. 信息存储</h2>
    
    <h3>4.1 本地存储</h3>
    <p>您的所有决策记录、分析结果和个人偏好设置都存储在您的设备本地，使用Apple提供的Core Data框架。这些数据不会上传到我们的服务器。</p>

    <h3>4.2 服务器存储</h3>
    <p>我们不在自己的服务器上存储您的个人数据。唯一涉及服务器的通信是：</p>
    <ul>
        <li><strong>AI分析服务</strong>：当您使用决策分析、SWOT分析或决策矩阵时，我们会将您的问题和输入发送到AI服务提供商（DeepSeek）进行分析。这些数据仅用于生成分析结果，不会被永久存储。</li>
        <li><strong>订阅验证</strong>：通过Apple的服务器验证您的订阅状态。</li>
    </ul>

    <h2>5. 信息共享</h2>
    
    <p>我们不会向第三方出售、出租或以其他方式披露您的个人信息，除非：</p>
    <ul>
        <li><strong>经您同意</strong>：在获得您明确同意的情况下</li>
        <li><strong>法律要求</strong>：根据法律法规、法律程序、诉讼或政府主管部门强制性要求</li>
        <li><strong>服务提供商</strong>：与AI服务提供商（DeepSeek）共享必要信息以提供分析服务。这些服务提供商受到严格的保密协议约束</li>
    </ul>

    <h2>6. 信息安全</h2>
    
    <p>我们采取合理的安全措施保护您的信息：</p>
    <ul>
        <li>使用Apple提供的安全存储机制（Core Data、UserDefaults）</li>
        <li>通过HTTPS加密传输与服务器的通信</li>
        <li>不在我们的服务器上存储敏感信息</li>
        <li>遵守Apple的安全最佳实践</li>
    </ul>

    <h2>7. 您的权利</h2>
    
    <h3>7.1 访问和控制</h3>
    <p>您对自己的信息拥有以下权利：</p>
    <ul>
        <li><strong>访问权</strong>：您可以随时在App内查看您的决策记录和分析历史</li>
        <li><strong>删除权</strong>：您可以在App内删除任何决策记录</li>
        <li><strong>拒绝权</strong>：您可以拒绝提供位置信息，虽然这可能影响某些功能的使用</li>
        <li><strong>数据导出</strong>：专业版用户可以导出自己的数据（即将推出）</li>
    </ul>

    <h3>7.2 删除账户</h3>
    <p>如果您希望完全删除您的数据：</p>
    <ul>
        <li>在设备上卸载App即可删除所有本地存储的数据</li>
        <li>通过App Store管理您的订阅</li>
    </ul>

    <h2>8. 儿童隐私</h2>
    
    <p>我们的App适用于4岁及以上用户。我们不会故意收集13岁以下儿童的个人信息。如果您发现我们无意中收集了儿童的个人信息，请联系我们，我们将立即删除。</p>

    <h2>9. 第三方服务</h2>
    
    <h3>9.1 AI服务（DeepSeek）</h3>
    <ul>
        <li><strong>用途</strong>：提供决策分析、SWOT分析和决策矩阵的AI解读</li>
        <li><strong>数据</strong>：仅发送您输入的问题和选项</li>
        <li><strong>隐私</strong>：DeepSeek有自己的隐私政策，建议您查阅</li>
    </ul>

    <h3>9.2 订阅服务（Apple）</h3>
    <ul>
        <li><strong>用途</strong>：处理应用内购买和订阅</li>
        <li><strong>隐私</strong>：Apple有严格的隐私保护标准，不会向我们披露您的支付信息</li>
    </ul>

    <h2>10. 定位权限说明</h2>
    
    <p>我们使用定位服务的目的和方式：</p>
    <ul>
        <li><strong>权限类型</strong>：使用时定位（When In Use）</li>
        <li><strong>精度</strong>：仅获取城市级别位置（如"北京市"），不获取精确坐标</li>
        <li><strong>用途</strong>：为决策分析提供时空参考因素</li>
        <li><strong>缓存</strong>：成功定位后会缓存24小时，避免频繁请求</li>
        <li><strong>可选性</strong>：您可以拒绝定位权限，不影响核心功能使用</li>
    </ul>

    <h2>11. 数据保留</h2>
    
    <ul>
        <li><strong>决策记录</strong>：永久保留在您的设备上，直到您主动删除或卸载App</li>
        <li><strong>位置缓存</strong>：在设备本地保留24小时后自动失效</li>
        <li><strong>订阅状态</strong>：由Apple管理，我们仅在需要时查询</li>
        <li><strong>AI分析</strong>：不在服务器上永久保留</li>
    </ul>

    <h2>12. 国际数据传输</h2>
    
    <p>由于我们使用的AI服务可能部署在不同国家和地区，您的数据可能会被传输到中国境外。我们会采取适当措施确保您的数据得到与本隐私政策相同水平的保护。</p>

    <h2>13. 隐私政策更新</h2>
    
    <p>我们可能会不时更新本隐私政策。更新后，我们会：</p>
    <ul>
        <li>更新"最后更新"日期</li>
        <li>在App内发布新版本</li>
        <li>对于重大变更，会通过App内通知或其他方式告知您</li>
    </ul>
    
    <p>建议您定期查看本隐私政策以了解我们如何保护您的信息。</p>

    <h2>14. 联系我们</h2>
    
    <p>如果您对本隐私政策有任何疑问、意见或投诉，或希望行使您的权利，请通过以下方式联系我们：</p>
    <ul>
        <li><strong>App内反馈</strong>：打开App → "我的" → "帮助与反馈"</li>
        <li><strong>电子邮件</strong>：[您的联系邮箱]</li>
    </ul>
    
    <p>我们会在收到您的请求后尽快（通常在30天内）回复。</p>

    <h2>15. 适用法律</h2>
    
    <p>本隐私政策的制定、解释和执行均适用中华人民共和国法律。我们承诺遵守：</p>
    <ul>
        <li>《中华人民共和国网络安全法》</li>
        <li>《中华人民共和国数据安全法》</li>
        <li>《中华人民共和国个人信息保护法》</li>
        <li>《App违法违规收集使用个人信息行为认定方法》</li>
        <li>其他相关法律法规</li>
    </ul>

    <hr>
    
    <p style="text-align: center; color: #666; margin-top: 40px;">
        <strong>人生教练</strong><br>
        您的智能决策助手<br>
        <br>
        版本：1.2<br>
        最后更新：2025年12月2日
    </p>
</body>
</html>
```

**2. 推送到GitHub**

```bash
# 添加文件
git add privacy-policy.html

# 提交
git commit -m "添加隐私政策HTML页面"

# 推送
git push origin main
```

**3. 启用GitHub Pages**

```
1. 访问GitHub仓库页面
2. 点击"Settings"
3. 在左侧菜单找到"Pages"
4. 在"Source"下选择：
   - Branch: main
   - Folder: / (root)
5. 点击"Save"
6. 等待1-2分钟
7. 访问提供的URL，例如：
   https://[你的用户名].github.io/6yao/privacy-policy.html
```

**4. 在App Store Connect中使用**

```
隐私政策URL：
https://[你的用户名].github.io/6yao/privacy-policy.html

例如：
https://zhangsan.github.io/6yao/privacy-policy.html
```

---

### 方案2：使用简单的网页托管服务

**选项A：Netlify（推荐，免费）**
```
1. 访问 https://www.netlify.com
2. 注册账号（可用GitHub登录）
3. 点击"Add new site" → "Deploy manually"
4. 拖拽 privacy-policy.html 文件
5. 自动生成URL，例如：
   https://lifecoach-privacy.netlify.app
```

**选项B：Vercel（免费）**
```
1. 访问 https://vercel.com
2. 注册账号（可用GitHub登录）
3. 导入GitHub仓库或直接上传文件
4. 自动部署并生成URL
```

---

### 方案3：使用自己的域名（高级）

如果你有自己的域名：

```
1. 在域名提供商配置DNS
2. 部署HTML到服务器或GitHub Pages
3. 使用自定义域名，例如：
   https://privacy.lifecoach.com
   https://www.lifecoach.com/privacy
```

---

## ✅ 推荐方案

**最简单：GitHub Pages（免费）**

**步骤总结：**
1. 创建 `privacy-policy.html`（上面提供的内容）
2. 推送到GitHub仓库
3. 启用GitHub Pages
4. 获得URL：`https://[用户名].github.io/6yao/privacy-policy.html`
5. 在App Store Connect中填写这个URL

---

## 🎯 下一步

**立即操作：**

1. **创建HTML文件**
   ```bash
   cd /Users/zhangshaocong6/Desktop/cs/AI/6yao
   # 使用上面提供的HTML内容创建 privacy-policy.html
   ```

2. **推送到GitHub**
   ```bash
   git add privacy-policy.html
   git commit -m "添加隐私政策页面用于App Store审核"
   git push origin main
   ```

3. **启用GitHub Pages**
   - 访问GitHub仓库设置
   - 启用Pages功能
   - 选择main分支，根目录

4. **获取URL**
   - GitHub会提供一个URL
   - 测试URL是否可访问
   - 确认内容显示正确

5. **填写到App Store Connect**
   - 在App信息中找到"隐私政策URL"字段
   - 粘贴GitHub Pages生成的URL
   - 保存

---

## ⚠️ 重要提示

1. **URL必须可公开访问**
   - 不需要登录
   - 不需要VPN
   - 全球可访问

2. **内容必须与App内一致**
   - 建议完全相同
   - 或至少要涵盖所有要点

3. **必须使用HTTPS**
   - GitHub Pages自动提供HTTPS
   - Apple要求必须是安全连接

4. **定期更新**
   - 如果隐私政策有变化
   - 同时更新App内和URL版本

---

## 📝 快速操作指令

如果你想让我帮你创建这个文件，我可以：

1. 创建 `privacy-policy.html` 文件
2. 提供推送到GitHub的命令
3. 帮你验证URL是否可访问

准备好了告诉我！🚀

---

**优先级**：🔥 高（App Store审核必需）  
**预计时间**：10分钟  
**难度**：⭐ 简单

