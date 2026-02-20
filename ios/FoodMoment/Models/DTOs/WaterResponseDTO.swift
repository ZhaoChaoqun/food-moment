import Foundation

// MARK: - Water Log Response DTO

struct WaterLogResponseDTO: Decodable, Sendable {
    let id: UUID
    let amountMl: Int
    let recordedAt: Date
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Daily Water Response DTO

struct DailyWaterResponseDTO: Decodable, Sendable {
    let date: String
    let totalMl: Int
    let goalMl: Int
    let logs: [WaterLogResponseDTO]
}

// MARK: - Water Log Create DTO

struct WaterLogCreateDTO: Encodable, Sendable {
    let amountMl: Int
}
