import SwiftUI

/// Displays three nutrition rings side by side for Protein, Carbs, and Fat.
struct NutritionRingsRow: View {

    let nutrition: NutritionDataDTO

    var body: some View {
        HStack(spacing: 24) {
            // Protein - green color (matching primary brand) with glow
            NutritionRing(
                value: nutrition.proteinG,
                label: "蛋白质",
                color: AppTheme.Colors.primary,
                maxValue: 80,
                showGlow: true
            )

            // Carbs - blue color (no glow)
            NutritionRing(
                value: nutrition.carbsG,
                label: "碳水",
                color: Color(hex: "#3B82F6"),
                maxValue: 120,
                showGlow: false
            )

            // Fat - orange color (no glow)
            NutritionRing(
                value: nutrition.fatG,
                label: "脂肪",
                color: Color(hex: "#F97316"),
                maxValue: 65,
                showGlow: false
            )
        }
    }
}
