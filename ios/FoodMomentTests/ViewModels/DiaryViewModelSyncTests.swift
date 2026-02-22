import XCTest
import SwiftData
@testable import FoodMoment

/// DiaryViewModel.refreshFromAPI 同步逻辑测试
/// 覆盖：UUID upsert、未同步记录保护、孤儿记录清理、待删除记录保护
@MainActor
final class DiaryViewModelSyncTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var mockMealService: MockMealService!
    private var sut: DiaryViewModel!

    override func setUp() async throws {
        try await super.setUp()
        container = PersistenceController.createPreviewContainer()
        context = container.mainContext
        mockMealService = MockMealService()
        sut = DiaryViewModel(mealService: mockMealService)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        mockMealService = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeMealDTO(
        id: UUID,
        title: String = "API Meal",
        totalCalories: Int = 500,
        mealTime: Date? = nil,
        updatedAt: Date = Date()
    ) -> MealResponseDTO {
        MealResponseDTO(
            id: id,
            imageUrl: nil,
            mealType: "lunch",
            mealTime: mealTime ?? sut.selectedDate,
            totalCalories: totalCalories,
            proteinGrams: 20,
            carbsGrams: 50,
            fatGrams: 15,
            fiberGrams: 5,
            title: title,
            descriptionText: nil,
            aiAnalysis: nil,
            tags: nil,
            detectedFoods: [],
            createdAt: Date(),
            updatedAt: updatedAt
        )
    }

    private func insertLocalMeal(
        id: UUID,
        title: String = "Local Meal",
        isSynced: Bool = true,
        pendingDeletion: Bool = false,
        mealTime: Date? = nil,
        updatedAt: Date = Date()
    ) -> MealRecord {
        let record = MealRecord(
            id: id,
            mealType: "lunch",
            mealTime: mealTime ?? sut.selectedDate,
            title: title,
            totalCalories: 300,
            proteinGrams: 10,
            carbsGrams: 30,
            fatGrams: 8,
            isSynced: isSynced
        )
        record.pendingDeletion = pendingDeletion
        record.updatedAt = updatedAt
        context.insert(record)
        try? context.save()
        return record
    }

    private func fetchAllMeals() -> [MealRecord] {
        (try? context.fetch(FetchDescriptor<MealRecord>())) ?? []
    }

    // MARK: - Upsert: 新记录插入

    func test_refreshFromAPI_insertsNewRemoteMeals() async {
        let remoteID = UUID()
        mockMealService.getMealsResult = .success([
            makeMealDTO(id: remoteID, title: "Remote Lunch")
        ])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.title, "Remote Lunch")
        XCTAssertEqual(meals.first?.id, remoteID)
        XCTAssertTrue(meals.first?.isSynced == true)
    }

    // MARK: - Upsert: 已同步记录更新

    func test_refreshFromAPI_updatesSyncedLocalRecords() async {
        let id = UUID()
        let oldTime = Date(timeIntervalSince1970: 1000)
        let newTime = Date(timeIntervalSince1970: 2000)

        _ = insertLocalMeal(id: id, title: "Old Title", isSynced: true, updatedAt: oldTime)

        mockMealService.getMealsResult = .success([
            makeMealDTO(id: id, title: "Updated Title", totalCalories: 800, updatedAt: newTime)
        ])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.title, "Updated Title", "已同步的本地记录应被远端更新")
        XCTAssertEqual(meals.first?.totalCalories, 800)
    }

    // MARK: - 未同步记录保护

    func test_refreshFromAPI_preservesUnsyncedLocalRecords() async {
        let localID = UUID()
        let remoteID = UUID()

        _ = insertLocalMeal(id: localID, title: "Unsynced Local", isSynced: false)

        mockMealService.getMealsResult = .success([
            makeMealDTO(id: remoteID, title: "Remote Meal")
        ])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        let titles = Set(meals.map(\.title))

        XCTAssertTrue(titles.contains("Unsynced Local"), "未同步记录不应被删除")
        XCTAssertTrue(titles.contains("Remote Meal"), "远端新记录应被插入")
        XCTAssertEqual(meals.count, 2)
    }

    func test_refreshFromAPI_doesNotOverwriteUnsyncedRecord_evenWithSameID() async {
        let id = UUID()
        let localTime = Date(timeIntervalSince1970: 1000)
        let remoteTime = Date(timeIntervalSince1970: 2000)

        _ = insertLocalMeal(id: id, title: "Local Unsynced", isSynced: false, updatedAt: localTime)

        mockMealService.getMealsResult = .success([
            makeMealDTO(id: id, title: "Remote Update", updatedAt: remoteTime)
        ])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.title, "Local Unsynced", "isSynced=false 的记录不应被远端覆盖")
    }

    // MARK: - 待删除记录保护

    func test_refreshFromAPI_preservesPendingDeletionRecords() async {
        let id = UUID()
        _ = insertLocalMeal(id: id, title: "Pending Delete", isSynced: true, pendingDeletion: true)

        mockMealService.getMealsResult = .success([
            makeMealDTO(id: id, title: "Still on Server")
        ])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.title, "Pending Delete", "pendingDeletion=true 的记录不应被远端覆盖")
        XCTAssertTrue(meals.first?.pendingDeletion == true)
    }

    func test_refreshFromAPI_doesNotDeletePendingDeletionRecord_evenIfNotOnServer() async {
        let id = UUID()
        _ = insertLocalMeal(id: id, title: "Pending Delete", isSynced: true, pendingDeletion: true)

        mockMealService.getMealsResult = .success([])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        XCTAssertEqual(meals.count, 1, "待删除的记录不应被清理，即使服务端已不存在")
    }

    // MARK: - 孤儿记录清理

    func test_refreshFromAPI_deletesSyncedOrphanRecords() async {
        let orphanID = UUID()
        let activeID = UUID()

        _ = insertLocalMeal(id: orphanID, title: "Orphan Synced", isSynced: true)
        _ = insertLocalMeal(id: activeID, title: "Active Synced", isSynced: true)

        mockMealService.getMealsResult = .success([
            makeMealDTO(id: activeID, title: "Active From API")
        ])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        let ids = Set(meals.map(\.id))
        XCTAssertFalse(ids.contains(orphanID), "已同步 + 服务端不存在的记录应被清理")
        XCTAssertTrue(ids.contains(activeID), "服务端仍有的记录应保留")
    }

    // MARK: - API 失败

    func test_refreshFromAPI_apiFailure_preservesAllLocalData() async {
        let id = UUID()
        _ = insertLocalMeal(id: id, title: "Cached Meal", isSynced: true)

        mockMealService.getMealsResult = .failure(APIError.networkError(NSError(domain: "", code: -1)))

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        XCTAssertEqual(meals.count, 1, "API 失败时应保持缓存数据不变")
        XCTAssertEqual(meals.first?.title, "Cached Meal")
    }

    // MARK: - 混合场景

    func test_refreshFromAPI_mixedScenario() async {
        let syncedOnServer = UUID()
        let syncedOrphan = UUID()
        let unsyncedLocal = UUID()
        let pendingDelete = UUID()
        let newRemote = UUID()

        _ = insertLocalMeal(id: syncedOnServer, title: "Synced Active", isSynced: true,
                           updatedAt: Date(timeIntervalSince1970: 1000))
        _ = insertLocalMeal(id: syncedOrphan, title: "Synced Orphan", isSynced: true)
        _ = insertLocalMeal(id: unsyncedLocal, title: "Unsynced", isSynced: false)
        _ = insertLocalMeal(id: pendingDelete, title: "PendingDel", isSynced: true, pendingDeletion: true)

        mockMealService.getMealsResult = .success([
            makeMealDTO(id: syncedOnServer, title: "Updated Active", updatedAt: Date(timeIntervalSince1970: 2000)),
            makeMealDTO(id: newRemote, title: "Brand New"),
        ])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        let mealDict = Dictionary(uniqueKeysWithValues: meals.map { ($0.id, $0) })

        // syncedOnServer: 已同步 + 服务端有 → 更新
        XCTAssertEqual(mealDict[syncedOnServer]?.title, "Updated Active")

        // syncedOrphan: 已同步 + 服务端无 → 删除
        XCTAssertNil(mealDict[syncedOrphan], "孤儿已同步记录应被清理")

        // unsyncedLocal: 未同步 → 保留
        XCTAssertEqual(mealDict[unsyncedLocal]?.title, "Unsynced")

        // pendingDelete: 待删除 → 保留
        XCTAssertEqual(mealDict[pendingDelete]?.title, "PendingDel")

        // newRemote: 本地无 → 插入
        XCTAssertEqual(mealDict[newRemote]?.title, "Brand New")

        XCTAssertEqual(meals.count, 4)
    }
}
