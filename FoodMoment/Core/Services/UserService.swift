import Foundation

// MARK: - User Service Protocol

protocol UserServiceProtocol: Sendable {
    func getProfile() async throws -> UserProfileResponseDTO
    func updateProfile(_ update: UserProfileUpdateDTO) async throws -> UserProfileResponseDTO
    func updateGoals(_ goals: GoalsUpdateDTO) async throws
    func getAchievements() async throws -> [AchievementResponseDTO]
    func getStreaks() async throws -> StreakResponseDTO
    func logWeight(_ entry: WeightLogCreateDTO) async throws -> WeightLogResponseDTO
}

// MARK: - User Service

final class UserService: UserServiceProtocol {

    static let shared = UserService()
    private init() {}

    func getProfile() async throws -> UserProfileResponseDTO {
        try await APIClient.shared.request(.getProfile)
    }

    func updateProfile(_ update: UserProfileUpdateDTO) async throws -> UserProfileResponseDTO {
        try await APIClient.shared.request(.updateProfile, body: update)
    }

    func updateGoals(_ goals: GoalsUpdateDTO) async throws {
        try await APIClient.shared.requestVoid(.updateGoals, body: goals)
    }

    func getAchievements() async throws -> [AchievementResponseDTO] {
        try await APIClient.shared.request(.achievements)
    }

    func getStreaks() async throws -> StreakResponseDTO {
        try await APIClient.shared.request(.streaks)
    }

    func logWeight(_ entry: WeightLogCreateDTO) async throws -> WeightLogResponseDTO {
        try await APIClient.shared.request(.logWeight, body: entry)
    }
}
