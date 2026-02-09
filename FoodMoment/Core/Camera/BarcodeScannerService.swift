import AVFoundation
import Vision
import UIKit

// MARK: - BarcodeResult

/// Barcode scan result containing the detected code and its type
struct BarcodeResult: Sendable, Equatable {
    let payload: String
    let symbology: VNBarcodeSymbology
    let boundingBox: CGRect

    var displayType: String {
        switch symbology {
        case .ean8, .ean13:
            return "EAN"
        case .upce:
            return "UPC-E"
        case .code128:
            return "Code 128"
        case .qr:
            return "QR Code"
        case .dataMatrix:
            return "Data Matrix"
        default:
            return "Barcode"
        }
    }
}

// MARK: - BarcodeScannerError

/// Errors that can occur during barcode scanning
enum BarcodeScannerError: Error, LocalizedError {
    case cameraNotAvailable
    case videoOutputNotAvailable
    case scanningFailed(Error)

    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available for barcode scanning."
        case .videoOutputNotAvailable:
            return "Video output could not be configured."
        case .scanningFailed(let error):
            return "Barcode scanning failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - BarcodeScannerDelegate

/// Protocol for barcode scan callbacks
protocol BarcodeScannerDelegate: AnyObject {
    @MainActor func barcodeScanner(_ scanner: BarcodeScannerService, didDetect result: BarcodeResult)
    @MainActor func barcodeScanner(_ scanner: BarcodeScannerService, didFailWithError error: BarcodeScannerError)
}

// MARK: - BarcodeScannerService

/// Service for real-time barcode scanning using Vision framework.
/// Analyzes video frames from AVCaptureSession to detect barcodes.
/// Uses @unchecked Sendable with internal synchronization for thread safety.
final class BarcodeScannerService: NSObject, @unchecked Sendable {

    // MARK: - Properties

    weak var delegate: BarcodeScannerDelegate?
    private(set) var isScanning = false

    // MARK: - Private Properties

    private let captureSession: AVCaptureSession
    private var videoOutput: AVCaptureVideoDataOutput?
    private let processingQueue = DispatchQueue(label: "com.foodmoment.barcode.processing", qos: .userInitiated)
    private let sampleBufferDelegate: SampleBufferDelegate

    /// Symbologies to scan for (food-related barcodes)
    private let supportedSymbologies: [VNBarcodeSymbology] = [
        .ean8,
        .ean13,
        .upce,
        .code128,
        .code39,
        .itf14,
        .qr,
        .dataMatrix
    ]

    /// Track the last detected barcode to prevent duplicate callbacks
    private var lastDetectedPayload: String?
    private var lastDetectionTime: Date?
    private let debounceInterval: TimeInterval = 2.0

    // MARK: - Initialization

    init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
        self.sampleBufferDelegate = SampleBufferDelegate()
        super.init()

        // Set up sample buffer processing callback
        sampleBufferDelegate.onSampleBuffer = { [weak self] sampleBuffer in
            self?.processFrame(sampleBuffer)
        }
    }

    // MARK: - Public Methods

    /// Start barcode scanning by adding video output to the capture session
    func startScanning() {
        guard !isScanning else { return }

        configureVideoOutput()
        isScanning = true
    }

    /// Stop barcode scanning and remove video output
    func stopScanning() {
        guard isScanning else { return }

        if let output = videoOutput {
            captureSession.beginConfiguration()
            captureSession.removeOutput(output)
            captureSession.commitConfiguration()
            videoOutput = nil
        }

        isScanning = false
        lastDetectedPayload = nil
        lastDetectionTime = nil
    }

    /// Reset the debounce state to allow detecting the same barcode again
    func resetDebounce() {
        lastDetectedPayload = nil
        lastDetectionTime = nil
    }

    /// Set the delegate for barcode detection callbacks
    func setDelegate(_ delegate: BarcodeScannerDelegate?) {
        self.delegate = delegate
    }

    // MARK: - Private Methods

    private func configureVideoOutput() {
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(sampleBufferDelegate, queue: processingQueue)
        output.alwaysDiscardsLateVideoFrames = true

        // Use a format that Vision can process efficiently
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        captureSession.beginConfiguration()

        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            videoOutput = output
        }

        captureSession.commitConfiguration()
    }

    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectBarcodesRequest()
        request.symbologies = supportedSymbologies

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([request])

            guard let results = request.results,
                  let firstResult = results.first,
                  let payload = firstResult.payloadStringValue else {
                return
            }

            // Check if this is a supported symbology
            guard supportedSymbologies.contains(firstResult.symbology) else { return }

            // Debounce duplicate detections
            let now = Date()
            if let lastPayload = lastDetectedPayload,
               let lastTime = lastDetectionTime,
               lastPayload == payload,
               now.timeIntervalSince(lastTime) < debounceInterval {
                return
            }

            lastDetectedPayload = payload
            lastDetectionTime = now

            let result = BarcodeResult(
                payload: payload,
                symbology: firstResult.symbology,
                boundingBox: firstResult.boundingBox
            )

            notifyDelegate(result: result)
        } catch {
            notifyDelegateError(error)
        }
    }

    private func notifyDelegate(result: BarcodeResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.barcodeScanner(self, didDetect: result)
        }
    }

    private func notifyDelegateError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.barcodeScanner(self, didFailWithError: .scanningFailed(error))
        }
    }
}

// MARK: - SampleBufferDelegate

/// Helper class to handle AVCaptureVideoDataOutputSampleBufferDelegate callbacks
private final class SampleBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    var onSampleBuffer: ((CMSampleBuffer) -> Void)?

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onSampleBuffer?(sampleBuffer)
    }
}
