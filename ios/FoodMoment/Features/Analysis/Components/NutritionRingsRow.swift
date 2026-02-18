import SwiftUI

/// Displays three nutrition rings side by side for Protein, Carbs, and Fat.
struct NutritionRingsRow: View {

    let nutrition: NutritionDataDTO

    var body: some View {
        HStack(spacing: 24) {
            // Protein - green color (matching protein token) with glow
            NutritionRing(
                value: nutrition.proteinG,
                label: "蛋白质",
                color: AppTheme.Colors.protein,
                maxValue: 80,
                showGlow: true
            )
            .accessibilityIdentifier("ProteinRing")

            // Carbs - yellow color (no glow)
            NutritionRing(
                value: nutrition.carbsG,
                label: "碳水",
                color: AppTheme.Colors.carbs,
                maxValue: 120,
                showGlow: false
            )
            .accessibilityIdentifier("CarbsRing")

            // Fat - orange color (no glow)
            NutritionRing(
                value: nutrition.fatG,
                label: "脂肪",
                color: AppTheme.Colors.fat,
                maxValue: 65,
                showGlow: false
            )
            .accessibilityIdentifier("FatRing")
        }
    }
}

#Preview {
    NutritionRingsRow(
        nutrition: NutritionDataDTO(
            proteinG: 35.0,
            carbsG: 60.0,
            fatG: 20.0,
            fiberG: 8.0
        )
    )
    .padding()
}
