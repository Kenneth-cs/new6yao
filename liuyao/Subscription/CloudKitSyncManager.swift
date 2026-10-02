//
//  CloudKitSyncManager.swift
//  人生教练
//
//  把点券余额和月度配额同步到 iCloud 私有数据库。
//  iCloud 不可用时静默跳过，本地记账照常使用。
//

import CloudKit
import Foundation

@MainActor
final class CloudKitSyncManager {
    static let shared = CloudKitSyncManager()

    private let container = CKContainer(identifier: "iCloud.com.cs.liuyao")
    private let recordType = "UserQuota"
    private let recordID = CKRecord.ID(recordName: "UserQuota-current")
    private var isSyncing = false

    private var database: CKDatabase { container.privateCloudDatabase }

    private init() {}

    func syncOnLaunch() async {
        guard !isSyncing else { return }
        guard await iCloudAvailable() else { return }
        isSyncing = true
        defer { isSyncing = false }

        switch await fetchSnapshot() {
        case .failed:
            return
        case .missing:
            await saveQuota(PermissionManager.shared.cloudSnapshot())
        case .found(let remote):
            let shouldUpload = PermissionManager.shared.mergeCloudSnapshot(remote)
            if shouldUpload {
                await saveQuota(PermissionManager.shared.cloudSnapshot())
            }
        }
    }

    func saveQuota(_ snapshot: CloudQuotaSnapshot) async {
        guard await iCloudAvailable() else { return }
        let record: CKRecord
        do {
            if let existing = try await existingRecord() {
                record = existing
            } else {
                record = CKRecord(recordType: recordType, recordID: recordID)
            }
        } catch {
            return
        }
        record["masterCredits"] = snapshot.masterCredits as NSNumber
        record["deductionCredits"] = snapshot.deductionCredits as NSNumber
        record["monthlyReadingUsed"] = snapshot.monthlyReadingUsed as NSNumber
        record["monthlyMasterGiftUsed"] = snapshot.monthlyMasterGiftUsed as NSNumber
        record["monthlyResetDate"] = snapshot.monthlyResetDate as NSDate
        record["lastUpdatedAt"] = Date() as NSDate
        record["masterUnlockedReadingIDs"] = snapshot.masterUnlockedReadingIDs.joined(separator: "\n") as NSString
        do {
            _ = try await database.save(record)
        } catch {
            print("☁️ CloudKit 写入失败：\(error.localizedDescription)")
        }
    }

    func resetMonthlyOnCloud() async {
        await saveQuota(PermissionManager.shared.cloudSnapshot())
    }

    private func iCloudAvailable() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            return false
        }
    }

    private enum SnapshotFetch {
        case missing
        case failed
        case found(CloudQuotaSnapshot)
    }

    private func existingRecord() async throws -> CKRecord? {
        do {
            return try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private func fetchSnapshot() async -> SnapshotFetch {
        let record: CKRecord?
        do {
            record = try await existingRecord()
        } catch {
            return .failed
        }
        guard let record else { return .missing }
        let unlocked = (record["masterUnlockedReadingIDs"] as? String ?? "")
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
        return .found(CloudQuotaSnapshot(
            masterCredits: intValue(record["masterCredits"]),
            deductionCredits: intValue(record["deductionCredits"]),
            monthlyReadingUsed: intValue(record["monthlyReadingUsed"]),
            monthlyMasterGiftUsed: intValue(record["monthlyMasterGiftUsed"]),
            monthlyResetDate: record["monthlyResetDate"] as? Date ?? Date(),
            masterUnlockedReadingIDs: unlocked,
            lastUpdatedAt: record["lastUpdatedAt"] as? Date ?? .distantPast
        ))
    }

    private func intValue(_ value: Any?) -> Int {
        if let number = value as? NSNumber { return number.intValue }
        if let int = value as? Int { return int }
        return 0
    }
}
