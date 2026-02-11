import SwiftUI
import UIKit

struct FoodMomentCarousel: View {

    // MARK: - Properties

    let meals: [MealRecord]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            contentView
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text("今日食刻")
                .font(.Jakarta.bold(20))
                .foregroundStyle(.primary)

            Spacer()

            Button(action: {}) {
                HStack(spacing: 4) {
                    Text("更多")
                        .font(.Jakarta.medium(14))
                    Image(systemName: "chevron.right")
                        .font(.Jakarta.semiBold(10))
                }
                .foregroundStyle(AppTheme.Colors.primary)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if meals.isEmpty {
            emptyStateView
        } else {
            mealScrollView
        }
    }

    // MARK: - Meal Scroll View

    private var mealScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(meals, id: \.id) { meal in
                    FoodMomentCard(meal: meal)
                }
            }
            .padding(.horizontal, 20)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.Colors.primary.opacity(0.08),
                                AppTheme.Colors.primary.opacity(0.02)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 35
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "camera.fill")
                    .font(.Jakarta.regular(32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.primary.opacity(0.6),
                                AppTheme.Colors.primary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("还没有记录今天的美食")
                .font(.Jakarta.medium(14))
                .foregroundStyle(.secondary)

            Text("拍张照片，开启你的食刻")
                .font(.Jakarta.regular(12))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium)
        .padding(.horizontal, 20)
    }
}

// MARK: - Food Moment Card

private struct FoodMomentCard: View {

    // MARK: - Properties

    let meal: MealRecord

    // MARK: - Design Constants

    private let cardWidth: CGFloat = 220
    private let cardHeight: CGFloat = 280

    // MARK: - Computed Properties

    private var mealTypeInfo: (name: String, color: Color) {
        switch meal.mealType {
        case "breakfast":
            return ("早餐", AppTheme.Colors.breakfast)
        case "lunch":
            return ("午餐", AppTheme.Colors.lunch)
        case "dinner":
            return ("晚餐", AppTheme.Colors.dinner)
        case "snack":
            return ("加餐", AppTheme.Colors.snack)
        default:
            return ("其他", AppTheme.Colors.primary)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            imageLayer
            gradientOverlay
            contentOverlay
            caloriesBadge
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .modifier(CardShadow())
    }

    // MARK: - Image Layer

    @ViewBuilder
    private var imageLayer: some View {
        if let assetName = meal.localAssetName {
            // 优先使用本地 Asset 图片（用于演示数据）
            Image(assetName)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: cardHeight)
                .clipped()
        } else if let imageURL = meal.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: cardWidth, height: cardHeight)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else if let imageData = meal.localImageData,
                  let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: cardWidth, height: cardHeight)
                .clipped()
        } else {
            placeholderView
        }
    }

    // MARK: - Gradient Overlay

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.6)],
            startPoint: .center,
            endPoint: .bottom
        )
    }

    // MARK: - Content Overlay

    private var contentOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()

            Text(mealTypeInfo.name)
                .font(.Jakarta.semiBold(10))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(mealTypeInfo.color.opacity(0.85))
                .clipShape(Capsule())

            Text(meal.title)
                .font(.Jakarta.semiBold(18))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Calories Badge

    private var caloriesBadge: some View {
        VStack {
            HStack {
                Spacer()
                Text("\(meal.totalCalories) kcal")
                    .font(.Jakarta.bold(10))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(12)
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    mealTypeInfo.color.opacity(0.3),
                    mealTypeInfo.color.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "fork.knife")
                .font(.Jakarta.regular(36))
                .foregroundStyle(mealTypeInfo.color.opacity(0.5))
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}
