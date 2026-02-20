import SwiftUI
import UIKit

struct MealDetailView: View {

    // MARK: - Properties

    let meal: MealRecord

    @State private var decodedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    private var nutrition: NutritionDataDTO {
        NutritionDataDTO(
            proteinG: meal.proteinGrams,
            carbsG: meal.carbsGrams,
            fatG: meal.fatGrams,
            fiberG: meal.fiberGrams
        )
    }

    private var mealType: MealRecord.MealType {
        DiaryViewModel.mealType(for: meal)
    }

    private var mealColor: Color {
        DiaryViewModel.mealColor(for: meal)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                photoSection
                totalEnergySection
                NutritionRingsRow(nutrition: nutrition)
                    .padding(.horizontal, 20)
                detectedFoodsList
                tagsSection
                aiAnalysisSection
            }
            .padding(.bottom, 16)
        }
        .premiumBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(meal.title)
                        .font(.Jakarta.semiBold(16))
                    Text(meal.mealTime.formatted(as: "M月d日 HH:mm"))
                        .font(.Jakarta.regular(12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        ZStack(alignment: .topLeading) {
            photoView
                .frame(height: 280)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            mealTypeBadge
                .padding(16)
        }
    }

    @ViewBuilder
    private var photoView: some View {
        if let imageData = meal.localImageData {
            if let uiImage = decodedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholderView
                    .task(id: meal.id) {
                        decodedImage = await Self.decodeImage(from: imageData)
                    }
            }
        } else if let assetName = meal.localAssetName, !assetName.isEmpty {
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let urlString = meal.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderView.overlay(ProgressView())
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [mealColor.opacity(0.15), mealColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Text(mealType.emoji)
                    .font(.Jakarta.regular(48))
                Text(mealType.displayName)
                    .font(.Jakarta.medium(14))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var mealTypeBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(mealColor)
                .frame(width: 8, height: 8)
            Text(mealType.displayName)
                .font(.Jakarta.medium(12))
                .foregroundColor(.white)
            Text(meal.mealTime.mealTimeString)
                .font(.Jakarta.regular(11))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Total Energy

    private var totalEnergySection: some View {
        VStack(spacing: 4) {
            Text("总热量")
                .font(.Jakarta.semiBold(14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .tracking(2)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(meal.totalCalories)")
                    .font(.Jakarta.extraBold(48))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("kcal")
                    .font(.Jakarta.bold(20))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Detected Foods List

    @ViewBuilder
    private var detectedFoodsList: some View {
        let foods = meal.detectedFoods ?? []
        if !foods.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("识别食物")
                    .font(.Jakarta.bold(16))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)

                VStack(spacing: 8) {
                    ForEach(foods, id: \.id) { food in
                        foodRow(food)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func foodRow(_ food: DetectedFood) -> some View {
        HStack(spacing: 12) {
            Text(food.emoji)
                .font(.system(size: 28))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(food.displayName)
                        .font(.Jakarta.semiBold(14))
                        .foregroundColor(.primary)

                    Text(food.confidencePercentage)
                        .font(.Jakarta.regular(11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.gray.opacity(0.1))
                        )
                }

                HStack(spacing: 12) {
                    nutritionLabel("\(food.calories)", unit: "kcal", color: .orange)
                    nutritionLabel(String(format: "%.1f", food.proteinGrams), unit: "g P", color: AppTheme.Colors.protein)
                    nutritionLabel(String(format: "%.1f", food.carbsGrams), unit: "g C", color: AppTheme.Colors.carbs)
                    nutritionLabel(String(format: "%.1f", food.fatGrams), unit: "g F", color: AppTheme.Colors.fat)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
        )
    }

    private func nutritionLabel(_ value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.Jakarta.semiBold(12))
                .foregroundColor(color)
            Text(unit)
                .font(.Jakarta.regular(10))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Tags

    @ViewBuilder
    private var tagsSection: some View {
        if !meal.tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(meal.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.Jakarta.medium(12))
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(AppTheme.Colors.primary.opacity(0.08))
                                    .background(Capsule().fill(.ultraThinMaterial))
                            )
                            .overlay(
                                Capsule().stroke(AppTheme.Colors.primary.opacity(0.15), lineWidth: 0.5)
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - AI Analysis

    @ViewBuilder
    private var aiAnalysisSection: some View {
        if let analysis = meal.aiAnalysis, !analysis.isEmpty {
            AIInsightCard(analysisText: analysis)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers

    private static func decodeImage(from data: Data) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let image = UIImage(data: data)
                continuation.resume(returning: image)
            }
        }
    }
}
