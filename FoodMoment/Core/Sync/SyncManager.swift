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
                    // 需要外部传入 modelContext，此处仅标记需要同步
                    // 由调用方监听 isConnected 变化并调用 syncPendingRecords
                    NotificationCenter.default.post(
                        name: .syncManagerNetworkRestored,
                        object: nil
                    )
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

    /// 同步未上传的 MealRecord 到后端
    func syncPendingRecords(modelContext: ModelContext) async {
        guard isConnected else { return }
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            // 查询所有未同步的 MealRecord
            let predicate = #Predicate<MealRecord> { record in
                record.isSynced == false
            }
            let descriptor = FetchDescriptor<MealRecord>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )

            let unsyncedRecords = try modelContext.fetch(descriptor)
            pendingCount = unsyncedRecords.count

            guard !unsyncedRecords.isEmpty else { return }

            for record in unsyncedRecords {
                do {
                    try await uploadMealRecord(record)
                    record.isSynced = true
                    pendingCount -= 1
                } catch {
                    // 单条上传失败不中断整体同步流程
                    Self.logger.error("Failed to sync record \(record.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    continue
                }
            }

            // 保存同步状态变更
            try modelContext.save()
        } catch {
            Self.logger.error("Sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 更新待同步计数（可在首页加载时调用）
    func updatePendingCount(modelContext: ModelContext) {
        do {
            let predicate = #Predicate<MealRecord> { record in
                record.isSynced == false
            }
            let descriptor = FetchDescriptor<MealRecord>(predicate: predicate)
            let records = try modelContext.fetch(descriptor)
            pendingCount = records.count
        } catch {
            Self.logger.error("Failed to count pending records: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private

    /// 将单条 MealRecord 上传至后端
    private func uploadMealRecord(_ record: MealRecord) async throws {
        let createDTO = MealCreateDTO(
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
}

// MARK: - Notification Name

extension Notification.Name {
    static let syncManagerNetworkRestored = Notification.Name("syncManagerNetworkRestored")
}
