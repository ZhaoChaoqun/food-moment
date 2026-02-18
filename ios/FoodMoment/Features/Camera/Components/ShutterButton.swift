import SwiftUI

// MARK: - ShutterButton

/// Shutter button with green ring outline and white inner circle.
/// Animates with a scale effect on press.
struct ShutterButton: View {

    // MARK: - Properties

    let action: () -> Void

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Constants

    private let outerDiameter: CGFloat = 80
    private let innerDiameter: CGFloat = 66
    private let strokeWidth: CGFloat = 4

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            ZStack {
                outerRing
                innerCircle
            }
            .shadow(color: AppTheme.Colors.primary.opacity(0.5), radius: 20)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(pressGesture)
        .accessibilityLabel("拍照")
    }

    // MARK: - Outer Ring

    private var outerRing: some View {
        Circle()
            .stroke(AppTheme.Colors.primary, lineWidth: strokeWidth)
            .frame(width: outerDiameter, height: outerDiameter)
    }

    // MARK: - Inner Circle

    private var innerCircle: some View {
        Circle()
            .fill(.white)
            .frame(width: innerDiameter, height: innerDiameter)
    }

    // MARK: - Press Gesture

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    isPressed = true
                }
            }
            .onEnded { _ in
                isPressed = false
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        ShutterButton(action: {})
    }
}
