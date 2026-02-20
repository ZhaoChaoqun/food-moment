import XCTest

/// UI Tests for the complete capture to log flow
final class CaptureToLogFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-camera", "--mock-data"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Tests

    func test_tapScanButton_opensCameraView() throws {
        // Find and tap the scan button in tab bar
        let scanButton = app.buttons["ScanTabButton"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: 10), "Scan button should exist")
        scanButton.tap()

        // Camera view should appear (check for shutter button)
        let shutterButton = app.buttons["ShutterButton"]
        XCTAssertTrue(shutterButton.waitForExistence(timeout: 10), "Shutter button should appear after tapping scan")
    }

    func test_cameraView_hasRequiredControls() throws {
        // Navigate to camera
        let scanButton = app.buttons["ScanTabButton"]
        guard scanButton.waitForExistence(timeout: 10) else {
            XCTFail("Scan button not found")
            return
        }
        scanButton.tap()

        // Check for essential controls
        let shutterButton = app.buttons["ShutterButton"]
        XCTAssertTrue(shutterButton.waitForExistence(timeout: 10), "Shutter button should exist")

        let flashButton = app.buttons["FlashToggleButton"]
        XCTAssertTrue(flashButton.waitForExistence(timeout: 10), "Flash toggle button should exist")

        let closeButton = app.buttons["CloseButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10), "Close button should exist")
    }

    func test_cameraView_closeButton_dismisses() throws {
        // Navigate to camera
        let scanButton = app.buttons["ScanTabButton"]
        guard scanButton.waitForExistence(timeout: 10) else {
            XCTFail("Scan button not found")
            return
        }
        scanButton.tap()

        // Wait for camera to open
        let closeButton = app.buttons["CloseButton"]
        guard closeButton.waitForExistence(timeout: 10) else {
            XCTFail("Close button not found")
            return
        }

        // Tap close
        closeButton.tap()

        // Should return to home view
        let homeView = app.otherElements["HomeView"]
        XCTAssertTrue(homeView.waitForExistence(timeout: 10), "Should return to home view after closing camera")
    }

    func test_cameraView_flashToggle() throws {
        // Navigate to camera
        let scanButton = app.buttons["ScanTabButton"]
        guard scanButton.waitForExistence(timeout: 10) else {
            XCTFail("Scan button not found")
            return
        }
        scanButton.tap()

        // Find flash button
        let flashButton = app.buttons["FlashToggleButton"]
        guard flashButton.waitForExistence(timeout: 10) else {
            XCTFail("Flash button not found")
            return
        }

        // Tap flash button (should cycle through modes)
        flashButton.tap()

        // Button should still exist after tap
        XCTAssertTrue(flashButton.exists, "Flash button should still exist after tap")
    }
}
