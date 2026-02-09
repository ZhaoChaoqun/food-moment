import XCTest

/// UI Tests for home screen
final class HomeScreenTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-data"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Layout Tests

    func test_homeView_exists() {
        // Home view should be displayed after launch in UI testing mode
        let homeView = app.otherElements["HomeView"]
        XCTAssertTrue(homeView.waitForExistence(timeout: 10), "HomeView should exist after launch")
    }

    func test_homeView_greetingDisplayed() {
        let greeting = app.staticTexts["GreetingText"]
        XCTAssertTrue(greeting.waitForExistence(timeout: 10), "Greeting text should be displayed")
    }

    func test_homeView_calorieRingDisplayed() {
        let calorieRing = app.otherElements["CalorieRingChart"]
        XCTAssertTrue(calorieRing.waitForExistence(timeout: 10), "Calorie ring chart should be displayed")
    }

    func test_homeView_waterCardDisplayed() {
        let waterCard = app.otherElements["WaterCard"]
        XCTAssertTrue(waterCard.waitForExistence(timeout: 10), "Water card should be displayed")
    }

    func test_homeView_stepsCardDisplayed() {
        let stepsCard = app.otherElements["StepsCard"]
        XCTAssertTrue(stepsCard.waitForExistence(timeout: 10), "Steps card should be displayed")
    }

    func test_homeView_caloriesRemainingDisplayed() {
        let caloriesText = app.staticTexts["CaloriesRemainingText"]
        XCTAssertTrue(caloriesText.waitForExistence(timeout: 10), "Calories remaining text should be displayed")
    }

    // MARK: - Tab Bar Tests

    func test_tabBar_exists() {
        let tabBar = app.otherElements["CustomTabBar"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Custom tab bar should exist")
    }

    func test_tabBar_scanButtonExists() {
        let scanButton = app.buttons["ScanTabButton"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: 10), "Scan tab button should exist")
    }

    // MARK: - Interaction Tests

    func test_homeView_scrollable() {
        let scrollView = app.scrollViews["HomeScrollView"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10), "Home scroll view should exist")

        // Try scrolling
        scrollView.swipeUp()
        scrollView.swipeDown()
    }
}
