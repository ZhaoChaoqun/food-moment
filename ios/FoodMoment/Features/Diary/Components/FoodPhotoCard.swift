import SwiftUI
import UIKit

/// 食物照片卡片，显示餐食类型徽章、卡路里标签、标题和营养标签
struct FoodPhotoCard: View {

    // MARK: - Properties

    let meal: MealRecord

    @State private var decodedImage: UIImage?
    @State private var imageRetryID: Int = 0

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
        if let imageData = meal.localImageData {
            if let uiImage = decodedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholderView
                    .task(id: meal.id) {
                        decodedImage = await Self.decodeThumbnail(from: imageData)
                    }
            }
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
                imageErrorView
            @unknown default:
                placeholderView
            }
        }
        .id(imageRetryID)
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
                    .font(.Jakarta.regular(40))

                Text(mealType.displayName)
                    .font(.Jakarta.medium(14))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var imageErrorView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGray5), Color(.systemGray6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)

                Text("图片加载失败")
                    .font(.Jakarta.medium(12))
                    .foregroundStyle(.secondary)

                Button {
                    imageRetryID += 1
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                        Text("重试")
                            .font(.Jakarta.semiBold(12))
                    }
                    .foregroundStyle(AppTheme.Colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.primary.opacity(0.1))
                    )
                }
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
            Text(mealType.displayName)
                .font(.Jakarta.semiBold(11))
                .foregroundColor(.white)

            Text(meal.mealTime.mealTimeString)
                .font(.Jakarta.regular(11))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(mealColor.opacity(0.85))
        .clipShape(Capsule())
        .accessibilityIdentifier("FoodPhotoCard.MealTypeBadge")
    }

    private var calorieBadge: some View {
        Text("\(meal.totalCalories) kcal")
            .font(.Jakarta.bold(13))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.Colors.calorieBadgeBackground)
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
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.primary.opacity(0.06))
                    .background(Capsule().fill(.ultraThinMaterial))
            )
            .overlay(
                Capsule()
                    .stroke(AppTheme.Colors.primary.opacity(0.12), lineWidth: 0.5)
            )
    }

    // MARK: - Image Decoding

    private static func decodeThumbnail(from data: Data) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let fullImage = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                let targetSize = CGSize(width: 400, height: 400)
                let thumbnail = fullImage.preparingThumbnail(of: targetSize)
                continuation.resume(returning: thumbnail ?? fullImage)
            }
        }
    }
}

#Preview {
    FoodPhotoCard(
        meal: MealRecord(
            mealType: "lunch",
            mealTime: Date(),
            title: "番茄炒蛋盖饭",
            descriptionText: "鲜嫩多汁的家常菜",
            totalCalories: 450,
            proteinGrams: 20.0,
            carbsGrams: 55.0,
            fatGrams: 12.0,
            fiberGrams: 3.0,
            tags: ["home-cooked", "balanced"]
        )
    )
    .padding()
    .modelContainer(for: [MealRecord.self], inMemory: true)
}
