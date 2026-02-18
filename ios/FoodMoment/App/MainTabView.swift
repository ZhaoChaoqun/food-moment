import SwiftUI

/// 主 Tab 视图 - 包含底部导航栏
struct MainTabView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - Initialization

    init() {
        // 完全隐藏系统原生 TabBar
        UITabBar.appearance().isHidden = true
    }

    // MARK: - Body

    var body: some View {
        @Bindable var appState = appState

        ZStack(alignment: .bottom) {
            tabContent

            CustomTabBar(selectedTab: $appState.selectedTab) {
                appState.activeFullScreen = .camera
            }
        }
        .overlay {
            if let achievement = appState.currentUnlockAchievement {
                AchievementUnlockView(achievement: achievement) {
                    appState.dismissCurrentUnlockAchievement()
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .fullScreenCover(item: $appState.activeFullScreen) { destination in
            switch destination {
            case .camera:
                CameraView()
            case .analysis(let image):
                AnalysisView(image: image)
            }
        }
        .accessibilityIdentifier("MainTabView")
    }

    // MARK: - Tab Content

    private var tabContent: some View {
        @Bindable var appState = appState

        return TabView(selection: $appState.selectedTab) {
            HomeView()
                .tag(AppState.TabItem.home)

            StatisticsView()
                .tag(AppState.TabItem.statistics)

            Color.clear
                .tag(AppState.TabItem.camera)

            DiaryView()
                .tag(AppState.TabItem.diary)

            ProfileView()
                .tag(AppState.TabItem.profile)
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environment(AppState())
}
