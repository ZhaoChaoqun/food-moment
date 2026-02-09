import XCTest

/// UI Tests for capturing screenshots of all app screens
/// Run with: xcodebuild test -scheme FoodMoment -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:FoodMomentUITests/ScreenshotTests
final class ScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    /// Directory to save screenshots
    private var screenshotDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("FoodMomentScreenshots")
    }

    override func setUpWithError() throws {
        continueAfterFailure = true // Continue capturing even if one screen fails
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-data", "--mock-camera"]
        app.launch()

        // Create screenshot directory if needed
        try? FileManager.default.createDirectory(at: screenshotDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Main Screenshot Test

    /// Capture screenshots of all main screens
    func test_captureAllScreenshots() throws {
        // 1. Home Screen
        captureHomeScreen()

        // 2. Statistics Screen
        captureStatisticsScreen()

        // 3. Diary Screen
        captureDiaryScreen()

        // 4. Profile Screen
        captureProfileScreen()

        // 5. Camera Screen
        captureCameraScreen()

        // 6. Settings Screen
        captureSettingsScreen()

        // Print screenshot location
        print("📸 Screenshots saved to: \(screenshotDirectory.path)")
    }

    // MARK: - Individual Screen Captures

    func test_captureHomeScreen() {
        captureHomeScreen()
    }

    func test_captureStatisticsScreen() {
        captureStatisticsScreen()
    }

    func test_captureDiaryScreen() {
        captureDiaryScreen()
    }

    func test_captureProfileScreen() {
        captureProfileScreen()
    }

    func test_captureCameraScreen() {
        captureCameraScreen()
    }

    func test_captureSettingsScreen() {
        captureSettingsScreen()
    }

    // MARK: - Dark Mode Screenshots

    func test_captureAllScreenshots_DarkMode() throws {
        // Relaunch in dark mode
        app.terminate()
        app.launchArguments = ["--uitesting", "--mock-data", "--mock-camera", "-AppleInterfaceStyle", "Dark"]
        app.launch()

        captureHomeScreen(suffix: "_dark")
        captureStatisticsScreen(suffix: "_dark")
        captureDiaryScreen(suffix: "_dark")
        captureProfileScreen(suffix: "_dark")
        captureCameraScreen(suffix: "_dark")
        captureSettingsScreen(suffix: "_dark")
    }

    // MARK: - Helper Methods

    // MARK: - Helper: Find Tab Button

    /// Find tab button by trying multiple element types
    private func findTabButton(identifier: String) -> XCUIElement? {
        // Try as button first
        let button = app.buttons[identifier]
        if button.exists {
            return button
        }
        // Try as other element (VStack with accessibilityIdentifier)
        let other = app.otherElements[identifier]
        if other.exists {
            return other
        }
        // Try finding by label
        let byLabel = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", identifier)).firstMatch
        if byLabel.exists {
            return byLabel
        }
        return nil
    }

    private func captureHomeScreen(suffix: String = "") {
        // Navigate to Home tab if not already there
        if let homeTab = findTabButton(identifier: "HomeTabButton") {
            if homeTab.waitForExistence(timeout: 5) {
                homeTab.tap()
            }
        }

        // Wait for content to load
        let homeView = app.otherElements["HomeView"]
        guard homeView.waitForExistence(timeout: 10) else {
            // Try capturing anyway
            sleep(1)
            takeScreenshot(named: "01_Home\(suffix)")
            return
        }

        sleep(1) // Allow animations to complete
        takeScreenshot(named: "01_Home\(suffix)")

        // Capture scrolled state
        let scrollView = app.scrollViews["HomeScrollView"]
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            takeScreenshot(named: "01_Home_Scrolled\(suffix)")
            scrollView.swipeDown()
        }

        // Capture Water Tracking Sheet if available
        let waterCard = app.otherElements["WaterCard"]
        if waterCard.exists && waterCard.isHittable {
            waterCard.tap()
            sleep(1)
            takeScreenshot(named: "01_Home_WaterSheet\(suffix)")

            // Dismiss sheet
            app.swipeDown()
            sleep(1)
        }
    }

    private func captureStatisticsScreen(suffix: String = "") {
        // Tab ID is "StatsTabButton" based on title "Stats"
        if let statsTab = findTabButton(identifier: "StatsTabButton") {
            if statsTab.waitForExistence(timeout: 5) {
                statsTab.tap()
            }
        }

        sleep(2) // Wait for view to load
        takeScreenshot(named: "02_Statistics\(suffix)")

        // Scroll to see more content
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            takeScreenshot(named: "02_Statistics_Scrolled\(suffix)")
        }
    }

    private func captureDiaryScreen(suffix: String = "") {
        // Tab ID is "LogTabButton" based on title "Log"
        if let diaryTab = findTabButton(identifier: "LogTabButton") {
            if diaryTab.waitForExistence(timeout: 5) {
                diaryTab.tap()
            }
        }

        sleep(2) // Wait for view to load
        takeScreenshot(named: "03_Diary\(suffix)")

        // Scroll diary entries
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            takeScreenshot(named: "03_Diary_Scrolled\(suffix)")
        }
    }

    private func captureProfileScreen(suffix: String = "") {
        if let profileTab = findTabButton(identifier: "ProfileTabButton") {
            if profileTab.waitForExistence(timeout: 5) {
                profileTab.tap()
            }
        }

        sleep(2) // Wait for view to load
        takeScreenshot(named: "04_Profile\(suffix)")

        // Scroll to see more content
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            takeScreenshot(named: "04_Profile_Scrolled\(suffix)")
        }

        // Capture Weight Input Sheet
        let weightCard = app.otherElements["WeightCard"]
        if weightCard.exists && weightCard.isHittable {
            weightCard.tap()
            sleep(1)
            takeScreenshot(named: "04_Profile_WeightSheet\(suffix)")

            // Dismiss
            app.swipeDown()
            sleep(1)
        }
    }

    private func captureCameraScreen(suffix: String = "") {
        // ScanTabButton is on a VStack, not a Button
        if let scanTab = findTabButton(identifier: "ScanTabButton") {
            if scanTab.waitForExistence(timeout: 5) {
                scanTab.tap()
            }
        }

        sleep(2) // Wait for camera view to load
        takeScreenshot(named: "05_Camera\(suffix)")

        // Close camera view if there's a close button
        let closeButton = app.buttons["CameraCloseButton"]
        if closeButton.exists {
            closeButton.tap()
            sleep(1)
        } else {
            // Try swiping down to dismiss
            app.swipeDown()
            sleep(1)
        }
    }

    private func captureSettingsScreen(suffix: String = "") {
        // First navigate to Profile
        if let profileTab = findTabButton(identifier: "ProfileTabButton") {
            if profileTab.waitForExistence(timeout: 5) {
                profileTab.tap()
            }
        }

        sleep(1)

        // Tap settings button
        let settingsButton = app.buttons["SettingsButton"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            sleep(2)
            takeScreenshot(named: "06_Settings\(suffix)")

            // Scroll settings
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                sleep(1)
                takeScreenshot(named: "06_Settings_Scrolled\(suffix)")
            }

            // Go back
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
    }

    // MARK: - Screenshot Utility

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()

        // Save to test attachments (visible in Xcode test results)
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Also save to file system
        let fileURL = screenshotDirectory.appendingPathComponent("\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: fileURL)
            print("✅ Saved: \(name).png")
        } catch {
            print("❌ Failed to save \(name): \(error)")
        }
    }
}
