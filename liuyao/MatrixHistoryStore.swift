import Foundation
import SwiftUI

// ============================================================
// MARK: - 五行决策历史记录模型
// ============================================================
struct MatrixDecisionRecord: Codable, Identifiable {
    let id:               UUID
    let date:             Date
    let scenario:         String   // 场景名，如"事业/学业"
    let scenarioIcon:     String   // SF Symbol，如"graduationcap.fill"
    let question:         String   // 决策问题（可为空）
    let options:          [String] // 选项列表
    let verdict:          String   // 总评，如"优选选项A"
    let recommendedName:  String   // 推荐选项名，如"选项A"
    let score:            Int      // 推荐选项分数 0~100
    let verdictLabel:     String   // 大吉/小吉/平/小凶/大凶
    let fullResult:       DecisionMatrixResultV2?  // 完整报告（旧记录为 nil）

    /// 吉凶颜色（用于 UI 展示）
    var verdictColor: Color {
        switch verdictLabel {
        case "大吉": return Color(red: 0.020, green: 0.588, blue: 0.412)
        case "小吉": return Color(red: 0.306, green: 0.275, blue: 0.898)
        case "平":   return Color.secondary
        case "小凶": return Color(red: 0.855, green: 0.537, blue: 0.145)
        case "大凶": return Color(red: 0.863, green: 0.196, blue: 0.196)
        default:     return Color.secondary
        }
    }
}

// ============================================================
// MARK: - 历史记录持久化（UserDefaults + JSON）
// ============================================================
final class MatrixHistoryStore: ObservableObject {
    static let shared = MatrixHistoryStore()
    private init() {}

    private let ud      = UserDefaults.standard
    private let key     = "matrix_decision_history"

    // ── 读 ──────────────────────────────────────────────────
    func loadAll() -> [MatrixDecisionRecord] {
        guard let data = ud.data(forKey: key),
              let records = try? JSONDecoder().decode([MatrixDecisionRecord].self, from: data)
        else { return [] }
        return records
    }

    // ── 写（含条数限制）─────────────────────────────────────
    /// 保存一条新记录，自动按订阅层级裁剪条数
    func save(_ record: MatrixDecisionRecord) {
        var records = loadAll()
        records.insert(record, at: 0)          // 最新的放最前

        let maxCount = PermissionManager.shared.currentTier.isPro ? Int.max : 3
        if records.count > maxCount {
            records = Array(records.prefix(maxCount))
        }

        persist(records)
        objectWillChange.send()
    }

    // ── 删 ──────────────────────────────────────────────────
    func delete(id: UUID) {
        var records = loadAll()
        records.removeAll { $0.id == id }
        persist(records)
        objectWillChange.send()
    }

    /// 会员升级后调用：取消 3 条限制（保留已有的不删）
    func onProUpgraded() {
        // 已有记录保留，只是后续不再裁剪
        objectWillChange.send()
    }

    // ── 内部 ────────────────────────────────────────────────
    private func persist(_ records: [MatrixDecisionRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            ud.set(data, forKey: key)
        }
    }
}

// ============================================================
// MARK: - 从 DecisionMatrixResultV2 + 场景信息快速构建记录
// ============================================================
extension MatrixDecisionRecord {
    init(scenario: DecisionScenario?, question: String,
         options: [String], result: DecisionMatrixResultV2) {
        let winner = result.recommendedOption
        self.id              = UUID()
        self.date            = Date()
        self.scenario        = scenario?.name ?? "通用决策"
        self.scenarioIcon    = scenario?.icon ?? "sparkles"
        self.question        = question
        self.options         = options
        self.verdict         = result.verdict
        self.recommendedName = winner?.name ?? (options.first ?? "—")
        self.score           = winner?.score ?? 0
        self.verdictLabel    = winner?.verdict ?? "—"
        self.fullResult      = result  // 保存完整报告供历史回顾
    }
}
