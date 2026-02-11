import Foundation
import SwiftData
import CloudKit
import Network
import Observation
import os

/// Sendable data structure for concurrent upload
struct RecordUploadData: Sendable {
    let id: UUID
    let mealType: String
    let mealTime: Date
    let totalCalories: Int
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    let fiberGrams: Double
    let title: String
    let descriptionText: String?
    let aiAnalysis: String?
    let tags: [String]
    let createdAt: Date
    let localImageData: Data?
}

/// iCloud 同步管理器
/// 基于 SwiftData + CloudKit 实现多设备自动同步
@MainActor
@Observable
final class CloudSyncManager {
    static let shared = CloudSyncManager()

    private nonisolated static let logger = Logger(subsystem: "com.foodmoment", category: "CloudSyncManager")

    // MARK: - State

    var syncStatus: SyncStatus = .idle
    var lastSyncDate: Date?
    var pendingUploadCount = 0
    var iCloudAvailable = false
    var errorMessage: String?

    // MARK: - Private

    private var isConnected = false
    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.foodmoment.cloudsync.monitor")

    // CloudKit Container Identifier
    nonisolated static let containerIdentifier = "iCloud.com.zhaochaoqun.FoodMoment"

    private init() {
        // 延迟检查 iCloud 状态，避免阻塞应用启动
        // 在模拟器或未配置 iCloud 的环境中，直接设置为不可用
        #if targetEnvironment(simulator)
        iCloudAvailable = false
        errorMessage = "iCloud 在模拟器中不可用"
        #else
        // 暂时禁用 iCloud 检查，因为 entitlements 中未配置 iCloud 权限
        // 启用 iCloud 后取消以下注释
        iCloudAvailable = false
        errorMessage = "iCloud 同步暂未启用"
        // Task { @MainActor in
        //     checkiCloudStatus()
        // }
        #endif
    }

    // MARK: - Sync Status Enum

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case uploading(progress: Double)
        case downloading(progress: Double)
        case completed
        case error(String)

