import SwiftUI
import AVFoundation

// MARK: - CameraPreviewView

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer.
/// Displays the live camera feed from CameraService.
struct CameraPreviewView: UIViewRepresentable {

    // MARK: - Properties

    let cameraService: CameraService

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black

        // Add preview layer directly (CameraService is not an actor anymore)
        let previewLayer = cameraService.previewLayer
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        view.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer?.frame = uiView.bounds
    }
}

// MARK: - CameraPreviewUIView

/// Custom UIView that automatically updates the preview layer frame on layout changes.
final class CameraPreviewUIView: UIView {

    // MARK: - Properties

    var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update preview layer to match the current bounds
        previewLayer?.frame = bounds
    }
}
