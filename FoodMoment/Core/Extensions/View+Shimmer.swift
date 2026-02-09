import SwiftUI

// MARK: - Shimmer Modifier

/// 闪烁加载效果修饰器
///
/// 在视图上叠加一个从左到右移动的渐变光效，
/// 用于表示内容正在加载中。
private struct ShimmerModifier: ViewModifier {

    // MARK: - State

    @State private var phase: CGFloat = 0

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: phase * geometry.size.width * 1.6 - geometry.size.width * 0.3)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Shimmer View Extensions

extension View {

    /// 应用闪烁加载效果
    ///
    /// 在视图上添加一个从左到右循环移动的光效。
    ///
    /// - Returns: 带有闪烁效果的视图
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    /// 条件性应用遮挡和闪烁效果
    ///
    /// 当条件为真时，使用 `.redacted(reason: .placeholder)` 遮挡内容，
    /// 并添加闪烁效果。
    ///
    /// - Parameter condition: 是否显示加载状态
    /// - Returns: 根据条件应用效果的视图
    func redactedShimmer(_ condition: Bool) -> some View {
        self
            .redacted(reason: condition ? .placeholder : [])
            .modifier(condition ? ShimmerModifier() : nil)
    }
}

// MARK: - Optional Modifier Helper

private extension View {
    @ViewBuilder
    func modifier<T: ViewModifier>(_ modifier: T?) -> some View {
        if let modifier = modifier {
            self.modifier(modifier)
        } else {
            self
        }
    }
}
