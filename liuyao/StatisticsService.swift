import Foundation
import CoreData
import SwiftUI

// MARK: - 问题类型数据模型
struct QuestionTypeData {
    let type: String
    let count: Int
    let percentage: Double
}

// MARK: - 准确度反馈数据模型
struct AccuracyFeedback {
    let id: UUID
    let divinationId: UUID
    let rating: Int // 1-5 星级评分
    let feedback: String?
    let createdAt: Date
}

// MARK: - 统计服务类（单例模式）
class StatisticsService: ObservableObject {
    static let shared = StatisticsService()
    
    @Published var totalDivinations: Int = 0
    @Published var monthlyDivinations: Int = 0
    @Published var averageAccuracy: Double = 0.0
    @Published var consecutiveDays: Int = 0
    @Published var questionTypes: [QuestionTypeData] = []
    @Published var accuracyFeedbacks: [AccuracyFeedback] = []
    
    private init() {}
    
    // MARK: - 加载统计数据
    func loadStatistics(context: NSManagedObjectContext) {
        loadDivinationStatistics(context: context)
        loadQuestionTypeAnalysis(context: context)
        loadAccuracyFeedbacks(context: context)
        calculateConsecutiveDays(context: context)
    }
    
    // MARK: - 加载问卦统计
    private func loadDivinationStatistics(context: NSManagedObjectContext) {
        let request: NSFetchRequest<DivinationRecord> = DivinationRecord.fetchRequest()
        
        do {
            let records = try context.fetch(request)
            
            // 总问卦次数
            totalDivinations = records.count
            
            // 本月问卦次数
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            
            monthlyDivinations = records.filter { record in
                guard let createdAt = record.createdAt else { return false }
                return createdAt >= startOfMonth
            }.count
            
        } catch {
            print("加载问卦统计失败: \(error)")
        }
    }
    
    // MARK: - 加载问题类型分析
    private func loadQuestionTypeAnalysis(context: NSManagedObjectContext) {
        let request: NSFetchRequest<DivinationRecord> = DivinationRecord.fetchRequest()
        
        do {
            let records = try context.fetch(request)
            
            // 统计各类型问题数量
            var typeCounts: [String: Int] = [:]
            
            for record in records {
                let questionType = categorizeQuestion(record.question ?? "")
                typeCounts[questionType, default: 0] += 1
            }
            
            // 计算百分比并排序
            let total = records.count
            questionTypes = typeCounts.map { (type, count) in
                QuestionTypeData(
                    type: type,
                    count: count,
                    percentage: total > 0 ? Double(count) / Double(total) : 0.0
                )
            }.sorted { $0.count > $1.count }
            
        } catch {
            print("加载问题类型分析失败: \(error)")
        }
    }
    
    // MARK: - 问题分类逻辑
    private func categorizeQuestion(_ question: String) -> String {
        let lowerQuestion = question.lowercased()
        
        // 感情类关键词
        let loveKeywords = ["感情", "爱情", "恋爱", "结婚", "分手", "复合", "喜欢", "男友", "女友", "老公", "老婆", "夫妻"]
        if loveKeywords.contains(where: { lowerQuestion.contains($0) }) {
            return "感情婚姻"
        }
        
        // 事业类关键词
        let careerKeywords = ["工作", "事业", "职业", "升职", "跳槽", "创业", "生意", "公司", "老板", "同事", "面试"]
        if careerKeywords.contains(where: { lowerQuestion.contains($0) }) {
            return "事业工作"
        }
        
        // 财运类关键词
        let wealthKeywords = ["财运", "赚钱", "投资", "股票", "理财", "收入", "财富", "金钱", "经济", "买房", "买车"]
        if wealthKeywords.contains(where: { lowerQuestion.contains($0) }) {
            return "财运投资"
        }
        
        // 健康类关键词
        let healthKeywords = ["健康", "身体", "疾病", "病情", "医院", "治疗", "康复", "养生", "锻炼"]
        if healthKeywords.contains(where: { lowerQuestion.contains($0) }) {
            return "健康养生"
        }
        
        // 学业类关键词
        let studyKeywords = ["学习", "考试", "升学", "学校", "成绩", "毕业", "留学", "培训", "技能"]
        if studyKeywords.contains(where: { lowerQuestion.contains($0) }) {
            return "学业考试"
        }
        
        // 家庭类关键词
        let familyKeywords = ["家庭", "父母", "孩子", "子女", "亲情", "家人", "搬家", "装修"]
        if familyKeywords.contains(where: { lowerQuestion.contains($0) }) {
            return "家庭亲情"
        }
        
        return "其他问题"
    }
    
