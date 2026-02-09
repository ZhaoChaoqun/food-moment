import SwiftUI

// MARK: - Custom Font Extension

extension Font {

    /// Plus Jakarta Sans 自定义字体
    ///
    /// 提供应用中使用的 Plus Jakarta Sans 字体的各种字重。
    ///
    /// ## 使用示例
    /// ```swift
    /// Text("Hello")
    ///     .font(.Jakarta.bold(24))
    /// ```
    enum Jakarta {

        /// 常规字重
        ///
        /// - Parameter size: 字体大小
        /// - Returns: 常规字重的 Plus Jakarta Sans 字体
        static func regular(_ size: CGFloat) -> Font {
            .custom("PlusJakartaSans-Regular", size: size)
        }

        /// 中等字重
        ///
        /// - Parameter size: 字体大小
        /// - Returns: 中等字重的 Plus Jakarta Sans 字体
        static func medium(_ size: CGFloat) -> Font {
            .custom("PlusJakartaSans-Medium", size: size)
        }

        /// 半粗字重
        ///
        /// - Parameter size: 字体大小
        /// - Returns: 半粗字重的 Plus Jakarta Sans 字体
        static func semiBold(_ size: CGFloat) -> Font {
            .custom("PlusJakartaSans-SemiBold", size: size)
        }

        /// 粗体字重
        ///
        /// - Parameter size: 字体大小
        /// - Returns: 粗体字重的 Plus Jakarta Sans 字体
        static func bold(_ size: CGFloat) -> Font {
            .custom("PlusJakartaSans-Bold", size: size)
        }

        /// 特粗字重
        ///
        /// - Parameter size: 字体大小
        /// - Returns: 特粗字重的 Plus Jakarta Sans 字体
        static func extraBold(_ size: CGFloat) -> Font {
            .custom("PlusJakartaSans-ExtraBold", size: size)
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
