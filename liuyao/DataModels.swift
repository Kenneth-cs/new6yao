import Foundation
import CoreData
import SwiftUI

// MARK: - Core Data Stack
class PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 添加一些预览数据
        let sampleRecord = DivinationRecord(context: viewContext)
        sampleRecord.id = UUID()
        sampleRecord.question = "我和他之间还有未来吗？"
        sampleRecord.tossResults = [true, false, true, false, true, false]
        sampleRecord.aiInterpretation = "根据卦象显示..."
        sampleRecord.advice = "建议您..."
        sampleRecord.createdAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DivinationModel")
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// MARK: - Core Data Entity Extensions
extension DivinationRecord {
    // 删除所有 @NSManaged 属性声明和 fetchRequest 方法
    // 因为 Codegen = Class Definition 会自动生成这些
    
    // 便利属性
    var tossResults: [Bool] {
        get {
            guard let data = tossResultsData else { return [] }
            return (try? JSONDecoder().decode([Bool].self, from: data)) ?? []
        }
        set {
            tossResultsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var formattedDate: String {
        guard let date = createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var yaoLines: [YaoXiang] {
        get {
            if let data = yaoLinesData,
               let lines = try? JSONDecoder().decode([YaoXiang].self, from: data),
               !lines.isEmpty {
                return lines
            }
            return tossResults.map { $0 ? .youngYang : .youngYin }
        }
        set {
            yaoLinesData = try? JSONEncoder().encode(newValue)
        }
    }

    var liuYaoChart: LiuYaoReading? {
        get {
            guard let data = chartJSON else { return nil }
            return try? JSONDecoder().decode(LiuYaoReading.self, from: data)
        }
        set {
            chartJSON = try? JSONEncoder().encode(newValue)
        }
    }

    var hexagramDisplay: String {
        yaoLines.map(\.shortLabel).joined(separator: " ")
    }

    var modeBadgeTitle: String? {
        guard let raw = interpretationMode, let mode = InterpretationMode(rawValue: raw) else { return nil }
        return mode.badgeTitle
    }

    var followUpSuggestions: [String] {
        get {
            guard let data = followUpSuggestionsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            followUpSuggestionsData = newValue.isEmpty ? nil : (try? JSONEncoder().encode(newValue))
        }
    }

    var resolvedCastTime: Date {
        castTime ?? createdAt ?? Date()
    }

    var resolvedHexagram: (name: String, description: String) {
        let binary = tossResults.map { $0 ? "1" : "0" }.joined()
        return HexagramData.getHexagram(for: binary)
    }

    var resolvedChart: LiuYaoReading? {
        if let chart = liuYaoChart { return chart }
        let lines = yaoLines
        guard lines.count == 6 else { return nil }
        let bits = lines.map { $0.isYang ? "1" : "0" }.joined()
        var moving: [Int: String] = [:]
        for (index, line) in lines.enumerated() where line.isMoving {
            moving[index + 1] = line.rawValue
        }
        let resolved = QuestionCategoryResolver.resolve(question: question ?? "", hint: nil)
        return LiuYaoEngine.buildReading(
            bits: bits,
            moving: moving,
            date: resolvedCastTime,
            category: resolved.category,
            question: question ?? "",
            location: locationName
        )
    }

    var deductionReport: DeductionReport? {
        get {
            guard let deductionReportJSON else { return nil }
            return try? JSONDecoder().decode(DeductionReport.self, from: Data(deductionReportJSON.utf8))
        }
        set {
            deductionReportJSON = newValue.flatMap { report in
                (try? JSONEncoder().encode(report)).flatMap { String(data: $0, encoding: .utf8) }
            }
        }
    }

    var latestFollowUpSession: FollowUpSession? {
        let sessions = followUpSessions as? Set<FollowUpSession> ?? []
        return sessions.max { ($0.updatedAt ?? .distantPast) < ($1.updatedAt ?? .distantPast) }
    }
    
    // 获取准确度评分
    var accuracyRating: Int {
        return Int(feedback?.rating ?? 0)
    }
    
    // 是否有反馈
    var hasFeedback: Bool {
        return feedback != nil
    }
}

// MARK: - FollowUpSession
extension FollowUpSession {
    var messages: [FollowUpChatMessage] {
        get {
            guard let data = messagesJSON else { return [] }
            return (try? JSONDecoder().decode([FollowUpChatMessage].self, from: data)) ?? []
        }
        set {
            messagesJSON = try? JSONEncoder().encode(newValue)
            let turns = newValue.filter { $0.role == .user }.count
            totalTurns = Int16(clamping: turns)
        }
    }
}

// MARK: - FeedbackRecord Extensions
extension FeedbackRecord {
    var formattedDate: String {
        guard let date = createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var ratingStars: String {
        return String(repeating: "⭐", count: Int(rating))
    }
}

// 删除 Identifiable 扩展，因为自动生成的代码已经包含了

/// 把当前解卦结果页写成一条历史所需的内容。推演和追问在结果还没保存时，用它补建同一条记录。
struct DivinationArchiveDraft {
    let question: String
    let tossResults: [Bool]
    let aiInterpretation: String
    let advice: String
    let castTime: Date
    let mode: InterpretationMode?
    let chart: LiuYaoReading?
    let yaoLines: [YaoXiang]
    let category: String?
    let categorySource: CategorySource?
    let locationName: String?
    let oneSentenceConclusion: String?
    let followUpSuggestions: [String]
}

// MARK: - Data Service
class DataService: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
    }
    
    @discardableResult
    func saveDivinationRecord(
        question: String,
        tossResults: [Bool],
        aiInterpretation: String,
        advice: String,
        castTime: Date? = nil,
        mode: InterpretationMode? = nil,
        chart: LiuYaoReading? = nil,
        yaoLines: [YaoXiang]? = nil,
        category: String? = nil,
        categorySource: CategorySource? = nil,
        locationName: String? = nil,
        oneSentenceConclusion: String? = nil,
        followUpSuggestions: [String] = []
    ) -> DivinationRecord? {
        guard PermissionManager.shared.canSaveMoreRecords() else {
            print("历史记录已达上限，未写入新记录")
            return nil
        }
        let record = DivinationRecord(context: viewContext)
        record.id = UUID()
        record.question = question
        record.tossResults = tossResults
        record.aiInterpretation = aiInterpretation
        record.advice = advice
        record.createdAt = Date()
        record.castTime = castTime
        record.interpretationMode = mode?.rawValue
        record.engineCategory = category ?? "unclassified"
        record.categorySource = categorySource?.rawValue
        record.locationName = locationName
        record.oneSentenceConclusion = oneSentenceConclusion
        record.followUpSuggestions = followUpSuggestions
        if let yaoLines {
            record.yaoLines = yaoLines
        }
        record.liuYaoChart = chart
        
        do {
            try viewContext.save()
            PermissionManager.shared.syncHistoryRecordCount()
            print("问卦记录保存成功")
            return record
        } catch {
            print("保存失败: \(error)")
            return nil
        }
    }

    /// 已有记录就沿用；还没有时按当前页内容新建一条。不改动记录上已有的推演和追问。
    @discardableResult
    func ensureDivinationArchive(
        existing: DivinationRecord?,
        draft: DivinationArchiveDraft?
    ) -> DivinationRecord? {
        if let existing { return existing }
        guard let draft else { return nil }
        return saveDivinationRecord(
            question: draft.question,
            tossResults: draft.tossResults,
            aiInterpretation: draft.aiInterpretation,
            advice: draft.advice,
            castTime: draft.castTime,
            mode: draft.mode,
            chart: draft.chart,
            yaoLines: draft.yaoLines,
            category: draft.category,
            categorySource: draft.categorySource,
            locationName: draft.locationName,
            oneSentenceConclusion: draft.oneSentenceConclusion,
            followUpSuggestions: draft.followUpSuggestions
        )
    }

    @discardableResult
    func createFollowUpSession(for record: DivinationRecord?) -> FollowUpSession {
        let session = FollowUpSession(context: viewContext)
        session.id = UUID()
        let now = Date()
        session.createdAt = now
        session.updatedAt = now
        session.totalTurns = 0
        session.messagesJSON = try? JSONEncoder().encode([FollowUpChatMessage]())
        session.divinationRecord = record
        saveContext(action: "创建追问会话")
        return session
    }

    func saveFollowUpMessages(_ messages: [FollowUpChatMessage], to session: FollowUpSession) {
        session.messages = messages
        session.updatedAt = Date()
        saveContext(action: "保存追问消息")
    }

    func fetchFollowUpSession(for record: DivinationRecord) -> FollowUpSession? {
        record.latestFollowUpSession
    }

    func attach(_ session: FollowUpSession, to record: DivinationRecord) {
        session.divinationRecord = record
        saveContext(action: "关联追问会话")
    }

    @discardableResult
    func saveDeductionReport(_ report: DeductionReport, for record: DivinationRecord?) -> Bool {
        guard let record else { return false }
        record.deductionReport = report
        do {
            try viewContext.save()
            return true
        } catch {
            print("保存推演报告失败: \(error)")
            return false
        }
    }

    private func saveContext(action: String) {
        do {
            try viewContext.save()
        } catch {
            print("\(action)失败: \(error)")
        }
    }
    
    func saveFeedback(
        for divinationRecord: DivinationRecord,
        rating: Int,
        feedback: String?
    ) {
        let feedbackRecord = FeedbackRecord(context: viewContext)
        feedbackRecord.id = UUID()
        feedbackRecord.rating = Int16(rating)
        feedbackRecord.feedback = feedback
        feedbackRecord.createdAt = Date()
        feedbackRecord.divination = divinationRecord
        
        do {
            try viewContext.save()
            print("反馈保存成功")
        } catch {
            print("反馈保存失败: \(error)")
        }
    }
    
    func saveFeedback(
        for divinationId: UUID,
        rating: Int,
        feedback: String?
    ) {
        let request: NSFetchRequest<DivinationRecord> = DivinationRecord.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", divinationId as CVarArg)
        
        do {
            let records = try viewContext.fetch(request)
            if let record = records.first {
                saveFeedback(for: record, rating: rating, feedback: feedback)
            }
        } catch {
            print("查找问卦记录失败: \(error)")
        }
    }
    
    func fetchAllRecords() -> [DivinationRecord] {
        let request: NSFetchRequest<DivinationRecord> = DivinationRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DivinationRecord.createdAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("获取记录失败: \(error)")
            return []
        }
    }
    
    func deleteRecord(_ record: DivinationRecord) {
        viewContext.delete(record)
        
        do {
            try viewContext.save()
            PermissionManager.shared.syncHistoryRecordCount()
            print("记录删除成功")
        } catch {
            print("删除失败: \(error)")
        }
    }
}