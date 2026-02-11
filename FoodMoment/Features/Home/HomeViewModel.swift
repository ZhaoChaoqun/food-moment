import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Published Properties

    var userName: String = "User"
    var userAvatarAssetName: String?
    var dailyCalorieGoal: Int = 2500
    var consumedCalories: Int = 0
    var proteinGrams: Double = 0
    var carbsGrams: Double = 0
    var fatGrams: Double = 0
    var waterAmount: Int = 0
    var stepCount: Int = 0
    var todayMeals: [MealRecord] = []
    var isLoading: Bool = false
    var caloriesBurned: Int = 0

    // MARK: - Goal Properties

    var dailyProteinGoal: Int = 50
    var dailyCarbsGoal: Int = 250
    var dailyFatGoal: Int = 65
    var dailyWaterGoal: Int = 2500
    var dailyStepGoal: Int = 10000

    // MARK: - Computed Properties

    var caloriesLeft: Int {
        max(dailyCalorieGoal - consumedCalories, 0)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "早安"
        case 12..<18:
            return "午好"
        default:
            return "晚好"
        }
    }

    var calorieProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0 }
        return min(Double(consumedCalories) / Double(dailyCalorieGoal), 1.0)
    }

    var proteinProgress: Double {
        guard dailyProteinGoal > 0 else { return 0 }
        return min(proteinGrams / Double(dailyProteinGoal), 1.0)
    }

    var carbsProgress: Double {
        guard dailyCarbsGoal > 0 else { return 0 }
        return min(carbsGrams / Double(dailyCarbsGoal), 1.0)
    }

    var fatProgress: Double {
        guard dailyFatGoal > 0 else { return 0 }
        return min(fatGrams / Double(dailyFatGoal), 1.0)
    }

    var waterProgress: Double {
        guard dailyWaterGoal > 0 else { return 0 }
        return min(Double(waterAmount) / Double(dailyWaterGoal), 1.0)
    }

    var stepProgress: Double {
        guard dailyStepGoal > 0 else { return 0 }
        return min(Double(stepCount) / Double(dailyStepGoal), 1.0)
    }

    // MARK: - Initialization

    init() {
        // 轻量级初始化，避免耗时操作
    }

    // MARK: - Public Methods

    func loadTodayData(modelContext: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        fetchTodayMeals(modelContext: modelContext, startOfDay: startOfDay, endOfDay: endOfDay)
        fetchTodayWaterLogs(modelContext: modelContext, startOfDay: startOfDay, endOfDay: endOfDay)
        loadUserProfile(modelContext: modelContext)
    }

    func addWater(amount: Int = 250, modelContext: ModelContext) {
        let waterLog = WaterLog(amountML: amount)
        modelContext.insert(waterLog)
        waterAmount += amount

        do {
            try modelContext.save()
        } catch {
            // 保存失败时回滚
            waterAmount -= amount
        }
    }

    func refresh() {
        // 占位方法，用于下拉刷新逻辑
        // 实际实现中可同步 HealthKit 或后端数据
    }

    func loadMockData() {
        loadMockUserData()
        loadMockNutritionData()
        loadMockHealthData()
        loadMockMeals()
    }

    // MARK: - Private Methods

    private func fetchTodayMeals(
        modelContext: ModelContext,
        startOfDay: Date,
        endOfDay: Date
    ) {
        let mealPredicate = #Predicate<MealRecord> { record in
            record.mealTime >= startOfDay && record.mealTime < endOfDay
        }
        let mealDescriptor = FetchDescriptor<MealRecord>(
            predicate: mealPredicate,
            sortBy: [SortDescriptor(\.mealTime)]
        )

        do {
            todayMeals = try modelContext.fetch(mealDescriptor)
            consumedCalories = todayMeals.reduce(0) { $0 + $1.totalCalories }
            proteinGrams = todayMeals.reduce(0) { $0 + $1.proteinGrams }
            carbsGrams = todayMeals.reduce(0) { $0 + $1.carbsGrams }
            fatGrams = todayMeals.reduce(0) { $0 + $1.fatGrams }
        } catch {
            todayMeals = []
        }
    }

    private func fetchTodayWaterLogs(
        modelContext: ModelContext,
        startOfDay: Date,
        endOfDay: Date
    ) {
        let waterPredicate = #Predicate<WaterLog> { log in
            log.recordedAt >= startOfDay && log.recordedAt < endOfDay
        }
        let waterDescriptor = FetchDescriptor<WaterLog>(
            predicate: waterPredicate
        )

        do {
            let waterLogs = try modelContext.fetch(waterDescriptor)
            waterAmount = waterLogs.reduce(0) { $0 + $1.amountML }
        } catch {
            waterAmount = 0
        }
    }

    private func loadUserProfile(modelContext: ModelContext) {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        do {
            if let profile = try modelContext.fetch(profileDescriptor).first {
                userName = profile.displayName
                dailyCalorieGoal = profile.dailyCalorieGoal
                dailyProteinGoal = profile.dailyProteinGoal
                dailyCarbsGoal = profile.dailyCarbsGoal
                dailyFatGoal = profile.dailyFatGoal
            }
        } catch {
            // 使用默认值
        }
    }

    private func loadMockUserData() {
        userName = MockDataProvider.User.displayName
        userAvatarAssetName = MockDataProvider.User.avatarAssetName
    }

    private func loadMockNutritionData() {
        dailyCalorieGoal = MockDataProvider.NutritionGoals.dailyCalorieGoal
        dailyProteinGoal = MockDataProvider.NutritionGoals.dailyProteinGoal
        dailyCarbsGoal = MockDataProvider.NutritionGoals.dailyCarbsGoal
        dailyFatGoal = MockDataProvider.NutritionGoals.dailyFatGoal

        consumedCalories = MockDataProvider.ConsumedNutrition.totalCalories
        proteinGrams = MockDataProvider.ConsumedNutrition.proteinGrams
        carbsGrams = MockDataProvider.ConsumedNutrition.carbsGrams
        fatGrams = MockDataProvider.ConsumedNutrition.fatGrams
    }

    private func loadMockHealthData() {
        waterAmount = MockDataProvider.Health.waterAmount
        dailyWaterGoal = MockDataProvider.NutritionGoals.dailyWaterGoal
        stepCount = MockDataProvider.Health.stepCount
        caloriesBurned = MockDataProvider.Health.caloriesBurned
        dailyStepGoal = MockDataProvider.NutritionGoals.dailyStepGoal
    }

    private func loadMockMeals() {
        todayMeals = MockDataProvider.generateMockMeals()
    }
}
