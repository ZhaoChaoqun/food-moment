import SwiftUI

/// 底部浮动进度条，显示每日卡路里进度
struct DailyProgressFloat: View {

    // MARK: - Properties

    let consumed: Int
    let goal: Int

    // MARK: - Computed Properties

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(consumed) / Double(goal), 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return AppTheme.Colors.calorieWarning // 超过目标 - 红色
        } else if progress >= 0.8 {
            return AppTheme.Colors.primary
        } else {
            return .secondary
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 10) {
            calorieInfoRow
            progressBar
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .regularGlassCard(cornerRadius: AppTheme.CornerRadius.medium)
        .padding(.horizontal, 16)
        .accessibilityIdentifier("DailyProgressFloat")
        .accessibilityLabel(accessibilityProgressLabel)
    }

    // MARK: - Calorie Info Row

    private var calorieInfoRow: some View {
        HStack {
            calorieTextStack

            Spacer()

            percentageText
        }
    }

    private var calorieTextStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("今日已摄入")
                .font(.Jakarta.regular(12))
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formattedCalories(consumed))
                    .font(.Jakarta.bold(20))
                    .foregroundColor(.primary)

                Text("/ \(formattedCalories(goal)) kcal")
                    .font(.Jakarta.medium(13))
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityIdentifier("DailyProgressFloat.CalorieText")
    }

    private var percentageText: some View {
        Text("\(percentage)%")
            .font(.Jakarta.bold(16))
            .foregroundColor(progressColor)
            .accessibilityIdentifier("DailyProgressFloat.Percentage")
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                progressTrack
                progressFill(width: geometry.size.width * progress)
            }
        }
        .frame(height: 6)
        .accessibilityIdentifier("DailyProgressFloat.ProgressBar")
    }

    private var progressTrack: some View {
        Capsule()
            .fill(Color.gray.opacity(0.12))
            .frame(height: 6)
    }

    private func progressFill(width: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: 6)
            .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 6, y: 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
    }

    // MARK: - Helper Methods

    private static let calorieFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()

    private func formattedCalories(_ value: Int) -> String {
        Self.calorieFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var accessibilityProgressLabel: String {
        "今日已摄入 \(consumed) 千卡，目标 \(goal) 千卡，完成 \(percentage)%"
    }
}
