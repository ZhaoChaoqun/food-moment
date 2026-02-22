import XCTest
import SwiftData
@testable import FoodMoment

/// MealRecord 同步逻辑测试
/// 覆盖：update(from:) LWW、MealRecord.from() 工厂方法
@MainActor
final class MealRecordSyncTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        container = PersistenceController.createPreviewContainer()
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        try await super.tearDown()
    }

    // MARK: - Helper

    private func makeMealDTO(
        id: UUID = UUID(),
        mealType: String = "lunch",
        title: String = "Test Meal",
        totalCalories: Int = 500,
        updatedAt: Date = Date()
    ) -> MealResponseDTO {
        MealResponseDTO(
            id: id,
            imageUrl: nil,
            mealType: mealType,
            mealTime: Date(),
            totalCalories: totalCalories,
            proteinGrams: 20,
            carbsGrams: 50,
            fatGrams: 15,
            fiberGrams: 5,
            title: title,
            descriptionText: nil,
            aiAnalysis: nil,
            tags: ["test"],
            detectedFoods: [],
            createdAt: Date(),
            updatedAt: updatedAt
        )
    }

    private func makeMealRecord(
        id: UUID = UUID(),
        title: String = "Local Meal",
        totalCalories: Int = 300,
        isSynced: Bool = true,
        updatedAt: Date = Date()
    ) -> MealRecord {
        let record = MealRecord(
            id: id,
            mealType: "lunch",
            mealTime: Date(),
            title: title,
            totalCalories: totalCalories,
            proteinGrams: 10,
            carbsGrams: 30,
            fatGrams: 8,
            fiberGrams: 2,
            isSynced: isSynced
        )
        record.updatedAt = updatedAt
        return record
    }

    // MARK: - MealRecord.from() Tests

    func test_from_createsRecordFromDTO_andMarkedAsSynced() {
        let id = UUID()
        let dto = makeMealDTO(id: id, title: "API Meal", totalCalories: 600)

        let record = MealRecord.from(dto)

        XCTAssertEqual(record.id, id)
        XCTAssertEqual(record.title, "API Meal")
        XCTAssertEqual(record.totalCalories, 600)
        XCTAssertTrue(record.isSynced, "从 DTO 创建的记录应标记为 isSynced = true")
    }

    // MARK: - update(from:) LWW Tests

    func test_update_remoteNewer_overwritesLocalFields() {
        let id = UUID()
        let localTime = Date(timeIntervalSince1970: 1000)
        let remoteTime = Date(timeIntervalSince1970: 2000)

        let record = makeMealRecord(id: id, title: "Old Title", totalCalories: 300, updatedAt: localTime)
        let dto = makeMealDTO(id: id, title: "New Title", totalCalories: 700, updatedAt: remoteTime)

        record.update(from: dto)

        XCTAssertEqual(record.title, "New Title", "远端更新时间更新，应覆盖本地字段")
        XCTAssertEqual(record.totalCalories, 700)
        XCTAssertEqual(record.updatedAt, remoteTime)
        XCTAssertTrue(record.isSynced)
    }

    func test_update_remoteOlder_preservesLocalFields() {
        let id = UUID()
        let localTime = Date(timeIntervalSince1970: 2000)
        let remoteTime = Date(timeIntervalSince1970: 1000)

        let record = makeMealRecord(id: id, title: "Local Title", totalCalories: 300, updatedAt: localTime)
        let dto = makeMealDTO(id: id, title: "Old Remote Title", totalCalories: 700, updatedAt: remoteTime)

        record.update(from: dto)

        XCTAssertEqual(record.title, "Local Title", "远端更新时间更早，不应覆盖本地字段")
        XCTAssertEqual(record.totalCalories, 300)
        XCTAssertEqual(record.updatedAt, localTime)
        XCTAssertTrue(record.isSynced, "即使不覆盖字段，也应标记 isSynced = true")
    }

    func test_update_sameTimestamp_preservesLocalFields() {
        let id = UUID()
        let sameTime = Date(timeIntervalSince1970: 1500)

        let record = makeMealRecord(id: id, title: "Local Title", totalCalories: 300, updatedAt: sameTime)
        let dto = makeMealDTO(id: id, title: "Remote Title", totalCalories: 700, updatedAt: sameTime)

        record.update(from: dto)

        XCTAssertEqual(record.title, "Local Title", "相同时间戳时不应覆盖（guard 用 >）")
        XCTAssertTrue(record.isSynced)
    }

    func test_update_setsTags_fromDTO() {
        let id = UUID()
        let localTime = Date(timeIntervalSince1970: 1000)
        let remoteTime = Date(timeIntervalSince1970: 2000)

        let record = makeMealRecord(id: id, updatedAt: localTime)
        record.tags = ["old"]

        let dto = MealResponseDTO(
            id: id,
            imageUrl: "https://img.example.com/food.jpg",
            mealType: "dinner",
            mealTime: Date(),
            totalCalories: 800,
            proteinGrams: 30,
            carbsGrams: 60,
            fatGrams: 25,
            fiberGrams: 10,
            title: "Dinner",
            descriptionText: "Tasty",
            aiAnalysis: "Good meal",
            tags: ["healthy", "protein"],
            detectedFoods: [],
            createdAt: Date(),
            updatedAt: remoteTime
        )

        record.update(from: dto)

        XCTAssertEqual(record.tags, ["healthy", "protein"])
        XCTAssertEqual(record.imageURL, "https://img.example.com/food.jpg")
        XCTAssertEqual(record.aiAnalysis, "Good meal")
        XCTAssertEqual(record.descriptionText, "Tasty")
    }

    func test_update_nilTags_setsEmptyArray() {
        let id = UUID()
        let localTime = Date(timeIntervalSince1970: 1000)
        let remoteTime = Date(timeIntervalSince1970: 2000)

        let record = makeMealRecord(id: id, updatedAt: localTime)
        record.tags = ["old"]

        let dto = MealResponseDTO(
            id: id,
            imageUrl: nil,
            mealType: "lunch",
            mealTime: Date(),
            totalCalories: 500,
            proteinGrams: 20,
            carbsGrams: 50,
            fatGrams: 15,
            fiberGrams: 5,
            title: "No Tags",
            descriptionText: nil,
            aiAnalysis: nil,
            tags: nil,
            detectedFoods: [],
            createdAt: Date(),
            updatedAt: remoteTime
        )

        record.update(from: dto)

        XCTAssertEqual(record.tags, [], "tags 为 nil 时应设为空数组")
    }
}
