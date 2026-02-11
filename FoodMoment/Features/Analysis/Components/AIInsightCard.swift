import SwiftUI

/// A card that displays the AI-generated analysis text with a sparkle icon,
/// a green gradient border, and a dark translucent background.
struct AIInsightCard: View {

    let analysisText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.Colors.primary.opacity(0.25),
                                    AppTheme.Colors.primary.opacity(0.08)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 16
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("AI Analysis")
                    .font(.Jakarta.bold(14))
                    .foregroundColor(Color(hex: "#0F172A"))

                Spacer()
            }

            // Content
            Text(analysisText)
                .font(.Jakarta.medium(14))
                .foregroundColor(Color(hex: "#475569"))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.primary.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
        )
    }
}
