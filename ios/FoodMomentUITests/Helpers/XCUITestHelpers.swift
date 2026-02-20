import XCTest

/// Helper extensions for UI testing
extension XCUIApplication {
    /// Launch with common test arguments
    func launchForTesting(
        mockCamera: Bool = false,
        mockData: Bool = false,
        resetState: Bool = false
    ) {
        launchArguments = ["--uitesting"]

        if mockCamera {
            launchArguments.append("--mock-camera")
        }
        if mockData {
            launchArguments.append("--mock-data")
        }
        if resetState {
            launchArguments.append("--reset-state")
        }

        launch()
    }

    /// Launch with specific accessibility settings
    func launchWithLargeText() {
        launchArguments.append("-UIPreferredContentSizeCategoryName")
        launchArguments.append("UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge")
        launch()
    }

    /// Launch in dark mode
    func launchInDarkMode() {
        launchArguments.append("-AppleInterfaceStyle")
        launchArguments.append("Dark")
        launch()
    }
}

extension XCUIElement {
    /// Clear text field and enter new text
    func clearAndEnterText(_ text: String) {
        guard let currentValue = value as? String else {
            tap()
            typeText(text)
            return
        }

        tap()

        // Select all and delete
        if !currentValue.isEmpty {
            tap()
            let selectAll = XCUIApplication().menuItems["Select All"]
            if selectAll.waitForExistence(timeout: 1) {
                selectAll.tap()
            }
            typeText(XCUIKeyboardKey.delete.rawValue)
        }

        typeText(text)
    }

    /// Check if switch is on
    var isOn: Bool {
        return (value as? String) == "1"
    }

    /// Wait for element to become hittable
    func waitForHittable(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

/// Test data constants
enum TestData {
    static let testEmail = "test@example.com"
    static let testPassword = "TestPassword123"
    static let testFoodName = "测试食物"
    static let testCalories = "500"

    static let mockImageName = "test_food_image"
}

/// Common accessibility identifiers
enum AccessibilityID {
    // Tab Bar
    static let homeTab = "HomeTabButton"
    static let statsTab = "StatsTabButton"
    static let scanTab = "ScanTabButton"
    static let diaryTab = "DiaryTabButton"
    static let profileTab = "ProfileTabButton"

    // Home
    static let calorieRing = "CalorieRingChart"
    static let waterCard = "WaterCard"
    static let stepsCard = "StepsCard"
    static let foodCarousel = "FoodMomentCarousel"

    // Camera
    static let shutterButton = "ShutterButton"
    static let flashButton = "FlashToggleButton"
    static let galleryButton = "GalleryThumbnailButton"
    // Analysis
    static let logMealButton = "LogMealButton"
    static let shareButton = "ShareButton"
    static let closeButton = "CloseButton"

    // Diary
    static let weekDatePicker = "WeekDatePicker"
    static let dailyProgress = "DailyProgressFloat"

    // Profile
    static let settingsButton = "SettingsButton"
    static let signOutButton = "SignOutButton"
}
