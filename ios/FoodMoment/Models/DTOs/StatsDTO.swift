import Foundation

// MARK: - Daily Stats DTO

struct DailyStatsDTO: Decodable, Sendable {
    let date: String
    let totalCalories: Int
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    let fiberGrams: Double
    let mealCount: Int
    let waterMl: Int
}

// MARK: - Weekly Stats DTO

struct WeeklyStatsDTO: Decodable, Sendable {
    let weekStart: String
    let weekEnd: String
    let avgCalories: Double
    let avgProtein: Double
    let avgCarbs: Double
    let avgFat: Double
    let totalMeals: Int
    let dailyStats: [DailyStatsDTO]
}

// MARK: - Monthly Stats DTO

struct MonthlyStatsDTO: Decodable, Sendable {
    let month: String
    let avgCalories: Double
    let avgProtein: Double
    let avgCarbs: Double
    let avgFat: Double
    let totalMeals: Int
    let streakDays: Int
    let dailyStats: [DailyStatsDTO]
}
