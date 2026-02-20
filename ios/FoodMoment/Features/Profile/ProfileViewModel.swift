import Foundation
import SwiftData
import SwiftUI

// MARK: - Achievement Item

struct AchievementItem: Identifiable, Sendable {
    let id = UUID()
    let type: String
    let title: String
    let subtitle: String
    let icon: String
    let tier: AchievementTier
    let isEarned: Bool
    let earnedDate: Date?
    let theme: BadgeTheme
    let category: Achievement.AchievementCategory
    let isHidden: Bool
    let description: String
    let badgeAssetName: String

    init(
        type: String,
        title: String,
        subtitle: String = "",
        icon: String,
        tier: AchievementTier,
        isEarned: Bool,
        earnedDate: Date? = nil,
        theme: BadgeTheme = BadgeTheme(primaryHex: "#A0A0A0", highlightHex: "#D0D0D0", shadowHex: "#606060"),
        category: Achievement.AchievementCategory = .habit,
        isHidden: Bool = false,
        description: String = "",
        badgeAssetName: String = ""
    ) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tier = tier
        self.isEarned = isEarned
        self.earnedDate = earnedDate
        self.theme = theme
        self.category = category
        self.isHidden = isHidden
        self.description = description
        self.badgeAssetName = badgeAssetName
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
    let proteinProgress: Double
    let carbsProgress: Double
    let fatProgress: Double
    let hasActivity: Bool

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Nutrition Goals

private enum NutritionGoals {
    static let dailyProteinGrams: Double = 50.0
    static let dailyCarbsGrams: Double = 250.0
    static let dailyFatGrams: Double = 65.0
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

    // MARK: - Private

    private let userService: UserServiceProtocol
    private let statsService: StatsServiceProtocol

    // MARK: - Computed Properties

    var hasAchievements: Bool {
        !achievements.isEmpty
    }

    // MARK: - Initialization

    init(
        userService: UserServiceProtocol = UserService.shared,
        statsService: StatsServiceProtocol = StatsService.shared
    ) {
        self.userService = userService
        self.statsService = statsService
    }

    // MARK: - Public Methods

    /// 从 SwiftData 缓存同步加载
    func loadProfile(modelContext: ModelContext) {
        loadUserProfile(modelContext: modelContext)
        loadWeightData(modelContext: modelContext)
        loadStreakData(modelContext: modelContext)
        loadAchievements(modelContext: modelContext)
        loadCalorieData(modelContext: modelContext)
        loadDailyActivities(modelContext: modelContext)
    }

    /// 从 API 刷新数据
    func refreshFromAPI() async {
        // 并发获取所有数据
        async let profileTask = userService.getProfile()
        async let streaksTask = userService.getStreaks()
        async let achievementsTask = userService.getAchievements()

        // 获取当前月的月统计
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let currentMonth = dateFormatter.string(from: Date())
        async let monthlyTask = statsService.getMonthlyStats(month: currentMonth)

        // 获取本周的周统计
        let weekFormatter = DateFormatter()
        weekFormatter.dateFormat = "yyyy-MM-dd"
        let weekStart = Date().startOfWeek
        let weekString = weekFormatter.string(from: weekStart)
        async let weeklyTask = statsService.getWeeklyStats(week: weekString)

        do {
            let profile = try await profileTask
            userName = profile.displayName
            isPro = profile.isPro
            targetWeight = profile.targetWeight ?? 65.0
        } catch {
            // 保持缓存
        }

        do {
            let streakDTO = try await streaksTask
            streakDays = streakDTO.currentStreak
        } catch {}

        do {
            let achievementDTOs = try await achievementsTask
            achievements = achievementDTOs.map { mapAchievement($0) }
        } catch {}

        do {
            let weeklyStats = try await weeklyTask
            averageCalories = Int(weeklyStats.avgCalories)
            dailyCalories = weeklyStats.dailyStats.map { $0.totalCalories }

            // 计算变化率（简化：对比平均与目标）
            if averageCalories > 0 {
                calorieChange = "+0%"
            }
        } catch {}

        do {
            let monthlyStats = try await monthlyTask
            let calendar = Calendar.current
            let now = Date()
            let range = calendar.range(of: .day, in: .month, for: now) ?? 1..<31
            let daysInMonth = range.count

            dailyActivities = (1...daysInMonth).map { day in
                guard let date = calendar.date(bySetting: .day, value: day, of: now) else {
                    return DailyActivityData(day: day, date: now, proteinProgress: 0, carbsProgress: 0, fatProgress: 0, hasActivity: false)
                }

                let dayString = weekFormatter.string(from: date)
                let dayStats = monthlyStats.dailyStats.first { $0.date == dayString }
                let hasActivity = (dayStats?.mealCount ?? 0) > 0

                return DailyActivityData(
                    day: day,
                    date: date,
                    proteinProgress: hasActivity ? min(dayStats!.proteinGrams / NutritionGoals.dailyProteinGrams, 1.0) : 0,
                    carbsProgress: hasActivity ? min(dayStats!.carbsGrams / NutritionGoals.dailyCarbsGrams, 1.0) : 0,
                    fatProgress: hasActivity ? min(dayStats!.fatGrams / NutritionGoals.dailyFatGrams, 1.0) : 0,
                    hasActivity: hasActivity
                )
            }
        } catch {}
    }

