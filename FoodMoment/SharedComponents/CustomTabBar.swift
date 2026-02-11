import SwiftUI

/// 自定义底部导航栏
struct CustomTabBar: View {

    // MARK: - Properties

    @Binding var selectedTab: AppState.TabItem
    var onScanTapped: () -> Void

    // MARK: - Private Properties

    private let scanButtonSize: CGFloat = 48

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            tabButton(for: .home)
            tabButton(for: .statistics)
            scanButton
            tabButton(for: .diary)
            tabButton(for: .profile)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tabBarBackground)
        .padding(.horizontal, 16)
        .accessibilityIdentifier("CustomTabBar")
    }

    // MARK: - Tab Bar Background

    private var tabBarBackground: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(.white.opacity(0.8))
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 20, y: -5)
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        Button(action: onScanTapped) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.primary,
                                AppTheme.Colors.primary.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: scanButtonSize, height: scanButtonSize)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 8, y: 2)

                Image(systemName: "plus")
                    .font(.Jakarta.semiBold(26))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("ScanTabButton")
    }

    // MARK: - Tab Button

    private func tabButton(for tab: AppState.TabItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.Jakarta.regular(20))

                Text(tab.title)
                    .font(.Jakarta.medium(10))
            }
            .foregroundStyle(selectedTab == tab ? AppTheme.Colors.primary : .gray.opacity(0.6))
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier(tab.accessibilityID)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(.home)) {
            print("Scan tapped")
        }
    }
    .background(Color.gray.opacity(0.1))
}
