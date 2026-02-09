import SwiftUI
import PhotosUI
import UIKit

// MARK: - CameraView

/// Full-screen camera view with live preview, controls, and AI-powered food scanning.
struct CameraView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

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
            await viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: galleryImage) { _, newImage in
            viewModel.setSelectedImage(newImage)
        }
        .fullScreenCover(isPresented: $viewModel.isShowingAnalysis) {
            viewModel.dismissAnalysis()
        } content: {
            analysisPlaceholderView
        }
        .alert("Camera Access Required", isPresented: $viewModel.isShowingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("FoodMoment needs camera access to scan and analyze your food. Please enable it in Settings.")
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
                AIHintBadge(mode: viewModel.currentMode)
                    .padding(.bottom, 20)
            }

            ModeSelector(selectedMode: $viewModel.currentMode)
                .padding(.bottom, 24)

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
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Switch Camera")
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
                    print("Looking up barcode: \(barcode.payload)")
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

    // MARK: - Analysis Placeholder View

    /// Placeholder view shown after capturing a photo.
    /// Will be replaced with the full analysis screen in a later sprint.
    private var analysisPlaceholderView: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    if let image = viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(AppTheme.Colors.primary)
                            .scaleEffect(1.2)

                        Text("Analyzing your food...")
                            .font(.Jakarta.semiBold(17))
                            .foregroundColor(.white)

                        Text("AI is identifying ingredients and nutrition")
                            .font(.Jakarta.regular(14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.dismissAnalysis()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func glassCircleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
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
