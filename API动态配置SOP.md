# 动态配置与 API Key 维护 SOP (标准作业程序)

## 背景说明

为了防止火山方舟 (Volcengine) 的 API 节点下线或 API Key 变更导致线上 App 罢工（AI 解读失败），我们在 App 中引入了基于苹果 CloudKit 的**动态配置方案**。

通过此方案，当我们需要更换大模型 API Key 或接入点 (Endpoint) 时，**无需修改代码、无需重新打包、无需等待苹果审核**，只需在网页端修改配置，用户的 App 在下次冷启动时即可自动生效。

---

## 触发场景

当遇到以下情况时，需要执行本 SOP：
1. 火山方舟后台提示当前使用的接入点（Endpoint）已下线或即将下线。
2. 发现 API Key 泄露，需要在火山方舟后台废弃旧 Key 并生成新 Key。
3. 线上 App 突然出现大面积的 AI 解读失败（如 404, 401, 429 等错误），且排查确认为节点或 Key 的问题。

---

## 操作步骤

### 第一步：在火山方舟获取新配置

1. 登录 [火山引擎控制台](https://console.volcengine.com/)。
2. 进入 **火山方舟 (大模型服务平台)**。
3. **获取新接入点 (Endpoint)**：
   - 左侧菜单 -> **在线推理** -> **接入点管理**。
   - 点击“创建接入点”，选择需要的模型（如 DeepSeek-V3），计费模式选择“按量计费”。
   - 创建成功后，复制以 `ep-` 开头的接入点名称（例如：`ep-20260516120006-f9pqw`）。
4. **获取新 API Key**（如需）：
   - 左侧菜单 -> **API Key 管理**。
   - 点击“创建 API Key”，复制新生成的 Key（例如：`ark-0ca54154...`）。
   - **安全提示**：记得将旧的/泄露的 API Key 禁用或删除。

### 第二步：在苹果 CloudKit 更新动态配置

1. 登录苹果开发者 CloudKit 控制台：[CloudKit Console](https://icloud.developer.apple.com/)。
2. 在左侧边栏选择对应的容器：`iCloud.com.cs.liuyao`。
3. **切换到生产环境**：
   - 确保网页左上角的下拉菜单选择的是 **Production**（生产环境），而不是 Development。
4. **查找配置记录**：
   - 左侧菜单 -> **Data** -> **Records**。
   - 确保 Database 选为 **Public Database**。
   - 在 `Record Type` 处输入或选择 **`AppConfig`**。
   - 在搜索框中直接输入 `AIConfig`，或者点击右侧的 `Query Records` 按钮（如果提示 `Type is not marked indexable` 忽略即可，直接在左侧列表找或者新建）。
   - 找到 `Record Name` 为 **`AIConfig`** 的那条记录并点击它。
5. **更新数据**：
   - 在右侧弹出的详情面板中，找到 `Fields` 区域。
   - 将 `apiKey` 字段的值替换为第一步获取的**新 API Key**。
   - 将 `modelEndpoint` 字段的值替换为第一步获取的**新接入点名称**。
6. **保存生效**：
   - 点击右下角的 **Save** 按钮。

### 第三步：验证生效

1. 拿出安装了线上版本（TestFlight 或 App Store 版）的手机。
2. 将 App 从后台彻底杀掉（向上滑动关闭）。
3. 重新打开 App。
4. 进行一次算卦或 AI 解读操作。
5. 如果能正常返回解读结果，说明动态配置已成功下发并生效。

---

## 常见问题 (FAQ)

**Q1: 为什么我在 CloudKit 里点 Query Records 报错 `Type is not marked indexable: AppConfig`？**
A: 这是正常现象。因为我们没有给该表设置查询索引。代码中是通过精确的 Record ID (`AIConfig`) 直接拉取数据的，不需要索引。只要确保记录存在且字段名拼写正确即可。

**Q2: 如果用户在无网环境下打开 App，或者 CloudKit 服务器宕机怎么办？**
A: App 内部代码 (`ConfigManager.swift`) 包含了一套“兜底配置”。如果拉取 CloudKit 失败，App 会自动使用随包打包时的默认 Key 和 Endpoint，确保 App 不会崩溃。

**Q3: 我在 Development 环境改了，为什么线上 App 没变化？**
A: 线上 App 强制读取的是 **Production** 环境的数据。请确保你在 CloudKit 控制台左上角切换到了 Production 环境进行修改。