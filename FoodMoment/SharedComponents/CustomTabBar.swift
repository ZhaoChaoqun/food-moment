import SwiftUI

/// 自定义底部导航栏
struct CustomTabBar: View {

    // MARK: - Properties

    @Binding var selectedTab: AppState.TabItem
    var onScanTapped: () -> Void

    // MARK: - Private Properties

    private let scanButtonSize: CGFloat = 64
    private let scanButtonOffset: CGFloat = -20

    // MARK: - Body

    var body: some View {
        ZStack {
            tabBarBackground
            tabButtonsRow
            scanButtonSection
        }
        .frame(height: 64)
        .padding(.horizontal, 16)
        .accessibilityIdentifier("CustomTabBar")
    }

    // MARK: - Tab Bar Background

    private var tabBarBackground: some View {
        RoundedRectangle(cornerRadius: 32)
            .fill(.white.opacity(0.8))
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 20, y: -5)
    }

    // MARK: - Tab Buttons Row

    private var tabButtonsRow: some View {
        HStack(spacing: 0) {
            tabButton(for: .home)
            tabButton(for: .statistics)

            // 中间占位，给扫描按钮留空间
            Color.clear
                .frame(maxWidth: .infinity)

            tabButton(for: .diary)
            tabButton(for: .profile)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    // MARK: - Scan Button Section

    private var scanButtonSection: some View {
        VStack(spacing: 0) {
            Button(action: onScanTapped) {
                scanButtonCircle
            }
            .offset(y: scanButtonOffset)

            Text("Scan")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primary)
                .offset(y: -16)
        }
        .accessibilityIdentifier("ScanTabButton")
    }

    private var scanButtonCircle: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.accent)
                .frame(width: scanButtonSize, height: scanButtonSize)
                .shadow(color: AppTheme.Colors.accent.opacity(0.4), radius: 15)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primary)
        }
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
                    .font(.system(size: 24))

                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? AppTheme.Colors.primary : .gray)
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
