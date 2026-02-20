import SwiftUI

/// Nutrition panel content view.
///
/// Renders analysis results, loading, or error state.
/// The caller is responsible for embedding this in a ScrollView.
struct FloatingNutritionPanel: View {

    let analysisResult: AnalysisResponseDTO?
    let isAnalyzing: Bool
    let errorMessage: String?

    let onLogMeal: () -> Void
    let onRetry: () -> Void

    // MARK: - Body

    var body: some View {
        Group {
            if let result = analysisResult {
                resultContent(result)
            } else if isAnalyzing {
                loadingContent
            } else if let error = errorMessage {
                errorContent(error)
            }
        }
    }

    // MARK: - Result Content

    private func resultContent(_ result: AnalysisResponseDTO) -> some View {
        VStack(spacing: 24) {
            totalEnergySection(result)

            NutritionRingsRow(nutrition: result.totalNutrition)
                .padding(.horizontal, 20)

            if !result.tags.isEmpty {
                tagsRow(result.tags)
            }

            AIInsightCard(analysisText: result.aiAnalysis)
                .padding(.horizontal, 20)

            LogMealButton(action: onLogMeal)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .padding(.top, 16)
    }

    // MARK: - Content Sections

    private func totalEnergySection(_ result: AnalysisResponseDTO) -> some View {
        VStack(spacing: 4) {
            Text("总热量")
                .font(.Jakarta.semiBold(14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .tracking(2)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(result.totalCalories)")
                    .font(.Jakarta.extraBold(48))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("kcal")
                    .font(.Jakarta.bold(20))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
    }

    private func tagsRow(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.Jakarta.medium(12))
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(AppTheme.Colors.primary.opacity(0.12))
                        )
                        .overlay(
                            Capsule().stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Loading

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.textPrimary))
                .scaleEffect(1.2)

            Text("正在分析营养成分...")
                .font(.Jakarta.medium(14))
                .foregroundColor(AppTheme.Colors.textPrimary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Error

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.Jakarta.regular(24))
                .foregroundColor(.orange)

            Text(message)
                .font(.Jakarta.medium(13))
                .foregroundColor(AppTheme.Colors.textPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Button(action: onRetry) {
                Text("重试")
                    .font(.Jakarta.semiBold(14))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().stroke(AppTheme.Colors.textPrimary.opacity(0.6), lineWidth: 1.5)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#Preview {
    ScrollView {
        FloatingNutritionPanel(
            analysisResult: AnalysisResponseDTO(
                imageUrl: "",
                totalCalories: 650,
                totalNutrition: NutritionDataDTO(
                    proteinG: 35.0,
                    carbsG: 60.0,
                    fatG: 20.0,
                    fiberG: 8.0
                ),
                detectedFoods: [],
                aiAnalysis: "This is a balanced meal with good protein and fiber content.",
                tags: ["高蛋白", "营养均衡"]
            ),
            isAnalyzing: false,
            errorMessage: nil,
            onLogMeal: {},
            onRetry: {}
        )
    }
}
