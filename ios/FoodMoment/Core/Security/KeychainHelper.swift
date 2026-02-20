import Foundation
import Security
import os

/// 简洁的 Keychain 封装
///
/// 替代直接调用 `SecItemAdd/SecItemCopyMatching/SecItemDelete`，
/// 提供类型安全的字符串存取 API。
enum KeychainHelper {

    private static let logger = Logger(subsystem: "com.foodmoment", category: "Keychain")

    /// 保存字符串到 Keychain
    ///
    /// 采用"先删后插"策略，保证幂等。
    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // 先删除已有条目（忽略 errSecItemNotFound）
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("[Keychain] save failed for key '\(key, privacy: .public)': \(status, privacy: .public)")
        }
    }

    /// 从 Keychain 读取字符串
    static func read(key: String) -> String? {
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

    /// 从 Keychain 删除条目
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("[Keychain] delete failed for key '\(key, privacy: .public)': \(status, privacy: .public)")
        }
    }
}
