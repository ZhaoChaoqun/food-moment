import Foundation
import os

// MARK: - Token Manager

/// 令牌管理器（线程安全）
///
/// 使用 actor 模式确保令牌操作的线程安全性。
/// 令牌安全存储在 Keychain 中（通过 `KeychainHelper`）。
/// JWT 解析通过 `JWTHelper` 完成。
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

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Properties

    /// 访问令牌
    var accessToken: String? {
        KeychainHelper.read(key: accessTokenKey)
    }

    /// 刷新令牌
    var refreshToken: String? {
        KeychainHelper.read(key: refreshTokenKey)
    }

    /// 令牌是否有效
    ///
    /// 通过解析 JWT 令牌的过期时间来判断有效性。
    var isTokenValid: Bool {
        guard let token = accessToken else { return false }
        return (try? JWTHelper.isTokenValid(token)) ?? false
    }

    /// 是否已登录
    var isAuthenticated: Bool {
        accessToken != nil
    }

    /// 设备唯一标识符
    ///
    /// 首次访问时自动生成 UUID 并存入 Keychain（卸载重装不丢失）。
    var deviceId: String {
        if let existing = KeychainHelper.read(key: deviceIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        KeychainHelper.save(key: deviceIdKey, value: newId)
        return newId
    }

    // MARK: - Public Methods

    /// 设置访问令牌
    func setAccessToken(_ token: String) {
        KeychainHelper.save(key: accessTokenKey, value: token)
    }

    /// 设置刷新令牌
    func setRefreshToken(_ token: String) {
        KeychainHelper.save(key: refreshTokenKey, value: token)
    }

    /// 同时设置访问令牌和刷新令牌
    func setTokens(access: String, refresh: String) {
        setAccessToken(access)
        setRefreshToken(refresh)
    }

    /// 清除所有令牌
    func clearTokens() {
        KeychainHelper.delete(key: accessTokenKey)
        KeychainHelper.delete(key: refreshTokenKey)
    }

    /// 重置认证与设备状态（仅测试场景）
    func resetForTesting() {
        clearTokens()
        KeychainHelper.delete(key: deviceIdKey)
    }
}
