import SwiftUI

/// Displays three nutrition rings side by side for Protein, Carbs, and Fat.
struct NutritionRingsRow: View {

    let nutrition: NutritionDataDTO

    var body: some View {
        HStack(spacing: 16) {
            // Protein - green color (matching primary brand) with glow
            NutritionRing(
                value: nutrition.proteinG,
                label: "Protein",
                color: AppTheme.Colors.primary,
                maxValue: 80,
                showGlow: true
            )

            // Carbs - blue color (no glow)
            NutritionRing(
                value: nutrition.carbsG,
                label: "Carbs",
                color: Color(hex: "#3B82F6"),
                maxValue: 120,
                showGlow: false
            )

            // Fat - orange color (no glow)
            NutritionRing(
                value: nutrition.fatG,
                label: "Fat",
                color: Color(hex: "#F97316"),
                maxValue: 65,
                showGlow: false
            )
        }
    }
}
