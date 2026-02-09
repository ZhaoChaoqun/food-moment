import SwiftUI

/// 根视图 - 根据认证状态显示不同内容
struct ContentView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - Body

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .accessibilityIdentifier("ContentView")
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppState())
}
