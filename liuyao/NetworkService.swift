import Foundation
import Network
import UIKit

class NetworkService {
    static let shared = NetworkService()
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var isNetworkAvailable = true
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // DeepSeek V3 API配置
    private let apiKey = "b6dbf75f-d0f0-4d17-8f29-62a3d9c20ff8"
    // 火山方舟API endpoint
    private let baseURL = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
    
    // 网络配置
    private struct NetworkConfig {
        static let connectTimeout: TimeInterval = 15  // 减少连接超时
        static let readTimeout: TimeInterval = 180    // 增加读取超时到 3 分钟
        static let maxRetries = 2                     // 减少重试次数
        static let baseRetryDelay: TimeInterval = 2.0
        static let maxRetryDelay: TimeInterval = 10.0
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkAvailable = path.status == .satisfied
            if path.status == .satisfied {
                print("[NetworkService] 网络连接已恢复")
            } else {
                print("[NetworkService] 网络连接不可用")
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    func sendRequest<T: Codable>(
        body: [String: Any],
        responseType: T.Type,
        maxRetries: Int = NetworkConfig.maxRetries
    ) async throws -> T {
        // --- 方案一：开启后台任务以防切出App导致请求中断 ---
        let bgTaskName = "AIRequest-\(UUID().uuidString)"
        var bgTask: UIBackgroundTaskIdentifier = .invalid
        bgTask = await MainActor.run {
            var taskId: UIBackgroundTaskIdentifier = .invalid
            taskId = UIApplication.shared.beginBackgroundTask(withName: bgTaskName) {
                // 超时闭包，系统强杀前调用
                if taskId != .invalid {
                    UIApplication.shared.endBackgroundTask(taskId)
                    print("[NetworkService] 后台任务 \(bgTaskName) 即将超时，清理完毕")
                }
            }
            print("[NetworkService] 开启后台任务: \(bgTaskName)")
            return taskId
        }
        
        defer {
            // 请求结束后释放后台任务
            Task { @MainActor [bgTask] in
                if bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    print("[NetworkService] 后台任务 \(bgTaskName) 已正常释放")
                }
            }
        }
        // ----------------------------------------
        
        // 检查网络连接
        guard isNetworkAvailable else {
            print("[NetworkService] 网络不可用，无法发送请求")
            throw NetworkError.noNetworkConnection
        }
        
        // 确保URL格式正确
        guard let url = URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw NetworkError.invalidURL
        }
        
        // 使用重试机制
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            print("[NetworkService] 尝试第 \(attempt + 1) 次请求 (最多 \(maxRetries) 次)")
            
            // 在重试前再次检查网络状态
            if attempt > 0 && !isNetworkAvailable {
                print("[NetworkService] 网络连接丢失，等待网络恢复...")
                try await waitForNetworkRecovery()
            }
            
