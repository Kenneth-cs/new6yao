import Foundation
import CloudKit

class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    // 默认兜底配置（如果没网或者CloudKit拉取失败，就用这个）
    @Published var apiKey: String = "ark-0ca54154-d3ff-49d9-a45b-a598b1759586-2a663"
    @Published var modelEndpoint: String = "ep-20260516120006-f9pqw"
    
    private init() {
        fetchConfigFromCloudKit()
    }
    
    func fetchConfigFromCloudKit() {
        // 使用你刚才创建的 Container ID
        let container = CKContainer(identifier: "iCloud.com.cs.liuyao")
        let publicDatabase = container.publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "AIConfig")
        
        publicDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            if let error = error {
                print("[ConfigManager] CloudKit 拉取配置失败 (将使用本地默认配置): \(error.localizedDescription)")
                return
            }
            
            guard let record = record else {
                print("[ConfigManager] CloudKit 未找到记录")
                return
            }
            
            // 回到主线程更新数据
            DispatchQueue.main.async {
                if let fetchedApiKey = record["apiKey"] as? String, !fetchedApiKey.isEmpty {
                    self?.apiKey = fetchedApiKey
                    print("[ConfigManager] 成功从 CloudKit 更新 API Key")
                }
                
                if let fetchedModel = record["modelEndpoint"] as? String, !fetchedModel.isEmpty {
                    self?.modelEndpoint = fetchedModel
                    print("[ConfigManager] 成功从 CloudKit 更新 Model Endpoint: \(fetchedModel)")
                }
            }
        }
    }
}
