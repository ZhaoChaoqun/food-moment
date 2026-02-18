import SwiftUI
import os

/// 根视图 - 自动设备注册后直接展示主界面
struct ContentView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState

    // MARK: - Private

    private static let logger = Logger(subsystem: "com.foodmoment", category: "ContentView")

    // MARK: - Body

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.Colors.primary)
                    ProgressView()
                        .tint(AppTheme.Colors.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .premiumBackground()
            }
        }
        .task {
            if ProcessInfo.processInfo.arguments.contains("--reset-state") {
                await TokenManager.shared.resetForTesting()
            }
            await autoRegisterDevice()
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
