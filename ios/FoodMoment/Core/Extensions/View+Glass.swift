import SwiftUI

// MARK: - Glass Material Style

/// 毛玻璃样式等级
enum GlassStyle {
    case ultraThin
    case regular
    case thick

    /// 对应的 Material
    var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        }
    }

    /// 对应的白底透明度
    var whiteOpacity: Double {
        switch self {
        case .ultraThin: return 0.6
        case .regular: return 0.5
        case .thick: return 0.4
        }
    }

    /// 对应的边框透明度
    var strokeOpacity: Double {
        whiteOpacity
    }
}

// MARK: - Glass Card View Modifiers

extension View {

    /// 通用毛玻璃卡片效果
    ///
    /// - Parameters:
    ///   - style: 毛玻璃样式（ultraThin / regular / thick）
    ///   - cornerRadius: 圆角半径
    /// - Returns: 应用了毛玻璃效果的视图
    func glassCard(
        style: GlassStyle = .ultraThin,
        cornerRadius: CGFloat = AppTheme.CornerRadius.medium
    ) -> some View {
        self
            .background(.white.opacity(style.whiteOpacity))
            .background(style.material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(style.strokeOpacity), lineWidth: 0.5)
            )
            .modifier(GlassShadow())
    }

    /// 常规毛玻璃卡片效果（便利方法）
    func regularGlassCard(cornerRadius: CGFloat = AppTheme.CornerRadius.medium) -> some View {
        glassCard(style: .regular, cornerRadius: cornerRadius)
    }

    /// 厚毛玻璃卡片效果（便利方法）
    func thickGlassCard(cornerRadius: CGFloat = AppTheme.CornerRadius.large) -> some View {
        glassCard(style: .thick, cornerRadius: cornerRadius)
    }

    /// 高级渐变页面背景
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

    /// 玻璃态分组容器
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
