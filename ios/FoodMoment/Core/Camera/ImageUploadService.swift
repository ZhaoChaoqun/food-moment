import UIKit
import Foundation

/// Image upload configuration
struct ImageUploadConfig {
    let compressionQuality: CGFloat
    let maxDimension: CGFloat
    let uploadEndpoint: String

    static let `default` = ImageUploadConfig(
        compressionQuality: 0.8,
        maxDimension: 1920,
        uploadEndpoint: "/api/v1/images/upload"
    )
}

/// Response from image upload
struct ImageUploadResponse: Codable {
    let url: String
    let imageId: String
    let width: Int
    let height: Int
    let sizeBytes: Int

    enum CodingKeys: String, CodingKey {
        case url
        case imageId = "image_id"
        case width
        case height
        case sizeBytes = "size_bytes"
    }
}

/// Errors that can occur during image upload
enum ImageUploadError: Error, LocalizedError {
    case compressionFailed
    case uploadFailed(Error)
    case invalidResponse
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image for upload."
        case .uploadFailed(let error):
            return "Image upload failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
}

/// Protocol for image upload
protocol ImageUploadProtocol: Sendable {
    /// Upload an image and return the URL
    func upload(image: UIImage, config: ImageUploadConfig) async throws -> ImageUploadResponse
}

/// Service for uploading images to OSS (Object Storage Service).
/// Handles compression, resizing, and multipart upload.
actor ImageUploadService: ImageUploadProtocol {

    // MARK: - Properties

    private let baseURL: String
    private let session: URLSession

    // MARK: - Initialization

    init(baseURL: String = "") {
        self.baseURL = baseURL
        self.session = URLSession(configuration: .appUpload)
    }

    // MARK: - Public Methods

    /// Upload an image to OSS
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - config: Upload configuration (compression, size limits)
    /// - Returns: ImageUploadResponse with the URL and metadata
    func upload(image: UIImage, config: ImageUploadConfig = .default) async throws -> ImageUploadResponse {
        // Resize image if needed
        let resizedImage = image.resized(maxDimension: config.maxDimension)

        // Compress to JPEG
        guard let imageData = resizedImage.jpegData(compressionQuality: config.compressionQuality) else {
            throw ImageUploadError.compressionFailed
        }

        // Create multipart form data request
        var multipart = MultipartFormData()
        multipart.addFilePart(
            name: "file",
            filename: "food_image.jpg",
            mimeType: "image/jpeg",
            data: imageData
        )

        var request = URLRequest(url: URL(string: baseURL + config.uploadEndpoint)!)
        request.httpMethod = "POST"
        request.setValue(multipart.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.finalize()

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImageUploadError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw ImageUploadError.serverError(httpResponse.statusCode, message)
            }

            let decoder = JSONDecoder.appDefault
            return try decoder.decode(ImageUploadResponse.self, from: data)

        } catch let error as ImageUploadError {
            throw error
        } catch {
            throw ImageUploadError.uploadFailed(error)
        }
    }

    /// Prepare image data for upload without actually uploading.
    /// Useful for offline scenarios or when upload URL is obtained separately.
    func prepareImageData(image: UIImage, config: ImageUploadConfig = .default) throws -> Data {
        let resizedImage = image.resized(maxDimension: config.maxDimension)

        guard let imageData = resizedImage.jpegData(compressionQuality: config.compressionQuality) else {
            throw ImageUploadError.compressionFailed
        }

        return imageData
    }

}

// MARK: - Mock Implementation for Development

/// Mock upload service that simulates server upload
actor MockImageUploadService: ImageUploadProtocol {

    func upload(image: UIImage, config: ImageUploadConfig = .default) async throws -> ImageUploadResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        let size = image.size
        let imageId = UUID().uuidString.lowercased()

        return ImageUploadResponse(
            url: "https://cdn.foodmoment.app/images/\(imageId).jpg",
            imageId: imageId,
            width: Int(size.width),
            height: Int(size.height),
            sizeBytes: Int(size.width * size.height * 0.3) // Approximate JPEG size
        )
    }
}
