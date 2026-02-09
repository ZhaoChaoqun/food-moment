import SwiftUI

struct AIInsightDarkCard: View {

    // MARK: - Properties

    let insight: String

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            contentSection
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .modifier(CardShadow())
        .padding(.horizontal, 20)
        .accessibilityIdentifier("AIInsightDarkCard")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18))
                .foregroundStyle(.yellow)

            Text("AI Insight")
                .font(.Jakarta.semiBold(16))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        Text(insight)
            .font(.Jakarta.regular(14))
            .foregroundStyle(.white.opacity(0.8))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "#1E293B"),
                    Color(hex: "#0F172A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Green glow effect in top-right corner
            glowEffect
        }
    }

    // MARK: - Glow Effect

    private var glowEffect: some View {
        GeometryReader { geometry in
            Circle()
                .fill(AppTheme.Colors.primary.opacity(0.3))
                .frame(width: 128, height: 128)
                .blur(radius: 40)
                .offset(
                    x: geometry.size.width - 54,
                    y: -54
                )
        }
        .clipped()
    }
}
