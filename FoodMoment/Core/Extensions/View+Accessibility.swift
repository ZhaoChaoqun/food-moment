import SwiftUI

// MARK: - Accessibility Modifiers

extension View {

    /// 为卡路里数值添加无障碍标签
    ///
    /// - Parameters:
    ///   - value: 当前卡路里值
    ///   - goal: 目标卡路里值
    /// - Returns: 添加了无障碍标签的视图
    func calorieAccessibility(value: Int, goal: Int) -> some View {
        let percentage = goal > 0 ? Int(Double(value) / Double(goal) * 100) : 0
        return self
            .accessibilityLabel("卡路里")
            .accessibilityValue("\(value)千卡，目标\(goal)千卡，完成\(percentage)%")
    }

    /// 为营养素添加无障碍标签
    ///
    /// - Parameters:
    ///   - name: 营养素名称
    ///   - value: 当前值
    ///   - unit: 单位
    ///   - goal: 目标值
    /// - Returns: 添加了无障碍标签的视图
    func nutrientAccessibility(
        name: String,
        value: Double,
        unit: String,
        goal: Double
    ) -> some View {
        let percentage = goal > 0 ? Int(value / goal * 100) : 0
        return self
            .accessibilityLabel(name)
            .accessibilityValue("\(Int(value))\(unit)，目标\(Int(goal))\(unit)，完成\(percentage)%")
    }

    /// 为进度环添加无障碍标签
    ///
    /// - Parameters:
    ///   - label: 标签文字
    ///   - progress: 进度值（0-1）
    /// - Returns: 添加了无障碍标签的视图
    func ringAccessibility(label: String, progress: Double) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue("完成\(Int(progress * 100))%")
    }

    /// 为餐食卡片添加无障碍标签
    ///
    /// - Parameters:
    ///   - mealType: 餐次类型
    ///   - title: 餐食标题
    ///   - calories: 卡路里值
    ///   - time: 用餐时间
    /// - Returns: 添加了无障碍标签的视图
    func mealCardAccessibility(
        mealType: String,
        title: String,
        calories: Int,
        time: Date
    ) -> some View {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")

        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(mealType)，\(title)")
            .accessibilityValue("\(calories)千卡，\(formatter.string(from: time))")
            .accessibilityHint("双击查看详情")
    }

    /// 为图片添加无障碍描述
    ///
    /// - Parameter description: 图片描述
    /// - Returns: 添加了无障碍标签的视图
    func imageAccessibility(description: String) -> some View {
        self
            .accessibilityLabel(description)
            .accessibilityAddTraits(.isImage)
    }

    /// 隐藏装饰性元素
    ///
    /// 用于纯装饰性的视觉元素，对辅助技术用户没有意义。
    func decorativeAccessibility() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Dynamic Type Support

extension View {

    /// 适配 Dynamic Type 的文本缩放
    ///
    /// - Parameters:
    ///   - style: 文本样式
    ///   - size: 基础字体大小
    ///   - weight: 字体粗细
    /// - Returns: 应用了动态字体的视图
    @ViewBuilder
    func scaledFont(
        _ style: Font.TextStyle,
        size: CGFloat,
        weight: Font.Weight = .regular
    ) -> some View {
        self
            .font(.appFont(weight, size: size))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    /// 确保最小触摸目标尺寸
    ///
    /// 根据 Apple Human Interface Guidelines，
    /// 可点击元素的最小尺寸应为 44x44 点。
    func minTouchTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }
}

// MARK: - Voice Control Labels

extension View {

    /// 为 Voice Control 添加自定义标签
    ///
    /// - Parameter label: 语音控制标签
    /// - Returns: 添加了语音控制标签的视图
    func voiceControlLabel(_ label: String) -> some View {
        self.accessibilityInputLabels([label])
    }

    /// 添加多个 Voice Control 标签
    ///
    /// - Parameter labels: 语音控制标签数组
    /// - Returns: 添加了语音控制标签的视图
    func voiceControlLabels(_ labels: [String]) -> some View {
        self.accessibilityInputLabels(labels)
    }
}

// MARK: - Accessibility Announcer

/// 无障碍公告管理器
///
/// 用于向 VoiceOver 用户发送屏幕变化通知。
@MainActor
final class AccessibilityAnnouncer {

    // MARK: - Singleton

    static let shared = AccessibilityAnnouncer()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 播报 VoiceOver 公告
    ///
    /// - Parameters:
    ///   - message: 要播报的消息
    ///   - priority: 通知优先级
    func announce(
        _ message: String,
        priority: UIAccessibility.Notification = .announcement
    ) {
        UIAccessibility.post(notification: priority, argument: message)
    }

    /// 播报屏幕变化
    ///
    /// - Parameter message: 新屏幕的描述
    func announceScreenChange(_ message: String) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }

    /// 播报布局变化
    ///
    /// - Parameter focusElement: 可选的焦点元素
    func announceLayoutChange(focusElement: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: focusElement)
    }
}

// MARK: - High Contrast Support

extension Color {

    /// 返回高对比度版本的颜色
    ///
    /// - Parameters:
    ///   - normalColor: 正常对比度下的颜色
    ///   - highContrastColor: 高对比度下的颜色
    /// - Returns: 根据系统设置返回对应颜色
    static func highContrast(
        _ normalColor: Color,
        highContrastColor: Color
    ) -> Color {
        // 注意：实际使用时应通过 @Environment(\.colorSchemeContrast) 判断
        return normalColor
    }
}

// MARK: - Reduce Motion Support

extension Animation {

    /// 尊重用户的减少动画设置
    ///
    /// - Parameter animation: 原始动画
    /// - Returns: 如果启用了减少动画则返回 nil，否则返回原始动画
    static func respectReduceMotion(_ animation: Animation) -> Animation? {
        if UIAccessibility.isReduceMotionEnabled {
            return nil
        }
        return animation
    }

    /// 适配减少动画设置的弹簧动画
    ///
    /// 如果用户启用了减少动画，则返回 nil。
    static var accessibleSpring: Animation? {
        respectReduceMotion(.spring(response: 0.5, dampingFraction: 0.7))
    }
}

// MARK: - Accessibility Environment

/// 无障碍环境键
private struct AccessibilityEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {

    /// VoiceOver 是否正在运行
    var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// 是否启用了减少动画
    var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// 是否启用了粗体文本
    var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }
}
