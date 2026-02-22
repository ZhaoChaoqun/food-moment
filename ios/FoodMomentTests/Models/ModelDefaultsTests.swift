import XCTest
@testable import FoodMoment

/// WaterLog 和 WeightLog 模型默认值及同步字段测试
final class ModelDefaultsTests: XCTestCase {

    // MARK: - WaterLog Tests

    func test_waterLog_defaultIsSynced_isFalse() {
        let log = WaterLog(amountML: 250)
        XCTAssertFalse(log.isSynced, "WaterLog 默认 isSynced 应为 false（离线优先）")
    }

    func test_waterLog_explicitIsSynced() {
        let log = WaterLog(amountML: 500, isSynced: true)
        XCTAssertTrue(log.isSynced)
    }

    func test_waterLog_defaultPendingDeletion_isFalse() {
        let log = WaterLog(amountML: 250)
        XCTAssertFalse(log.pendingDeletion)
    }

    func test_waterLog_hasTimestamps() {
        let beforeCreation = Date()
        let log = WaterLog(amountML: 300)
        let afterCreation = Date()

        XCTAssertGreaterThanOrEqual(log.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(log.createdAt, afterCreation)
        XCTAssertGreaterThanOrEqual(log.updatedAt, beforeCreation)
        XCTAssertLessThanOrEqual(log.updatedAt, afterCreation)
    }

    func test_waterLog_computedProperties() {
        let log = WaterLog(amountML: 1500)
        XCTAssertEqual(log.amountLiters, 1.5, accuracy: 0.001)
        XCTAssertEqual(log.formattedAmount, "1.5 L")

        let smallLog = WaterLog(amountML: 250)
        XCTAssertEqual(smallLog.formattedAmount, "250 ml")
    }

    // MARK: - WeightLog Tests

    func test_weightLog_defaultIsSynced_isFalse() {
        let log = WeightLog(weightKg: 70.0, recordedAt: Date())
        XCTAssertFalse(log.isSynced, "WeightLog 默认 isSynced 应为 false")
    }

    func test_weightLog_explicitIsSynced() {
        let log = WeightLog(weightKg: 70.0, recordedAt: Date(), isSynced: true)
        XCTAssertTrue(log.isSynced)
    }

    func test_weightLog_defaultPendingDeletion_isFalse() {
        let log = WeightLog(weightKg: 65.0, recordedAt: Date())
        XCTAssertFalse(log.pendingDeletion)
    }

    func test_weightLog_hasTimestamps() {
        let now = Date()
        let log = WeightLog(weightKg: 68.5, recordedAt: now)

        XCTAssertNotNil(log.updatedAt)
        XCTAssertNotNil(log.createdAt)
    }

    func test_weightLog_computedProperties() {
        let log = WeightLog(weightKg: 70.0, recordedAt: Date())
        XCTAssertEqual(log.weightLbs, 70.0 * 2.20462, accuracy: 0.01)
        XCTAssertEqual(log.formattedWeightKg, "70.0 kg")
    }

    // MARK: - MealRecord Tests

    func test_mealRecord_defaultIsSynced_isFalse() {
        let record = MealRecord(
            mealType: "lunch",
            mealTime: Date(),
            title: "Test",
            totalCalories: 500,
            proteinGrams: 20,
            carbsGrams: 50,
            fatGrams: 15
        )
        XCTAssertFalse(record.isSynced, "MealRecord 默认 isSynced 应为 false")
        XCTAssertFalse(record.pendingDeletion, "MealRecord 默认 pendingDeletion 应为 false")
    }

    func test_mealRecord_explicitIsSynced() {
        let record = MealRecord(
            mealType: "lunch",
            mealTime: Date(),
            title: "Test",
            totalCalories: 500,
            proteinGrams: 20,
            carbsGrams: 50,
            fatGrams: 15,
            isSynced: true
        )
        XCTAssertTrue(record.isSynced)
    }
}
