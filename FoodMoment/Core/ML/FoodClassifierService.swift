import UIKit
import Vision
import CoreML

/// Errors that can occur during food classification
enum FoodClassifierError: Error, LocalizedError {
    case modelNotLoaded
    case classificationFailed
    case invalidImage
    case visionRequestFailed(Error)
    case noResults

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "The food classification model could not be loaded."
        case .classificationFailed:
            return "Failed to classify the food in the image."
        case .invalidImage:
            return "The provided image could not be processed."
        case .visionRequestFailed(let error):
            return "Vision request failed: \(error.localizedDescription)"
        case .noResults:
            return "No food items were detected in the image."
        }
    }
}

/// Classification result from Vision framework
struct VisionClassificationResult: Sendable {
    let identifier: String
    let confidence: Float
    let boundingBox: CGRect?
}

/// Protocol defining the food classifier interface.
/// Implementations can use Core ML, on-device models, or server-side AI.
protocol FoodClassifierProtocol: Sendable {
    /// Classify food items in the given image and return detected food DTOs.
    func classify(image: UIImage) async throws -> [DetectedFoodDTO]
}

/// Protocol for raw Vision classification (without nutrition mapping)
protocol VisionClassifierProtocol: Sendable {
    /// Run Vision classification and return raw results
    func classifyRaw(image: UIImage) async throws -> [VisionClassificationResult]
}

/// Mock implementation of FoodClassifierProtocol that returns simulated food detection data.
/// Used during development until a real Core ML model (.mlmodel) is integrated.
final class MockFoodClassifierService: FoodClassifierProtocol, Sendable {

    /// Simulated classification delay range (seconds)
    private let minDelay: UInt64 = 800_000_000   // 0.8s
    private let maxDelay: UInt64 = 1_500_000_000  // 1.5s

    func classify(image: UIImage) async throws -> [DetectedFoodDTO] {
        // Validate the image has data
        guard image.cgImage != nil || image.ciImage != nil else {
            throw FoodClassifierError.invalidImage
        }

        // Simulate ML processing time
        let delay = UInt64.random(in: minDelay...maxDelay)
        try await Task.sleep(nanoseconds: delay)

        // Return mock detected foods
        return Self.mockFoods
    }

    // MARK: - Mock Data

    /// Sample food items for development and testing
    private static let mockFoods: [DetectedFoodDTO] = [
        DetectedFoodDTO(
            name: "Poached Egg",
            nameZh: "水波蛋",
            emoji: "🥚",
            confidence: 0.95,
            boundingBox: BoundingBoxDTO(x: 0.3, y: 0.2, w: 0.2, h: 0.15),
            calories: 71,
            proteinGrams: 6.3,
            carbsGrams: 0.4,
            fatGrams: 5.0,
            color: "#4ADE80"
        ),
        DetectedFoodDTO(
            name: "Avocado",
            nameZh: "牛油果",
            emoji: "🥑",
            confidence: 0.91,
            boundingBox: BoundingBoxDTO(x: 0.55, y: 0.25, w: 0.25, h: 0.2),
            calories: 160,
            proteinGrams: 2.0,
            carbsGrams: 8.5,
            fatGrams: 14.7,
            color: "#FACC15"
        ),
        DetectedFoodDTO(
            name: "Whole Wheat Toast",
            nameZh: "全麦吐司",
            emoji: "🍞",
            confidence: 0.88,
            boundingBox: BoundingBoxDTO(x: 0.1, y: 0.5, w: 0.35, h: 0.25),
            calories: 128,
            proteinGrams: 4.0,
            carbsGrams: 22.8,
            fatGrams: 2.5,
            color: "#FB923C"
        )
    ]
}

