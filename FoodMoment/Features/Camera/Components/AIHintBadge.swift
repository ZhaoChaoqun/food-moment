import SwiftUI

// MARK: - AIHintBadge

/// AI hint badge with a glassmorphic capsule background and pulsing opacity animation.
/// Displays contextual hints based on the current camera mode.
struct AIHintBadge: View {

    // MARK: - Properties

    var mode: CameraScanMode = .scan

    // MARK: - State

    @State private var isPulsing = false

    // MARK: - Computed Properties

    private var iconName: String {
        switch mode {
        case .scan:
            return "sparkles"
        case .barcode:
            return "barcode.viewfinder"
        case .history:
            return "clock.arrow.circlepath"
        }
    }

    private var hintText: String {
        switch mode {
        case .scan:
            return "Keep steady for better accuracy"
        case .barcode:
            return "Point at barcode to scan"
        case .history:
            return "View your recent scans"
        }
    }

    private var iconColor: Color {
        switch mode {
        case .scan:
            return AppTheme.Colors.primary
        case .barcode:
            return Color.orange
        case .history:
            return Color.blue
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)

            Text(hintText)
                .font(.Jakarta.medium(14))
                .foregroundColor(.white.opacity(0.9))
                .accessibilityIdentifier("AIHintText")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .opacity(isPulsing ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.3), value: mode)
        .onAppear {
            startPulseAnimation()
        }
        .accessibilityIdentifier("AIHintBadge")
    }

    // MARK: - Private Methods

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            isPulsing = true
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        VStack(spacing: 20) {
            AIHintBadge(mode: .scan)
            AIHintBadge(mode: .barcode)
            AIHintBadge(mode: .history)
        }
    }
}
