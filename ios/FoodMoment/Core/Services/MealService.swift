import Foundation

// MARK: - Meal Service Protocol

protocol MealServiceProtocol: Sendable {
    func getMeals(date: String) async throws -> [MealResponseDTO]
    func getWeekDates(week: String) async throws -> WeekDatesDTO
    func createMeal(_ meal: MealCreateDTO) async throws -> MealResponseDTO
    func updateMeal(id: String, _ update: MealUpdateDTO) async throws -> MealResponseDTO
    func deleteMeal(id: String) async throws
}

// MARK: - Meal Service

final class MealService: MealServiceProtocol {

    static let shared = MealService()
    private init() {}

    func getMeals(date: String) async throws -> [MealResponseDTO] {
        try await APIClient.shared.request(.getMeals(date: date))
    }

    func getWeekDates(week: String) async throws -> WeekDatesDTO {
        try await APIClient.shared.request(.getWeekDates(week: week))
    }

    func createMeal(_ meal: MealCreateDTO) async throws -> MealResponseDTO {
        try await APIClient.shared.request(.createMeal, body: meal)
    }

    func updateMeal(id: String, _ update: MealUpdateDTO) async throws -> MealResponseDTO {
        try await APIClient.shared.request(.updateMeal(id: id), body: update)
    }

    func deleteMeal(id: String) async throws {
        try await APIClient.shared.requestVoid(.deleteMeal(id: id))
    }
}
