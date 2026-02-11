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
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.white)
    }

    // MARK: - Mode B: Asset Image

    private var assetBadge: some View {
        Image(item.badgeAssetName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 72, height: 72)
    }

    // MARK: - Locked Badge (Neumorphism Style)

    private var lockedBadge: some View {
        ZStack {
            // 外圈：neumorphism 凹陷效果
            Circle()
                .fill(Color(hex: "#ECECEC"))
                .shadow(color: .white, radius: 4, x: -2, y: -2)
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 2, y: 2)
                .frame(width: 72, height: 72)

            // 外圈描边
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.8), Color.gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 72, height: 72)

            // 内圆：银色渐变
            Circle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#E0E0E0"), location: 0.0),
                            .init(color: Color(hex: "#F5F5F5"), location: 0.4),
                            .init(color: Color(hex: "#D0D0D0"), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)

            // 内圆描边
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 56, height: 56)

            // 图标
            lockedIcon
        }
    }

    @ViewBuilder
    private var lockedIcon: some View {
        if item.isHidden {
            Text("???")
                .font(.Jakarta.bold(14))
                .foregroundStyle(Color.gray.opacity(0.5))
        } else {
            Image(systemName: "lock.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.gray.opacity(0.5))
        }
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
                // 占位符：与等级标签等高，保持所有徽章垂直对齐一致
                Text(" ")
                    .font(.Jakarta.bold(8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .hidden()
            }
        }
    }
}
