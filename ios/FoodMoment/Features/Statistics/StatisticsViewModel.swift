import Foundation
import Observation
import SwiftUI
import UniformTypeIdentifiers
import os

// MARK: - Data Models

struct DailyCalorie: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double

    init(date: Date, calories: Int, protein: Double = 0, carbs: Double = 0, fat: Double = 0) {
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

// MARK: - Time Range

enum TimeRange: String, CaseIterable, Identifiable {
    case day = "日"
    case week = "周"
    case month = "月"

    var id: String { rawValue }

    var dayCount: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        }
    }

    var englishTitle: String {
        switch self {
        case .day: return "Daily"
        case .week: return "Weekly"
        case .month: return "Monthly"
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class StatisticsViewModel {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "StatisticsViewModel")

    // MARK: - Private

    private let statsService: StatsServiceProtocol

    // MARK: - Published Properties

    var selectedRange: TimeRange = .week {
        didSet {
            Task { await loadStatistics() }
        }
    }

    var calorieData: [DailyCalorie] = []
    var weeklyAverage: Int = 0
    var weeklyChange: Double = 0.0

    var proteinTotal: Double = 0
    var carbsTotal: Double = 0
    var fatTotal: Double = 0

    var checkinDays: [Date] = []

    var aiInsight: String = ""

    var selectedDataPoint: DailyCalorie?

    var isLoading = false
    var selectedDate: Date = Date()

    // MARK: - Computed Properties

    var weeklyChangeText: String {
        let sign = weeklyChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", weeklyChange))%"
    }

    var isPositiveChange: Bool {
        weeklyChange >= 0
    }

    var averageLabel: String {
        selectedRange.englishTitle + " Average"
    }

    var averageLabelCN: String {
        switch selectedRange {
        case .day: return "今日摄入"
        case .week: return "每周平均"
        case .month: return "每月平均"
        }
    }

    // MARK: - Initialization

    init(statsService: StatsServiceProtocol = StatsService.shared) {
        self.statsService = statsService
        Task { await loadStatistics() }
    }

    // MARK: - Public Methods

    func loadStatistics() async {
        isLoading = true
        defer { isLoading = false }

        let today = selectedDate

        switch selectedRange {
        case .day:
            let dateString = today.apiDateString
            do {
                let stats = try await statsService.getDailyStats(date: dateString)
                calorieData = [DailyCalorie(
                    date: today,
                    calories: stats.totalCalories,
                    protein: stats.proteinGrams,
                    carbs: stats.carbsGrams,
                    fat: stats.fatGrams
                )]
                weeklyAverage = stats.totalCalories
                proteinTotal = stats.proteinGrams
                carbsTotal = stats.carbsGrams
                fatTotal = stats.fatGrams
                checkinDays = stats.mealCount > 0 ? [today] : []
                weeklyChange = 0
            } catch {
                Self.logger.error("[Stats] Failed to load daily stats: \(error, privacy: .public)")
            }

        case .week:
            let weekStart = today.startOfWeek
            let weekString = weekStart.apiDateString
            do {
                let stats = try await statsService.getWeeklyStats(week: weekString)
                applyMultiDayStats(
                    dailyStats: stats.dailyStats,
                    avgCalories: stats.avgCalories,
                    avgProtein: stats.avgProtein,
                    avgCarbs: stats.avgCarbs,
                    avgFat: stats.avgFat
                )
            } catch {
                Self.logger.error("[Stats] Failed to load weekly stats: \(error, privacy: .public)")
            }

        case .month:
            let monthString = today.apiMonthString
            do {
                let stats = try await statsService.getMonthlyStats(month: monthString)
                applyMultiDayStats(
                    dailyStats: stats.dailyStats,
                    avgCalories: stats.avgCalories,
                    avgProtein: stats.avgProtein,
                    avgCarbs: stats.avgCarbs,
                    avgFat: stats.avgFat
                )
            } catch {
                Self.logger.error("[Stats] Failed to load monthly stats: \(error, privacy: .public)")
            }
        }

        // Load AI insights
        await loadInsights()
    }

    func isCheckedIn(date: Date) -> Bool {
        let calendar = Calendar.current
        return checkinDays.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    // MARK: - CSV Export

    func generateCSVData() -> String {
        var csv = CSVBuilder(headers: ["Date", "Calories", "Protein(g)", "Carbs(g)", "Fat(g)"])

        for item in calorieData {
            csv.addRow([
                item.date.formatted(.iso8601.year().month().day().dateSeparator(.dash)),
                "\(item.calories)",
                String(format: "%.1f", item.protein),
                String(format: "%.1f", item.carbs),
                String(format: "%.1f", item.fat)
            ])
        }

        return csv.build()
    }

    func createCSVFile() -> URL? {
        let csvString = generateCSVData()
        let timestamp = Date().formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false).timeSeparator(.omitted))
        let filename = "FoodMoment_Statistics_\(timestamp).csv"

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            Self.logger.error("[Stats] Failed to create CSV file: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Data Aggregation

    struct AggregatedData: Codable {
        let period: String
        let startDate: Date
        let endDate: Date
        let totalCalories: Int
        let averageCalories: Int
        let totalProtein: Double
        let totalCarbs: Double
        let totalFat: Double
    }

    func prepareAggregatedDataForAPI() -> AggregatedData {
        let totalCal = calorieData.reduce(0) { $0 + $1.calories }
        let avgCal = calorieData.isEmpty ? 0 : totalCal / calorieData.count

        return AggregatedData(
            period: selectedRange.rawValue,
            startDate: calorieData.first?.date ?? Date(),
            endDate: calorieData.last?.date ?? Date(),
            totalCalories: totalCal,
            averageCalories: avgCal,
            totalProtein: proteinTotal,
            totalCarbs: carbsTotal,
            totalFat: fatTotal
        )
    }

    // MARK: - Private Methods

    private func applyMultiDayStats(
        dailyStats: [DailyStatsDTO],
        avgCalories: Double,
        avgProtein: Double,
        avgCarbs: Double,
        avgFat: Double
    ) {
        calorieData = dailyStats.compactMap { daily in
            guard let date = Date.fromAPIDateString(daily.date) else { return nil }
            return DailyCalorie(
                date: date,
                calories: daily.totalCalories,
                protein: daily.proteinGrams,
                carbs: daily.carbsGrams,
                fat: daily.fatGrams
            )
        }
        weeklyAverage = Int(avgCalories)
        proteinTotal = avgProtein * Double(dailyStats.count)
        carbsTotal = avgCarbs * Double(dailyStats.count)
        fatTotal = avgFat * Double(dailyStats.count)
        checkinDays = dailyStats.filter { $0.mealCount > 0 }.compactMap {
            Date.fromAPIDateString($0.date)
        }
        weeklyChange = 0
    }

    private func loadInsights() async {
        do {
            let insight = try await statsService.getInsights()
            aiInsight = insight.insight
        } catch {
            aiInsight = "暂无数据分析，记录更多餐食后将生成个性化建议。"
        }
    }
}
