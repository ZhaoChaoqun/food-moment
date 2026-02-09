import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            // Background gradient
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
                        .fill(Color(hex: "#13EC5B").opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color(hex: "#13EC5B"))
                }

                // Title
                VStack(spacing: 8) {
                    Text("FoodMoment")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("AI 食物识别 · 智能饮食管理")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Sign in with Apple
                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await viewModel.handleSignInWithApple(result: result)
                            if viewModel.errorMessage == nil {
                                appState.isAuthenticated = true
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(Capsule())

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Skip for development
                    #if DEBUG
                    Button {
                        appState.isAuthenticated = true
                    } label: {
                        Text("跳过登录 (开发模式)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    #endif
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
