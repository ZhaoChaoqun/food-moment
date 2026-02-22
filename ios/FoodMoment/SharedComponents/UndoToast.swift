import SwiftUI

/// 可撤销操作的底部 Toast 提示
///
/// 显示操作结果消息和撤销按钮，适用于删除等可逆操作。
struct UndoToast: View {

    // MARK: - Properties

    let message: String
    let onUndo: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash.fill")
                .font(.Jakarta.medium(14))
                .foregroundColor(.white.opacity(0.7))

            Text(message)
                .font(.Jakarta.medium(14))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Button {
                onUndo()
            } label: {
                Text("撤销")
                    .font(.Jakarta.semiBold(14))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            .accessibilityIdentifier("UndoToast.UndoButton")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(Color(.systemGray6).opacity(0.95))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(.ultraThickMaterial)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .padding(.horizontal, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityIdentifier("UndoToast")
    }
}

#Preview {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        VStack {
            Spacer()
            UndoToast(message: "\"番茄炒蛋盖饭\" 已删除", onUndo: {})
                .padding(.bottom, 100)
        }
    }
}
