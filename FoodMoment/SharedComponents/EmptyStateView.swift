import SwiftUI

/// 空状态视图组件 - 用于显示列表为空时的占位内容
struct EmptyStateView: View {

    // MARK: - Properties

    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String?
    let action: (() -> Void)?

    // MARK: - Initialization

    init(
        icon: String,
        title: String,
        subtitle: String,
        buttonTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            iconView
            titleView
            subtitleView
            actionButton
        }
        .padding(32)
        .accessibilityIdentifier("EmptyStateView")
    }

    // MARK: - Icon View

    private var iconView: some View {
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
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)

            Image(systemName: icon)
                .font(.Jakarta.regular(48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.primary.opacity(0.7),
                            AppTheme.Colors.primary.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    // MARK: - Title View

    private var titleView: some View {
        Text(title)
            .font(.Jakarta.semiBold(20))
            .foregroundStyle(.primary)
    }

    // MARK: - Subtitle View

    private var subtitleView: some View {
        Text(subtitle)
            .font(.Jakarta.regular(14))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        if let buttonTitle, let action {
            GradientButton(buttonTitle, action: action)
                .padding(.horizontal, 48)
                .padding(.top, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        EmptyStateView(
            icon: "fork.knife.circle",
            title: "No Meals Yet",
            subtitle: "Start tracking your meals by tapping the camera button below.",
            buttonTitle: "Add First Meal"
        ) {
            print("Add meal tapped")
        }

        Divider()

        EmptyStateView(
            icon: "chart.bar.xaxis",
            title: "No Data",
            subtitle: "Statistics will appear once you start logging meals."
        )
    }
}
