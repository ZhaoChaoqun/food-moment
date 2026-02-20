import Foundation

// MARK: - JSONDecoder 全局预配置

extension JSONDecoder {

    /// 应用主 Decoder：snake_case key + ISO 8601 日期
    ///
    /// 用于与后端 API 通信的标准解码器。
    static let appSnakeCase: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// 默认 Decoder：无特殊策略
    ///
    /// 用于第三方 API 或自定义 CodingKeys 的场景。
    static let appDefault: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

// MARK: - JSONEncoder 全局预配置

extension JSONEncoder {

    /// 应用主 Encoder：snake_case key + ISO 8601 日期
    static let appSnakeCase: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// 默认 Encoder：无特殊策略
    static let appDefault: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

// MARK: - URLSessionConfiguration 工厂

extension URLSessionConfiguration {

    /// 标准 API 请求配置（30s 超时）
    static var appStandard: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        return config
    }

    /// 文件上传配置（60s 超时）
    static var appUpload: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        return config
    }
}
