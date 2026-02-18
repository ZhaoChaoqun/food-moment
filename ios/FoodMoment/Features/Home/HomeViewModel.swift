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

    // MARK: - Private

    private let mealService: MealServiceProtocol
    private let waterService: WaterServiceProtocol
    private let userService: UserServiceProtocol

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

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

    init(
        mealService: MealServiceProtocol = MealService.shared,
        waterService: WaterServiceProtocol = WaterService.shared,
        userService: UserServiceProtocol = UserService.shared
    ) {
        self.mealService = mealService
        self.waterService = waterService
        self.userService = userService
    }

    // MARK: - Public Methods

    /// 从 SwiftData 缓存同步加载（立即显示）
    func loadTodayData(modelContext: ModelContext, includeWater: Bool = true) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        // 加载餐食缓存
        let mealPredicate = #Predicate<MealRecord> { record in
            record.mealTime >= startOfDay && record.mealTime < endOfDay
        }
        let mealDescriptor = FetchDescriptor<MealRecord>(
            predicate: mealPredicate,
            sortBy: [SortDescriptor(\.mealTime)]
        )
        todayMeals = (try? modelContext.fetch(mealDescriptor)) ?? []
        consumedCalories = todayMeals.reduce(0) { $0 + $1.totalCalories }
        proteinGrams = todayMeals.reduce(0) { $0 + $1.proteinGrams }
        carbsGrams = todayMeals.reduce(0) { $0 + $1.carbsGrams }
        fatGrams = todayMeals.reduce(0) { $0 + $1.fatGrams }

        if includeWater {
            // 加载水量缓存
            let waterPredicate = #Predicate<WaterLog> { log in
                log.recordedAt >= startOfDay && log.recordedAt < endOfDay
            }
            let waterDescriptor = FetchDescriptor<WaterLog>(predicate: waterPredicate)
            let waterLogs = (try? modelContext.fetch(waterDescriptor)) ?? []
            waterAmount = waterLogs.reduce(0) { $0 + $1.amountML }
        }

        // 加载用户配置缓存
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(profileDescriptor).first {
            userName = profile.displayName
            dailyCalorieGoal = profile.dailyCalorieGoal
            dailyProteinGoal = profile.dailyProteinGoal
            dailyCarbsGoal = profile.dailyCarbsGoal
            dailyFatGoal = profile.dailyFatGoal
        }
    }

    /// 从 API 刷新数据并更新 SwiftData 缓存
    func refreshFromAPI(modelContext: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        let todayString = Self.dateFormatter.string(from: Date())

        // 并发请求
        async let mealsTask = mealService.getMeals(date: todayString)
        async let waterTask = waterService.getWater(date: todayString)
        async let profileTask = userService.getProfile()

        do {
            let (mealDTOs, waterDTO, profile) = try await (mealsTask, waterTask, profileTask)

            // 更新用户配置
            userName = profile.displayName
            dailyCalorieGoal = profile.dailyCalorieGoal
            dailyProteinGoal = profile.dailyProteinGoal
            dailyCarbsGoal = profile.dailyCarbsGoal
            dailyFatGoal = profile.dailyFatGoal
            dailyWaterGoal = waterDTO.goalMl

            // 更新水量（合并本地未同步记录）
            waterAmount = waterDTO.totalMl + unsyncedWaterAmount(modelContext: modelContext)

            // 更新餐食 - 清除旧缓存并写入新数据
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            let predicate = #Predicate<MealRecord> { record in
                record.mealTime >= startOfDay && record.mealTime < endOfDay
            }
            let existing = (try? modelContext.fetch(FetchDescriptor<MealRecord>(predicate: predicate))) ?? []
            for record in existing {
                modelContext.delete(record)
            }

            for dto in mealDTOs {
                let record = MealRecord(
                    mealType: dto.mealType,
                    mealTime: dto.mealTime,
                    title: dto.title,
                    totalCalories: dto.totalCalories,
                    proteinGrams: dto.proteinGrams,
                    carbsGrams: dto.carbsGrams,
                    fatGrams: dto.fatGrams,
                    fiberGrams: dto.fiberGrams
                )
                record.id = dto.id
                record.imageURL = dto.imageUrl
                record.descriptionText = dto.descriptionText
                record.aiAnalysis = dto.aiAnalysis
                record.tags = dto.tags ?? []
                record.isSynced = true
                modelContext.insert(record)
            }
            try? modelContext.save()

            // 重新从 SwiftData 加载（不覆盖水量）
            loadTodayData(modelContext: modelContext, includeWater: false)
        } catch {
            // API 失败时保持缓存数据
        }
    }

    /// 添加饮水记录 - 本地优先
    func addWater(
        amount: Int = 250,
        modelContext: ModelContext,
        writeToHealthKit: Bool = false
    ) async {
        guard amount > 0 else { return }

        let waterLog = WaterLog(amountML: amount, isSynced: false)
        modelContext.insert(waterLog)
        try? modelContext.save()

        // 立即更新 UI
        waterAmount += amount

        if writeToHealthKit {
            do {
                try await HealthKitManager.shared.saveWaterIntake(
                    milliliters: Double(amount),
                    date: Date()
                )
            } catch {
                // 忽略 HealthKit 写入失败
            }
        }

        do {
            let _ = try await waterService.logWater(WaterLogCreateDTO(amountMl: amount))
            // API 成功，标记已同步
            waterLog.isSynced = true
            try? modelContext.save()
        } catch {
            // API 失败，保留未同步记录，不回滚 UI
        }
    }

    // MARK: - Private

    private func unsyncedWaterAmount(modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let predicate = #Predicate<WaterLog> { log in
            log.recordedAt >= startOfDay && log.recordedAt < endOfDay && log.isSynced == false
        }
        let descriptor = FetchDescriptor<WaterLog>(predicate: predicate)
        let logs = (try? modelContext.fetch(descriptor)) ?? []
        return logs.reduce(0) { $0 + $1.amountML }
    }

    func refresh(modelContext: ModelContext) async {
        await refreshFromAPI(modelContext: modelContext)
    }
}
