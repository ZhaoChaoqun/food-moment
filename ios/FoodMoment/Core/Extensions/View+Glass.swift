import SwiftUI

// MARK: - Glass Card View Modifiers

extension View {

    /// 应用超薄毛玻璃卡片效果
    ///
    /// 使用 `.ultraThinMaterial` 背景，适合叠加在图片或渐变上。
    ///
    /// - Parameter cornerRadius: 圆角半径，默认为 `AppTheme.CornerRadius.medium`
    /// - Returns: 应用了毛玻璃效果的视图
    func glassCard(cornerRadius: CGFloat = AppTheme.CornerRadius.medium) -> some View {
        self
            .background(.white.opacity(0.6))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
            )
            .modifier(GlassShadow())
    }

    /// 应用常规毛玻璃卡片效果
    ///
    /// 使用 `.regularMaterial` 背景，提供适中的模糊度。
    ///
    /// - Parameter cornerRadius: 圆角半径，默认为 `AppTheme.CornerRadius.medium`
    /// - Returns: 应用了毛玻璃效果的视图
    func regularGlassCard(cornerRadius: CGFloat = AppTheme.CornerRadius.medium) -> some View {
        self
            .background(.white.opacity(0.5))
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
            )
            .modifier(GlassShadow())
    }

    /// 应用厚毛玻璃卡片效果
    ///
    /// 使用 `.thickMaterial` 背景，提供更强的模糊效果。
    ///
    /// - Parameter cornerRadius: 圆角半径，默认为 `AppTheme.CornerRadius.large`
    /// - Returns: 应用了毛玻璃效果的视图
    func thickGlassCard(cornerRadius: CGFloat = AppTheme.CornerRadius.large) -> some View {
        self
            .background(.white.opacity(0.4))
            .background(.thickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
            )
            .modifier(GlassShadow())
    }

    /// 高级渐变页面背景，替代扁平的 AppTheme.Colors.background
    func premiumBackground() -> some View {
        self.background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "#ECFDF5"),
                        Color(hex: "#F5F7FA"),
                        Color(hex: "#EEF2FF")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [
                        AppTheme.Colors.primary.opacity(0.08),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 500
                )
                RadialGradient(
                    colors: [
                        Color(hex: "#818CF8").opacity(0.04),
                        Color.clear
                    ],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 400
                )
            }
            .ignoresSafeArea()
        )
    }

    /// 玻璃态分组容器，用于替代原生 Form Section
    func glassSection(cornerRadius: CGFloat = AppTheme.CornerRadius.small) -> some View {
        self
            .background(.white.opacity(0.7))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
            )
            .modifier(GlassShadow())
    }
}
