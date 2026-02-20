import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Properties

    var userName: String = "User"
    var userAvatarAssetName: String?
    var stepCount: Int = 0
    var caloriesBurned: Int = 0

    // MARK: - Private

    private let mealService: MealServiceProtocol
    private let waterService: WaterServiceProtocol
    private let userService: UserServiceProtocol

    // MARK: - Computed Properties

    var greeting: String {
        Date().greetingTime
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

    /// 从 API 刷新数据并更新 SwiftData 缓存
    func refreshFromAPI(modelContext: ModelContext) async {
        let todayString = Date().apiDateString

        // 并发请求
        async let mealsTask = mealService.getMeals(date: todayString)
        async let waterTask = waterService.getWater(date: todayString)
        async let profileTask = userService.getProfile()

        do {
            let (mealDTOs, waterDTO, profile) = try await (mealsTask, waterTask, profileTask)

            // 更新用户配置到 SwiftData
            userName = profile.displayName

            // 更新水量 - 将 API 同步到的水量日志写入 SwiftData
            // (WaterLog 通过 @Query 自动驱动 UI)

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
                let record = MealRecord.from(dto)
                modelContext.insert(record)
            }

            // 同步水量：用 API 总量覆盖已同步记录，保留未同步的
            let waterPredicate = #Predicate<WaterLog> { log in
                log.recordedAt >= startOfDay && log.recordedAt < endOfDay && log.isSynced == true
            }
            let existingWater = (try? modelContext.fetch(FetchDescriptor<WaterLog>(predicate: waterPredicate))) ?? []
            for log in existingWater {
                modelContext.delete(log)
            }
            // 插入一条合并记录代表已同步的水量
            if waterDTO.totalMl > 0 {
                let syncedLog = WaterLog(amountML: waterDTO.totalMl, isSynced: true)
                modelContext.insert(syncedLog)
            }

            try? modelContext.save()
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
            // API 失败，保留未同步记录
        }
    }

    func refresh(modelContext: ModelContext) async {
        await refreshFromAPI(modelContext: modelContext)
    }
}
