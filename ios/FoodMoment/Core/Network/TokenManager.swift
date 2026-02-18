import Foundation
import Security
import os

// MARK: - Token Manager

/// Token 验证错误类型
enum TokenValidationError: Error {
    case tokenMissing
    case invalidFormat
    case invalidBase64Payload
    case missingExpirationClaim
    case tokenExpired
}

/// 令牌管理器（线程安全）
///
/// 使用 actor 模式确保令牌操作的线程安全性。
/// 令牌安全存储在 Keychain 中。
///
/// ## 使用示例
/// ```swift
/// // 保存令牌
/// await TokenManager.shared.setTokens(access: accessToken, refresh: refreshToken)
///
/// // 获取令牌
/// if let token = await TokenManager.shared.accessToken {
///     // 使用令牌
/// }
///
/// // 检查令牌有效性
/// let isValid = await TokenManager.shared.isTokenValid
/// ```
actor TokenManager {

    // MARK: - Singleton

    private static let logger = Logger(subsystem: "com.foodmoment", category: "TokenManager")

    static let shared = TokenManager()

    // MARK: - Private Properties

    private let accessTokenKey = "com.foodmoment.accessToken"
    private let refreshTokenKey = "com.foodmoment.refreshToken"
    private let deviceIdKey = "com.foodmoment.deviceId"
    private let jwtPartCount = 3

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Properties

    /// 访问令牌
    var accessToken: String? {
        readKeychain(key: accessTokenKey)
    }

    /// 刷新令牌
    var refreshToken: String? {
        readKeychain(key: refreshTokenKey)
    }

    /// 令牌是否有效
    ///
    /// 通过解析 JWT 令牌的过期时间来判断有效性。
    var isTokenValid: Bool {
        guard let token = accessToken else { return false }
        return (try? validateToken(token)) ?? false
    }

    /// 是否已登录
    var isAuthenticated: Bool {
        accessToken != nil
    }

    /// 设备唯一标识符
    ///
    /// 首次访问时自动生成 UUID 并存入 Keychain（卸载重装不丢失）。
    var deviceId: String {
        if let existing = readKeychain(key: deviceIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        saveKeychain(key: deviceIdKey, value: newId)
        return newId
    }

    // MARK: - Token Validation

    /// 验证 JWT Token
    ///
    /// - Parameter token: JWT Token 字符串
    /// - Throws: TokenValidationError
    /// - Returns: Token 是否有效
    private func validateToken(_ token: String) throws -> Bool {
        // 验证 Token 格式
        let parts = token.split(separator: ".")
        guard parts.count == jwtPartCount else {
            throw TokenValidationError.invalidFormat
        }

        // 解码 payload
        let payloadPart = String(parts[1])
        guard let payloadData = Data(base64Encoded: payloadPart.base64URLDecoded) else {
            throw TokenValidationError.invalidBase64Payload
        }

        // 解析过期时间
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            throw TokenValidationError.missingExpirationClaim
        }

        // 检查是否过期
        let expirationDate = Date(timeIntervalSince1970: exp)
        let isValid = expirationDate > Date()

        if !isValid {
            throw TokenValidationError.tokenExpired
        }

        return true
    }

    // MARK: - Public Methods

    /// 设置访问令牌
    ///
    /// - Parameter token: 访问令牌字符串
    func setAccessToken(_ token: String) {
        saveKeychain(key: accessTokenKey, value: token)
    }

    /// 设置刷新令牌
    ///
    /// - Parameter token: 刷新令牌字符串
    func setRefreshToken(_ token: String) {
        saveKeychain(key: refreshTokenKey, value: token)
    }

    /// 同时设置访问令牌和刷新令牌
    ///
    /// - Parameters:
    ///   - access: 访问令牌
    ///   - refresh: 刷新令牌
    func setTokens(access: String, refresh: String) {
        setAccessToken(access)
        setRefreshToken(refresh)
    }

    /// 清除所有令牌
    ///
    /// 用于用户登出或令牌失效时。
    func clearTokens() {
        deleteKeychain(key: accessTokenKey)
        deleteKeychain(key: refreshTokenKey)
    }

    /// 重置认证与设备状态（仅测试场景）
    func resetForTesting() {
        clearTokens()
        deleteKeychain(key: deviceIdKey)
    }

    // MARK: - Private Methods

    private func saveKeychain(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // 先删除已有的条目
        SecItemDelete(query as CFDictionary)

        // 添加新条目
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Self.logger.error("[Token] Failed to save keychain item: \(status, privacy: .public)")
        }
    }

    private func readKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func deleteKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            Self.logger.error("[Token] Failed to delete keychain item: \(status, privacy: .public)")
        }
    }
}

// MARK: - String Base64 URL Decoding

private extension String {
    /// 将 Base64 URL 编码转换为标准 Base64 编码
    var base64URLDecoded: String {
        var result = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // 添加填充
        while result.count % 4 != 0 {
            result.append("=")
        }

        return result
    }
}
