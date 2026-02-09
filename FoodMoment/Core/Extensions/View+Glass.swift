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
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
            .background(.thickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .modifier(GlassShadow())
    }
}