/// Production-ready Core ML classifier using Vision framework.
/// Runs VNCoreMLRequest with a food detection model for on-device inference.
final class CoreMLFoodClassifierService: FoodClassifierProtocol, VisionClassifierProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// The loaded Vision Core ML model
    private var vnModel: VNCoreMLModel?

    /// Model loading state
    private var isModelLoaded = false

    /// Nutrition database for mapping food identifiers to nutrition data
    private let nutritionMapper: NutritionMapperProtocol

    // MARK: - Initialization

    init(nutritionMapper: NutritionMapperProtocol = DefaultNutritionMapper()) {
        self.nutritionMapper = nutritionMapper
        loadModel()
    }

    // MARK: - Model Loading

    /// Load the Core ML model asynchronously
    private func loadModel() {
        // TODO: Replace "FoodDetector" with your actual model class name
        // The model class is auto-generated when you add a .mlmodel file to Xcode
        //
        // Example:
        // do {
        //     let config = MLModelConfiguration()
        //     config.computeUnits = .all // Use Neural Engine when available
        //     let mlModel = try FoodDetector(configuration: config)
        //     vnModel = try VNCoreMLModel(for: mlModel.model)
        //     isModelLoaded = true
        // } catch {
        //     print("Failed to load Core ML model: \(error)")
        // }

        // For now, model loading is stubbed until .mlmodel is added
        isModelLoaded = false
    }

    // MARK: - FoodClassifierProtocol

    func classify(image: UIImage) async throws -> [DetectedFoodDTO] {
        // If model is not loaded, fall back to mock service
        guard isModelLoaded, vnModel != nil else {
            let mockService = MockFoodClassifierService()
            return try await mockService.classify(image: image)
        }

        // Run raw classification
        let rawResults = try await classifyRaw(image: image)

        // Map raw results to DetectedFoodDTO with nutrition data
        var detectedFoods: [DetectedFoodDTO] = []

        for result in rawResults {
            if let foodDTO = nutritionMapper.map(
                identifier: result.identifier,
                confidence: Double(result.confidence),
                boundingBox: result.boundingBox
            ) {
                detectedFoods.append(foodDTO)
            }
        }

        guard !detectedFoods.isEmpty else {
            throw FoodClassifierError.noResults
        }

        return detectedFoods
    }

    // MARK: - VisionClassifierProtocol

    func classifyRaw(image: UIImage) async throws -> [VisionClassificationResult] {
        guard let cgImage = image.cgImage else {
            throw FoodClassifierError.invalidImage
        }

        guard let vnModel else {
            throw FoodClassifierError.modelNotLoaded
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: vnModel) { request, error in
                if let error {
                    continuation.resume(throwing: FoodClassifierError.visionRequestFailed(error))
                    return
                }

                var results: [VisionClassificationResult] = []

                // Handle object detection results (with bounding boxes)
                if let observations = request.results as? [VNRecognizedObjectObservation] {
                    for observation in observations {
                        guard let topLabel = observation.labels.first else { continue }
                        results.append(VisionClassificationResult(
                            identifier: topLabel.identifier,
                            confidence: topLabel.confidence,
                            boundingBox: observation.boundingBox
                        ))
                    }
                }
                // Handle classification results (without bounding boxes)
                else if let observations = request.results as? [VNClassificationObservation] {
                    for observation in observations where observation.confidence > 0.1 {
                        results.append(VisionClassificationResult(
                            identifier: observation.identifier,
                            confidence: observation.confidence,
                            boundingBox: nil
                        ))
                    }
                }

                continuation.resume(returning: results)
            }

            // Configure request for best accuracy
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: FoodClassifierError.visionRequestFailed(error))
            }
        }
    }
}

// MARK: - Nutrition Mapper Protocol

/// Protocol for mapping food identifiers to nutrition data
protocol NutritionMapperProtocol: Sendable {
    /// Map a food identifier to a DetectedFoodDTO with nutrition information
    func map(identifier: String, confidence: Double, boundingBox: CGRect?) -> DetectedFoodDTO?
}

/// Default nutrition mapper with a built-in food database
final class DefaultNutritionMapper: NutritionMapperProtocol, Sendable {

