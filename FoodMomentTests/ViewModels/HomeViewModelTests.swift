import XCTest
@testable import FoodMoment

/// Tests for HomeViewModel
@MainActor
final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!

    override func setUp() {
        super.setUp()
        sut = HomeViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_consumedCaloriesIsZero() {
        XCTAssertEqual(sut.consumedCalories, 0)
    }

    func test_initialState_waterAmountIsZero() {
        XCTAssertEqual(sut.waterAmount, 0)
    }

    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Calories Calculation Tests

    func test_caloriesLeft_whenUnderGoal_returnsPositive() {
        // Given
        sut.dailyCalorieGoal = 2000
        sut.consumedCalories = 1200

        // When
        let remaining = sut.caloriesLeft

        // Then
        XCTAssertEqual(remaining, 800)
    }

    func test_caloriesLeft_whenOverGoal_returnsZero() {
        // Given (caloriesLeft uses max(..., 0) so it won't return negative)
        sut.dailyCalorieGoal = 2000
        sut.consumedCalories = 2500

        // When
        let remaining = sut.caloriesLeft

        // Then
        XCTAssertEqual(remaining, 0)
    }

    func test_caloriesLeft_whenAtGoal_returnsZero() {
        // Given
        sut.dailyCalorieGoal = 2000
        sut.consumedCalories = 2000

        // When
        let remaining = sut.caloriesLeft

        // Then
        XCTAssertEqual(remaining, 0)
    }

    // MARK: - Progress Calculation Tests

    func test_calorieProgress_whenHalfway_returns50Percent() {
        // Given
        sut.dailyCalorieGoal = 2000
        sut.consumedCalories = 1000

        // When
        let progress = sut.calorieProgress

        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func test_calorieProgress_whenOverGoal_capsAt100Percent() {
        // Given
        sut.dailyCalorieGoal = 2000
        sut.consumedCalories = 3000

        // When
        let progress = sut.calorieProgress

        // Then
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }

    func test_proteinProgress_calculatesCorrectly() {
        // Given
        sut.dailyProteinGoal = 100
        sut.proteinGrams = 75

        // When
        let progress = sut.proteinProgress

        // Then
        XCTAssertEqual(progress, 0.75, accuracy: 0.001)
    }

    func test_carbsProgress_calculatesCorrectly() {
        // Given
        sut.dailyCarbsGoal = 250
        sut.carbsGrams = 125

        // When
        let progress = sut.carbsProgress

        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func test_fatProgress_calculatesCorrectly() {
        // Given
        sut.dailyFatGoal = 65
        sut.fatGrams = 32.5

        // When
        let progress = sut.fatProgress

        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func test_waterProgress_calculatesCorrectly() {
        // Given
        sut.dailyWaterGoal = 2500
        sut.waterAmount = 1250

        // When
        let progress = sut.waterProgress

        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    // MARK: - Greeting Tests

    func test_greeting_returnsNonEmptyString() {
        let greeting = sut.greeting
        XCTAssertFalse(greeting.isEmpty)
    }

    func test_greeting_returnsValidGreeting() {
        let greeting = sut.greeting
        let validGreetings = ["早安", "午好", "晚好"]
        XCTAssertTrue(validGreetings.contains(greeting))
    }

    // MARK: - Today's Meals Tests

    func test_todayMeals_initiallyEmpty() {
        XCTAssertTrue(sut.todayMeals.isEmpty)
    }

    // MARK: - Mock Data Tests

    func test_loadMockData_populatesAllFields() {
        // When
        sut.loadMockData()

        // Then
        XCTAssertEqual(sut.userName, "User")
        XCTAssertEqual(sut.dailyCalorieGoal, 2500)
        XCTAssertEqual(sut.consumedCalories, 1260)
        XCTAssertEqual(sut.proteinGrams, 45)
        XCTAssertEqual(sut.carbsGrams, 120)
        XCTAssertEqual(sut.fatGrams, 38)
        XCTAssertEqual(sut.waterAmount, 1250)
        XCTAssertEqual(sut.stepCount, 6842)
        XCTAssertEqual(sut.todayMeals.count, 3)
    }

    func test_loadMockData_mealsHaveCorrectTypes() {
        // When
        sut.loadMockData()

        // Then
        let mealTypes = sut.todayMeals.map { $0.mealType }
        XCTAssertTrue(mealTypes.contains("breakfast"))
        XCTAssertTrue(mealTypes.contains("lunch"))
        XCTAssertTrue(mealTypes.contains("snack"))
    }

    // MARK: - Edge Cases

    func test_calorieProgress_whenGoalIsZero_returnsZero() {
        // Given
        sut.dailyCalorieGoal = 0
        sut.consumedCalories = 1000

        // When
        let progress = sut.calorieProgress

        // Then
        XCTAssertEqual(progress, 0)
    }

    func test_proteinProgress_whenGoalIsZero_returnsZero() {
        // Given
        sut.dailyProteinGoal = 0
        sut.proteinGrams = 50

        // When
        let progress = sut.proteinProgress

        // Then
        XCTAssertEqual(progress, 0)
    }
}
