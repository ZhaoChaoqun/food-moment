import SwiftUI

// MARK: - ModeSelector

/// Horizontal mode selector with Scan / Barcode / History options.
/// The selected mode is highlighted in green with bold text.
struct ModeSelector: View {

    // MARK: - Properties

    @Binding var selectedMode: CameraScanMode

    // MARK: - Body

    var body: some View {
        HStack(spacing: 24) {
            ForEach(CameraScanMode.allCases, id: \.self) { mode in
                modeButton(for: mode)
            }
        }
        .accessibilityIdentifier("ModeSelector")
    }

    // MARK: - Mode Button

    private func modeButton(for mode: CameraScanMode) -> some View {
        Button {
            withAnimation(AppTheme.Animation.defaultSpring) {
                selectedMode = mode
            }
        } label: {
            Text(mode.rawValue)
                .font(selectedMode == mode ? .Jakarta.semiBold(14) : .Jakarta.regular(14))
                .foregroundColor(selectedMode == mode ? AppTheme.Colors.primary : Color.white.opacity(0.5))
                .shadow(
                    color: selectedMode == mode ? AppTheme.Colors.primary.opacity(0.5) : .clear,
                    radius: 8
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ModeButton_\(mode.rawValue.lowercased())")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        ModeSelector(selectedMode: .constant(.scan))
    }
}
