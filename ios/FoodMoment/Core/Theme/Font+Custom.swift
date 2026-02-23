import SwiftUI
import UIKit

// MARK: - Custom Font Extension

extension Font {

    /// 应用字体配置
    ///
    /// 英文/数字使用 SF Pro Rounded，中文使用狮尾圆体 (Swei Gothic CJK SC)
    /// 通过 UIFont cascade list 实现中英文圆角风格统一
    ///
    /// ## 使用示例
    /// ```swift
    /// Text("Hello 你好")
    ///     .font(.appFont(.semibold, size: 24))
    /// ```

    // MARK: - 主要字体方法

    /// 应用标准字体（圆角设计）
    /// - Parameters:
    ///   - weight: 字重
    ///   - size: 字体大小
    /// - Returns: SF Pro Rounded + 狮尾圆体组合字体
    static func appFont(_ weight: Font.Weight = .regular, size: CGFloat) -> Font {
        Font(FontBuilder.build(weight: weight.uiFontWeight, size: size))
    }

    /// 数字专用字体（圆角设计，适合数据展示）
    /// - Parameters:
    ///   - weight: 字重
    ///   - size: 字体大小
    /// - Returns: 圆角设计的系统字体
    static func appNumber(_ weight: Font.Weight = .bold, size: CGFloat) -> Font {
        Font(FontBuilder.build(weight: weight.uiFontWeight, size: size))
    }

    // MARK: - 兼容旧 API（Jakarta 别名）

    /// Jakarta Sans 兼容层
    /// 现已改用 SF Pro Rounded + 狮尾圆体，保留此命名空间以兼容现有代码
    enum Jakarta {

        /// 常规字重
        static func regular(_ size: CGFloat) -> Font {
            Font(FontBuilder.build(weight: .regular, size: size))
        }

        /// 中等字重
        static func medium(_ size: CGFloat) -> Font {
            Font(FontBuilder.build(weight: .medium, size: size))
        }

        /// 半粗字重
        static func semiBold(_ size: CGFloat) -> Font {
            Font(FontBuilder.build(weight: .semibold, size: size))
        }

        /// 粗体字重
        static func bold(_ size: CGFloat) -> Font {
            Font(FontBuilder.build(weight: .bold, size: size))
        }

        /// 特粗字重
        static func extraBold(_ size: CGFloat) -> Font {
            Font(FontBuilder.build(weight: .heavy, size: size))
        }
    }
}

// MARK: - Font Builder

/// 构建 SF Pro Rounded + 狮尾圆体组合字体
///
/// 使用 UIFont cascade list 机制：
/// - 主字体：SF Pro Rounded（英文/数字）
/// - 回退字体：狮尾圆体 CJK SC（中文），内嵌于 App 包内
private enum FontBuilder {

    /// 构建组合字体
    static func build(weight: UIFont.Weight, size: CGFloat) -> UIFont {
        // 1. 创建 SF Pro Rounded 作为主字体
        let roundedDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .body)
            .withDesign(.rounded)?
            .addingAttributes([
                .traits: [UIFontDescriptor.TraitKey.weight: weight]
            ]) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)

        let baseFont = UIFont(descriptor: roundedDescriptor, size: size)

        // 2. 创建狮尾圆体作为中文回退字体
        let postScriptName = sweiGothicName(for: weight)
        guard let cjkFont = UIFont(name: postScriptName, size: size) else {
            return baseFont
        }

        let combinedDescriptor = baseFont.fontDescriptor.addingAttributes([
            .cascadeList: [cjkFont.fontDescriptor]
        ])

        return UIFont(descriptor: combinedDescriptor, size: size)
    }

    /// 根据字重映射狮尾圆体的 PostScript 名称
    ///
    /// 内嵌 4 个字重：Regular / Medium / Bold / Black
    private static func sweiGothicName(for weight: UIFont.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light, .regular:
            return "SweiGothicCJKsc-Regular"
        case .medium:
            return "SweiGothicCJKsc-Medium"
        case .semibold, .bold:
            return "SweiGothicCJKsc-Bold"
        default: // heavy, black
            return "SweiGothicCJKsc-Black"
        }
    }
}

// MARK: - Font.Weight to UIFont.Weight

extension Font.Weight {

    /// 将 SwiftUI Font.Weight 转换为 UIKit UIFont.Weight
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}

// MARK: - Text Style Modifiers

extension View {

    /// 大标题样式 - 28pt Bold
    ///
    /// 用于页面主标题、用户名等。
    func titleStyle() -> some View {
        self.font(.appFont(.bold, size: AppTheme.Typography.displaySmall))
    }

    /// Section 标题样式 - 20pt SemiBold
    ///
    /// 用于模块标题（成就、今日食刻等）。
    func headlineStyle() -> some View {
        self.font(.appFont(.semibold, size: AppTheme.Typography.headline))
    }

    /// 正文样式 - 15pt Regular
    func bodyStyle() -> some View {
        self.font(.appFont(.regular, size: AppTheme.Typography.body))
    }

    /// 辅助信息样式 - 13pt Medium，次要颜色
    func captionStyle() -> some View {
        self
            .font(.appFont(.medium, size: AppTheme.Typography.caption))
            .foregroundStyle(.secondary)
    }

    /// 小标签样式 - 11pt SemiBold
    ///
    /// 用于徽章、标签和极小文字。
    func labelStyle() -> some View {
        self.font(.appFont(.semibold, size: AppTheme.Typography.micro))
    }

    /// 数字显示样式 - 44pt Bold
    ///
    /// 用于核心数字（卡路里百分比等）。
    func numberStyle() -> some View {
        self.font(.appFont(.bold, size: AppTheme.Typography.displayLarge))
    }
}
