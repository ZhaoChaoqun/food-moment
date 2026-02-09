import Foundation

// MARK: - API Error

/// API 错误类型
///
/// 定义所有可能的 API 错误，包括网络错误、HTTP 错误和解析错误。
/// 遵循 `LocalizedError` 协议以提供本地化的错误描述。
///
/// ## 使用示例
/// ```swift
/// do {
///     let data = try await APIClient.shared.request(.getProfile)
/// } catch let error as APIError {
///     print(error.errorDescription ?? "未知错误")
///     if error.isRetryable {
///         // 可以重试
///     }
/// }
/// ```
enum APIError: LocalizedError {

    // MARK: - Error Cases

    /// 无效的请求 URL
    case invalidURL

    /// 服务器响应无效
    case invalidResponse

    /// HTTP 错误
    /// - Parameters:
    ///   - statusCode: HTTP 状态码
    ///   - message: 错误消息
    case httpError(statusCode: Int, message: String?)

    /// 响应数据解析失败
    case decodingError(Error)

    /// 请求数据编码失败
    case encodingError(Error)

    /// 网络连接错误
    case networkError(Error)

    /// 认证失败（令牌过期或无效）
    case unauthorized

    /// 服务器内部错误
    case serverError(String)

    /// 请求频率限制
    /// - Parameter retryAfter: 建议的重试等待时间（秒）
    case rateLimited(retryAfter: TimeInterval?)

    /// 未知错误
    case unknown

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .invalidResponse:
            return "服务器响应无效"
        case .httpError(let code, let message):
            return message ?? "请求失败（错误码: \(code)）"
        case .decodingError:
            return "数据解析失败"
        case .encodingError:
            return "请求数据编码失败"
        case .networkError(let error):
            return "网络连接失败: \(error.localizedDescription)"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .serverError(let message):
            return message
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "请求过于频繁，请 \(Int(seconds)) 秒后重试"
            }
            return "请求过于频繁，请稍后重试"
        case .unknown:
            return "未知错误"
        }
    }

    // MARK: - Computed Properties

    /// 错误是否可重试
    ///
    /// 网络错误、服务器错误和频率限制错误通常可以重试。
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .rateLimited:
            return true
        default:
            return false
        }
    }

    /// 是否需要重新登录
    var requiresReauthentication: Bool {
        switch self {
        case .unauthorized:
            return true
        default:
            return false
        }
    }

    /// 获取底层错误（如果有）
    var underlyingError: Error? {
        switch self {
        case .decodingError(let error), .encodingError(let error), .networkError(let error):
            return error
        default:
            return nil
        }
    }
}
