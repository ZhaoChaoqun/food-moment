import SwiftUI
import PhotosUI
import UIKit
import os

// MARK: - CameraView

/// Full-screen camera view with live preview, controls, and AI-powered food scanning.
struct CameraView: View {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "CameraView")

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var viewModel = CameraViewModel()
    @State private var galleryImage: UIImage?

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundLayer

                cameraPreviewLayer(geometry: geometry)

                gradientOverlays

                focusReticleLayer

                controlsLayout(geometry: geometry)

                captureFlashOverlay

                barcodeResultOverlay
            }
        }
        .statusBarHidden()
        .task {
            viewModel.onImageReadyForAnalysis = { image in
                dismiss()
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    appState.showAnalysis(image: image)
                }
            }
            await viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: galleryImage) { _, newImage in
            guard let newImage else { return }
            viewModel.onImageReadyForAnalysis?(newImage)
        }
        .alert("需要相机权限", isPresented: $viewModel.isShowingPermissionAlert) {
            Button("打开设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("食刻需要访问相机来扫描和分析食物。请在设置中启用相机权限。")
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        Color.black
            .ignoresSafeArea()
    }

    // MARK: - Camera Preview Layer

    private func cameraPreviewLayer(geometry: GeometryProxy) -> some View {
        CameraPreviewView(cameraService: viewModel.cameraService)
            .ignoresSafeArea()
            .onTapGesture { location in
                viewModel.focus(at: location, in: geometry.size)
            }
    }

    // MARK: - Gradient Overlays

    private var gradientOverlays: some View {
        ZStack {
            // Top gradient (black -> transparent)
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.4), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)

                Spacer()
            }
            .ignoresSafeArea()

            // Bottom gradient (transparent -> black)
            VStack {
                Spacer()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 260)
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Focus Reticle Layer

    @ViewBuilder
    private var focusReticleLayer: some View {
        if viewModel.isShowingFocusReticle, let point = viewModel.focusPoint {
            FocusReticle(position: point)
                .ignoresSafeArea()
        }
    }

    // MARK: - Controls Layout

    private func controlsLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            topControlBar
                .padding(.top, geometry.safeAreaInsets.top + 8)

            Spacer()

            // AI hint badge (hide when showing barcode result)
            if !viewModel.isShowingBarcodeResult {
                AIHintBadge()
                    .padding(.bottom, 20)
            }

            bottomControlBar
                .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
        }
        .ignoresSafeArea()
    }

    // MARK: - Top Control Bar

    private var topControlBar: some View {
        HStack {
            glassCircleButton(icon: "xmark") {
                dismiss()
            }
            .accessibilityIdentifier("CloseButton")

            Spacer()

            glassCircleButton(icon: viewModel.flashMode.iconName) {
                viewModel.toggleFlash()
            }
            .accessibilityIdentifier("FlashToggleButton")
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Bottom Control Bar

    private var bottomControlBar: some View {
        HStack(alignment: .center) {
            GalleryThumbnail(selectedImage: $galleryImage)
                .frame(width: 60, alignment: .center)
                .accessibilityIdentifier("GalleryThumbnailButton")

            Spacer()

            ShutterButton {
                viewModel.capturePhoto()
            }
            .accessibilityIdentifier("ShutterButton")

            Spacer()

            flipCameraButton
                .frame(width: 60, alignment: .center)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Flip Camera Button

    private var flipCameraButton: some View {
        Button {
            withAnimation(AppTheme.Animation.defaultSpring) {
                viewModel.switchCamera()
            }
        } label: {
            Image(systemName: "camera.rotate.fill")
                .font(.Jakarta.regular(20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("切换摄像头")
    }

    // MARK: - Capture Flash Overlay

    @ViewBuilder
    private var captureFlashOverlay: some View {
        if viewModel.isCapturing {
            Color.white
                .ignoresSafeArea()
                .opacity(0.3)
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }

    // MARK: - Barcode Result Overlay

    @ViewBuilder
    private var barcodeResultOverlay: some View {
        if viewModel.isShowingBarcodeResult, let barcode = viewModel.detectedBarcode {
            BarcodeResultOverlay(
                result: barcode,
                onLookup: {
                    // TODO: Navigate to food lookup with barcode
                    // For now, just dismiss and print the barcode
                    Self.logger.debug("[Camera] Looking up barcode: \(barcode.payload, privacy: .public)")
                    viewModel.dismissBarcodeResult()
                },
                onDismiss: {
                    viewModel.dismissBarcodeResult()
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(AppTheme.Animation.defaultSpring, value: viewModel.isShowingBarcodeResult)
        }
    }

    // MARK: - Helper Methods

    private func glassCircleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.Jakarta.medium(18))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    CameraView()
}
