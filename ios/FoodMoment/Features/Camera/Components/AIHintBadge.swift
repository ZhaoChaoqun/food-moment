import SwiftUI

// MARK: - AIHintBadge

/// AI hint badge with a glassmorphic capsule background and pulsing opacity animation.
struct AIHintBadge: View {

    // MARK: - State

    @State private var isPulsing = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.Jakarta.medium(18))
                .foregroundColor(AppTheme.Colors.primary)

            Text("保持稳定以获得更准确的识别")
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

        AIHintBadge()
    }
}
