import SwiftUI

// MARK: - FocusReticle

/// Focus reticle component with four corner L-shaped brackets and a center crosshair.
/// Appears with a spring scale animation at the given position.
struct FocusReticle: View {

    // MARK: - Properties

    let position: CGPoint

    // MARK: - State

    @State private var scale: CGFloat = 1.5
    @State private var opacity: Double = 1.0

    // MARK: - Constants

    private let reticleSize: CGFloat = 256
    private let cornerLength: CGFloat = 32
    private let cornerThickness: CGFloat = 2
    private let crosshairSize: CGFloat = 12

    // MARK: - Body

    var body: some View {
        ZStack {
            cornersView
            crosshairView
        }
        .frame(width: reticleSize, height: reticleSize)
        .scaleEffect(scale)
        .opacity(opacity)
        .position(position)
        .onAppear {
            animateAppearance()
        }
    }

    // MARK: - Corners View

    private var cornersView: some View {
        ZStack {
            // Top-left
            cornerBracket(rotation: 0)
                .position(x: cornerLength / 2, y: cornerLength / 2)

            // Top-right
            cornerBracket(rotation: 90)
                .position(x: reticleSize - cornerLength / 2, y: cornerLength / 2)

            // Bottom-right
            cornerBracket(rotation: 180)
                .position(x: reticleSize - cornerLength / 2, y: reticleSize - cornerLength / 2)

            // Bottom-left
            cornerBracket(rotation: 270)
                .position(x: cornerLength / 2, y: reticleSize - cornerLength / 2)
        }
        .frame(width: reticleSize, height: reticleSize)
    }

    // MARK: - Corner Bracket

    private func cornerBracket(rotation: Double) -> some View {
        Path { path in
            // Horizontal line
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: cornerLength, y: 0))
            // Vertical line
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: cornerLength))
        }
        .stroke(Color.white.opacity(0.5), lineWidth: cornerThickness)
        .frame(width: cornerLength, height: cornerLength)
        .rotationEffect(.degrees(rotation))
    }

    // MARK: - Crosshair View

    private var crosshairView: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(AppTheme.Colors.primary)
                .frame(width: crosshairSize, height: 1)

            // Vertical line
            Rectangle()
                .fill(AppTheme.Colors.primary)
                .frame(width: 1, height: crosshairSize)
        }
    }

    // MARK: - Private Methods

    private func animateAppearance() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.0
        }
        // Fade out after a delay
        withAnimation(.easeOut(duration: 0.3).delay(1.2)) {
            opacity = 0.0
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        FocusReticle(position: CGPoint(x: 200, y: 400))
    }
}
