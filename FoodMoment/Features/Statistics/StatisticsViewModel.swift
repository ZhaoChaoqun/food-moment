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
    case year = "年"

    var id: String { rawValue }

    var dayCount: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }

    var englishTitle: String {
        switch self {
        case .day: return "Daily"
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Yearly"
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class StatisticsViewModel {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "StatisticsViewModel")

    // MARK: - Published Properties

    var selectedRange: TimeRange = .week {
        didSet {
            loadStatistics()
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

    init() {
        loadStatistics()
    }

    // MARK: - Public Methods

    func loadStatistics() {
        isLoading = true
        defer { isLoading = false }

        loadMockData()
        loadMockMacros()
        loadMockCheckins()
        loadMockAIInsight()
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

    private func loadMockData() {
        let calendar = Calendar.current
        let today = Date()
        let count = selectedRange.dayCount

        var data: [DailyCalorie] = []
        for i in (0..<count).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let base = MockDataProvider.Statistics.baseCalories
            let variation = Int.random(in: MockDataProvider.Statistics.calorieVariationRange)
            let calories = max(MockDataProvider.Statistics.calorieMinClamp, min(MockDataProvider.Statistics.calorieMaxClamp, base + variation))
            let protein = Double.random(in: 15...45)
            let carbs = Double.random(in: 30...80)
            let fat = Double.random(in: 10...30)
            data.append(DailyCalorie(date: date, calories: calories, protein: protein, carbs: carbs, fat: fat))
        }
        calorieData = data

        let recentDays = Array(data.suffix(7))
        let totalCalories = recentDays.reduce(0) { $0 + $1.calories }
        weeklyAverage = recentDays.isEmpty ? 0 : totalCalories / recentDays.count
        weeklyChange = Double.random(in: -15...20)
    }

    private func loadMockMacros() {
        let ranges: (protein: ClosedRange<Double>, carbs: ClosedRange<Double>, fat: ClosedRange<Double>)
        switch selectedRange {
        case .day:   ranges = MockDataProvider.Statistics.MacroRanges.day
        case .week:  ranges = MockDataProvider.Statistics.MacroRanges.week
        case .month: ranges = MockDataProvider.Statistics.MacroRanges.month
        case .year:  ranges = MockDataProvider.Statistics.MacroRanges.year
        }
        proteinTotal = Double.random(in: ranges.protein)
        carbsTotal = Double.random(in: ranges.carbs)
        fatTotal = Double.random(in: ranges.fat)
    }

    private func loadMockCheckins() {
        let calendar = Calendar.current
        let today = Date()
        var days: [Date] = []

        for i in 0..<MockDataProvider.Statistics.checkinLookbackDays {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            if Bool.random() || Int.random(in: 0...9) < 7 {
                days.append(date)
            }
        }
        checkinDays = days
    }

    private func loadMockAIInsight() {
        let insights = MockDataProvider.Statistics.aiInsights
        aiInsight = insights.randomElement() ?? insights[0]
    }
}
