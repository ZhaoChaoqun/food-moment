import SwiftUI

struct MacroIndicatorRow: View {

    // MARK: - Properties

    let calories: Int
    let proteinGrams: Double
    let carbsGrams: Double

    // MARK: - Design Colors

    private let calorieColor = Color(hex: "#076653")
    private let proteinColor = Color(hex: "#E3EF26")
    private let carbsColor = Color(hex: "#E2FBCE")

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            MacroIndicatorItem(
                color: calorieColor,
                label: "热量",
                value: "\(calories)",
                unit: "kcal"
            )

            MacroIndicatorItem(
                color: proteinColor,
                label: "蛋白质",
                value: String(format: "%.0f", proteinGrams),
                unit: "g"
            )

            MacroIndicatorItem(
                color: carbsColor,
                label: "碳水",
                value: String(format: "%.0f", carbsGrams),
                unit: "g",
                needsBorder: true
            )
        }
    }
}

// MARK: - Macro Indicator Item

private struct MacroIndicatorItem: View {

    // MARK: - Properties

    let color: Color
    let label: String
    let value: String
    let unit: String
    var needsBorder: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 6) {
            colorDot
            labelAndValue
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(itemBackground)
    }

    // MARK: - Subviews

    private var colorDot: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay {
                if needsBorder {
                    Circle()
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                }
            }
    }

    private var labelAndValue: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.Jakarta.semiBold(10))
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.Jakarta.bold(16))
                    .foregroundStyle(.primary)

                Text(unit)
                    .font(.Jakarta.regular(10))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var itemBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.white.opacity(0.5))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MacroIndicatorRow(
            calories: 850,
            proteinGrams: 45,
            carbsGrams: 120
        )
        .padding(.horizontal)

        MacroIndicatorRow(
            calories: 1260,
            proteinGrams: 62,
            carbsGrams: 180
        )
        .padding(.horizontal)
        .background(Color.gray.opacity(0.1))
    }
}
