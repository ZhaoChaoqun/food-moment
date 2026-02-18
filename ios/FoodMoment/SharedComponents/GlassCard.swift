import SwiftUI

/// 玻璃拟态卡片容器组件
struct GlassCard<Content: View>: View {

    // MARK: - Properties

    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    // MARK: - Initialization

    init(
        cornerRadius: CGFloat = AppTheme.CornerRadius.medium,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    // MARK: - Body

    var body: some View {
        content()
            .glassCard(cornerRadius: cornerRadius)
    }
}

// MARK: - Preview

#Preview {
    GlassCard {
        Text("Glass Card Content")
            .padding()
    }
    .padding()
}
