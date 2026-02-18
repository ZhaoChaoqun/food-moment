import Foundation

// MARK: - Achievement Response DTO

struct AchievementResponseDTO: Decodable, Sendable {
    let id: String
    let title: String
    let description: String
    let emoji: String
    let unlocked: Bool
    let progress: Int
    let target: Int
}
