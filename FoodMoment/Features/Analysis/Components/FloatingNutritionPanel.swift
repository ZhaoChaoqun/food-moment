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
                    Text(Self.localizedTag(tag))
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

    // MARK: - Tag Localization

    private static let tagTranslations: [String: String] = [
        "high-protein": "高蛋白",
        "high protein": "高蛋白",
        "low-protein": "低蛋白",
        "low protein": "低蛋白",
        "high-carb": "高碳水",
        "high carb": "高碳水",
        "low-carb": "低碳水",
        "low carb": "低碳水",
        "high-fat": "高脂肪",
        "high fat": "高脂肪",
        "low-fat": "低脂",
        "low fat": "低脂",
        "high-sugar": "高糖",
        "high sugar": "高糖",
        "low-sugar": "低糖",
        "low sugar": "低糖",
        "high-fiber": "高纤维",
        "high fiber": "高纤维",
        "low-calorie": "低卡",
        "low calorie": "低卡",
        "high-calorie": "高热量",
        "high calorie": "高热量",
        "balanced": "均衡",
        "vegetarian": "素食",
        "vegan": "纯素",
        "gluten-free": "无麸质",
        "gluten free": "无麸质",
        "organic": "有机",
        "healthy": "健康",
        "omega-3": "Omega-3",
        "chinese-cuisine": "中式",
        "chinese cuisine": "中式",
        "home-cooked": "家常",
        "home cooked": "家常",
        "alcoholic": "含酒精",
        "non-alcoholic": "无酒精",
        "beverage": "饮品",
        "dessert": "甜品",
        "snack": "零食",
        "breakfast": "早餐",
        "lunch": "午餐",
        "dinner": "晚餐",
        "spicy": "辛辣",
        "fried": "油炸",
        "steamed": "蒸制",
        "grilled": "烧烤",
        "raw": "生食",
        "fermented": "发酵",
        "antioxidant": "抗氧化",
        "low-gi": "低GI",
        "high-sodium": "高钠",
        "low-sodium": "低钠",
    ]

    private static func localizedTag(_ tag: String) -> String {
        tagTranslations[tag.lowercased()] ?? tag
    }
}
