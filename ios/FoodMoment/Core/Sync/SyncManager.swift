import Foundation
import SwiftData
import Network
import Observation
import os

@MainActor
@Observable
final class SyncManager {
    static let shared = SyncManager()

    private static let logger = Logger(subsystem: "com.foodmoment", category: "SyncManager")

    var isSyncing = false
    var pendingCount = 0

    /// 网络恢复且有待同步数据时递增，订阅方可通过 onChange 监听此值变化
    var networkRestoredTrigger = 0

    private var isConnected = false
    private var monitor: NWPathMonitor?
    private var monitorQueue = DispatchQueue(label: "com.foodmoment.sync.monitor")

    private init() {}

    // MARK: - Network Monitoring

    /// 开始网络状态监听，网络恢复时自动触发同步
    func startMonitoring() {
        guard monitor == nil else { return }

        let monitor = NWPathMonitor()
        self.monitor = monitor

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasConnected = self.isConnected
                self.isConnected = (path.status == .satisfied)

                // 网络恢复时自动同步
                if !wasConnected && self.isConnected && self.pendingCount > 0 {
                    self.networkRestoredTrigger += 1
                }
            }
        }

        monitor.start(queue: monitorQueue)
    }

    /// 停止网络监听
    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }

    // MARK: - Sync

    /// 同步所有模型的未上传记录到后端
    func syncAll(modelContext: ModelContext) async {
        guard isConnected else { return }
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        // Push: 上传未同步记录
        await syncPendingMeals(modelContext: modelContext)
        await syncPendingWaterLogs(modelContext: modelContext)
        await syncPendingWeightLogs(modelContext: modelContext)

        // Push: 同步待删除记录
        await syncPendingDeletions(modelContext: modelContext)

        updatePendingCount(modelContext: modelContext)
    }

    /// 兼容旧调用：同步未上传的 MealRecord 到后端
    func syncPendingRecords(modelContext: ModelContext) async {
        await syncAll(modelContext: modelContext)
    }

    /// 更新待同步计数（包含所有模型的未上传和待删除记录）
    func updatePendingCount(modelContext: ModelContext) {
        do {
            let unsyncedMeals = try modelContext.fetchCount(
                FetchDescriptor<MealRecord>(predicate: #Predicate { $0.isSynced == false })
            )
            let deletionMeals = try modelContext.fetchCount(
                FetchDescriptor<MealRecord>(predicate: #Predicate { $0.pendingDeletion == true })
            )
            let unsyncedWater = try modelContext.fetchCount(
                FetchDescriptor<WaterLog>(predicate: #Predicate { $0.isSynced == false })
            )
            let unsyncedWeight = try modelContext.fetchCount(
                FetchDescriptor<WeightLog>(predicate: #Predicate { $0.isSynced == false })
            )
            pendingCount = unsyncedMeals + deletionMeals + unsyncedWater + unsyncedWeight
        } catch {
            Self.logger.error("[Sync] Failed to count pending records: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private: Meal Sync

    /// 同步未上传的 MealRecord
    private func syncPendingMeals(modelContext: ModelContext) async {
        do {
            let predicate = #Predicate<MealRecord> { record in
                record.isSynced == false
            }
            let descriptor = FetchDescriptor<MealRecord>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )

            let unsyncedRecords = try modelContext.fetch(descriptor)
            guard !unsyncedRecords.isEmpty else { return }

            for record in unsyncedRecords {
                do {
                    try await uploadMealRecord(record)
                    record.isSynced = true
                } catch {
                    Self.logger.error("[Sync] Failed to sync meal \(record.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    continue
                }
            }

            try modelContext.save()
        } catch {
            Self.logger.error("[Sync] Meal sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 将单条 MealRecord 上传至后端
    private func uploadMealRecord(_ record: MealRecord) async throws {
        let createDTO = MealCreateDTO(
            id: record.id,
            imageUrl: record.imageURL,
            mealType: record.mealType,
            mealTime: record.mealTime,
            totalCalories: record.totalCalories,
            proteinGrams: record.proteinGrams,
            carbsGrams: record.carbsGrams,
            fatGrams: record.fatGrams,
            fiberGrams: record.fiberGrams,
            title: record.title,
            descriptionText: record.descriptionText,
            aiAnalysis: record.aiAnalysis,
            tags: record.tags,
            detectedFoods: record.detectedFoods.map { food in
                DetectedFoodCreateDTO(
                    name: food.name,
                    nameZh: food.nameZh,
                    emoji: food.emoji,
                    confidence: food.confidence,
                    boundingBoxX: food.boundingBoxX,
                    boundingBoxY: food.boundingBoxY,
                    boundingBoxW: food.boundingBoxW,
                    boundingBoxH: food.boundingBoxH,
                    calories: food.calories,
                    proteinGrams: food.proteinGrams,
                    carbsGrams: food.carbsGrams,
                    fatGrams: food.fatGrams
                )
            }
        )

        let _: MealResponseDTO = try await APIClient.shared.request(.createMeal, body: createDTO)
    }

    /// 同步待删除的 MealRecord 到后端
    private func syncPendingDeletions(modelContext: ModelContext) async {
        do {
            let predicate = #Predicate<MealRecord> { record in
                record.pendingDeletion == true
            }
            let descriptor = FetchDescriptor<MealRecord>(predicate: predicate)
            let pendingDeletions = try modelContext.fetch(descriptor)

            guard !pendingDeletions.isEmpty else { return }

            for record in pendingDeletions {
                do {
                    try await MealService.shared.deleteMeal(id: record.id.uuidString)
                    modelContext.delete(record)
                } catch {
                    Self.logger.error("[Sync] Failed to sync deletion for \(record.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    continue
                }
            }

            try modelContext.save()
        } catch {
            Self.logger.error("[Sync] Delete sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private: Water Sync

    /// 同步未上传的 WaterLog
    private func syncPendingWaterLogs(modelContext: ModelContext) async {
        do {
            let predicate = #Predicate<WaterLog> { log in
                log.isSynced == false
            }
            let descriptor = FetchDescriptor<WaterLog>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.recordedAt, order: .forward)]
            )

            let unsynced = try modelContext.fetch(descriptor)
            guard !unsynced.isEmpty else { return }

            for log in unsynced {
                do {
                    let dto = WaterLogCreateDTO(amountMl: log.amountML)
                    let _: WaterLogResponseDTO = try await APIClient.shared.request(.logWater, body: dto)
                    log.isSynced = true
                } catch {
                    Self.logger.error("[Sync] Failed to sync water log: \(error.localizedDescription, privacy: .public)")
                    continue
                }
            }

            try modelContext.save()
        } catch {
            Self.logger.error("[Sync] Water sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private: Weight Sync

    /// 同步未上传的 WeightLog
    private func syncPendingWeightLogs(modelContext: ModelContext) async {
        do {
            let predicate = #Predicate<WeightLog> { log in
                log.isSynced == false
            }
            let descriptor = FetchDescriptor<WeightLog>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.recordedAt, order: .forward)]
            )

            let unsynced = try modelContext.fetch(descriptor)
            guard !unsynced.isEmpty else { return }

            for log in unsynced {
                do {
                    let dto = WeightLogCreateDTO(weightKg: log.weightKg, recordedAt: log.recordedAt)
                    let _: WeightLogResponseDTO = try await APIClient.shared.request(.logWeight, body: dto)
                    log.isSynced = true
                } catch {
                    Self.logger.error("[Sync] Failed to sync weight log: \(error.localizedDescription, privacy: .public)")
                    continue
                }
            }

            try modelContext.save()
        } catch {
            Self.logger.error("[Sync] Weight sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
