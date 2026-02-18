import AVFoundation
import UIKit

// MARK: - CameraFlashMode

/// Flash mode for the camera
enum CameraFlashMode: Sendable {
    case on
    case off
    case auto

    var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .on: return .on
        case .off: return .off
        case .auto: return .auto
        }
    }

    var iconName: String {
        switch self {
        case .on: return "bolt.fill"
        case .off: return "bolt.slash.fill"
        case .auto: return "bolt.badge.automatic.fill"
        }
    }

    var next: CameraFlashMode {
        switch self {
        case .off: return .on
        case .on: return .auto
        case .auto: return .off
        }
    }
}

// MARK: - CameraPosition

/// Camera position (front/back)
enum CameraPosition: Sendable {
    case front
    case back

    var avPosition: AVCaptureDevice.Position {
        switch self {
        case .front: return .front
        case .back: return .back
        }
    }
}

// MARK: - CameraServiceDelegate

/// Protocol for photo capture callbacks
protocol CameraServiceDelegate: AnyObject {
    @MainActor func cameraService(_ service: CameraService, didCapturePhoto image: UIImage)
    @MainActor func cameraService(_ service: CameraService, didFailWithError error: CameraServiceError)
}

// MARK: - CameraServiceError

/// Errors that can occur during camera operations
enum CameraServiceError: Error, LocalizedError {
    case notAuthorized
    case configurationFailed
    case deviceNotAvailable
    case captureFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access is not authorized."
        case .configurationFailed:
            return "Failed to configure camera session."
        case .deviceNotAvailable:
            return "Camera device is not available."
        case .captureFailed(let error):
            return "Photo capture failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - CameraService

/// AVFoundation camera service managing capture session, preview layer, and photo capture.
/// Uses @unchecked Sendable with internal synchronization for thread safety.
final class CameraService: @unchecked Sendable {

    // MARK: - Properties

    let captureSession = AVCaptureSession()
    let previewLayer: AVCaptureVideoPreviewLayer

    weak var delegate: CameraServiceDelegate?

    private(set) var flashMode: CameraFlashMode = .off
    private(set) var cameraPosition: CameraPosition = .back
    private(set) var isSessionRunning = false

    // MARK: - Private Properties

    private let photoOutput = AVCapturePhotoOutput()
    private var currentDeviceInput: AVCaptureDeviceInput?
    private let photoCaptureDelegate: PhotoCaptureDelegate
    private let sessionQueue = DispatchQueue(label: "com.foodmoment.camera.session")

    // MARK: - Initialization

    init() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.photoCaptureDelegate = PhotoCaptureDelegate()
        self.previewLayer.videoGravity = .resizeAspectFill
    }

    // MARK: - Authorization

    /// Check and request camera authorization
    func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Session Configuration

    /// Configure the capture session
    func configureSession() {
        sessionQueue.async { [weak self] in
            self?.configureSessionInternal()
        }
    }

    private func configureSessionInternal() {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .photo

        // Add video input
        guard let videoDevice = bestDevice(for: cameraPosition.avPosition) else {
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                currentDeviceInput = videoInput
            }
        } catch {
            return
        }

        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .balanced
        }
    }

    /// Start the capture session
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            self.isSessionRunning = true
        }
    }

    /// Stop the capture session
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            self.isSessionRunning = false
        }
    }

    // MARK: - Photo Capture

    /// Capture a photo with current settings
    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            let settings = AVCapturePhotoSettings()

            // Configure flash
            if self.photoOutput.supportedFlashModes.contains(self.flashMode.avFlashMode) {
                settings.flashMode = self.flashMode.avFlashMode
            }

            // Set delegate callback
            self.photoCaptureDelegate.onPhotoCapture = { [weak self] result in
                guard let self else { return }
                self.handlePhotoCaptureResult(result)
            }

            self.photoOutput.capturePhoto(with: settings, delegate: self.photoCaptureDelegate)
        }
    }

    private func handlePhotoCaptureResult(_ result: Result<UIImage, Error>) {
        DispatchQueue.main.async { [weak self, weak delegate] in
            guard let self else { return }
            switch result {
            case .success(let image):
                delegate?.cameraService(self, didCapturePhoto: image)
            case .failure(let error):
                delegate?.cameraService(self, didFailWithError: .captureFailed(error))
            }
        }
    }

    // MARK: - Flash

    /// Toggle flash mode (off -> on -> auto -> off)
    func toggleFlash() -> CameraFlashMode {
        flashMode = flashMode.next
        return flashMode
    }

    /// Set a specific flash mode
    func setFlashMode(_ mode: CameraFlashMode) {
        flashMode = mode
    }

    // MARK: - Camera Switch

    /// Switch between front and back camera
    func switchCamera() {
        sessionQueue.async { [weak self] in
            self?.switchCameraInternal()
        }
    }

    private func switchCameraInternal() {
        captureSession.beginConfiguration()

        // Remove current input
        if let currentInput = currentDeviceInput {
            captureSession.removeInput(currentInput)
        }

        // Toggle position
        cameraPosition = (cameraPosition == .back) ? .front : .back

        // Add new input
        guard let newDevice = bestDevice(for: cameraPosition.avPosition) else {
            captureSession.commitConfiguration()
            return
        }

        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                currentDeviceInput = newInput
            }
        } catch {
            // Re-add old input if possible
            if let oldInput = currentDeviceInput,
               captureSession.canAddInput(oldInput) {
                captureSession.addInput(oldInput)
            }
        }

        captureSession.commitConfiguration()
    }

    // MARK: - Focus

    /// Set focus point of interest (normalized coordinates 0...1)
    func focus(at point: CGPoint) {
        guard let device = currentDeviceInput?.device else { return }

        do {
            try device.lockForConfiguration()

            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }

            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }

            device.unlockForConfiguration()
        } catch {
            // Focus configuration failed silently
        }
    }

    // MARK: - Private Methods

    private func bestDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        // Prefer dual/wide camera on back, true depth on front
        if position == .back {
            if let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: position) {
                return device
            }
            if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position) {
                return device
            }
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
                return device
            }
        } else {
            if let device = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: position) {
                return device
            }
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
                return device
            }
        }
        return AVCaptureDevice.default(for: .video)
    }
}

// MARK: - PhotoCaptureDelegate

/// Helper class to handle AVCapturePhotoCaptureDelegate callbacks
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {

    var onPhotoCapture: ((Result<UIImage, Error>) -> Void)?

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            onPhotoCapture?(.failure(error))
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            onPhotoCapture?(.failure(CameraServiceError.captureFailed(
                NSError(domain: "CameraService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from photo data"])
            )))
            return
        }

        onPhotoCapture?(.success(image))
    }
}