    func logWeight(_ weight: Double) async {
        let previousWeight = currentWeight
        currentWeight = weight
        weightTrend = formatWeightTrend(current: weight, previous: previousWeight)

        do {
            let _ = try await userService.logWeight(
                WeightLogCreateDTO(weightKg: weight, recordedAt: Date())
            )
        } catch {
            // 回滚
            currentWeight = previousWeight
        }

        // 同步到 HealthKit
        Task {
            try? await HealthKitManager.shared.saveWeight(kilograms: weight, date: Date())
        }
    }

    func deleteAccount(appState: AppState) {
        Task {
            try? await APIClient.shared.requestVoid(.deleteAccount)
            await TokenManager.shared.clearTokens()
            appState.isAuthenticated = false
            appState.currentUser = nil
        }
    }

    // MARK: - Private Methods

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

    private func mapAchievement(_ dto: AchievementResponseDTO) -> AchievementItem {
        let ratio = dto.target > 0 ? Double(dto.progress) / Double(dto.target) : 0
        let tier: AchievementItem.AchievementTier = switch ratio {
            case 1.0: .gold
            case 0.5...: .silver
            default: .bronze
        }

        return AchievementItem(
            type: dto.id,
            title: dto.title,
            subtitle: dto.description,
            icon: dto.emoji,
            tier: tier,
            isEarned: dto.unlocked,
            description: dto.description
        )
    }

    // MARK: - SwiftData Cache Methods (for initial sync load)

    private func loadUserProfile(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let profile = try? modelContext.fetch(descriptor).first {
            userName = profile.displayName
            avatarAssetName = profile.avatarAssetName
            isPro = profile.isPro
            targetWeight = profile.targetWeight ?? 65.0
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
        }
    }

    private func loadStreakData(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<MealRecord>(
            sortBy: [SortDescriptor(\.mealTime, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        guard !records.isEmpty else {
            streakDays = 0
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
    }

    private func loadAchievements(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>()
        let earned = (try? modelContext.fetch(descriptor)) ?? []
        let earnedTypes = Set(earned.map { $0.type })

        if !earnedTypes.isEmpty {
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
                    subtitle: achievementType.subtitle,
                    icon: achievementType.icon,
                    tier: matchedTier,
                    isEarned: isEarned,
                    earnedDate: matchedAchievement?.earnedAt,
                    theme: achievementType.theme,
                    category: achievementType.category,
                    isHidden: achievementType.isHidden,
                    description: achievementType.description,
                    badgeAssetName: achievementType.badgeAssetName
                )
            }
        }
    }

    private func loadCalorieData(modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
              let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) else {
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

        var dailyCaloriesDict: [Date: Int] = [:]
        for record in thisWeekRecords {
            let day = calendar.startOfDay(for: record.mealTime)
            dailyCaloriesDict[day, default: 0] += record.totalCalories
        }

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
            calorieChange = change < 0 ? String(format: "%.0f%%", change) : String(format: "+%.0f%%", change)
        } else {
            calorieChange = "0%"
        }
    }

    private func loadDailyActivities(modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return }

        let range = calendar.range(of: .day, in: .month, for: now) ?? 1..<31
        let daysInMonth = range.count

        let descriptor = FetchDescriptor<MealRecord>(
            predicate: #Predicate<MealRecord> { record in
                record.mealTime >= startOfMonth
            }
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []

        var recordsByDay: [Int: [MealRecord]] = [:]
        for record in records {
            let day = calendar.component(.day, from: record.mealTime)
            recordsByDay[day, default: []].append(record)
        }

        dailyActivities = (1...daysInMonth).map { day in
            guard let date = calendar.date(bySetting: .day, value: day, of: now) else {
                return DailyActivityData(day: day, date: now, proteinProgress: 0, carbsProgress: 0, fatProgress: 0, hasActivity: false)
            }
            let dayRecords = recordsByDay[day] ?? []

            guard !dayRecords.isEmpty else {
                return DailyActivityData(day: day, date: date, proteinProgress: 0, carbsProgress: 0, fatProgress: 0, hasActivity: false)
            }

            let totalProtein = dayRecords.reduce(0.0) { $0 + $1.proteinGrams }
            let totalCarbs = dayRecords.reduce(0.0) { $0 + $1.carbsGrams }
            let totalFat = dayRecords.reduce(0.0) { $0 + $1.fatGrams }
            return DailyActivityData(
                day: day, date: date,
                proteinProgress: min(totalProtein / NutritionGoals.dailyProteinGrams, 1.0),
                carbsProgress: min(totalCarbs / NutritionGoals.dailyCarbsGrams, 1.0),
                fatProgress: min(totalFat / NutritionGoals.dailyFatGrams, 1.0),
                hasActivity: true
            )
        }
    }
}
