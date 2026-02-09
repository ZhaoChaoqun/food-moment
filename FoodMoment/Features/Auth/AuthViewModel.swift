import SwiftUI
import AuthenticationServices

@MainActor
@Observable
final class AuthViewModel {
    var isLoading = false
    var errorMessage: String?

    /// Handle Sign in with Apple completion
    func handleSignInWithApple(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                errorMessage = "无法获取 Apple 登录凭证"
                isLoading = false
                return
            }

            let fullName = [
                credential.fullName?.givenName,
                credential.fullName?.familyName
            ].compactMap { $0 }.joined(separator: " ")

            do {
                // Send to backend for verification
                let response: TokenResponseDTO = try await APIClient.shared.request(
                    .appleSignIn,
                    body: AppleAuthRequestDTO(
                        identityToken: identityToken,
                        authorizationCode: String(data: credential.authorizationCode ?? Data(), encoding: .utf8) ?? "",
                        fullName: fullName.isEmpty ? nil : fullName,
                        email: credential.email
                    )
                )

                // Store tokens
                await TokenManager.shared.setAccessToken(response.accessToken)

            } catch {
                errorMessage = "登录失败: \(error.localizedDescription)"
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Apple 登录失败: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }

    func signOut() async {
        await TokenManager.shared.clearTokens()
    }
}

// MARK: - DTOs
private struct AppleAuthRequestDTO: Encodable {
    let identityToken: String
    let authorizationCode: String
    let fullName: String?
    let email: String?
}

struct TokenResponseDTO: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
}
