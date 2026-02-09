import UIKit
import Foundation

/// Configuration for cloud vision API
struct CloudVisionConfig: Sendable {
    let apiKey: String
    let baseURL: String
    let modelName: String
    let maxTokens: Int
    let compressionQuality: CGFloat
    let maxImageDimension: CGFloat

    static let gemini = CloudVisionConfig(
        apiKey: "", // Set via environment or secure storage
        baseURL: "https://generativelanguage.googleapis.com/v1beta",
        modelName: "gemini-1.5-flash",
        maxTokens: 2048,
        compressionQuality: 0.8,
        maxImageDimension: 1024
    )
}

/// Errors that can occur during cloud vision processing
enum CloudVisionError: Error, LocalizedError {
    case invalidAPIKey
    case imageEncodingFailed
    case networkError(Error)
    case invalidResponse
    case apiError(Int, String)
    case parseError(String)
    case rateLimitExceeded
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid or missing API key for cloud vision service."
        case .imageEncodingFailed:
            return "Failed to encode image for upload."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from cloud vision API."
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .parseError(let message):
            return "Failed to parse response: \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .quotaExceeded:
            return "API quota exceeded. Please try again tomorrow."
        }
    }
}

/// Protocol for cloud-based food recognition
protocol CloudVisionProtocol: Sendable {
    /// Analyze food in an image using cloud AI
    func analyzeFood(image: UIImage) async throws -> CloudVisionResponse
}

/// Response from cloud vision food analysis
struct CloudVisionResponse: Codable, Sendable {
    let foods: [CloudDetectedFood]
    let totalCalories: Int
    let aiAnalysis: String
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case foods
        case totalCalories = "total_calories"
        case aiAnalysis = "ai_analysis"
        case tags
    }
}

/// Food item detected by cloud vision
struct CloudDetectedFood: Codable, Sendable {
    let name: String
    let nameZh: String
    let emoji: String
    let portion: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case name
        case nameZh = "name_zh"
        case emoji
        case portion
        case calories
        case protein
        case carbs
        case fat
        case confidence
    }
}

