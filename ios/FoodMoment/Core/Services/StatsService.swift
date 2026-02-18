import Foundation

// MARK: - Stats Service Protocol

protocol StatsServiceProtocol: Sendable {
    func getDailyStats(date: String) async throws -> DailyStatsDTO
    func getWeeklyStats(week: String) async throws -> WeeklyStatsDTO
    func getMonthlyStats(month: String) async throws -> MonthlyStatsDTO
    func getInsights() async throws -> InsightResponseDTO
}

// MARK: - Stats Service

final class StatsService: StatsServiceProtocol {

    static let shared = StatsService()
    private init() {}

    func getDailyStats(date: String) async throws -> DailyStatsDTO {
        try await APIClient.shared.request(.dailyStats(date: date))
    }

    func getWeeklyStats(week: String) async throws -> WeeklyStatsDTO {
        try await APIClient.shared.request(.weeklyStats(week: week))
    }

    func getMonthlyStats(month: String) async throws -> MonthlyStatsDTO {
        try await APIClient.shared.request(.monthlyStats(month: month))
    }

    func getInsights() async throws -> InsightResponseDTO {
        try await APIClient.shared.request(.insights)
    }
}
