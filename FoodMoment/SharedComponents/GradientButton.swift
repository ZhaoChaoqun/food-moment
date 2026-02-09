import SwiftUI

/// 渐变按钮组件 - 带有按压动画效果
struct GradientButton: View {

    // MARK: - Properties

    let title: String
    let icon: String?
    let action: () -> Void

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Private Properties

    private let buttonHeight: CGFloat = 56

    // MARK: - Initialization

    init(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            buttonContent
        }
        .buttonStyle(.plain)
        .simultaneousGesture(pressGesture)
        .accessibilityIdentifier("GradientButton_\(title)")
    }

    // MARK: - Button Content

    private var buttonContent: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
            }
            Text(title)
        }
        .font(.Jakarta.semiBold(17))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: buttonHeight)
        .background(buttonBackground)
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }

    // MARK: - Button Background

    private var buttonBackground: some View {
        Capsule()
            .fill(AppTheme.Colors.primary)
            .modifier(GlowShadow())
    }

    // MARK: - Gestures

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                withAnimation(.spring(response: 0.2)) {
                    isPressed = true
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.2)) {
                    isPressed = false
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        GradientButton("Get Started", icon: "arrow.right") {
            print("Button tapped")
        }

        GradientButton("Continue") {
            print("Continue tapped")
        }
    }
    .padding()
}