    /// Nutrition database mapping food identifiers to nutrition data
    private static let database: [String: (nameZh: String, emoji: String, calories: Int, protein: Double, carbs: Double, fat: Double, color: String)] = [
        // Fruits
        "apple": ("苹果", "🍎", 52, 0.3, 14.0, 0.2, "#EF4444"),
        "banana": ("香蕉", "🍌", 89, 1.1, 23.0, 0.3, "#FACC15"),
        "orange": ("橙子", "🍊", 47, 0.9, 12.0, 0.1, "#FB923C"),
        "avocado": ("牛油果", "🥑", 160, 2.0, 8.5, 14.7, "#84CC16"),

        // Vegetables
        "broccoli": ("西兰花", "🥦", 34, 2.8, 7.0, 0.4, "#22C55E"),
        "carrot": ("胡萝卜", "🥕", 41, 0.9, 10.0, 0.2, "#FB923C"),
        "tomato": ("番茄", "🍅", 18, 0.9, 3.9, 0.2, "#EF4444"),

        // Proteins
        "egg": ("鸡蛋", "🥚", 155, 13.0, 1.1, 11.0, "#FCD34D"),
        "chicken": ("鸡肉", "🍗", 165, 31.0, 0.0, 3.6, "#D97706"),
        "fish": ("鱼", "🐟", 206, 22.0, 0.0, 12.0, "#3B82F6"),
        "beef": ("牛肉", "🥩", 250, 26.0, 0.0, 15.0, "#DC2626"),
        "tofu": ("豆腐", "🧈", 76, 8.0, 1.9, 4.8, "#FEF3C7"),

        // Grains
        "rice": ("米饭", "🍚", 130, 2.7, 28.0, 0.3, "#F5F5F4"),
        "bread": ("面包", "🍞", 265, 9.0, 49.0, 3.2, "#D97706"),
        "noodles": ("面条", "🍜", 138, 4.5, 25.0, 2.1, "#FEF3C7"),
        "toast": ("吐司", "🍞", 128, 4.0, 22.8, 2.5, "#FB923C"),

        // Dairy
        "milk": ("牛奶", "🥛", 42, 3.4, 5.0, 1.0, "#F5F5F4"),
        "cheese": ("奶酪", "🧀", 402, 25.0, 1.3, 33.0, "#FACC15"),
        "yogurt": ("酸奶", "🥛", 59, 10.0, 3.6, 0.7, "#F5F5F4"),

        // Beverages
        "coffee": ("咖啡", "☕️", 2, 0.3, 0.0, 0.0, "#78350F"),
        "tea": ("茶", "🍵", 1, 0.0, 0.0, 0.0, "#84CC16"),

        // Common dishes
        "salad": ("沙拉", "🥗", 20, 1.5, 3.0, 0.2, "#22C55E"),
        "soup": ("汤", "🍲", 30, 2.0, 4.0, 1.0, "#F97316"),
        "pizza": ("披萨", "🍕", 266, 11.0, 33.0, 10.0, "#EF4444"),
        "burger": ("汉堡", "🍔", 295, 17.0, 24.0, 14.0, "#D97706"),
        "sushi": ("寿司", "🍣", 150, 5.5, 30.0, 0.7, "#F43F5E"),
        "ramen": ("拉面", "🍜", 436, 16.0, 56.0, 15.0, "#FEF3C7")
    ]

    func map(identifier: String, confidence: Double, boundingBox: CGRect?) -> DetectedFoodDTO? {
        let normalizedId = identifier.lowercased().trimmingCharacters(in: .whitespaces)

        // Try exact match first
        if let data = Self.database[normalizedId] {
            return createDTO(
                name: identifier.capitalized,
                data: data,
                confidence: confidence,
                boundingBox: boundingBox
            )
        }

        // Try partial match
        for (key, data) in Self.database {
            if normalizedId.contains(key) || key.contains(normalizedId) {
                return createDTO(
                    name: identifier.capitalized,
                    data: data,
                    confidence: confidence,
                    boundingBox: boundingBox
                )
            }
        }

        // Return nil for unknown foods (caller should handle)
        return nil
    }

    private func createDTO(
        name: String,
        data: (nameZh: String, emoji: String, calories: Int, protein: Double, carbs: Double, fat: Double, color: String),
        confidence: Double,
        boundingBox: CGRect?
    ) -> DetectedFoodDTO {
        let box = boundingBox ?? CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
        return DetectedFoodDTO(
            name: name,
            nameZh: data.nameZh,
            emoji: data.emoji,
            confidence: confidence,
            boundingBox: BoundingBoxDTO(x: box.origin.x, y: box.origin.y, w: box.width, h: box.height),
            calories: data.calories,
            proteinGrams: data.protein,
            carbsGrams: data.carbs,
            fatGrams: data.fat,
            color: data.color
        )
    }
}
