import Foundation
import SwiftData
import SwiftUI

// MARK: - Achievement Item

struct AchievementItem: Identifiable, Sendable {
    let id = UUID()
    let type: String
    let title: String
    let icon: String
    let tier: AchievementTier
    let isEarned: Bool
    let earnedDate: Date?

    init(
        type: String,
        title: String,
        icon: String,
        tier: AchievementTier,
        isEarned: Bool,
        earnedDate: Date? = nil
    ) {
        self.type = type
        self.title = title
        self.icon = icon
        self.tier = tier
        self.isEarned = isEarned
        self.earnedDate = earnedDate
    }

    enum AchievementTier: String, Sendable {
        case gold
        case silver
        case bronze

        var label: String {
            switch self {
            case .gold: return "GOLD"
            case .silver: return "SILVER"
            case .bronze: return "BRONZE"
            }
        }

        var colors: [Color] {
            switch self {
            case .gold:
                return [Color(hex: "#FFD700"), Color(hex: "#FFA500")]
            case .silver:
                return [Color(hex: "#E0E0E0"), Color(hex: "#A0A0A0")]
            case .bronze:
                return [Color(hex: "#CD7F32"), Color(hex: "#8B4513")]
            }
        }

        var borderColor: Color {
            switch self {
            case .gold: return Color(hex: "#E6C200")
            case .silver: return Color(hex: "#A0A0A0")
            case .bronze: return Color(hex: "#A0522D")
            }
        }

        var backgroundColor: (light: Color, dark: Color) {
            switch self {
            case .gold:
                return (Color(hex: "#FFF8E7"), Color(hex: "#3D3200").opacity(0.3))
            case .silver:
                return (Color(hex: "#F5F5F5"), Color(hex: "#333333").opacity(0.3))
            case .bronze:
                return (Color(hex: "#FFF0E0"), Color(hex: "#3D2000").opacity(0.3))
            }
        }
    }
}

// MARK: - Daily Activity Data

struct DailyActivityData: Identifiable {
    let id = UUID()
    let day: Int
    let date: Date
    let proteinProgress: Double // 0-1
    let carbsProgress: Double   // 0-1
    let fatProgress: Double     // 0-1
    let hasActivity: Bool

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Nutrition Goals

/// 每日营养目标配置
private enum NutritionGoals {
    static let dailyProteinGrams: Double = 50.0
    static let dailyCarbsGrams: Double = 250.0
    static let dailyFatGrams: Double = 65.0
}

// MARK: - Date Range Configuration

/// 日期范围配置
private enum DateRangeConfig {
    static let oneWeekDays = -7
    static let twoWeeksDays = -14
}

// MARK: - Profile View Model

@MainActor
@Observable
final class ProfileViewModel {

    // MARK: - Published Properties

    var userName: String = ""
    var avatarAssetName: String?
    var isPro: Bool = false
    var currentWeight: Double = 0.0
    var targetWeight: Double = 0.0
    var weightTrend: String = ""
    var streakDays: Int = 0
    var achievements: [AchievementItem] = []
    var averageCalories: Int = 0
    var calorieChange: String = ""
    var isShowingSettings: Bool = false
    var isShowingWeightInput: Bool = false
    var dailyActivities: [DailyActivityData] = []
    var dailyCalories: [Int] = []

    // MARK: - Computed Properties

    var hasAchievements: Bool {
        !achievements.isEmpty
    }

    // MARK: - Initialization

    init() {
        // 轻量级初始化，避免耗时操作
    }

    // MARK: - Public Methods

    func loadProfile(modelContext: ModelContext) {
        loadUserProfile(modelContext: modelContext)
        loadWeightData(modelContext: modelContext)
        loadStreakData(modelContext: modelContext)
        loadAchievements(modelContext: modelContext)
        loadCalorieData(modelContext: modelContext)
        loadDailyActivities(modelContext: modelContext)
    }

