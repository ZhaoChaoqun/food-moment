import Foundation

// MARK: - Meal Service Protocol

protocol MealServiceProtocol: Sendable {
    func getMeals(date: String) async throws -> [MealResponseDTO]
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