    // MARK: - 加载准确度反馈
    private func loadAccuracyFeedbacks(context: NSManagedObjectContext) {
        let request: NSFetchRequest<FeedbackRecord> = FeedbackRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FeedbackRecord.createdAt, ascending: false)]
        
        do {
            let feedbackRecords = try context.fetch(request)
            
            // 转换为AccuracyFeedback模型
            accuracyFeedbacks = feedbackRecords.compactMap { record in
                guard let id = record.id,
                      let divinationId = record.divination?.id,
                      let createdAt = record.createdAt else {
                    return nil
                }
                
                return AccuracyFeedback(
                    id: id,
                    divinationId: divinationId,
                    rating: Int(record.rating),
                    feedback: record.feedback,
                    createdAt: createdAt
                )
            }
            
            // 计算平均准确度
            if !accuracyFeedbacks.isEmpty {
                let totalRating = accuracyFeedbacks.reduce(0) { $0 + $1.rating }
                averageAccuracy = Double(totalRating) / Double(accuracyFeedbacks.count) / 5.0
            } else {
                // 如果没有反馈数据，使用默认值
                averageAccuracy = 0.0
            }
            
        } catch {
            print("加载准确度反馈失败: \(error)")
            accuracyFeedbacks = []
            averageAccuracy = 0.0
        }
    }
    
    // MARK: - 计算连续使用天数
    private func calculateConsecutiveDays(context: NSManagedObjectContext) {
        let request: NSFetchRequest<DivinationRecord> = DivinationRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DivinationRecord.createdAt, ascending: false)]
        
        do {
            let records = try context.fetch(request)
            
            guard !records.isEmpty else {
                consecutiveDays = 0
                return
            }
            
            let calendar = Calendar.current
            var currentDate = calendar.startOfDay(for: Date())
            var days = 0
            
            // 检查是否今天有记录
            if let latestRecord = records.first,
               let latestDate = latestRecord.createdAt,
               calendar.isDate(latestDate, inSameDayAs: currentDate) {
                days = 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            }
            
            // 向前检查连续天数
            for record in records.dropFirst() {
                guard let recordDate = record.createdAt else { continue }
                let recordDay = calendar.startOfDay(for: recordDate)
                
                if calendar.isDate(recordDay, inSameDayAs: currentDate) {
                    days += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else if recordDay < currentDate {
                    break
                }
            }
            
            consecutiveDays = days
            
        } catch {
            print("计算连续天数失败: \(error)")
            consecutiveDays = 0
        }
    }
    
    // MARK: - 添加准确度反馈
    func addAccuracyFeedback(divinationId: UUID, rating: Int, feedback: String?) {
        let newFeedback = AccuracyFeedback(
            id: UUID(),
            divinationId: divinationId,
            rating: rating,
            feedback: feedback,
            createdAt: Date()
        )
        
        accuracyFeedbacks.append(newFeedback)
        
        // 重新计算平均准确度
        let totalRating = accuracyFeedbacks.reduce(0) { $0 + $1.rating }
        averageAccuracy = Double(totalRating) / Double(accuracyFeedbacks.count) / 5.0
        
        // TODO: 保存到Core Data
    }
    
    // MARK: - 获取特定时间段的统计
    func getStatisticsForPeriod(_ period: StatisticsPeriod, context: NSManagedObjectContext) -> PeriodStatistics {
        let request: NSFetchRequest<DivinationRecord> = DivinationRecord.fetchRequest()
        
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        request.predicate = NSPredicate(format: "createdAt >= %@", startDate as NSDate)
        
        do {
            let records = try context.fetch(request)
            return PeriodStatistics(
                period: period,
                divinationCount: records.count,
                startDate: startDate,
                endDate: now
            )
        } catch {
            print("获取时间段统计失败: \(error)")
            return PeriodStatistics(period: period, divinationCount: 0, startDate: startDate, endDate: now)
        }
    }
}

// MARK: - 统计时间段枚举
enum StatisticsPeriod: String, CaseIterable {
    case week = "本周"
    case month = "本月"
    case year = "本年"
}

// MARK: - 时间段统计数据
struct PeriodStatistics {
    let period: StatisticsPeriod
    let divinationCount: Int
    let startDate: Date
    let endDate: Date
}