    func logWeight(_ weight: Double, modelContext: ModelContext) {
        let log = WeightLog(weightKg: weight, recordedAt: Date())
        modelContext.insert(log)
        try? modelContext.save()

        let previousWeight = currentWeight
        currentWeight = weight
        weightTrend = formatWeightTrend(current: weight, previous: previousWeight)

        // 同步到 HealthKit
        Task {
            try? await HealthKitManager.shared.saveWeight(kilograms: weight, date: Date())
        }
    }

    func signOut(appState: AppState) {
        Task {
            await TokenManager.shared.clearTokens()
            appState.isAuthenticated = false
            appState.currentUser = nil
        }
    }

    // MARK: - Private Methods

    /// 格式化体重变化趋势
    ///
    /// - Parameters:
    ///   - current: 当前体重
    ///   - previous: 上次体重
    /// - Returns: 格式化的趋势字符串
    private func formatWeightTrend(current: Double, previous: Double) -> String {
        let diff = current - previous
        if diff < 0 {
            return String(format: "\u{2193} %.1fkg", abs(diff))
        } else if diff > 0 {
            return String(format: "\u{2191} %.1fkg", diff)
        } else {
            return "-- 0.0kg"
        }
    }

    private func loadUserProfile(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        if let profile = try? modelContext.fetch(descriptor).first {
            userName = profile.displayName
            avatarAssetName = profile.avatarAssetName
            isPro = profile.isPro
            targetWeight = profile.targetWeight ?? 65.0
        } else {
            loadMockData()
        }
    }

    private func loadWeightData(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<WeightLog>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )

        let logs = (try? modelContext.fetch(descriptor)) ?? []

        if let latest = logs.first {
            currentWeight = latest.weightKg

            if logs.count >= 2 {
                let previous = logs[1].weightKg
                weightTrend = formatWeightTrend(current: latest.weightKg, previous: previous)
            } else {
                weightTrend = "\u{2193} 0.0kg"
            }
        } else {
            currentWeight = 68.0
            weightTrend = "\u{2193} 0.5kg"
        }
    }

    private func loadStreakData(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<MealRecord>(
            sortBy: [SortDescriptor(\.mealTime, order: .reverse)]
        )

        let records = (try? modelContext.fetch(descriptor)) ?? []
        guard !records.isEmpty else {
            streakDays = 12 // Mock for demo
            return
        }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let dayStart = checkDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let hasRecord = records.contains { record in
                record.mealTime >= dayStart && record.mealTime < dayEnd
            }

            if hasRecord {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        streakDays = max(streak, 0)
        if streakDays == 0 {
            streakDays = 12 // Mock for demo
        }
    }

    private func loadAchievements(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>()
        let earned = (try? modelContext.fetch(descriptor)) ?? []
        let earnedTypes = Set(earned.map { $0.type })

        if earnedTypes.isEmpty {
            // Load mock achievements
            achievements = [
                AchievementItem(type: "streak_7day", title: "7 Day Streak", icon: "trophy.fill", tier: .gold, isEarned: true, earnedDate: Date().addingTimeInterval(-86400 * 5)),
                AchievementItem(type: "veggie_king", title: "Veggie King", icon: "leaf.fill", tier: .silver, isEarned: true, earnedDate: Date().addingTimeInterval(-86400 * 12)),
                AchievementItem(type: "early_bird", title: "Early Bird", icon: "sunrise.fill", tier: .bronze, isEarned: true, earnedDate: Date().addingTimeInterval(-86400 * 20)),
                AchievementItem(type: "first_meal", title: "First Meal", icon: "fork.knife", tier: .gold, isEarned: true, earnedDate: Date().addingTimeInterval(-86400 * 30)),
                AchievementItem(type: "streak_30day", title: "30 Days", icon: "flame.circle.fill", tier: .gold, isEarned: false),
                AchievementItem(type: "protein_champ", title: "Protein Champ", icon: "dumbbell.fill", tier: .silver, isEarned: false),
                AchievementItem(type: "water_hero", title: "Water Hero", icon: "drop.fill", tier: .silver, isEarned: false),
            ]
        } else {
            achievements = Achievement.AchievementType.allCases.map { achievementType in
                let isEarned = earnedTypes.contains(achievementType.rawValue)
                let matchedAchievement = earned.first(where: { $0.type == achievementType.rawValue })
                let matchedTier: AchievementItem.AchievementTier

                if let match = matchedAchievement {
                    switch match.tier {
                    case "gold": matchedTier = .gold
                    case "silver": matchedTier = .silver
                    default: matchedTier = .bronze
                    }
                } else {
                    matchedTier = .bronze
                }

                return AchievementItem(
                    type: achievementType.rawValue,
                    title: achievementType.displayName,
                    icon: achievementType.icon,
                    tier: matchedTier,
                    isEarned: isEarned,
                    earnedDate: matchedAchievement?.earnedAt
                )
            }
        }
    }

    private func loadCalorieData(modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        guard let weekAgo = calendar.date(byAdding: .day, value: DateRangeConfig.oneWeekDays, to: now),
              let twoWeeksAgo = calendar.date(byAdding: .day, value: DateRangeConfig.twoWeeksDays, to: now) else {
            averageCalories = 0
            calorieChange = "0%"
            return
        }

        let thisWeekDescriptor = FetchDescriptor<MealRecord>(
            predicate: #Predicate<MealRecord> { record in
                record.mealTime >= weekAgo && record.mealTime <= now
            }
        )

        let lastWeekDescriptor = FetchDescriptor<MealRecord>(
            predicate: #Predicate<MealRecord> { record in
                record.mealTime >= twoWeeksAgo && record.mealTime < weekAgo
            }
        )

