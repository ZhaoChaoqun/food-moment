import SwiftUI

/// 成就解锁全屏弹窗视图
///
/// 以 overlay 方式挂载在 MainTabView 之上，显示新解锁的成就徽章。
/// 采用徽章主色径向渐变背景 + 玻璃态内容卡片 + 发光徽章的视觉方案。
struct AchievementUnlockView: View {

    // MARK: - Properties

    let achievement: AchievementItem
    let onDismiss: () -> Void

    // MARK: - Computed

    private var primaryColor: Color { achievement.theme.primaryColor }
    private var shadowColor: Color { achievement.theme.shadowColor }

    // MARK: - State

    @State private var isAppearing = false
    @State private var badgeScale: CGFloat = 0.3
    @State private var badgeOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var cardOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayers

            VStack(spacing: 0) {
                Spacer()

                badgeSection
                    .padding(.bottom, 32)

                infoCard
                    .padding(.horizontal, 32)

                Spacer()

                dismissButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            performEntryAnimation()
        }
        .accessibilityIdentifier("AchievementUnlockView")
    }

    // MARK: - Background Layers

    private var backgroundLayers: some View {
        ZStack {
            // 底层：深色 + 毛玻璃
            Color.black.opacity(0.5)
                .background(.ultraThinMaterial)

            // 中层：徽章主色径向渐变光晕
            RadialGradient(
                colors: [
                    primaryColor.opacity(0.3),
                    primaryColor.opacity(0.08),
                    Color.clear,
                ],
                center: .center,
                startRadius: 40,
                endRadius: 320
            )

            // 顶层：底部暗角渐变
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.4)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .opacity(isAppearing ? 1 : 0)
    }

    // MARK: - Badge Section

    private var badgeSection: some View {
        ZStack {
            // 发光环：徽章主色模糊光晕
            Circle()
                .fill(primaryColor.opacity(0.25))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .opacity(glowOpacity)

            // 徽章
            AchievementBadge(item: achievement, renderMode: .asset)
                .scaleEffect(2.0)
                .frame(width: 160, height: 220)
        }
        .scaleEffect(badgeScale)
        .opacity(badgeOpacity)
    }

    // MARK: - Info Card (玻璃态)

    private var infoCard: some View {
        VStack(spacing: 16) {
            // ACHIEVEMENT UNLOCKED 标签
            Text("ACHIEVEMENT UNLOCKED")
                .font(.Jakarta.bold(10))
                .tracking(3)
                .foregroundStyle(primaryColor)

            // 成就名称
            Text(achievement.title)
                .font(.Jakarta.bold(24))
                .foregroundStyle(.white)

            // 英文副标题
            Text(achievement.subtitle)
                .font(.Jakarta.medium(14))
                .foregroundStyle(.white.opacity(0.5))

            // 分隔线
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, primaryColor.opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)

            // 解锁条件
            Text(achievement.description)
                .font(.Jakarta.regular(13))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    primaryColor.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    primaryColor.opacity(0.15),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .modifier(GlassShadow())
        .opacity(cardOpacity)
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        Button {
            performExitAnimation {
                onDismiss()
            }
        } label: {
            Text("太棒了!")
                .font(.Jakarta.semiBold(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(
                            LinearGradient(
                                colors: [primaryColor, shadowColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: primaryColor.opacity(0.3), radius: 12, y: 4)
        }
        .opacity(buttonOpacity)
        .accessibilityIdentifier("AchievementUnlockDismissButton")
    }

    // MARK: - Animations

    private func performEntryAnimation() {
        withAnimation(.easeIn(duration: 0.3)) {
            isAppearing = true
        }

        withAnimation(
            .spring(response: 0.6, dampingFraction: 0.65)
            .delay(0.2)
        ) {
            badgeScale = 1.0
            badgeOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            glowOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            cardOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.3).delay(0.7)) {
            buttonOpacity = 1.0
        }
    }

    private func performExitAnimation(completion: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.25)) {
            badgeScale = 0.8
            badgeOpacity = 0
            glowOpacity = 0
            cardOpacity = 0
            buttonOpacity = 0
            isAppearing = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            completion()
        }
    }
}
