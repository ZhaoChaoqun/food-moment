import SwiftUI

// MARK: - Color Hex Initializer

extension Color {

    /// 使用十六进制字符串初始化颜色
    ///
    /// 支持以下格式：
    /// - RGB (12-bit): "#RGB"
    /// - RGB (24-bit): "#RRGGBB"
    /// - ARGB (32-bit): "#AARRGGBB"
    ///
    /// - Parameter hex: 十六进制颜色字符串
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Brand Color Extensions

extension ShapeStyle where Self == Color {

    /// 品牌主色
    static var brandPrimary: Color {
        AppTheme.Colors.primary
    }

    /// 品牌背景色
    static var brandBackground: Color {
        AppTheme.Colors.background
    }

    /// 品牌深色背景
    static var brandDarkBackground: Color {
        AppTheme.Colors.darkBackground
    }

    /// 早餐颜色
    static var mealBreakfast: Color {
        AppTheme.Colors.breakfast
    }

    /// 午餐颜色
    static var mealLunch: Color {
        AppTheme.Colors.lunch
    }

    /// 晚餐颜色
    static var mealDinner: Color {
        AppTheme.Colors.dinner
    }

    /// 加餐颜色
    static var mealSnack: Color {
        AppTheme.Colors.snack
    }

    /// 蛋白质颜色
    static var nutrientProtein: Color {
        AppTheme.Colors.protein
    }

    /// 碳水颜色
    static var nutrientCarbs: Color {
        AppTheme.Colors.carbs
    }

    /// 脂肪颜色
    static var nutrientFat: Color {
        AppTheme.Colors.fat
    }

    /// 纤维颜色
    static var nutrientFiber: Color {
        AppTheme.Colors.fiber
    }
}
