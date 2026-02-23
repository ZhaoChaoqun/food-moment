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
    let progress: Int
    let target: Int

    /// 完成比例 (0.0 ~ 1.0)
    var progressRatio: Double {
        target > 0 ? Double(progress) / Double(target) : 0
    }

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
        badgeAssetName: String = "",
        progress: Int = 0,
        target: Int = 1
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
        self.progress = progress
        self.target = target
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
    var avatarUrl: String?
    var isPro: Bool = false
    var currentWeight: Double = 0.0
    var targetWeight: Double = 0.0
    var weightTrend: String = ""
    /// 最近体重记录（按时间升序），用于 sparkline
    var weightHistory: [(date: Date, weight: Double)] = []
    /// 体重记录总数
    var weightRecordCount: Int = 0
    var streakDays: Int = 0
    var achievements: [AchievementItem] = []
    var averageCalories: Int = 0
    var calorieChange: String = ""
    var isShowingSettings: Bool = false
    var isShowingAchievements: Bool = false
    var dailyActivities: [DailyActivityData] = []
    var dailyCalories: [Int] = []
    var userProfile: UserProfile?

    // MARK: - Private

    private let userService: UserServiceProtocol

    // MARK: - Computed Properties

    var hasAchievements: Bool {
        !achievements.isEmpty
    }

    // MARK: - Achievement Gallery Computed Properties

    /// 已解锁成就数量
    var unlockedCount: Int {
        achievements.filter { $0.isEarned }.count
    }

    /// 总可见成就数量（隐藏彩蛋未解锁时不计入分母）
    var totalVisibleCount: Int {
        achievements.filter { !$0.isHidden || $0.isEarned }.count
    }

    /// 总完成度比例 (0.0 ~ 1.0)
    var completionProgress: Double {
        guard totalVisibleCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalVisibleCount)
    }

    /// 最近解锁的成就
    var latestUnlockedAchievement: AchievementItem? {
        achievements
            .filter { $0.isEarned && $0.earnedDate != nil }
            .sorted { ($0.earnedDate ?? .distantPast) > ($1.earnedDate ?? .distantPast) }
            .first
    }

    /// 按分类分组的成就
    var achievementsByCategory: [(category: Achievement.AchievementCategory, items: [AchievementItem])] {
        Achievement.AchievementCategory.allCases.compactMap { category in
            let items = achievements.filter { $0.category == category }
            guard !items.isEmpty else { return nil }
            return (category: category, items: items)
        }
    }

    /// Profile 页单行展示用：已解锁徽章 + 接近解锁的徽章，保证至少 3 个
    var highlightedAchievements: [AchievementItem] {
        let unlocked = achievements
            .filter { $0.isEarned }
            .sorted { ($0.earnedDate ?? .distantPast) > ($1.earnedDate ?? .distantPast) }

        // 未解锁且非隐藏，按进度降序排列
        let lockedCandidates = achievements
            .filter { !$0.isEarned && !$0.isHidden }
            .sorted { $0.progressRatio > $1.progressRatio }

        // 优先选进度 >= 50% 的
        let nearlyUnlocked = lockedCandidates.filter { $0.progressRatio >= 0.5 }

        let minTotal = 3
        let needed = max(0, minTotal - unlocked.count - nearlyUnlocked.count)
        // 不够 3 个时，从剩余候选中补充（进度最高的优先）
        let filler = Array(lockedCandidates.filter { $0.progressRatio < 0.5 }.prefix(needed))

        return unlocked + nearlyUnlocked + filler
    }

    // MARK: - Initialization

    init(
        userService: UserServiceProtocol = UserService.shared
    ) {
        self.userService = userService
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

    /// 从 API 刷新数据，同步到 SwiftData 后重新从本地计算统计值
    func refreshFromAPI(modelContext: ModelContext) async {
        // 并发获取用户档案和成就
        async let profileTask = userService.getProfile()
        async let achievementsTask = userService.getAchievements()

        // 用户档案：写入 SwiftData（不存在则创建），再从 SwiftData 读取
        do {
            let profile = try await profileTask
            updateUserProfileInSwiftData(profile, modelContext: modelContext)
            loadUserProfile(modelContext: modelContext)
        } catch {
            // API 失败时保持 SwiftData 缓存
        }

        // 成就：保持现有同步模式（API → SwiftData + 内存 progress）
        do {
            let achievementDTOs = try await achievementsTask
            let apiMap = Dictionary(uniqueKeysWithValues: achievementDTOs.map { ($0.id, $0) })
            achievements = Achievement.AchievementType.allCases.map { type in
                if let dto = apiMap[type.rawValue], let item = mapAchievement(dto) {
                    return item
                }
                return buildLocalFallback(type)
            }
            syncAchievementsToSwiftData(achievementDTOs, modelContext: modelContext)
        } catch {}

        // 统计数据：统一从 SwiftData 本地计算（包含离线未同步记录）
        loadStreakData(modelContext: modelContext)
        loadCalorieData(modelContext: modelContext)
        loadDailyActivities(modelContext: modelContext)
    }

    /// 将 API 用户档案数据写入 SwiftData（不存在则创建）
    private func updateUserProfileInSwiftData(_ dto: UserProfileResponseDTO, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let profile: UserProfile
        if let existing = try? modelContext.fetch(descriptor).first {
            profile = existing
        } else {
            profile = UserProfile(id: dto.id, displayName: dto.displayName)
            modelContext.insert(profile)
        }

        profile.displayName = dto.displayName
        profile.avatarUrl = dto.avatarUrl
        profile.isPro = dto.isPro
        profile.targetWeight = dto.targetWeight
        profile.dailyCalorieGoal = dto.dailyCalorieGoal
        profile.dailyProteinGoal = dto.dailyProteinGoal
        profile.dailyCarbsGoal = dto.dailyCarbsGoal
        profile.dailyFatGoal = dto.dailyFatGoal
        profile.dailyWaterGoal = dto.dailyWaterGoal
        profile.dailyStepGoal = dto.dailyStepGoal
        profile.gender = dto.gender
        profile.birthYear = dto.birthYear
        profile.birthDate = dto.birthDate
        profile.heightCm = dto.heightCm
        profile.activityLevel = dto.activityLevel
        profile.updatedAt = Date()

        try? modelContext.save()
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
            return String(format: "▾%.1f", abs(diff))
        } else if diff > 0 {
            return String(format: "▴%.1f", diff)
        } else {
            return ""
        }
    }

    private func mapAchievement(_ dto: AchievementResponseDTO) -> AchievementItem? {
        guard let localType = Achievement.AchievementType(rawValue: dto.id) else { return nil }
        let ratio = dto.target > 0 ? Double(dto.progress) / Double(dto.target) : 0
        let tier: AchievementItem.AchievementTier = switch ratio {
            case 1.0: .gold
            case 0.5...: .silver
            default: .bronze
        }

        return AchievementItem(
            type: dto.id,
            title: localType.displayName,
            subtitle: localType.subtitle,
            icon: localType.icon,
            tier: tier,
            isEarned: dto.unlocked,
            theme: localType.theme,
            category: localType.category,
            isHidden: localType.isHidden,
            description: localType.description,
            badgeAssetName: localType.badgeAssetName,
            progress: dto.progress,
            target: dto.target
        )
    }

    /// 为未被 API 返回的成就类型构建本地默认状态
    private func buildLocalFallback(_ type: Achievement.AchievementType) -> AchievementItem {
        // 尝试从当前数组中找到已有项
        if let existing = achievements.first(where: { $0.type == type.rawValue }) {
            return existing
        }
        return AchievementItem(
            type: type.rawValue,
            title: type.displayName,
            subtitle: type.subtitle,
            icon: type.icon,
            tier: .bronze,
            isEarned: false,
            theme: type.theme,
            category: type.category,
            isHidden: type.isHidden,
            description: type.description,
            badgeAssetName: type.badgeAssetName
        )
    }

    /// 将 API 返回的已解锁成就同步写入 SwiftData
    private func syncAchievementsToSwiftData(_ dtos: [AchievementResponseDTO], modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>()
        let earned = (try? modelContext.fetch(descriptor)) ?? []
        let earnedTypes = Set(earned.map { $0.type })

        var inserted = false
        for dto in dtos where dto.unlocked {
            guard !earnedTypes.contains(dto.id) else { continue }
            let achievement = Achievement(
                type: dto.id,
                tier: dto.progress >= dto.target ? "gold" : "bronze",
                earnedAt: Date()
            )
            modelContext.insert(achievement)
            inserted = true
        }
        if inserted {
            try? modelContext.save()
        }
    }

    // MARK: - SwiftData Cache Methods (for initial sync load)

    private func loadUserProfile(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let profile = try? modelContext.fetch(descriptor).first {
            userProfile = profile
            userName = profile.displayName
            avatarAssetName = profile.avatarAssetName
            avatarUrl = profile.avatarUrl
            isPro = profile.isPro
            targetWeight = profile.targetWeight ?? 65.0
        }
    }

    private func loadWeightData(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<WeightLog>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        let logs = (try? modelContext.fetch(descriptor)) ?? []
        weightRecordCount = logs.count

        // 取最近 7 条记录，按时间升序排列，用于 sparkline
        let recent = Array(logs.prefix(7)).reversed()
        weightHistory = recent.map { (date: $0.recordedAt, weight: $0.weightKg) }

        if let latest = logs.first {
            currentWeight = latest.weightKg
            if logs.count >= 2 {
                let previous = logs[1].weightKg
                weightTrend = formatWeightTrend(current: latest.weightKg, previous: previous)
            } else {
                weightTrend = ""
            }
        } else {
            currentWeight = 0
            weightTrend = ""
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
                    badgeAssetName: achievementType.badgeAssetName,
                    progress: isEarned ? 1 : 0,
                    target: 1
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
