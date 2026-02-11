import Foundation

// MARK: - Insight Response DTO

struct InsightResponseDTO: Decodable, Sendable {
    let insight: String
    let tips: [String]
    let calorieTrend: String
    let proteinAdequacy: String
}
