import SwiftUI

struct AchievementsGalleryView: View {

    // MARK: - Properties

    let viewModel: ProfileViewModel

    // MARK: - State

    @State private var selectedAchievement: AchievementItem?

    // MARK: - Constants

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                summaryCard
                categorySections
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .premiumBackground()
        .navigationTitle("成就")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .accessibilityIdentifier("AchievementsGalleryView")
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: 20) {
            completionRing

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("解锁进度")
                        .font(.Jakarta.medium(12))
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.unlockedCount) / \(viewModel.totalVisibleCount) 已解锁")
                        .font(.Jakarta.bold(20))
                        .foregroundStyle(.primary)
                }

                if let latest = viewModel.latestUnlockedAchievement {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最近解锁")
                            .font(.Jakarta.medium(12))
                            .foregroundStyle(.secondary)
                        Text(latest.title)
                            .font(.Jakarta.semiBold(14))
                            .foregroundStyle(.primary)
                        if let date = latest.earnedDate {
                            Text(date.fullDateString)
                                .font(.Jakarta.regular(12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Completion Ring

    private var completionRing: some View {
        ZStack {
            RingView(
                progress: viewModel.completionProgress,
                lineWidth: 10
            )

            Text("\(Int(viewModel.completionProgress * 100))%")
                .font(.Jakarta.bold(18))
                .foregroundStyle(.primary)
        }
        .frame(width: 80, height: 80)
    }

    // MARK: - Category Sections

    private var categorySections: some View {
        VStack(spacing: 24) {
            ForEach(viewModel.achievementsByCategory, id: \.category) { group in
                categorySection(category: group.category, items: group.items)
            }
        }
    }

    private func categorySection(
        category: Achievement.AchievementCategory,
        items: [AchievementItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.Jakarta.regular(14))
                    .foregroundStyle(AppTheme.Colors.primary)
                Text(category.displayName)
                    .font(.Jakarta.semiBold(16))
                    .foregroundStyle(.primary)

                Spacer()

                let earned = items.filter { $0.isEarned }.count
                Text("\(earned)/\(items.count)")
                    .font(.Jakarta.medium(12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    galleryBadgeCell(item: item)
                        .onTapGesture {
                            selectedAchievement = item
                        }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Gallery Badge Cell

    private func galleryBadgeCell(item: AchievementItem) -> some View {
        VStack(spacing: 4) {
            AchievementBadge(item: item, renderMode: .swiftUI)

            Group {
                if item.isEarned {
                    if let date = item.earnedDate {
                        Text(date.dayString)
                            .font(.Jakarta.regular(10))
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(" ")
                            .font(.Jakarta.regular(10))
                    }
                } else {
                    Text(item.isHidden ? "继续探索即可发现" : item.description)
                        .font(.Jakarta.regular(9))
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(height: 24, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Achievement Detail Sheet

private struct AchievementDetailSheet: View {

    let achievement: AchievementItem

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 8)
            badgeSection
            infoSection
            Spacer()
        }
        .padding(.horizontal, 24)
        .premiumBackground()
        .accessibilityIdentifier("AchievementDetailSheet")
    }

    // MARK: - Badge Section

    private var badgeSection: some View {
        AchievementBadge(item: achievement, renderMode: .swiftUI)
            .scaleEffect(1.8)
            .frame(width: 144, height: 198)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 16) {
            Text(displayName)
                .font(.Jakarta.bold(24))
                .foregroundStyle(.primary)

            if achievement.isEarned {
                tierLabel
            }

            Text(displayDescription)
                .font(.Jakarta.regular(15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            if achievement.isEarned {
                if let date = achievement.earnedDate {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.Jakarta.regular(12))
                        Text(date.fullDateString)
                            .font(.Jakarta.medium(14))
                    }
                    .foregroundStyle(.tertiary)
                }
            } else {
                unlockConditionCard
            }
        }
    }

    // MARK: - Unlock Condition Card

    private var unlockConditionCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.Jakarta.regular(12))
                Text("解锁条件")
                    .font(.Jakarta.medium(14))
            }
            .foregroundStyle(.tertiary)

            Text(achievement.isHidden ? "继续探索即可发现" : achievement.description)
                .font(.Jakarta.regular(13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(Color.gray.opacity(0.08))
                )
        }
    }

    // MARK: - Computed Display Properties

    private var displayName: String {
        if achievement.isHidden && !achievement.isEarned {
            return "???"
        }
        return achievement.title
    }

    private var displayDescription: String {
        if achievement.isHidden && !achievement.isEarned {
            return "继续探索即可发现"
        }
        return achievement.description
    }

    private var tierLabel: some View {
        Text(achievement.tier.label)
            .font(.Jakarta.bold(11))
            .foregroundStyle(achievement.theme.primaryColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(achievement.theme.primaryColor.opacity(0.15))
            )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AchievementsGalleryView(viewModel: ProfileViewModel())
    }
    .environment(AppState())
    .modelContainer(for: [Achievement.self, MealRecord.self])
}
