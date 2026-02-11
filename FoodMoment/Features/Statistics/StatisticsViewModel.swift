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

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()

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
            let dateString = Self.dateFormatter.string(from: today)
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
                Self.logger.error("Failed to load daily stats: \(error, privacy: .public)")
            }

        case .week:
            let weekStart = today.startOfWeek
            let weekString = Self.dateFormatter.string(from: weekStart)
            do {
                let stats = try await statsService.getWeeklyStats(week: weekString)
                calorieData = stats.dailyStats.compactMap { daily in
                    guard let date = Self.dateFormatter.date(from: daily.date) else { return nil }
                    return DailyCalorie(
                        date: date,
                        calories: daily.totalCalories,
                        protein: daily.proteinGrams,
                        carbs: daily.carbsGrams,
                        fat: daily.fatGrams
                    )
                }
                weeklyAverage = Int(stats.avgCalories)
                proteinTotal = stats.avgProtein * Double(stats.dailyStats.count)
                carbsTotal = stats.avgCarbs * Double(stats.dailyStats.count)
                fatTotal = stats.avgFat * Double(stats.dailyStats.count)
                checkinDays = stats.dailyStats.filter { $0.mealCount > 0 }.compactMap {
                    Self.dateFormatter.date(from: $0.date)
                }
                weeklyChange = 0
            } catch {
                Self.logger.error("Failed to load weekly stats: \(error, privacy: .public)")
            }

        case .month:
            let monthString = Self.monthFormatter.string(from: today)
            do {
                let stats = try await statsService.getMonthlyStats(month: monthString)
                calorieData = stats.dailyStats.compactMap { daily in
                    guard let date = Self.dateFormatter.date(from: daily.date) else { return nil }
                    return DailyCalorie(
                        date: date,
                        calories: daily.totalCalories,
                        protein: daily.proteinGrams,
                        carbs: daily.carbsGrams,
                        fat: daily.fatGrams
                    )
                }
                weeklyAverage = Int(stats.avgCalories)
                proteinTotal = stats.avgProtein * Double(stats.dailyStats.count)
                carbsTotal = stats.avgCarbs * Double(stats.dailyStats.count)
                fatTotal = stats.avgFat * Double(stats.dailyStats.count)
                checkinDays = stats.dailyStats.filter { $0.mealCount > 0 }.compactMap {
                    Self.dateFormatter.date(from: $0.date)
                }
                weeklyChange = 0
            } catch {
                Self.logger.error("Failed to load monthly stats: \(error, privacy: .public)")
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var csvString = "Date,Calories,Protein(g),Carbs(g),Fat(g)\n"

        for item in calorieData {
            let dateString = dateFormatter.string(from: item.date)
            let proteinString = String(format: "%.1f", item.protein)
            let carbsString = String(format: "%.1f", item.carbs)
            let fatString = String(format: "%.1f", item.fat)
            csvString += "\(dateString),\(item.calories),\(proteinString),\(carbsString),\(fatString)\n"
        }

        return csvString
    }

    func createCSVFile() -> URL? {
        let csvString = generateCSVData()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "FoodMoment_Statistics_\(timestamp).csv"

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            Self.logger.error("Failed to create CSV file: \(error.localizedDescription, privacy: .public)")
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

    private func loadInsights() async {
        do {
            let insight = try await statsService.getInsights()
            aiInsight = insight.insight
        } catch {
            aiInsight = "暂无数据分析，记录更多餐食后将生成个性化建议。"
        }
    }
}
