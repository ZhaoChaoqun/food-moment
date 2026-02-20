import SwiftUI
import AVFoundation
import UIKit
import os

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
    var isCapturing = false
    var isCameraAuthorized = false
    var isShowingPermissionAlert = false
    var focusPoint: CGPoint?
    var isShowingFocusReticle = false

    /// Called when a photo is ready for analysis (captured or selected from gallery)
    var onImageReadyForAnalysis: ((UIImage) -> Void)?

    // MARK: - Services

    let cameraService: CameraService
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

        cameraService.stopSession()
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
            Self.logger.error("[Camera] Camera error: \(error.localizedDescription, privacy: .public)")
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
