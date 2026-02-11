import SwiftUI

struct StepsCard: View {

    // MARK: - Properties

    let stepCount: Int
    let dailyGoal: Int
    let progress: Double
    let caloriesBurned: Int

    // MARK: - Design Constants

    private let cardCornerRadius: CGFloat = 32
    private let iconSize: CGFloat = 40
    private let iconFontSize: CGFloat = 20
    private let progressHeight: CGFloat = 6

    private let stepsGradient = LinearGradient(
        colors: [Color(hex: "#E3EF26"), Color(hex: "#076653")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            contentSection
            progressBar
        }
        .padding(20)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .top) {
            stepsIcon
            Spacer()
            caloriesBadge
        }
    }

    private var stepsIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#E3EF26").opacity(0.2))
                .frame(width: iconSize, height: iconSize)

            Image(systemName: "shoeprints.fill")
                .font(.system(size: iconFontSize))
                .foregroundStyle(Color(hex: "#076653"))
        }
    }

    private var caloriesBadge: some View {
        Text("+\(formattedCalories)")
            .font(.Jakarta.bold(10))
            .foregroundStyle(Color(hex: "#076653"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(hex: "#E3EF26").opacity(0.3))
            )
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("今日步数")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(formattedSteps)
                    .font(.Jakarta.bold(24))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text("步")
                    .font(.Jakarta.medium(12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: progressHeight)

                Capsule()
                    .fill(stepsGradient)
                    .frame(
                        width: max(geometry.size.width * CGFloat(min(progress, 1.0)), progressHeight),
                        height: progressHeight
                    )
                    .shadow(color: Color(hex: "#076653").opacity(0.2), radius: 5, y: 0)
                    .animation(.easeOut(duration: 0.6), value: progress)
            }
        }
        .frame(height: progressHeight)
        .padding(.top, 4)
    }

    // MARK: - Card Styling

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius)
            .fill(.white.opacity(0.75))
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(.ultraThinMaterial)
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius)
            .stroke(Color.white.opacity(0.5), lineWidth: 1)
    }

    // MARK: - Computed Properties

    private var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: stepCount)) ?? "\(stepCount)"
    }

    private var formattedCalories: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: caloriesBurned)) ?? "\(caloriesBurned)"
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        StepsCard(
            stepCount: 5432,
            dailyGoal: 10000,
            progress: 0.54,
            caloriesBurned: 1200
        )
    }
    .padding()
    .background(Color(hex: "#FBFBFB"))
}
