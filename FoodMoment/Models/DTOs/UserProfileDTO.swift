import Foundation

// MARK: - User Profile Response DTO

struct UserProfileResponseDTO: Decodable, Sendable {
    let id: UUID
    let displayName: String
    let email: String?
    let avatarUrl: String?
    let isPro: Bool
    let dailyCalorieGoal: Int
    let dailyProteinGoal: Int
    let dailyCarbsGoal: Int
    let dailyFatGoal: Int
    let targetWeight: Double?
    let createdAt: Date
}

// MARK: - User Profile Update DTO

struct UserProfileUpdateDTO: Encodable, Sendable {
    let displayName: String?
    let avatarUrl: String?
    let dailyCalorieGoal: Int?
    let dailyProteinGoal: Int?
    let dailyCarbsGoal: Int?
    let dailyFatGoal: Int?
    let targetWeight: Double?
}

// MARK: - Goals Update DTO

struct GoalsUpdateDTO: Encodable, Sendable {
    let dailyCalorieGoal: Int?
    let dailyProteinGoal: Int?
    let dailyCarbsGoal: Int?
    let dailyFatGoal: Int?
}

// MARK: - Weight Log DTOs

struct WeightLogCreateDTO: Encodable, Sendable {
    let weightKg: Double
    let recordedAt: Date
}

struct WeightLogResponseDTO: Decodable, Sendable {
    let id: UUID
    let weightKg: Double
    let recordedAt: Date
    let createdAt: Date
}

// MARK: - Streak Response DTO

struct StreakResponseDTO: Decodable, Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let totalDaysLogged: Int
}
