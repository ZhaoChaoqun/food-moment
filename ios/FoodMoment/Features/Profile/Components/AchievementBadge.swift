import SwiftUI

/// 成就徽章渲染模式
enum BadgeRenderMode {
    /// SwiftUI 代码绘制（SF Symbols 图标）
    case swiftUI
    /// Assets 图片加载（HTML/CSS 生成的 Material Symbols 图片）
    case asset
}

struct AchievementBadge: View {

    // MARK: - Properties

    let item: AchievementItem
    var renderMode: BadgeRenderMode = .asset

    // MARK: - Computed Properties

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
        .frame(width: 80, height: 110)
        .accessibilityIdentifier("AchievementBadge_\(item.type)")
    }

    // MARK: - Badge Circle

    @ViewBuilder
    private var badgeCircle: some View {
        if item.isEarned {
            switch renderMode {
            case .swiftUI:
                swiftUIBadge
            case .asset:
                assetBadge
            }
        } else {
            lockedBadge
        }
    }

    // MARK: - Mode A: SwiftUI Drawing

    private var swiftUIBadge: some View {
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
                    colors: [item.theme.primaryColor.opacity(0.3),
                             item.theme.shadowColor.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 72, height: 72)
    }

    private var innerBadgeCircle: some View {
        Circle()
            .fill(
                LinearGradient(
                    stops: [.init(color: item.theme.primaryColor, location: 0.0),
                            .init(color: item.theme.highlightColor.opacity(0.35), location: 0.5),
                            .init(color: item.theme.shadowColor, location: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 56, height: 56)
    }

    private var badgeBorder: some View {
        Circle()
            .strokeBorder(
                LinearGradient(
                    colors: [item.theme.primaryColor,
                             item.theme.highlightColor,
                             item.theme.shadowColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: item.tier == .gold ? 3 : 2
            )
            .frame(width: 60, height: 60)
    }

    private var badgeIcon: some View {
        Image(systemName: item.icon)
            .font(.Jakarta.medium(20))
            .foregroundStyle(.white)
    }

    // MARK: - Mode B: Asset Image

    private var assetBadge: some View {
        Image(item.badgeAssetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 72, height: 72)
    }

    // MARK: - Locked Badge (Desaturated Theme Color Style)

    private var lockedBadge: some View {
        ZStack {
            // 外圈：主题色淡化背景
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            item.theme.primaryColor.opacity(0.15),
                            item.theme.shadowColor.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)

            // 内圆：主题色低饱和渐变
            Circle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: item.theme.primaryColor.opacity(0.18), location: 0.0),
                            .init(color: item.theme.highlightColor.opacity(0.12), location: 0.5),
                            .init(color: item.theme.shadowColor.opacity(0.10), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)

            // 真实图标（主题色降低不透明度）
            lockedIcon

            // 右下角小锁标识
            lockIndicator
        }
    }

    @ViewBuilder
    private var lockedIcon: some View {
        if item.isHidden {
            Text("???")
                .font(.Jakarta.bold(14))
                .foregroundStyle(Color.gray.opacity(0.4))
        } else {
            Image(systemName: item.icon)
                .font(.Jakarta.medium(20))
                .foregroundStyle(item.theme.primaryColor.opacity(0.4))
        }
    }

    private var lockIndicator: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 16, height: 16)
            .background(
                Circle()
                    .fill(Color.gray.opacity(0.55))
            )
            .offset(x: 24, y: 24)
    }

    // MARK: - Title Text

    private var titleText: some View {
        Text(item.isHidden && !item.isEarned
             ? "???"
             : item.title)
            .font(.Jakarta.medium(12))
            .foregroundStyle(item.isEarned ? .primary : .secondary)
            .lineLimit(1)
    }

    // MARK: - Tier Badge

    private var tierBadge: some View {
        Group {
            if item.isEarned {
                Text(tierLabel)
                    .font(.Jakarta.bold(8))
                    .foregroundStyle(item.theme.primaryColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(item.theme.primaryColor.opacity(0.15))
                    )
            } else {
                Text("未达成")
                    .font(.Jakarta.bold(8))
                    .foregroundStyle(Color.gray.opacity(0.4))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.08))
                    )
            }
        }
    }
}
