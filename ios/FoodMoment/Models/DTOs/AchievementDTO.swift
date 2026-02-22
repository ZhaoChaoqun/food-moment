import Foundation

// MARK: - Achievement Response DTO

struct AchievementResponseDTO: Decodable, Sendable {
    let id: String
    let unlocked: Bool
    let progress: Int
    let target: Int
    let category: String
}