/// Cloud vision service using Google Gemini Vision API for food recognition.
/// Provides detailed nutritional analysis with multi-language support.
actor CloudVisionService: CloudVisionProtocol {

    // MARK: - Properties

    private let config: CloudVisionConfig
    private let session: URLSession

    /// System prompt for food analysis
    private let systemPrompt = """
    You are a professional nutritionist AI assistant. Analyze the food in this image and provide detailed nutritional information.

    Respond ONLY with valid JSON in this exact format:
    {
        "foods": [
            {
                "name": "Food Name in English",
                "name_zh": "中文名称",
                "emoji": "🍎",
                "portion": "estimated portion size",
                "calories": 100,
                "protein": 5.0,
                "carbs": 20.0,
                "fat": 3.0,
                "confidence": 0.95
            }
        ],
        "total_calories": 500,
        "ai_analysis": "Brief nutritional analysis and health tips in both English and Chinese",
        "tags": ["healthy", "high-protein", "low-carb"]
    }

    Guidelines:
    1. Identify ALL visible food items in the image
    2. Estimate portion sizes based on visual cues
    3. Provide accurate nutritional estimates per serving
    4. Include confidence score (0.0-1.0) for each food
    5. Use appropriate food emoji for each item
    6. Provide both English and Chinese names
    7. Add relevant dietary tags
    8. Keep the analysis concise but informative
    """

    // MARK: - Initialization

    init(config: CloudVisionConfig = .gemini) {
        self.config = config

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public Methods

    /// Analyze food in an image using Gemini Vision API
    func analyzeFood(image: UIImage) async throws -> CloudVisionResponse {
        guard !config.apiKey.isEmpty else {
            throw CloudVisionError.invalidAPIKey
        }

        // Resize and encode image
        let resizedImage = resizeImage(image, maxDimension: config.maxImageDimension)
        guard let imageData = resizedImage.jpegData(compressionQuality: config.compressionQuality) else {
            throw CloudVisionError.imageEncodingFailed
        }
        let base64Image = imageData.base64EncodedString()

        // Build API request
        let url = URL(string: "\(config.baseURL)/models/\(config.modelName):generateContent?key=\(config.apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body for Gemini API
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": systemPrompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "maxOutputTokens": config.maxTokens,
                "responseMimeType": "application/json"
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make API request
        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudVisionError.invalidResponse
        }

        // Handle HTTP errors
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 429:
            throw CloudVisionError.rateLimitExceeded
        case 403:
            throw CloudVisionError.quotaExceeded
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CloudVisionError.apiError(httpResponse.statusCode, message)
        }

        // Parse Gemini response
        return try parseGeminiResponse(data)
    }

    // MARK: - Private Methods

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw CloudVisionError.networkError(error)
        }
    }

    private func parseGeminiResponse(_ data: Data) throws -> CloudVisionResponse {
        // Gemini API response structure
        struct GeminiResponse: Codable {
            let candidates: [Candidate]?
            let error: GeminiError?
        }

        struct Candidate: Codable {
            let content: Content
        }

        struct Content: Codable {
            let parts: [Part]
        }

        struct Part: Codable {
            let text: String?
        }

        struct GeminiError: Codable {
            let message: String
            let code: Int
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        // Check for API error
        if let error = geminiResponse.error {
            throw CloudVisionError.apiError(error.code, error.message)
        }

        // Extract text content
        guard let candidates = geminiResponse.candidates,
              let firstCandidate = candidates.first,
              let text = firstCandidate.content.parts.first?.text else {
            throw CloudVisionError.invalidResponse
        }

        // Parse the JSON from the text response
        guard let jsonData = text.data(using: .utf8) else {
            throw CloudVisionError.parseError("Invalid text encoding")
        }

        do {
            return try JSONDecoder().decode(CloudVisionResponse.self, from: jsonData)
        } catch {
            throw CloudVisionError.parseError(error.localizedDescription)
        }
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = max(size.width, size.height) / maxDimension

        guard ratio > 1 else { return image }

        let newSize = CGSize(
            width: size.width / ratio,
            height: size.height / ratio
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Mock Implementation

/// Mock cloud vision service for development and testing
actor MockCloudVisionService: CloudVisionProtocol {

    func analyzeFood(image: UIImage) async throws -> CloudVisionResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)

        return CloudVisionResponse(
            foods: [
                CloudDetectedFood(
                    name: "Grilled Salmon",
                    nameZh: "烤三文鱼",
                    emoji: "🐟",
                    portion: "150g fillet",
                    calories: 280,
                    protein: 35.0,
                    carbs: 0.0,
                    fat: 15.0,
                    confidence: 0.92
                ),
                CloudDetectedFood(
                    name: "Steamed Broccoli",
                    nameZh: "清蒸西兰花",
                    emoji: "🥦",
                    portion: "100g",
                    calories: 35,
                    protein: 2.8,
                    carbs: 7.0,
                    fat: 0.4,
                    confidence: 0.89
                ),
                CloudDetectedFood(
                    name: "Brown Rice",
                    nameZh: "糙米饭",
                    emoji: "🍚",
                    portion: "1 cup cooked",
                    calories: 216,
                    protein: 5.0,
                    carbs: 45.0,
                    fat: 1.8,
                    confidence: 0.85
                )
            ],
            totalCalories: 531,
            aiAnalysis: "This is a well-balanced meal with high-quality protein from salmon, fiber-rich vegetables, and complex carbohydrates. The omega-3 fatty acids in salmon support heart health. Consider adding a colorful vegetable for more antioxidants. / 这是一顿营养均衡的餐食，三文鱼提供优质蛋白质，蔬菜富含纤维，搭配复合碳水化合物。三文鱼中的omega-3脂肪酸有益心脏健康。建议添加彩色蔬菜以获取更多抗氧化物。",
            tags: ["high-protein", "omega-3", "balanced", "low-sugar"]
        )
    }
}

// MARK: - Hybrid Classifier

/// Hybrid food classifier that combines on-device Core ML with cloud AI.
/// Uses on-device model for quick preliminary results, then enhances with cloud API.
final class HybridFoodClassifierService: FoodClassifierProtocol, @unchecked Sendable {

    private let localClassifier: FoodClassifierProtocol
    private let cloudService: CloudVisionProtocol
    private let useCloudFallback: Bool

    init(
        localClassifier: FoodClassifierProtocol = CoreMLFoodClassifierService(),
        cloudService: CloudVisionProtocol = MockCloudVisionService(),
        useCloudFallback: Bool = true
    ) {
        self.localClassifier = localClassifier
        self.cloudService = cloudService
        self.useCloudFallback = useCloudFallback
    }

    func classify(image: UIImage) async throws -> [DetectedFoodDTO] {
        // Try local classification first
        do {
            let localResults = try await localClassifier.classify(image: image)
            if !localResults.isEmpty {
                return localResults
            }
        } catch {
            // If local fails and cloud fallback is enabled, continue to cloud
            guard useCloudFallback else { throw error }
        }

        // Fall back to cloud classification
        let cloudResponse = try await cloudService.analyzeFood(image: image)

        // Convert cloud response to DetectedFoodDTO
        return cloudResponse.foods.enumerated().map { index, food in
            // Generate a simple bounding box layout for multiple items
            let row = index / 2
            let col = index % 2
            let x = 0.1 + Double(col) * 0.45
            let y = 0.1 + Double(row) * 0.35

            return DetectedFoodDTO(
                name: food.name,
                nameZh: food.nameZh,
                emoji: food.emoji,
                confidence: food.confidence,
                boundingBox: BoundingBoxDTO(x: x, y: y, w: 0.4, h: 0.25),
                calories: food.calories,
                proteinGrams: food.protein,
                carbsGrams: food.carbs,
                fatGrams: food.fat,
                color: colorForFood(food.name)
            )
        }
    }

    private func colorForFood(_ name: String) -> String {
        let lowercased = name.lowercased()

        if lowercased.contains("salmon") || lowercased.contains("fish") {
            return "#F97316"
        } else if lowercased.contains("broccoli") || lowercased.contains("vegetable") || lowercased.contains("salad") {
            return "#22C55E"
        } else if lowercased.contains("rice") || lowercased.contains("bread") || lowercased.contains("pasta") {
            return "#FCD34D"
        } else if lowercased.contains("chicken") || lowercased.contains("meat") || lowercased.contains("beef") {
            return "#DC2626"
        } else if lowercased.contains("egg") {
            return "#FACC15"
        } else {
            return "#4ADE80"
        }
    }
}
