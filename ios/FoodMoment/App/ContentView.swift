import SwiftUI
import os

/// 根视图 - 自动设备注册后直接展示主界面
struct ContentView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - Private

    private static let logger = Logger(subsystem: "com.foodmoment", category: "ContentView")

    @State private var showMain = false

    // MARK: - Body

    var body: some View {
        Group {
            if showMain {
                MainTabView()
                    .transition(.opacity)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: "#102216"),
                            Color(hex: "#0A1A10")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 32) {
                        Spacer()

                        // Logo
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.primary.opacity(0.15))
                                .frame(width: 120, height: 120)

                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(AppTheme.Colors.primary)
                        }

                        // Title
                        VStack(spacing: 8) {
                            Text("FoodMoment")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("AI 食物识别 · 智能饮食管理")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        Spacer()

                        ProgressView()
                            .tint(AppTheme.Colors.primary)
                            .padding(.bottom, 48)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: showMain)
        .task {
            if ProcessInfo.processInfo.arguments.contains("--reset-state") {
                await TokenManager.shared.resetForTesting()
            }

            let start = ContinuousClock.now
            await autoRegisterDevice()

            // 确保启动页至少显示 1.2 秒
            let elapsed = ContinuousClock.now - start
            let remaining = Duration.seconds(1.2) - elapsed
            if remaining > .zero {
                try? await Task.sleep(for: remaining)
            }
            showMain = true
        }
        .accessibilityIdentifier("ContentView")
    }

    // MARK: - Device Registration

    /// 自动设备注册
    ///
    /// 检查是否已有有效 token，若无则使用设备 UUID 注册/登录。
    private func autoRegisterDevice() async {
        // 已有有效 token 则跳过
        let isValid = await TokenManager.shared.isTokenValid
        if isValid {
            appState.isAuthenticated = true
            return
        }

        let deviceId = await TokenManager.shared.deviceId
        Self.logger.info("[Auth] Device auth with deviceId: \(deviceId.prefix(8), privacy: .public)...")

        do {
            let response: DeviceAuthResponseDTO = try await APIClient.shared.request(
                .deviceAuth,
                body: DeviceAuthRequestDTO(deviceId: deviceId)
            )
            await TokenManager.shared.setTokens(
                access: response.accessToken,
                refresh: response.refreshToken
            )
            appState.isAuthenticated = true
            Self.logger.info("[Auth] Device auth succeeded")

            // DEBUG 模式下自动 seed 演示数据
            #if DEBUG
            try? await APIClient.shared.requestVoid(.seedDemo)
            Self.logger.debug("[Auth] Demo seed completed")
            #endif
        } catch {
            Self.logger.error("[Auth] Device auth failed: \(error, privacy: .public)")
        }
    }
}

// MARK: - DTOs

private struct DeviceAuthRequestDTO: Encodable {
    let deviceId: String
}

private struct DeviceAuthResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppState())
}
