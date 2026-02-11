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

    /// 将数值格式化为紧凑字符串：4 位及以上使用 "k" 后缀（如 1100 → "1.1k"）
    private var formattedValue: String {
        let intVal = Int(value)
        if intVal >= 1000 {
            let k = Double(intVal) / 1000.0
            // 整千无小数，否则保留一位
            if intVal % 1000 == 0 {
                return "\(intVal / 1000)k"
            } else {
                return String(format: "%.1fk", k)
            }
        }
        return "\(intVal)"
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Track (background circle)
                Circle()
                    .stroke(Color(hex: "#E2E8F0").opacity(0.6), lineWidth: 6)

                // Progress arc with gradient and shadow
                Circle()
                    .trim(from: 0, to: CGFloat(animatedProgress))
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.3), radius: showGlow ? 6 : 4, y: 0)

                // Center label: value + unit on one line
                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text(formattedValue)
                        .font(.Jakarta.bold(20))
                        .foregroundColor(Color(hex: "#0F172A"))

                    Text(unit)
                        .font(.Jakarta.semiBold(13))
                        .foregroundColor(Color(hex: "#64748B"))
                }
            }
            .frame(width: 90, height: 90)

            // Bottom label
            Text(label)
                .font(.Jakarta.semiBold(14))
                .foregroundColor(Color(hex: "#475569"))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                animatedProgress = targetProgress
            }
        }
    }
}
