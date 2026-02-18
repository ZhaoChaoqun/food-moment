import Foundation

// MARK: - Water Service Protocol

protocol WaterServiceProtocol: Sendable {
    func getWater(date: String) async throws -> DailyWaterResponseDTO
    func logWater(_ entry: WaterLogCreateDTO) async throws -> WaterLogResponseDTO
}

// MARK: - Water Service

final class WaterService: WaterServiceProtocol {

    static let shared = WaterService()
    private init() {}

    func getWater(date: String) async throws -> DailyWaterResponseDTO {
        try await APIClient.shared.request(.getWater(date: date))
    }

    func logWater(_ entry: WaterLogCreateDTO) async throws -> WaterLogResponseDTO {
        try await APIClient.shared.request(.logWater, body: entry)
    }
}
