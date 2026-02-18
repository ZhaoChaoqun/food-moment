import XCTest

/// UI Tests for new user first-day flow (anonymous trial)
final class NewUserFirstDayFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--mock-camera", "--reset-state"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func test_firstDayFlow_anonymousTrial_coreTabs_and_captureFlow() throws {
        // 1) Launch -> should land on Home
        let homeView = app.otherElements["HomeView"]
        XCTAssertTrue(homeView.waitForExistence(timeout: 10), "HomeView should be visible after launch")

        // 2) Open Camera via scan tab
        let scanButton = app.buttons["ScanTabButton"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: 10), "Scan tab button should exist")
        scanButton.tap()

        // 3) Capture -> Analysis
        let shutterButton = app.buttons["ShutterButton"]
        XCTAssertTrue(shutterButton.waitForExistence(timeout: 10), "Shutter button should exist")
        shutterButton.tap()

        let analysisView = app.otherElements["AnalysisView"]
        XCTAssertTrue(analysisView.waitForExistence(timeout: 15), "Analysis view should appear after capture")

        // 4) Verify nutrition rings
        XCTAssertTrue(app.otherElements["ProteinRing"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["CarbsRing"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["FatRing"].waitForExistence(timeout: 10))

        // 5) Log meal
        let logMealButton = app.buttons["LogMealButton"]
        XCTAssertTrue(logMealButton.waitForExistence(timeout: 10), "Log meal button should exist")
        logMealButton.tap()

        // 6) Back to Home and carousel visible
        XCTAssertTrue(homeView.waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["FoodMomentCarousel"].waitForExistence(timeout: 10))

        // 7) Diary tab
        let diaryTab = app.buttons["DiaryTabButton"]
        XCTAssertTrue(diaryTab.waitForExistence(timeout: 10))
        diaryTab.tap()
        XCTAssertTrue(app.otherElements["DiaryView"].waitForExistence(timeout: 10))

        // 8) Statistics tab
        let statsTab = app.buttons["StatsTabButton"]
        XCTAssertTrue(statsTab.waitForExistence(timeout: 10))
        statsTab.tap()
        XCTAssertTrue(app.otherElements["StatisticsView"].waitForExistence(timeout: 10))

        // 9) Profile tab
        let profileTab = app.buttons["ProfileTabButton"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 10))
        profileTab.tap()
        XCTAssertTrue(app.otherElements["ProfileView"].waitForExistence(timeout: 10))
    }
}
