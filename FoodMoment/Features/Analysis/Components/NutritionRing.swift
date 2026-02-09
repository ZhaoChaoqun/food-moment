import SwiftUI

/// A single nutrition ring that displays a nutrient value as an animated arc
/// with a gradient foreground, a gray track, a center value label, and a bottom caption.
struct NutritionRing: View {

    let value: Double
    let unit: String
    let label: String
    let color: Color
    let maxValue: Double
    let showGlow: Bool

    @State private var animatedProgress: Double = 0

    /// Computed progress clamped to [0, 1].
    private var targetProgress: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }

    init(
        value: Double,
        unit: String = "g",
        label: String,
        color: Color,
        maxValue: Double = 100,
        showGlow: Bool = false
    ) {
        self.value = value
        self.unit = unit
        self.label = label
        self.color = color
        self.maxValue = maxValue
        self.showGlow = showGlow
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Track (background circle)
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 3)

                // Progress arc with conditional glow effect
                Circle()
                    .trim(from: 0, to: CGFloat(animatedProgress))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: showGlow ? color.opacity(0.6) : .clear, radius: showGlow ? 6 : 0)

                // Center label
                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(.Jakarta.bold(18))
                        .foregroundColor(.white)

                    Text(unit)
                        .font(.Jakarta.semiBold(14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 80, height: 80)

            // Bottom label
            Text(label)
                .font(.Jakarta.semiBold(14))
                .foregroundColor(.white.opacity(0.7))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                animatedProgress = targetProgress
            }
        }
    }
}