        let thisWeekRecords = (try? modelContext.fetch(thisWeekDescriptor)) ?? []
        let lastWeekRecords = (try? modelContext.fetch(lastWeekDescriptor)) ?? []

        // 计算每日卡路里用于图表展示
        var dailyCaloriesDict: [Date: Int] = [:]
        for record in thisWeekRecords {
            let day = calendar.startOfDay(for: record.mealTime)
            dailyCaloriesDict[day, default: 0] += record.totalCalories
        }

        // 生成最近 7 天数据
        dailyCalories = (0..<7).reversed().map { daysAgo in
            let day = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -daysAgo, to: now)!)
            return dailyCaloriesDict[day] ?? 0
        }

        let thisWeekTotal = thisWeekRecords.reduce(0) { $0 + $1.totalCalories }
        let thisWeekDays = max(1, Set(thisWeekRecords.map { calendar.startOfDay(for: $0.mealTime) }).count)
        averageCalories = thisWeekTotal / thisWeekDays

        let lastWeekTotal = lastWeekRecords.reduce(0) { $0 + $1.totalCalories }
        let lastWeekDays = max(1, Set(lastWeekRecords.map { calendar.startOfDay(for: $0.mealTime) }).count)
        let lastWeekAvg = lastWeekTotal / lastWeekDays

        if lastWeekAvg > 0 {
            let change = Double(averageCalories - lastWeekAvg) / Double(lastWeekAvg) * 100
            if change < 0 {
                calorieChange = String(format: "%.0f%%", change)
            } else {
                calorieChange = String(format: "+%.0f%%", change)
            }
        } else {
            calorieChange = "0%"
        }

        if averageCalories == 0 {
            loadMockCalorieData()
        }
    }

    private func loadDailyActivities(modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return
        }

        let range = calendar.range(of: .day, in: .month, for: now) ?? 1..<31
        let daysInMonth = range.count

        let descriptor = FetchDescriptor<MealRecord>(
            predicate: #Predicate<MealRecord> { record in
                record.mealTime >= startOfMonth
            }
        )

        let records = (try? modelContext.fetch(descriptor)) ?? []

        // 按天分组
        var recordsByDay: [Int: [MealRecord]] = [:]
        for record in records {
            let day = calendar.component(.day, from: record.mealTime)
            recordsByDay[day, default: []].append(record)
        }

        // 生成每日活动数据，演示时使用随机进度
        dailyActivities = (1...daysInMonth).map { day in
            guard let date = calendar.date(bySetting: .day, value: day, of: now) else {
                return DailyActivityData(
                    day: day,
                    date: now,
                    proteinProgress: 0,
                    carbsProgress: 0,
                    fatProgress: 0,
                    hasActivity: false
                )
            }

            let dayRecords = recordsByDay[day] ?? []
            let currentDay = calendar.component(.day, from: now)
            let isPastOrToday = day <= currentDay
            let mockActivityProbability = 0.7
            let hasActivity = !dayRecords.isEmpty || (isPastOrToday && Double.random(in: 0...1) < mockActivityProbability)

            // 计算或模拟进度
            let progress = calculateNutritionProgress(from: dayRecords, withMockActivity: hasActivity && dayRecords.isEmpty)

            return DailyActivityData(
                day: day,
                date: date,
                proteinProgress: progress.protein,
                carbsProgress: progress.carbs,
                fatProgress: progress.fat,
                hasActivity: hasActivity
            )
        }
    }

    /// 计算营养进度
    ///
    /// - Parameters:
    ///   - records: 餐食记录列表
    ///   - hasMockActivity: 是否使用模拟数据
    /// - Returns: 蛋白质、碳水、脂肪的进度元组
    private func calculateNutritionProgress(
        from records: [MealRecord],
        withMockActivity hasMockActivity: Bool
    ) -> (protein: Double, carbs: Double, fat: Double) {
        if !records.isEmpty {
            let totalProtein = records.reduce(0.0) { $0 + $1.proteinGrams }
            let totalCarbs = records.reduce(0.0) { $0 + $1.carbsGrams }
            let totalFat = records.reduce(0.0) { $0 + $1.fatGrams }

            return (
                protein: min(totalProtein / NutritionGoals.dailyProteinGrams, 1.0),
                carbs: min(totalCarbs / NutritionGoals.dailyCarbsGrams, 1.0),
                fat: min(totalFat / NutritionGoals.dailyFatGrams, 1.0)
            )
        } else if hasMockActivity {
            // 演示时使用随机进度
            return (
                protein: Double.random(in: 0.3...1.0),
                carbs: Double.random(in: 0.4...1.0),
                fat: Double.random(in: 0.2...0.9)
            )
        } else {
            return (protein: 0, carbs: 0, fat: 0)
        }
    }

    // MARK: - Mock Data

    func loadMockData() {
        // 原型数据: Jane Doe 用户
        userName = "Jane Doe"
        // 原型数据: 用户头像（本地 Asset）
        avatarAssetName = "avatar_jane"
        isPro = true
        // 原型数据: 体重 68kg, 目标 65kg, 趋势 -0.5kg
        currentWeight = 68.0
        targetWeight = 65.0
        weightTrend = "\u{2193} 0.5kg"
        // 原型数据: 连续 12 天
        streakDays = 12

        achievements = [
            AchievementItem(type: "streak_7day", title: "7 Day Streak", icon: "trophy.fill", tier: .gold, isEarned: true, earnedDate: Date().addingTimeInterval(-86400 * 5)),
            AchievementItem(type: "veggie_king", title: "Veggie King", icon: "leaf.fill", tier: .silver, isEarned: true, earnedDate: Date().addingTimeInterval(-86400 * 12)),
            AchievementItem(type: "early_bird", title: "Early Bird", icon: "sunrise.fill", tier: .bronze, isEarned: true, earnedDate: Date().addingTimeInterval(-86400 * 20)),
            AchievementItem(type: "first_meal", title: "First Meal", icon: "fork.knife", tier: .gold, isEarned: true, earnedDate: Date().addingTimeInterval(-86400 * 30)),
            AchievementItem(type: "streak_30day", title: "30 Days", icon: "flame.circle.fill", tier: .gold, isEarned: false),
            AchievementItem(type: "protein_champ", title: "Protein Champ", icon: "dumbbell.fill", tier: .silver, isEarned: false),
            AchievementItem(type: "water_hero", title: "Water Hero", icon: "drop.fill", tier: .silver, isEarned: false),
        ]

        loadMockCalorieData()
    }

    private func loadMockCalorieData() {
        // 原型数据: 平均 1,850 卡路里，-5%
        averageCalories = 1850
        calorieChange = "-5%"
        dailyCalories = [1800, 1950, 1700, 2100, 1850, 1600, 1900]
    }
}
