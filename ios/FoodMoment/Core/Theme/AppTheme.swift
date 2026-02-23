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

        /// 主色调 - 翡翠绿（Apple System Green）
        static let primary = Color(hex: "#34C759")

        /// 强调色 - 黄绿色
        static let accent = Color(hex: "#A8D84E")

        /// 浅色背景（Light: #F8F9FA / Dark: #000000）
        static let background = Color("Colors/AppBackground")

        /// 深色背景
        static let darkBackground = Color(hex: "#0D1F16")

        /// 卡片背景（Light: #FFFFFF / Dark: #1C1C1E）
        static let cardBackground = Color("Colors/CardBackground")

        // MARK: - Meal Type Colors

        /// 早餐颜色 - 黄色
        static let breakfast = Color(hex: "#FACC15")

        /// 午餐颜色 - 橙色
        static let lunch = Color(hex: "#FB923C")

        /// 晚餐颜色 - 红色
        static let dinner = Color(hex: "#F87171")

        /// 加餐颜色 - 蓝色
        static let snack = Color(hex: "#60A5FA")

        // MARK: - Nutrient Colors (方案 A：经典行业标准)

        /// 蛋白质颜色 - 蓝色
        static let protein = Color(hex: "#60A5FA")

        /// 碳水化合物颜色 - 绿色
        static let carbs = Color(hex: "#34D399")

        /// 脂肪颜色 - 琥珀黄
        static let fat = Color(hex: "#FBBF24")

        /// 膳食纤维颜色 - 紫色
        static let fiber = Color(hex: "#A78BFA")

        // MARK: - Text Colors (Dark Mode 自适应)

        /// 主文本色（Light: #1A1A2E / Dark: #F5F5F7）
        static let textPrimary = Color("Colors/TextPrimary")

        /// 次文本色（Light: #64748B / Dark: #A1A1AA）
        static let textSecondary = Color("Colors/TextSecondary")

        /// 辅助文本色（Light: #475569 / Dark: #71717A）
        static let textTertiary = Color("Colors/TextTertiary")

        // MARK: - UI Colors (Dark Mode 自适应)

        /// 进度条底色（Light: #E2E8F0 / Dark: #2C2C2E）
        static let trackGray = Color("Colors/TrackGray")

        /// 分割线颜色（Light: #F1F5F9 / Dark: #2C2C2E）
        static let divider = Color("Colors/AppDivider")

        /// 热量警告色（超标）
        static let calorieWarning = Color(hex: "#F87171")

        /// 拖拽指示条颜色（Light: #CBD5E1 / Dark: #48484A）
        static let dragIndicator = Color("Colors/DragIndicator")

        /// 卡路里标签背景色
        static let calorieBadgeBackground = Color.black.opacity(0.35)

        // MARK: - Health Metric Colors

        /// 热量环进度色 - 柔和黄绿色
        static let calorieRingProgress = Color(hex: "#7BC67E")

        /// 热量环底色 - 深绿色
        static let calorieRingTrack = Color(hex: "#1E3A2A")

        /// 热量环溢出高光色
        static let calorieRingOverflow = Color(hex: "#A8E86B")

        /// 水分主色 - 蓝色
        static let water = Color(hex: "#3B82F6")

        /// 水分浅色 - 用于渐变起始
        static let waterLight = Color(hex: "#93C5FD")

        /// 水分底色 - 用于图标容器
        static let waterBackground = Color(hex: "#EFF6FF")

        /// 水滴渐变浅色
        static let waterDropletLight = Color(hex: "#4FC3F7")

        /// 水滴渐变深色
        static let waterDropletDark = Color(hex: "#0288D1")

        /// 步数主色 - 深绿色
        static let steps = Color(hex: "#076653")
    }

    // MARK: - Corner Radius

    /// 圆角半径配置
    enum CornerRadius {
        /// 超小圆角 - 8pt（缩略图、小标签、进度条）
        static let xs: CGFloat = 8

        /// 小圆角 - 12pt（输入框、搜索框、小卡片）
        static let small: CGFloat = 12

        /// 中等圆角 - 20pt（标准卡片、Sheet）
        static let medium: CGFloat = 20

        /// 大圆角 - 28pt（大卡片、FoodMoment Card）
        static let large: CGFloat = 28

        /// 超大圆角 - 36pt（TabBar、特殊全宽容器）
        static let extraLarge: CGFloat = 36
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

    // MARK: - Typography

    /// 排版阶梯配置（对齐 HIG Dynamic Type Scale）
    enum Typography {
        /// 核心数字（卡路里百分比等） - 44pt Bold
        static let displayLarge: CGFloat = 44

        /// 页面主标题、用户名 - 28pt Bold
        static let displaySmall: CGFloat = 28

        /// Section 标题 - 20pt Semibold
        static let headline: CGFloat = 20

        /// 卡片标题 - 17pt Semibold
        static let titleSmall: CGFloat = 17

        /// 正文 - 15pt Regular
        static let body: CGFloat = 15

        /// 辅助信息 - 13pt Medium
        static let caption: CGFloat = 13

        /// 徽章、标签 - 11pt Semibold
        static let micro: CGFloat = 11
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
            .shadow(color: Color(hex: "#0F172A").opacity(0.06), radius: 10, y: 4)
    }
}

/// 发光阴影修饰器
struct GlowShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: AppTheme.Colors.primary.opacity(0.25), radius: 10)
    }
}

/// 卡片阴影修饰器
struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color(hex: "#0F172A").opacity(0.08), radius: 16, y: 6)
    }
}