        var description: String {
            switch self {
            case .idle:
                return "待同步"
            case .syncing:
                return "同步中..."
            case .uploading(let progress):
                return "上传中 \(Int(progress * 100))%"
            case .downloading(let progress):
                return "下载中 \(Int(progress * 100))%"
            case .completed:
                return "同步完成"
            case .error(let message):
                return "同步失败: \(message)"
            }
        }
    }

    // MARK: - iCloud Status Check

    func checkiCloudStatus() {
        // 在模拟器中跳过 iCloud 检查
        #if targetEnvironment(simulator)
        iCloudAvailable = false
        errorMessage = "iCloud 在模拟器中不可用"
        return
        #else
        // 暂时禁用 iCloud 检查，因为 entitlements 中未配置 iCloud 权限
        // 启用 iCloud 后取消以下代码的注释
        iCloudAvailable = false
        errorMessage = "iCloud 同步暂未启用"
        return

        /*
        // 真机上异步检查 iCloud 状态
        Task { @MainActor in
            do {
                let container = CKContainer(identifier: Self.containerIdentifier)
                let status = try await container.accountStatus()

                switch status {
                case .available:
                    self.iCloudAvailable = true
                    self.errorMessage = nil
                case .noAccount:
                    self.iCloudAvailable = false
                    self.errorMessage = "请登录 iCloud 账户"
                case .restricted:
                    self.iCloudAvailable = false
                    self.errorMessage = "iCloud 访问受限"
                case .couldNotDetermine:
                    self.iCloudAvailable = false
                    self.errorMessage = "无法确定 iCloud 状态"
                case .temporarilyUnavailable:
                    self.iCloudAvailable = false
                    self.errorMessage = "iCloud 暂时不可用"
                @unknown default:
                    self.iCloudAvailable = false
                    self.errorMessage = "未知 iCloud 状态"
                }
            } catch {
                self.iCloudAvailable = false
                self.errorMessage = error.localizedDescription
                print("[CloudSyncManager] iCloud status check failed: \(error)")
            }
        }
        */
        #endif
    }

    // MARK: - Network Monitoring

    func startNetworkMonitoring() {
        guard monitor == nil else { return }

        let monitor = NWPathMonitor()
        self.monitor = monitor

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasConnected = self.isConnected
                self.isConnected = (path.status == .satisfied)

                // 网络恢复时触发同步
                let networkJustRestored = !wasConnected && self.isConnected
                let hasPendingUploads = self.pendingUploadCount > 0

                if networkJustRestored && hasPendingUploads {
                    NotificationCenter.default.post(
                        name: .cloudSyncNetworkRestored,
                        object: nil
                    )
                }
            }
        }

        monitor.start(queue: monitorQueue)
    }

    func stopNetworkMonitoring() {
        monitor?.cancel()
        monitor = nil
    }

    // MARK: - Sync Operations

    /// 执行全量同步
    func performFullSync(modelContext: ModelContext) async {
        guard iCloudAvailable else {
            syncStatus = .error("iCloud 不可用")
            return
        }

        guard isConnected else {
            syncStatus = .error("网络不可用")
            return
        }

        syncStatus = .syncing

        // 1. 上传本地未同步的记录
        await uploadPendingRecords(modelContext: modelContext)

        // 2. SwiftData 配合 CloudKit 会自动处理下载和合并
        // 这里主要是触发和监控

        syncStatus = .completed
        lastSyncDate = Date()

        // 3 秒后重置状态
        try? await Task.sleep(for: .seconds(3))
        syncStatus = .idle
    }

    /// 上传待同步记录（使用 TaskGroup 批量上传）
    func uploadPendingRecords(modelContext: ModelContext) async {
        do {
            // 查询未同步的 MealRecord
            let predicate = #Predicate<MealRecord> { record in
                record.isSynced == false
            }
            let descriptor = FetchDescriptor<MealRecord>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )

            let unsyncedRecords = try modelContext.fetch(descriptor)
            pendingUploadCount = unsyncedRecords.count

            guard !unsyncedRecords.isEmpty else {
                Self.logger.debug("No pending records to upload")
                return
            }

            Self.logger.debug("Uploading \(unsyncedRecords.count, privacy: .public) records...")

            // Extract data from records for concurrent upload (MealRecord is not Sendable)
            let uploadDataList = unsyncedRecords.map { record in
                RecordUploadData(
                    id: record.id,
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
                    createdAt: record.createdAt,
                    localImageData: record.localImageData
                )
            }

            // Create a lookup dictionary for records by ID
            var recordsById: [UUID: MealRecord] = [:]
            for record in unsyncedRecords {
                recordsById[record.id] = record
            }

            // 使用 TaskGroup 并发上传，限制并发数为 5
            let batchSize = 5
            var uploadedCount = 0

            for batch in uploadDataList.chunked(into: batchSize) {
                await withTaskGroup(of: (UUID, Bool).self) { group in
                    for data in batch {
                        group.addTask {
                            do {
                                try await self.uploadRecordData(data)
                                return (data.id, true)
                            } catch {
                                CloudSyncManager.logger.error("Failed to upload record \(data.id, privacy: .public): \(String(describing: error), privacy: .public)")
                                return (data.id, false)
                            }
                        }
                    }

                    for await (recordId, success) in group {
                        if success, let record = recordsById[recordId] {
                            record.isSynced = true
                            uploadedCount += 1
                            pendingUploadCount -= 1

                            // 更新进度
                            let progress = Double(uploadedCount) / Double(unsyncedRecords.count)
                            syncStatus = .uploading(progress: progress)
                        }
                    }
                }
            }

            // 保存同步状态
            try modelContext.save()
            Self.logger.debug("Successfully uploaded \(uploadedCount, privacy: .public) records")

        } catch {
            Self.logger.error("Upload failed: \(error.localizedDescription, privacy: .public)")
            syncStatus = .error(error.localizedDescription)
        }
    }

    /// 上传单条记录到 CloudKit (使用 Sendable 数据结构)
    private nonisolated func uploadRecordData(_ data: RecordUploadData) async throws {
        let container = CKContainer(identifier: Self.containerIdentifier)
        let database = container.privateCloudDatabase

        let recordID = CKRecord.ID(recordName: data.id.uuidString)
        let ckRecord = CKRecord(recordType: "MealRecord", recordID: recordID)

        // 设置字段
        ckRecord["mealType"] = data.mealType
        ckRecord["mealTime"] = data.mealTime
        ckRecord["totalCalories"] = data.totalCalories
        ckRecord["proteinGrams"] = data.proteinGrams
        ckRecord["carbsGrams"] = data.carbsGrams
        ckRecord["fatGrams"] = data.fatGrams
        ckRecord["fiberGrams"] = data.fiberGrams
        ckRecord["title"] = data.title
        ckRecord["descriptionText"] = data.descriptionText
        ckRecord["aiAnalysis"] = data.aiAnalysis
        ckRecord["tags"] = data.tags
        ckRecord["createdAt"] = data.createdAt

        // 如果有图片数据，作为 Asset 上传
        if let imageData = data.localImageData {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")

            try imageData.write(to: tempURL)
            ckRecord["image"] = CKAsset(fileURL: tempURL)

            // 保存到 CloudKit
            _ = try await database.save(ckRecord)

            // 上传后清理临时文件
            try? FileManager.default.removeItem(at: tempURL)
        } else {
            // 保存到 CloudKit
            _ = try await database.save(ckRecord)
        }
    }

    /// 上传单条记录到 CloudKit
    private func uploadRecord(_ record: MealRecord) async throws {
        let container = CKContainer(identifier: Self.containerIdentifier)
        let database = container.privateCloudDatabase

        let recordID = CKRecord.ID(recordName: record.id.uuidString)
        let ckRecord = CKRecord(recordType: "MealRecord", recordID: recordID)

        // 设置字段
        ckRecord["mealType"] = record.mealType
        ckRecord["mealTime"] = record.mealTime
        ckRecord["totalCalories"] = record.totalCalories
        ckRecord["proteinGrams"] = record.proteinGrams
        ckRecord["carbsGrams"] = record.carbsGrams
        ckRecord["fatGrams"] = record.fatGrams
        ckRecord["fiberGrams"] = record.fiberGrams
        ckRecord["title"] = record.title
        ckRecord["descriptionText"] = record.descriptionText
        ckRecord["aiAnalysis"] = record.aiAnalysis
        ckRecord["tags"] = record.tags
        ckRecord["createdAt"] = record.createdAt

        // 如果有图片数据，作为 Asset 上传
        if let imageData = record.localImageData {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")

            try imageData.write(to: tempURL)
            ckRecord["image"] = CKAsset(fileURL: tempURL)

            // 保存到 CloudKit
            _ = try await database.save(ckRecord)

            // 上传后清理临时文件
            try? FileManager.default.removeItem(at: tempURL)
        } else {
            // 保存到 CloudKit
            _ = try await database.save(ckRecord)
        }
    }

    /// 更新待上传计数
    func updatePendingCount(modelContext: ModelContext) {
        do {
            let predicate = #Predicate<MealRecord> { record in
                record.isSynced == false
            }
            let descriptor = FetchDescriptor<MealRecord>(predicate: predicate)
            let records = try modelContext.fetch(descriptor)
            pendingUploadCount = records.count
        } catch {
            Self.logger.error("Failed to count pending records: \(String(describing: error), privacy: .public)")
        }
    }

    /// 强制刷新（从 CloudKit 拉取最新数据）
    func forceRefresh() async {
        // SwiftData + CloudKit 会自动处理同步
        // 这里可以触发一个手动刷新信号
        checkiCloudStatus()
        NotificationCenter.default.post(name: .cloudSyncRefreshRequested, object: nil)
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudSyncNetworkRestored = Notification.Name("cloudSyncNetworkRestored")
    static let cloudSyncRefreshRequested = Notification.Name("cloudSyncRefreshRequested")
}

// MARK: - SwiftData ModelContainer Configuration for CloudKit

extension ModelContainer {
    /// 创建支持 CloudKit 同步的 ModelContainer
    static func createWithCloudKit() throws -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            MealRecord.self,
            DetectedFood.self,
            WeightLog.self,
            WaterLog.self,
            Achievement.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .private(CloudSyncManager.containerIdentifier)
        )

        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
}
