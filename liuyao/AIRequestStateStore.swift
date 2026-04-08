import Foundation
import UserNotifications
import UIKit

// ============================================================
// MARK: - AI 请求状态 Store
// 解决用户切出 App 等待 AI 响应时的体验问题：
//   - 请求结果在后台到来 → 发本地通知
//   - 用户切回来 → 如果还在进行中显示 loading，已有结果直接渲染
// ============================================================

enum AIRequestStatus: String, Codable {
    case loading, success, failed
}

struct AIRequestSlot: Codable {
    var status: AIRequestStatus
    var result: String          // 完整原始响应 or 错误消息
    var timestamp: Date
    // DivinationResultPageView 三个解析子段
    var hexagramAnalysis: String?
    var questionInterpretation: String?
    var guidanceAdvice: String?
}

final class AIRequestStateStore: ObservableObject {
    static let shared = AIRequestStateStore()

    @Published private(set) var slots: [String: AIRequestSlot] = [:]

    private let ud = UserDefaults.standard
    private let udKey = "AIRequestStateStore.v1"

    private init() {
        loadFromDisk()
    }

    // ── 读 ──────────────────────────────────────────────────
    func slot(for key: String) -> AIRequestSlot? { slots[key] }

    // ── 写 ──────────────────────────────────────────────────

    func markLoading(key: String) {
        let slot = AIRequestSlot(status: .loading, result: "", timestamp: Date())
        update(key: key, slot: slot)
    }

    func markSuccess(
        key: String,
        result: String,
        hexagramAnalysis: String? = nil,
        questionInterpretation: String? = nil,
        guidanceAdvice: String? = nil
    ) {
        let slot = AIRequestSlot(
            status: .success,
            result: result,
            timestamp: Date(),
            hexagramAnalysis: hexagramAnalysis,
            questionInterpretation: questionInterpretation,
            guidanceAdvice: guidanceAdvice
        )
        update(key: key, slot: slot)
        sendNotificationIfBackgrounded(for: key)
    }

    func markFailed(key: String, message: String) {
        let slot = AIRequestSlot(status: .failed, result: message, timestamp: Date())
        update(key: key, slot: slot)
    }

    func clearSlot(key: String) {
        slots.removeValue(forKey: key)
        saveToDisk()
    }

    // ── 清除已推送的 AI 结果通知（App 回到前台时调用）──────────
    func clearDeliveredAINotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifs in
            let ids = notifs
                .filter { $0.request.content.userInfo["type"] as? String == "aiResult" }
                .map(\.request.identifier)
            if !ids.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
            }
        }
    }

    // ── 内部 ────────────────────────────────────────────────

    private func update(key: String, slot: AIRequestSlot) {
        slots[key] = slot
        saveToDisk()
    }

    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(slots) {
            ud.set(data, forKey: udKey)
        }
    }

    private func loadFromDisk() {
        guard let data = ud.data(forKey: udKey),
              var saved = try? JSONDecoder().decode([String: AIRequestSlot].self, from: data) else { return }
        // 超过 5 分钟仍为 loading 的 slot 说明 App 被杀时请求未完成
        // 不删除，改为 failed，让用户看到提示后自行决定是否重新请求
        let cutoff = Date().addingTimeInterval(-5 * 60)
        for key in saved.keys where saved[key]?.status == .loading && (saved[key]?.timestamp ?? Date()) < cutoff {
            saved[key]?.status = .failed
            saved[key]?.result = "上次解读未完成，请点击「重新解读」重试"
        }
        slots = saved
    }

    // ── 后台通知 ─────────────────────────────────────────────

    private func sendNotificationIfBackgrounded(for key: String) {
        // 必须在主线程读取 applicationState
        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState != .active else { return }
            self.scheduleNotification(for: key)
        }
    }

    private func scheduleNotification(for key: String) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            content.title    = self.notifTitle(for: key)
            content.body     = self.notifBody(for: key)
            content.sound    = .default
            content.userInfo = ["type": "aiResult", "key": key]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            let request  = UNNotificationRequest(
                identifier: "aiResult.\(key)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ AI结果通知发送失败: \(error.localizedDescription)")
                } else {
                    print("🔔 AI结果通知已发送: \(self.notifTitle(for: key))")
                }
            }
        }
    }

    private func notifTitle(for key: String) -> String {
        if key.hasPrefix("divination_") { return "解卦完成 ✨" }
        if key.hasPrefix("matrix_")     { return "决策分析完成 🎯" }
        if key.hasPrefix("swot_")       { return "SWOT分析完成 💡" }
        return "AI分析完成"
    }

    private func notifBody(for key: String) -> String {
        if key.hasPrefix("divination_") { return "点击查看您的卦象解读" }
        if key.hasPrefix("matrix_")     { return "点击查看五行决策矩阵结果" }
        if key.hasPrefix("swot_")       { return "点击查看SWOT分析结果" }
        return "点击返回查看结果"
    }
}
