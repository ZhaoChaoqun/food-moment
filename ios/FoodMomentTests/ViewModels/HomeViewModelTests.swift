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

    func test_initialState_userNameIsDefault() {
        XCTAssertEqual(sut.userName, "User")
    }

    func test_initialState_stepCountIsZero() {
        XCTAssertEqual(sut.stepCount, 0)
    }

    func test_initialState_caloriesBurnedIsZero() {
        XCTAssertEqual(sut.caloriesBurned, 0)
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
}
