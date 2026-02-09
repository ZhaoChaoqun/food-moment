import SwiftUI

/// A full-width green capsule button for logging a meal.
/// Features a glow shadow and a press-down scale animation.
struct LogMealButton: View {

    let action: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .rotationEffect(.degrees(isPressed ? 12 : 0))

                Text("Log Meal")
                    .font(.Jakarta.bold(17))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.primary)
            )
            .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 10, y: 10)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
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
        )
    }
}
