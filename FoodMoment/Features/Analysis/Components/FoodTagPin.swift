import SwiftUI

/// A single food label pin displayed over the analyzed food photo.
/// Shows a glass-morphism capsule with a colored dot, emoji, and food name,
/// connected to a glowing anchor point below via a thin white line.
struct FoodTagPin: View {

    let food: DetectedFoodDTO
    var onTap: (() -> Void)?

    @State private var isPressed: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Tag capsule
            tagCapsule
                .scaleEffect(isPressed ? 0.95 : 1.0)

            // Connector line
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 1, height: 24)

            // Anchor dot with glow
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .shadow(color: .white.opacity(0.8), radius: 6)
                .shadow(color: .white.opacity(0.5), radius: 10)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2)) {
                    isPressed = false
                }
                onTap?()
            }
        }
    }

    // MARK: - Subviews

    private var tagCapsule: some View {
        HStack(spacing: 8) {
            // Colored indicator dot
            Circle()
                .fill(Color(hex: food.color))
                .frame(width: 8, height: 8)

            // Food name with emoji
            Text("\(food.name) \(food.emoji)")
                .font(.Jakarta.semiBold(14))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
        )
    }
}
