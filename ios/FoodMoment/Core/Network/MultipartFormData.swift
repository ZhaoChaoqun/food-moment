import Foundation

/// 统一的 Multipart Form-Data 构建器
///
/// 替代 `APIClient` 和 `ImageUploadService` 中各自手动拼接 multipart 的逻辑，
/// 提供类型安全的 boundary 管理和 part 添加方法。
struct MultipartFormData {

    // MARK: - Properties

    let boundary: String
    private var body = Data()

    // MARK: - Initialization

    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }

    // MARK: - Content-Type

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    // MARK: - Mutating Methods

    /// 添加文件数据 part
    mutating func addFilePart(
        name: String,
        filename: String,
        mimeType: String,
        data: Data
    ) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n"
                .data(using: .utf8)!
        )
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
    }

    /// 添加文本字段 part
    mutating func addField(name: String, value: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
                .data(using: .utf8)!
        )
        body.append(value.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
    }

    /// 生成最终的 HTTP body data
    func finalize() -> Data {
        var result = body
        result.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return result
    }
}
