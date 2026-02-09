import SwiftUI

struct IntakeChartCard: View {

    // MARK: - Properties

    let averageCalories: Int
    let calorieChange: String
    let dailyData: [Int]

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // MARK: - Computed Properties

    private var isNegativeChange: Bool {
        calorieChange.hasPrefix("-")
    }

    private var maxValue: Int {
        max(dailyData.max() ?? 1, 1)
    }

    private var formattedCalories: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: averageCalories)) ?? "\(averageCalories)"
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            barChart
        }
        .padding(24)
        .glassCard(cornerRadius: 32)
        .accessibilityIdentifier("IntakeChartCard")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            calorieInfo
            Spacer()
            changeBadge
        }
    }

    private var calorieInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Average Intake")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formattedCalories)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("kcal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Change Badge

    private var changeBadge: some View {
        HStack(spacing: 2) {
            Text(calorieChange)
                .font(.caption.weight(.semibold))

            Text("vs last week")
                .font(.caption2)
        }
        .foregroundStyle(isNegativeChange ? AppTheme.Colors.primary : Color(hex: "#F87171"))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    isNegativeChange
                        ? AppTheme.Colors.primary.opacity(0.15)
                        : Color(hex: "#F87171").opacity(0.15)
                )
        )
    }

    // MARK: - Bar Chart

    private var barChart: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<min(dailyData.count, 7), id: \.self) { index in
                barColumn(for: index)
            }
        }
        .frame(height: 128)
    }

    private func barColumn(for index: Int) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.primary,
                            AppTheme.Colors.primary.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: barHeight(for: dailyData[index]))

            Text(dayLabels[index])
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Methods

    private func barHeight(for value: Int) -> CGFloat {
        let maxHeight: CGFloat = 108
        let minHeight: CGFloat = 4
        guard maxValue > 0 else { return minHeight }
        return max(CGFloat(value) / CGFloat(maxValue) * maxHeight, minHeight)
    }
}
