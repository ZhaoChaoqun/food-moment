import SwiftUI

struct AchievementBadge: View {

    // MARK: - Properties

    let item: AchievementItem

    // MARK: - Computed Properties

    private var gradientColors: [Color] {
        if item.isEarned {
            return item.tier.colors
        }
        return [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
    }

    private var tierLabel: String {
        item.tier.label
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {
            badgeCircle
            titleText
            tierBadge
        }
        .frame(width: 80, height: 100)
        .opacity(item.isEarned ? 1.0 : 0.5)
        .accessibilityIdentifier("AchievementBadge_\(item.type)")
    }

    // MARK: - Badge Circle

    private var badgeCircle: some View {
        ZStack {
            outerGradientBackground
            innerBadgeCircle

            if item.isEarned {
                badgeBorder
            }

            badgeIcon
        }
    }

    private var outerGradientBackground: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: item.isEarned
                        ? [item.tier.colors.first?.opacity(0.3) ?? Color.gray.opacity(0.1),
                           item.tier.colors.last?.opacity(0.1) ?? Color.gray.opacity(0.05)]
                        : [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 96, height: 96)
    }

    private var innerBadgeCircle: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: gradientColors,
                    center: .center,
                    startRadius: 2,
                    endRadius: 34
                )
            )
            .frame(width: 60, height: 60)
    }

    private var badgeBorder: some View {
        Circle()
            .strokeBorder(
                LinearGradient(
                    colors: item.tier.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: 64, height: 64)
    }

    private var badgeIcon: some View {
        Image(systemName: item.icon)
            .font(.title2)
            .foregroundStyle(item.isEarned ? .white : Color.gray.opacity(0.5))
    }

    // MARK: - Title Text

    private var titleText: some View {
        Text(item.title)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(item.isEarned ? .primary : .secondary)
            .lineLimit(1)
    }

    // MARK: - Tier Badge

    private var tierBadge: some View {
        Text(tierLabel)
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .foregroundStyle(item.isEarned ? item.tier.colors.first ?? .gray : Color.gray.opacity(0.5))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(
                        item.isEarned
                            ? (item.tier.colors.first ?? .gray).opacity(0.15)
                            : Color.gray.opacity(0.08)
                    )
            )
    }
}
