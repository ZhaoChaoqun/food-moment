import XCTest
import SwiftData
@testable import FoodMoment

/// HomeViewModel.refreshFromAPI 同步逻辑测试
/// 覆盖：餐食 upsert、水量同步、用户资料更新
@MainActor
final class HomeViewModelSyncTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var mockMealService: MockMealService!
    private var mockWaterService: MockWaterService!
    private var mockUserService: MockUserService!
    private var sut: HomeViewModel!

    override func setUp() async throws {
        try await super.setUp()
        container = PersistenceController.createPreviewContainer()
        context = container.mainContext
        mockMealService = MockMealService()
        mockWaterService = MockWaterService()
        mockUserService = MockUserService()
        sut = HomeViewModel(
            mealService: mockMealService,
            waterService: mockWaterService,
            userService: mockUserService
        )
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        mockMealService = nil
        mockWaterService = nil
        mockUserService = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeMealDTO(
        id: UUID,
        title: String = "API Meal",
        mealTime: Date = Date(),
        updatedAt: Date = Date()
    ) -> MealResponseDTO {
        MealResponseDTO(
            id: id,
            imageUrl: nil,
            mealType: "lunch",
            mealTime: mealTime,
            totalCalories: 500,
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
        mealTime: Date = Date(),
        updatedAt: Date = Date()
    ) -> MealRecord {
        let record = MealRecord(
            id: id,
            mealType: "lunch",
            mealTime: mealTime,
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

    private func fetchAllWaterLogs() -> [WaterLog] {
        (try? context.fetch(FetchDescriptor<WaterLog>())) ?? []
    }

    // MARK: - 餐食 Upsert 测试

    func test_refreshFromAPI_insertsNewRemoteMeals() async {
        let remoteID = UUID()
        mockMealService.getMealsResult = .success([
            makeMealDTO(id: remoteID, title: "Remote Lunch")
        ])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.title, "Remote Lunch")
        XCTAssertTrue(meals.first?.isSynced == true)
    }

    func test_refreshFromAPI_preservesUnsyncedLocalMeals() async {
        let unsyncedID = UUID()
        _ = insertLocalMeal(id: unsyncedID, title: "Offline Meal", isSynced: false)

        mockMealService.getMealsResult = .success([])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        XCTAssertEqual(meals.count, 1, "未同步的本地记录不应被清理")
        XCTAssertEqual(meals.first?.title, "Offline Meal")
    }

    func test_refreshFromAPI_deletesSyncedOrphanMeals() async {
        let orphanID = UUID()
        _ = insertLocalMeal(id: orphanID, title: "Orphan", isSynced: true)

        mockMealService.getMealsResult = .success([])

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        XCTAssertEqual(meals.count, 0, "已同步 + 服务端不存在 → 应清理")
    }

    // MARK: - 水量同步测试

    func test_refreshFromAPI_insertsWaterLogFromAPI() async {
        mockWaterService.getWaterResult = .success(
            DailyWaterResponseDTO(date: Date().apiDateString, totalMl: 1500, goalMl: 2000, logs: [])
        )
        mockMealService.getMealsResult = .success([])

        await sut.refreshFromAPI(modelContext: context)

        let logs = fetchAllWaterLogs()
        let syncedLogs = logs.filter { $0.isSynced }
        XCTAssertEqual(syncedLogs.count, 1, "应插入一条已同步的合并水量记录")
        XCTAssertEqual(syncedLogs.first?.amountML, 1500)
    }

    func test_refreshFromAPI_preservesUnsyncedWaterLogs() async {
        let unsyncedLog = WaterLog(amountML: 250, isSynced: false)
        context.insert(unsyncedLog)
        try? context.save()

        mockWaterService.getWaterResult = .success(
            DailyWaterResponseDTO(date: Date().apiDateString, totalMl: 1000, goalMl: 2000, logs: [])
        )
        mockMealService.getMealsResult = .success([])

        await sut.refreshFromAPI(modelContext: context)

        let logs = fetchAllWaterLogs()
        let unsyncedLogs = logs.filter { !$0.isSynced }
        XCTAssertEqual(unsyncedLogs.count, 1, "未同步的水量记录不应被删除")
        XCTAssertEqual(unsyncedLogs.first?.amountML, 250)
    }

    // MARK: - 用户资料更新

    func test_refreshFromAPI_updatesUserProfile() async {
        mockUserService.getProfileResult = .success(
            UserProfileResponseDTO(
                id: UUID(),
                displayName: "FoodLover",
                email: nil,
                avatarUrl: "https://example.com/avatar.jpg",
                isPro: true,
                dailyCalorieGoal: 2500,
                dailyProteinGoal: 80,
                dailyCarbsGoal: 300,
                dailyFatGoal: 70,
                targetWeight: 65.0,
                gender: nil,
                birthYear: nil,
                heightCm: nil,
                activityLevel: nil,
                dailyWaterGoal: 2000,
                dailyStepGoal: 10000,
                createdAt: Date(),
                updatedAt: Date()
            )
        )
        mockMealService.getMealsResult = .success([])

        await sut.refreshFromAPI(modelContext: context)

        XCTAssertEqual(sut.userName, "FoodLover")
        XCTAssertEqual(sut.userAvatarUrl, "https://example.com/avatar.jpg")
    }

    // MARK: - API 失败

    func test_refreshFromAPI_apiFailure_preservesLocalData() async {
        let localID = UUID()
        _ = insertLocalMeal(id: localID, title: "Cached", isSynced: true)

        mockMealService.getMealsResult = .failure(APIError.networkError(NSError(domain: "", code: -1)))

        await sut.refreshFromAPI(modelContext: context)

        let meals = fetchAllMeals()
        XCTAssertEqual(meals.count, 1, "API 失败时缓存数据应保持不变")
    }
}
