import SwiftUI

// MARK: - App Theme

/// 应用主题配置
///
/// 集中管理应用的视觉样式，包括颜色、圆角、阴影和动画。
enum AppTheme {

    // MARK: - Colors

    /// 应用颜色配置
    enum Colors {

        // MARK: - Primary Colors

        /// 主色调 - 活力绿
        static let primary = Color(hex: "#13EC5B")

        /// 强调色 - 黄绿色
        static let accent = Color(hex: "#E3EF26")

        /// 浅色背景
        static let background = Color(hex: "#F8F9FA")

        /// 深色背景
        static let darkBackground = Color(hex: "#102216")

        /// 卡片背景
        static let cardBackground = Color(.systemBackground)

        // MARK: - Meal Type Colors

        /// 早餐颜色 - 黄色
        static let breakfast = Color(hex: "#FACC15")

        /// 午餐颜色 - 橙色
        static let lunch = Color(hex: "#FB923C")

        /// 晚餐颜色 - 红色
        static let dinner = Color(hex: "#F87171")

        /// 加餐颜色 - 蓝色
        static let snack = Color(hex: "#60A5FA")

        // MARK: - Nutrient Colors (方案 B：暖冷对比)

        /// 蛋白质颜色 - 珊瑚红
        static let protein = Color(hex: "#FF6B6B")

        /// 碳水化合物颜色 - 电光蓝
        static let carbs = Color(hex: "#4DA8FF")

        /// 脂肪颜色 - 明黄
        static let fat = Color(hex: "#FFD43B")

        /// 膳食纤维颜色 - 翠绿
        static let fiber = Color(hex: "#51CF66")

        // MARK: - Text Colors

        /// 主文本色
        static let textPrimary = Color(hex: "#0F172A")

        /// 次文本色
        static let textSecondary = Color(hex: "#64748B")

        /// 辅助文本色
        static let textTertiary = Color(hex: "#475569")

        // MARK: - UI Colors

        /// 进度条底色
        static let trackGray = Color(hex: "#E2E8F0")

        /// 分割线颜色
        static let divider = Color(hex: "#F1F5F9")

        /// 热量警告色（超标）
        static let calorieWarning = Color(hex: "#F87171")

        /// 拖拽指示条颜色
        static let dragIndicator = Color(hex: "#CBD5E1")
    }

    // MARK: - Corner Radius

    /// 圆角半径配置
    enum CornerRadius {
        /// 小圆角 - 16pt
        static let small: CGFloat = 16

        /// 中等圆角 - 24pt
        static let medium: CGFloat = 24

        /// 大圆角 - 32pt
        static let large: CGFloat = 32

        /// 超大圆角 - 40pt
        static let extraLarge: CGFloat = 40
    }

    // MARK: - Shadows

    /// 阴影样式配置
    enum Shadows {
        /// 毛玻璃阴影
        static func glass() -> some ViewModifier { GlassShadow() }

        /// 发光阴影
        static func glow() -> some ViewModifier { GlowShadow() }

        /// 卡片阴影
        static func card() -> some ViewModifier { CardShadow() }
    }

    // MARK: - Animation

    /// 动画配置
    enum Animation {
        /// 弹簧动画响应时间
        static let springResponse: Double = 0.5

        /// 弹簧动画阻尼系数
        static let springDamping: Double = 0.7

        /// 默认弹簧动画
        static var defaultSpring: SwiftUI.Animation {
            .spring(response: springResponse, dampingFraction: springDamping)
        }

        /// 快速弹簧动画
        static var fastSpring: SwiftUI.Animation {
            .spring(response: 0.3, dampingFraction: 0.7)
        }

        /// 缓慢弹簧动画
        static var slowSpring: SwiftUI.Animation {
            .spring(response: 0.8, dampingFraction: 0.7)
        }
    }

    // MARK: - Spacing

    /// 间距配置
    enum Spacing {
        /// 超小间距 - 4pt
        static let xs: CGFloat = 4

        /// 小间距 - 8pt
        static let small: CGFloat = 8

        /// 中等间距 - 12pt
        static let medium: CGFloat = 12

        /// 大间距 - 16pt
        static let large: CGFloat = 16

        /// 超大间距 - 20pt
        static let xl: CGFloat = 20

        /// 特大间距 - 24pt
        static let xxl: CGFloat = 24
    }

    // MARK: - Layout

    /// 布局尺寸配置
    enum Layout {
        /// 自定义 Tab Bar 的视觉高度
        static let tabBarHeight: CGFloat = 68

        /// 内容底部预留间距（确保不被 Tab Bar 遮挡）
        static let tabBarClearance: CGFloat = 88

        /// 浮动组件底部间距（如 DailyProgressFloat）
        static let floatingElementBottomPadding: CGFloat = 80
    }
}

// MARK: - Shadow Modifiers

/// 毛玻璃阴影修饰器
struct GlassShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.05), radius: 8, y: 8)
    }
}

/// 发光阴影修饰器
struct GlowShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 15)
    }
}

/// 卡片阴影修饰器
struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
    }
}
