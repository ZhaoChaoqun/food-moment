import Foundation

/// JWT 解析工具
///
/// 提供 JWT payload 解码和过期时间检查，
/// 替代手动 `split(".")` + Base64URL 转换 + JSONSerialization 解析。
enum JWTHelper {

    /// JWT 解析错误
    enum JWTError: Error {
        case invalidFormat
        case invalidBase64Payload
        case missingExpirationClaim
        case tokenExpired
    }

    /// 解码 JWT payload 为字典
    ///
    /// - Parameter token: JWT 字符串（header.payload.signature）
    /// - Returns: payload 字典
    /// - Throws: `JWTError` 当格式不合法时
    static func decodePayload(_ token: String) throws -> [String: Any] {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            throw JWTError.invalidFormat
        }

        let payloadBase64URL = String(parts[1])
        let payloadBase64 = base64URLToBase64(payloadBase64URL)

        guard let payloadData = Data(base64Encoded: payloadBase64) else {
            throw JWTError.invalidBase64Payload
        }

        guard let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw JWTError.invalidBase64Payload
        }

        return payload
    }

    /// 检查 JWT 是否尚未过期
    ///
    /// - Parameter token: JWT 字符串
    /// - Returns: `true` 表示有效（未过期）
    /// - Throws: `JWTError` 当格式不合法或已过期时
    static func isTokenValid(_ token: String) throws -> Bool {
        let payload = try decodePayload(token)

        guard let exp = payload["exp"] as? TimeInterval else {
            throw JWTError.missingExpirationClaim
        }

        let expirationDate = Date(timeIntervalSince1970: exp)
        guard expirationDate > Date() else {
            throw JWTError.tokenExpired
        }

        return true
    }

    // MARK: - Private

    /// Base64URL → 标准 Base64
    private static func base64URLToBase64(_ input: String) -> String {
        var result = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // 补齐 padding
        while result.count % 4 != 0 {
            result.append("=")
        }

        return result
    }
}
