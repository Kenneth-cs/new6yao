import Foundation

/// AI 请求失败的统一编号。用户可见文案形如「解卦失败404」。
struct AIRequestFailure: Error, Equatable {
    let code: Int
    let title: String
    let message: String

    func headline(prefix: String) -> String {
        "\(prefix)\(code)"
    }

    static func from(_ error: Error) -> AIRequestFailure {
        if let failure = error as? AIRequestFailure {
            return failure
        }
        if let aiError = error as? AIServiceError {
            switch aiError {
            case .noResponse:
                return .code600
            case .requestFailed(let inner):
                return from(inner)
            }
        }
        if let networkError = error as? NetworkError {
            return from(networkError)
        }
        if let urlError = error as? URLError {
            return from(urlError)
        }
        if let nested = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error {
            return from(nested)
        }
        return .code800
    }

    private static func from(_ error: NetworkError) -> AIRequestFailure {
        switch error {
        case .noNetworkConnection:
            return .code201
        case .invalidURL:
            return .code104
        case .encodingError:
            return .code103
        case .missingAPIKey:
            return .code102
        case .invalidResponse:
            return .code601
        case .decodingError:
            return .code601
        case .requestTimeout:
            return .code302
        case .connectionFailed:
            return .code203
        case .dnsFailure:
            return .code202
        case .tlsFailure:
            return .code205
        case .cancelled:
            return .code206
        case .serverError(let status):
            return from(httpStatus: status)
        case .networkError(let inner):
            return from(inner)
        }
    }

    private static func from(_ error: URLError) -> AIRequestFailure {
        switch error.code {
        case .timedOut:
            return .code302
        case .notConnectedToInternet, .dataNotAllowed:
            return .code201
        case .cannotFindHost, .dnsLookupFailed:
            return .code202
        case .cannotConnectToHost:
            return .code203
        case .networkConnectionLost:
            return .code204
        case .secureConnectionFailed,
             .serverCertificateUntrusted,
             .serverCertificateHasUnknownRoot,
             .serverCertificateHasBadDate,
             .clientCertificateRejected,
             .clientCertificateRequired:
            return .code205
        case .cancelled:
            return .code206
        default:
            return .code800
        }
    }

    private static func from(httpStatus status: Int) -> AIRequestFailure {
        switch status {
        case 400: return AIRequestFailure(code: 400, title: "请求参数异常", message: "这次分析没有发出，请稍后重试")
        case 401: return AIRequestFailure(code: 401, title: "服务暂时不可用", message: "请稍后重试，次数未消耗")
        case 403: return AIRequestFailure(code: 403, title: "服务暂时不可用", message: "请稍后重试，次数未消耗")
        case 404: return AIRequestFailure(code: 404, title: "服务配置异常", message: "请更新应用或稍后重试")
        case 408: return AIRequestFailure(code: 408, title: "请求超时", message: "这次没有完成，次数未消耗")
        case 429: return AIRequestFailure(code: 429, title: "请求过多", message: "请稍等再试，次数未消耗")
        case 500: return AIRequestFailure(code: 500, title: "服务繁忙", message: "请稍后重试，次数未消耗")
        case 502: return AIRequestFailure(code: 502, title: "服务繁忙", message: "请稍后重试，次数未消耗")
        case 503: return AIRequestFailure(code: 503, title: "服务繁忙", message: "请稍后重试，次数未消耗")
        case 504: return AIRequestFailure(code: 504, title: "服务繁忙", message: "请稍后重试，次数未消耗")
        case 500..<600:
            return AIRequestFailure(code: 599, title: "服务繁忙", message: "请稍后重试，次数未消耗")
        default:
            return AIRequestFailure(code: status, title: "解读失败", message: "请稍后重试，次数未消耗")
        }
    }

    static let code102 = AIRequestFailure(code: 102, title: "服务配置异常", message: "请稍后重试，次数未消耗")
    static let code103 = AIRequestFailure(code: 103, title: "请求编码失败", message: "请稍后重试，次数未消耗")
    static let code104 = AIRequestFailure(code: 104, title: "服务配置异常", message: "请稍后重试，次数未消耗")
    static let code201 = AIRequestFailure(code: 201, title: "网络不可用", message: "请打开蜂窝或 Wi-Fi 后重试")
    static let code202 = AIRequestFailure(code: 202, title: "无法连接服务器", message: "请检查网络后重试")
    static let code203 = AIRequestFailure(code: 203, title: "无法连接服务器", message: "请检查网络后重试")
    static let code204 = AIRequestFailure(code: 204, title: "连接已中断", message: "请稍后重试，次数未消耗")
    static let code205 = AIRequestFailure(code: 205, title: "安全连接失败", message: "请关闭代理后重试")
    static let code206 = AIRequestFailure(code: 206, title: "请求已取消", message: "这次没有完成，次数未消耗")
    static let code302 = AIRequestFailure(code: 302, title: "请求超时", message: "这次没有完成，次数未消耗")
    static let code600 = AIRequestFailure(code: 600, title: "解读未生成", message: "请再试一次，次数未消耗")
    static let code601 = AIRequestFailure(code: 601, title: "解读未生成", message: "请再试一次，次数未消耗")
    static let code800 = AIRequestFailure(code: 800, title: "解读失败", message: "请稍后重试，次数未消耗")

    /// 根据整数错误码反查 AIRequestFailure（缓存恢复时使用）
    static func from(code: Int) -> AIRequestFailure {
        let all: [AIRequestFailure] = [
            .code102, .code103, .code104,
            .code201, .code202, .code203, .code204, .code205, .code206,
            .code302,
            .code600, .code601,
            .code800
        ]
        if let found = all.first(where: { $0.code == code }) { return found }
        // HTTP 4xx / 5xx 通过动态映射还原
        if code >= 100 && code < 600 {
            return from(httpStatus: code)
        }
        return .code800
    }
}
