import SwiftUI
import UIKit

/// 食物照片卡片，显示餐食类型徽章、卡路里标签、标题和营养标签
struct FoodPhotoCard: View {

    // MARK: - Properties

    let meal: MealRecord

    // MARK: - Computed Properties

    private var mealType: MealRecord.MealType {
        DiaryViewModel.mealType(for: meal)
    }

    private var mealColor: Color {
        DiaryViewModel.mealColor(for: meal)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            photoSection
            textContentSection
        }
        .accessibilityIdentifier("FoodPhotoCard.\(meal.id)")
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        ZStack(alignment: .topLeading) {
            photoView
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                .overlay(gradientOverlay)

            mealTypeBadge
                .padding(12)

            calorieBadgeOverlay
        }
    }

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [.clear, .clear, .black.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }

    private var calorieBadgeOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                calorieBadge
                    .padding(12)
            }
        }
    }

    // MARK: - Photo View

    @ViewBuilder
    private var photoView: some View {
        if let imageData = meal.localImageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let assetName = meal.localAssetName, !assetName.isEmpty {
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let urlString = meal.imageURL, let url = URL(string: urlString) {
            asyncImageView(url: url)
        } else {
            placeholderView
        }
    }

    private func asyncImageView(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                placeholderView
                    .overlay(ProgressView())
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                placeholderView
            @unknown default:
                placeholderView
            }
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
                    .font(.system(size: 40))

                Text(mealType.displayName)
                    .font(.Jakarta.medium(14))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Text Content Section

    private var textContentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleText
            descriptionText
            tagsRow
        }
        .padding(.horizontal, 4)
    }

    private var titleText: some View {
        Text(meal.title)
            .font(.Jakarta.semiBold(16))
            .foregroundColor(.primary)
            .lineLimit(1)
            .accessibilityIdentifier("FoodPhotoCard.Title")
    }

    @ViewBuilder
    private var descriptionText: some View {
        if let description = meal.descriptionText, !description.isEmpty {
            Text(description)
                .font(.Jakarta.regular(13))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .accessibilityIdentifier("FoodPhotoCard.Description")
        }
    }

    // MARK: - Badges

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
        .accessibilityIdentifier("FoodPhotoCard.MealTypeBadge")
    }

    private var calorieBadge: some View {
        Text("\(meal.totalCalories) kcal")
            .font(.Jakarta.bold(13))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .accessibilityIdentifier("FoodPhotoCard.CalorieBadge")
    }

    // MARK: - Tags

    @ViewBuilder
    private var tagsRow: some View {
        if !meal.tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(meal.tags, id: \.self) { tag in
                        tagView(tag: tag)
                    }
                }
            }
            .accessibilityIdentifier("FoodPhotoCard.TagsRow")
        }
    }

    private func tagView(tag: String) -> some View {
        Text("#\(tag)")
            .font(.Jakarta.medium(11))
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.primary.opacity(0.1))
            )
    }
}
