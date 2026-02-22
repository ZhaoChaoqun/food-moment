import Foundation
@testable import FoodMoment

// MARK: - Mock Meal Service

final class MockMealService: MealServiceProtocol, @unchecked Sendable {
    var getMealsResult: Result<[MealResponseDTO], Error> = .success([])
    var getWeekDatesResult: Result<WeekDatesDTO, Error> = .success(WeekDatesDTO(datesWithMeals: []))
    var createMealResult: Result<MealResponseDTO, Error>?
    var deleteMealResult: Result<Void, Error> = .success(())

    var getMealsCallCount = 0
    var lastGetMealsDate: String?

    func getMeals(date: String) async throws -> [MealResponseDTO] {
        getMealsCallCount += 1
        lastGetMealsDate = date
        return try getMealsResult.get()
    }

    func getWeekDates(week: String) async throws -> WeekDatesDTO {
        try getWeekDatesResult.get()
    }

    func createMeal(_ meal: MealCreateDTO) async throws -> MealResponseDTO {
        guard let result = createMealResult else {
            throw APIError.networkError(NSError(domain: "Mock", code: -1))
        }
        return try result.get()
    }

    func updateMeal(id: String, _ update: MealUpdateDTO) async throws -> MealResponseDTO {
        throw APIError.networkError(NSError(domain: "Mock", code: -1))
    }

    func deleteMeal(id: String) async throws {
        try deleteMealResult.get()
    }
}

// MARK: - Mock Water Service

final class MockWaterService: WaterServiceProtocol, @unchecked Sendable {
    var getWaterResult: Result<DailyWaterResponseDTO, Error> = .success(
        DailyWaterResponseDTO(date: "2025-01-01", totalMl: 0, goalMl: 2000, logs: [])
    )
    var logWaterResult: Result<WaterLogResponseDTO, Error>?

    func getWater(date: String) async throws -> DailyWaterResponseDTO {
        try getWaterResult.get()
    }

    func logWater(_ entry: WaterLogCreateDTO) async throws -> WaterLogResponseDTO {
        guard let result = logWaterResult else {
            throw APIError.networkError(NSError(domain: "Mock", code: -1))
        }
        return try result.get()
    }
}

// MARK: - Mock User Service

final class MockUserService: UserServiceProtocol, @unchecked Sendable {
    var getProfileResult: Result<UserProfileResponseDTO, Error> = .success(
        UserProfileResponseDTO(
            id: UUID(),
            displayName: "TestUser",
            email: nil,
            avatarUrl: nil,
            isPro: false,
            dailyCalorieGoal: 2000,
            dailyProteinGoal: 60,
            dailyCarbsGoal: 250,
            dailyFatGoal: 65,
            targetWeight: nil,
            gender: nil,
            birthYear: nil,
            heightCm: nil,
            activityLevel: nil,
            dailyWaterGoal: 2000,
            dailyStepGoal: 8000,
            createdAt: Date(),
            updatedAt: Date()
        )
    )

    func getProfile() async throws -> UserProfileResponseDTO {
        try getProfileResult.get()
    }

    func updateProfile(_ update: UserProfileUpdateDTO) async throws -> UserProfileResponseDTO {
        try getProfileResult.get()
    }

    func updateGoals(_ goals: GoalsUpdateDTO) async throws {}

    func getAchievements() async throws -> [AchievementResponseDTO] { [] }

    func getStreaks() async throws -> StreakResponseDTO {
        StreakResponseDTO(currentStreak: 0, longestStreak: 0, totalDaysLogged: 0)
    }

    func logWeight(_ entry: WeightLogCreateDTO) async throws -> WeightLogResponseDTO {
        WeightLogResponseDTO(
            id: UUID(),
            weightKg: entry.weightKg,
            recordedAt: entry.recordedAt,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func uploadAvatar(imageData: Data) async throws -> AvatarUploadResponseDTO {
        AvatarUploadResponseDTO(avatarUrl: "https://example.com/avatar.jpg")
    }
}
