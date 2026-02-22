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

    /// 应用标题样式
    ///
    /// 使用 28pt Bold 字体。
    func titleStyle() -> some View {
        self.font(.Jakarta.bold(28))
    }

    /// 应用大标题样式
    ///
    /// 使用 36pt ExtraBold 字体。
    func largeTitleStyle() -> some View {
        self.font(.Jakarta.extraBold(36))
    }

    /// 应用标题行样式
    ///
    /// 使用 20pt SemiBold 字体。
    func headlineStyle() -> some View {
        self.font(.Jakarta.semiBold(20))
    }

    /// 应用正文样式
    ///
    /// 使用 16pt Regular 字体。
    func bodyStyle() -> some View {
        self.font(.Jakarta.regular(16))
    }

    /// 应用说明文字样式
    ///
    /// 使用 12pt Medium 字体，次要颜色。
    func captionStyle() -> some View {
        self
            .font(.Jakarta.medium(12))
            .foregroundStyle(.secondary)
    }

    /// 应用小标签样式
    ///
    /// 使用 11pt SemiBold 字体，适用于徽章和标签。
    func labelStyle() -> some View {
        self.font(.Jakarta.semiBold(11))
    }

    /// 应用数字显示样式
    ///
    /// 使用 48pt ExtraBold 字体，适用于大数字显示。
    func numberStyle() -> some View {
        self.font(.Jakarta.extraBold(48))
    }
}
