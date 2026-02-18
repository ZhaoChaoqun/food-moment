import SwiftUI
import AVFoundation
import UIKit
import os

// MARK: - CameraScanMode

/// Camera scan mode
enum CameraScanMode: String, CaseIterable, Sendable {
    case scan = "Scan"
    case barcode = "Barcode"
    case history = "History"
}

// MARK: - CameraViewModel

/// ViewModel managing camera state and user interactions.
@MainActor
@Observable
final class CameraViewModel {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "CameraViewModel")

    private static var isMockCameraEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-camera")
    }

    // MARK: - Published Properties

    var flashMode: CameraFlashMode = .off
    var capturedImage: UIImage?
    var isShowingAnalysis = false
    var currentMode: CameraScanMode = .scan {
        didSet {
            handleModeChange(from: oldValue, to: currentMode)
        }
    }
    var isCapturing = false
    var isCameraAuthorized = false
    var isShowingPermissionAlert = false
    var focusPoint: CGPoint?
    var isShowingFocusReticle = false

    /// Barcode scanning state
    var detectedBarcode: BarcodeResult?
    var isShowingBarcodeResult = false
    var isBarcodeScanning = false

    /// Called when a photo is ready for analysis (captured or selected from gallery)
    var onImageReadyForAnalysis: ((UIImage) -> Void)?

    // MARK: - Services

    let cameraService: CameraService
    private var barcodeScanner: BarcodeScannerService?
    private var pendingTasks: [Task<Void, Never>] = []
    private var focusHideTask: Task<Void, Never>?

    // MARK: - Initialization

    init(cameraService: CameraService = CameraService()) {
        self.cameraService = cameraService
    }

    // MARK: - Session Lifecycle

    /// Check authorization and start the camera session
    func startSession() async {
        let authorized = await cameraService.checkAuthorization()
        isCameraAuthorized = authorized

        if authorized {
            cameraService.configureSession()
            cameraService.startSession()
            cameraService.delegate = self

            // Initialize barcode scanner with the camera's capture session
            barcodeScanner = BarcodeScannerService(captureSession: cameraService.captureSession)
            barcodeScanner?.setDelegate(self)

            // Start barcode scanning if in barcode mode
            if currentMode == .barcode {
                startBarcodeScanning()
            }
        } else {
            isShowingPermissionAlert = true
        }
    }

    /// Stop the camera session
    func stopSession() {
        pendingTasks.forEach { $0.cancel() }
        pendingTasks.removeAll()
        focusHideTask?.cancel()
        focusHideTask = nil

        stopBarcodeScanning()
        cameraService.stopSession()
    }

    // MARK: - Mode Change Handling

    private func handleModeChange(from oldMode: CameraScanMode, to newMode: CameraScanMode) {
        // Stop barcode scanning when leaving barcode mode
        if oldMode == .barcode && newMode != .barcode {
            stopBarcodeScanning()
        }

        // Start barcode scanning when entering barcode mode
        if newMode == .barcode && oldMode != .barcode {
            startBarcodeScanning()
        }

        // Clear any previous barcode results when switching modes
        if oldMode == .barcode {
            detectedBarcode = nil
            isShowingBarcodeResult = false
        }
    }

    // MARK: - Barcode Scanning

    /// Start the barcode scanner
    private func startBarcodeScanning() {
        guard !isBarcodeScanning else { return }
        barcodeScanner?.startScanning()
        isBarcodeScanning = true
    }

    /// Stop the barcode scanner
    private func stopBarcodeScanning() {
        guard isBarcodeScanning else { return }
        barcodeScanner?.stopScanning()
        isBarcodeScanning = false
    }

    /// Reset barcode detection to scan for a new barcode
    func resetBarcodeScanning() {
        detectedBarcode = nil
        isShowingBarcodeResult = false
        barcodeScanner?.resetDebounce()
    }

    // MARK: - Actions

    /// Capture a photo
    func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true

        if Self.isMockCameraEnabled {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                let placeholder = UIImage(systemName: "photo") ?? UIImage()
                self.capturedImage = placeholder
                self.isCapturing = false
                self.onImageReadyForAnalysis?(placeholder)
            }
            return
        }

        cameraService.capturePhoto()
    }

    /// Toggle flash mode (off -> on -> auto -> off)
    func toggleFlash() {
        flashMode = cameraService.toggleFlash()
    }

    /// Switch between front and back camera
    func switchCamera() {
        cameraService.switchCamera()
    }

    /// Handle tap-to-focus at a given point in the preview
    func focus(at point: CGPoint, in viewSize: CGSize) {
        // Convert view coordinates to camera coordinates (0...1)
        let normalizedPoint = CGPoint(
            x: point.y / viewSize.height,
            y: 1.0 - (point.x / viewSize.width)
        )

        cameraService.focus(at: normalizedPoint)

        // Show focus reticle at tap location
        focusPoint = point
        isShowingFocusReticle = true

        // Hide reticle after a delay
        focusHideTask?.cancel()
        focusHideTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                isShowingFocusReticle = false
            }
        }
    }

    /// Set captured image from photo library
    func setSelectedImage(_ image: UIImage?) {
        guard let image else { return }
        capturedImage = image
        onImageReadyForAnalysis?(image)
    }

    /// Reset state after analysis is dismissed
    func dismissAnalysis() {
        capturedImage = nil
        isShowingAnalysis = false
        isCapturing = false
    }

    /// Dismiss barcode result and continue scanning
    func dismissBarcodeResult() {
        isShowingBarcodeResult = false
        detectedBarcode = nil
        barcodeScanner?.resetDebounce()
    }
}

// MARK: - CameraServiceDelegate

extension CameraViewModel: CameraServiceDelegate {

    nonisolated func cameraService(_ service: CameraService, didCapturePhoto image: UIImage) {
        Task { @MainActor in
            self.capturedImage = image
            self.isCapturing = false
            self.onImageReadyForAnalysis?(image)
        }
    }

    nonisolated func cameraService(_ service: CameraService, didFailWithError error: CameraServiceError) {
        Task { @MainActor in
            self.isCapturing = false
            // TODO: Show error alert to user
            Self.logger.error("[Camera] Camera error: \(error.localizedDescription, privacy: .public)")
        }
    }
}

// MARK: - BarcodeScannerDelegate

extension CameraViewModel: BarcodeScannerDelegate {

    nonisolated func barcodeScanner(_ scanner: BarcodeScannerService, didDetect result: BarcodeResult) {
        Task { @MainActor in
            // Only process if we're in barcode mode and not already showing a result
            guard currentMode == .barcode, !isShowingBarcodeResult else { return }

            detectedBarcode = result
            isShowingBarcodeResult = true

            // Haptic feedback on successful scan
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }

    nonisolated func barcodeScanner(_ scanner: BarcodeScannerService, didFailWithError error: BarcodeScannerError) {
        Task { @MainActor in
            // Handle barcode scanning errors silently for now
            // Could show an alert for persistent errors
            Self.logger.error("[Camera] Barcode scanning error: \(error.localizedDescription, privacy: .public)")
        }
    }
}

// MARK: - CameraService Extension

extension CameraService {

    /// Set the delegate for photo capture callbacks
    func setDelegate(_ delegate: CameraServiceDelegate?) {
        self.delegate = delegate
    }
}