            do {
                let result = try await performSingleRequest(url: url, body: body, responseType: responseType)
                print("[NetworkService] 请求成功！")
                return result
            } catch {
                lastError = error
                print("[NetworkService] 第 \(attempt + 1) 次请求失败: \(error)")
                
                // 如果是最后一次尝试，直接抛出错误
                if attempt == maxRetries - 1 {
                    break
                }
                
                // 检查是否是可重试的错误
                if !isRetryableError(error) {
                    print("[NetworkService] 不可重试的错误，停止重试")
                    break
                }
                
                // 计算重试延迟 (指数退避 + 随机抖动)
                let baseDelay = NetworkConfig.baseRetryDelay * pow(2.0, Double(attempt))
                let jitter = Double.random(in: 0...0.5) // 添加随机抖动
                let delay = min(baseDelay + jitter, NetworkConfig.maxRetryDelay)
                
                print("[NetworkService] 等待 \(String(format: "%.1f", delay)) 秒后重试...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? NetworkError.networkError(NSError(domain: "UnknownError", code: -1))
    }
    
    private func waitForNetworkRecovery() async throws {
        let maxWaitTime: TimeInterval = 10.0
        let checkInterval: TimeInterval = 0.5
        let startTime = Date()
        
        while !isNetworkAvailable {
            if Date().timeIntervalSince(startTime) > maxWaitTime {
                throw NetworkError.noNetworkConnection
            }
            try await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
    }
    
    private func performSingleRequest<T: Codable>(
        url: URL,
        body: [String: Any],
        responseType: T.Type
    ) async throws -> T {
        // 使用系统默认URLSession，避免配置问题
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = NetworkConfig.readTimeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // JSON编码
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("[NetworkService] JSON编码失败: \(error)")
            throw NetworkError.encodingError
        }
        
        print("[NetworkService] 发送请求到: \(url)")
        print("[NetworkService] 请求头: \(request.allHTTPHeaderFields ?? [:])")
        print("[NetworkService] 请求体大小: \(request.httpBody?.count ?? 0) 字节")
        print("[NetworkService] 连接超时: \(NetworkConfig.connectTimeout)秒, 读取超时: \(NetworkConfig.readTimeout)秒")
        
        // 打印请求体内容用于调试
        if let httpBody = request.httpBody,
           let bodyString = String(data: httpBody, encoding: .utf8) {
            print("[NetworkService] 请求体内容: \(bodyString)")
        }
        
        let startTime = Date()
        
        do {
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            print("[NetworkService] 请求耗时: \(String(format: "%.2f", duration))秒")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            print("[NetworkService] 响应状态码: \(httpResponse.statusCode)")
            print("[NetworkService] 响应数据大小: \(data.count) 字节")
            
            guard 200...299 ~= httpResponse.statusCode else {
                print("[NetworkService] HTTP错误: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[NetworkService] 错误响应内容: \(responseString)")
                }
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            // JSON解码
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                print("[NetworkService] JSON解析成功")
                return decodedResponse
            } catch {
                print("[NetworkService] JSON解析失败: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[NetworkService] 响应内容: \(responseString.prefix(500))")
                }
                throw NetworkError.decodingError
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("[NetworkService] 请求失败，耗时: \(String(format: "%.2f", duration))秒")
            
            if let urlError = error as? URLError {
                print("[NetworkService] URLError详情: \(urlError.localizedDescription) (代码: \(urlError.code.rawValue))")
            }
            
            throw NetworkError.networkError(error)
        }
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet, 
                 .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed,
                 .resourceUnavailable, .dataNotAllowed:
                return true
            case .badServerResponse, .cannotParseResponse:
                return false // 这些通常是服务端问题，重试无意义
            default:
                return false
            }
        }
        
        if let networkError = error as? NetworkError {
            switch networkError {
            case .networkError(let underlyingError):
                return isRetryableError(underlyingError)
            case .serverError(let code):
                // 5xx 服务器错误和429(请求过多)可以重试
                return code >= 500 || code == 429
            case .noNetworkConnection, .requestTimeout, .connectionFailed:
                return true
            case .invalidURL, .encodingError, .decodingError, .invalidResponse:
                return false // 这些是客户端错误，重试无意义
            }
        }
        
        return false
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case invalidResponse
    case serverError(Int)
    case networkError(Error)
    case decodingError
    case noNetworkConnection
    case requestTimeout
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .encodingError:
            return "数据编码失败"
        case .invalidResponse:
            return "无效的响应"
        case .serverError(let code):
            return "服务器错误: \(code)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError:
            return "数据解析失败"
        case .noNetworkConnection:
            return "网络连接不可用，请检查网络设置"
        case .requestTimeout:
            return "请求超时，请稍后重试"
        case .connectionFailed:
            return "连接失败，请检查网络连接"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noNetworkConnection:
            return "请检查WiFi或移动数据连接"
        case .requestTimeout:
            return "网络较慢，建议稍后重试"
        case .connectionFailed:
            return "请检查网络设置或联系技术支持"
        case .serverError(let code) where code >= 500:
            return "服务器暂时不可用，请稍后重试"
        default:
            return nil
        }
    }
}