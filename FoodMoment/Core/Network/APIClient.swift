import Foundation

// MARK: - API Client

/// 网络请求客户端（线程安全）
///
/// 使用 actor 模式确保所有网络请求的线程安全性。
/// 提供统一的请求构建、执行和响应处理。
///
/// ## 使用示例
/// ```swift
/// let response: UserProfile = try await APIClient.shared.request(.getProfile)
/// ```
actor APIClient {

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Properties

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true

        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Public Methods

    /// 执行 API 请求并解码响应
    ///
    /// - Parameters:
    ///   - endpoint: API 端点
    ///   - body: 请求体（可选）
    /// - Returns: 解码后的响应对象
    /// - Throws: `APIError` 当请求失败时
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        body: (any Encodable)? = nil
    ) async throws -> T {
        let request = try await buildRequest(endpoint, body: body)
        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// 执行 API 请求但不解码响应体
    ///
    /// 适用于只需要确认请求成功的场景，如删除操作。
    ///
    /// - Parameters:
    ///   - endpoint: API 端点
    ///   - body: 请求体（可选）
    /// - Throws: `APIError` 当请求失败时
    func requestVoid(
        _ endpoint: APIEndpoint,
        body: (any Encodable)? = nil
    ) async throws {
        let request = try await buildRequest(endpoint, body: body)
        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)
    }

    /// 上传图片文件
    ///
    /// 使用 multipart/form-data 格式上传图片数据。
    ///
    /// - Parameters:
    ///   - endpoint: API 端点
    ///   - imageData: 图片二进制数据
    ///   - filename: 文件名，默认为 "food.jpg"
    ///   - mimeType: MIME 类型，默认为 "image/jpeg"
    /// - Returns: 解码后的响应对象
    /// - Throws: `APIError` 当请求失败时
    func upload<T: Decodable>(
        _ endpoint: APIEndpoint,
        imageData: Data,
        filename: String = "food.jpg",
        mimeType: String = "image/jpeg"
    ) async throws -> T {
        var request = try await buildRequest(endpoint, body: nil as String?)

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        let body = createMultipartBody(
            imageData: imageData,
            filename: filename,
            mimeType: mimeType,
            boundary: boundary
        )
        request.httpBody = body

        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Private Methods

    private func buildRequest(
        _ endpoint: APIEndpoint,
        body: (any Encodable)?
    ) async throws -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 添加认证令牌
        if endpoint.requiresAuth,
           let token = await TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 编码请求体
        if let body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.encodingError(error)
            }
        }

        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch {
            throw APIError.unknown
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return // 成功
        case 401:
            throw APIError.unauthorized
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw APIError.rateLimited(retryAfter: retryAfter)
        case 400..<500:
            let message = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                message: message?.detail
            )
        case 500..<600:
            let message = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.serverError(message?.detail ?? "服务器错误，请稍后重试")
        default:
            throw APIError.unknown
        }
    }

    private func createMultipartBody(
        imageData: Data,
        filename: String,
        mimeType: String,
        boundary: String
    ) -> Data {
        var body = Data()

        // 添加图片数据
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n"
                .data(using: .utf8)!
        )
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }
}

// MARK: - Error Response

/// API 错误响应模型
private struct ErrorResponse: Decodable {
    let detail: String
}
