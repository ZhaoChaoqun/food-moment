import SwiftUI

struct MacroDonutChart: View {

    // MARK: - Properties

    let proteinTotal: Double
    let carbsTotal: Double
    let fatTotal: Double

    private let proteinColor = Color(hex: "#60A5FA")
    private let carbsColor = Color(hex: "#FACC15")
    private let fatColor = Color(hex: "#F87171")

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            titleSection
            contentSection
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, 20)
        .accessibilityIdentifier("MacroDonutChart")
    }

    // MARK: - Title Section

    private var titleSection: some View {
        Text("Macronutrients")
            .font(.Jakarta.semiBold(18))
            .foregroundStyle(.primary)
    }

    // MARK: - Content Section

    private var contentSection: some View {
        HStack(spacing: 24) {
            concentricRingsView
            legendView
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Concentric Rings View

    private var concentricRingsView: some View {
        ZStack {
            // 背景轨道
            Circle()
                .stroke(proteinColor.opacity(0.15), lineWidth: 14)
                .frame(width: 130, height: 130)

            Circle()
                .stroke(carbsColor.opacity(0.15), lineWidth: 14)
                .frame(width: 98, height: 98)

            Circle()
                .stroke(fatColor.opacity(0.15), lineWidth: 14)
                .frame(width: 66, height: 66)

            // 蛋白质环（最外层）
            Circle()
                .trim(from: 0, to: proteinProgress)
                .stroke(
                    proteinColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))

            // 碳水环（中层）
            Circle()
                .trim(from: 0, to: carbsProgress)
                .stroke(
                    carbsColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 98, height: 98)
                .rotationEffect(.degrees(-90))

            // 脂肪环（最内层）
            Circle()
                .trim(from: 0, to: fatProgress)
                .stroke(
                    fatColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 66, height: 66)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 150, height: 150)
    }

    // MARK: - Legend View

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 16) {
            MacroLegendRow(
                color: proteinColor,
                name: "Protein",
                grams: proteinTotal
            )

            MacroLegendRow(
                color: carbsColor,
                name: "Carbs",
                grams: carbsTotal
            )

            MacroLegendRow(
                color: fatColor,
                name: "Fat",
                grams: fatTotal
            )
        }
    }

    // MARK: - Computed Properties

    private var totalMacros: Double {
        proteinTotal + carbsTotal + fatTotal
    }

    private var proteinProgress: CGFloat {
        guard totalMacros > 0 else { return 0 }
        return CGFloat(proteinTotal / totalMacros)
    }

    private var carbsProgress: CGFloat {
        guard totalMacros > 0 else { return 0 }
        return CGFloat(carbsTotal / totalMacros)
    }

    private var fatProgress: CGFloat {
        guard totalMacros > 0 else { return 0 }
        return CGFloat(fatTotal / totalMacros)
    }
}

// MARK: - Macro Legend Row

private struct MacroLegendRow: View {

    // MARK: - Properties

    let color: Color
    let name: String
    let grams: Double

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.Jakarta.medium(13))
                    .foregroundStyle(.secondary)

                Text("\(Int(grams))g")
                    .font(.Jakarta.bold(16))
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityIdentifier("MacroLegendRow.\(name)")
    }
}
