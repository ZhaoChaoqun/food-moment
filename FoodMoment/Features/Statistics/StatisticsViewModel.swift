import Foundation
import Observation
import SwiftUI
import UniformTypeIdentifiers

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
            print("Failed to create CSV file: \(error)")
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
            let base = 2100
            let variation = Int.random(in: -300...300)
            let calories = max(1400, min(2800, base + variation))
            let protein = Double.random(in: 15...45)
            let carbs = Double.random(in: 30...80)
            let fat = Double.random(in: 10...30)
            data.append(DailyCalorie(date: date, calories: calories, protein: protein, carbs: carbs, fat: fat))
        }
        calorieData = data

        // 计算周平均值
        let recentDays = Array(data.suffix(7))
        let totalCalories = recentDays.reduce(0) { $0 + $1.calories }
        weeklyAverage = recentDays.isEmpty ? 0 : totalCalories / recentDays.count

        // 模拟周变化百分比
        weeklyChange = Double.random(in: -15...20)
    }

    private func loadMockMacros() {
        switch selectedRange {
        case .day:
            proteinTotal = Double.random(in: 60...120)
            carbsTotal = Double.random(in: 180...280)
            fatTotal = Double.random(in: 50...90)
        case .week:
            proteinTotal = Double.random(in: 450...840)
            carbsTotal = Double.random(in: 1200...2000)
            fatTotal = Double.random(in: 350...630)
        case .month:
            proteinTotal = Double.random(in: 1800...3600)
            carbsTotal = Double.random(in: 5400...8400)
            fatTotal = Double.random(in: 1500...2700)
        case .year:
            proteinTotal = Double.random(in: 21600...43200)
            carbsTotal = Double.random(in: 64800...100800)
            fatTotal = Double.random(in: 18000...32400)
        }
    }

    private func loadMockCheckins() {
        let calendar = Calendar.current
        let today = Date()
        var days: [Date] = []

        for i in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            // 约 70% 概率打卡
            if Bool.random() || Int.random(in: 0...9) < 7 {
                days.append(date)
            }
        }
        checkinDays = days
    }

    private func loadMockAIInsight() {
        let insights = [
            "本周蛋白质摄入偏低，建议增加鸡蛋、鸡胸肉等高蛋白食物。碳水摄入稳定，继续保持！",
            "你的饮食习惯正在改善！本周蔬菜摄入增加了 20%，继续保持均衡饮食。",
            "近期脂肪摄入略高，可以适当减少油炸食品。建议多吃蒸煮类食物。",
            "打卡连续性很好！坚持记录饮食有助于养成健康的饮食习惯。本周热量控制在合理范围内。"
        ]
        aiInsight = insights.randomElement() ?? insights[0]
    }
}
