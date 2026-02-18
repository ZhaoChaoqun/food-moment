import Foundation

// MARK: - Meal Response DTO

struct MealResponseDTO: Decodable, Sendable {
    let id: UUID
    let imageUrl: String?
    let mealType: String
    let mealTime: Date
    let totalCalories: Int
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    let fiberGrams: Double
    let title: String
    let descriptionText: String?
    let aiAnalysis: String?
    let tags: [String]?
    let detectedFoods: [DetectedFoodDTO]
    let createdAt: Date
}

// MARK: - Meal Create DTO

struct MealCreateDTO: Encodable, Sendable {
    let imageUrl: String?
    let mealType: String
    let mealTime: Date
    let totalCalories: Int
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    let fiberGrams: Double
    let title: String
    let descriptionText: String?
    let aiAnalysis: String?
    let tags: [String]
    let detectedFoods: [DetectedFoodCreateDTO]
}

struct DetectedFoodCreateDTO: Encodable, Sendable {
    let name: String
    let nameZh: String
    let emoji: String
    let confidence: Double
    let boundingBoxX: Double
    let boundingBoxY: Double
    let boundingBoxW: Double
    let boundingBoxH: Double
    let calories: Int
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
}

// MARK: - Meal Update DTO

struct MealUpdateDTO: Encodable, Sendable {
    let mealType: String?
    let mealTime: Date?
    let totalCalories: Int?
    let proteinGrams: Double?
    let carbsGrams: Double?
    let fatGrams: Double?
    let fiberGrams: Double?
    let title: String?
    let descriptionText: String?
    let tags: [String]?
}
