import SwiftUI

struct StreakCard: View {

    // MARK: - Properties

    let streakDays: Int

    // MARK: - Computed Properties

    private var motivationText: String {
        switch streakDays {
        case 0:
            return "今天开始！"
        case 1...3:
            return "好的开始！"
        case 4...7:
            return "势头不错！"
        case 8...14:
            return "继续加油！"
        case 15...30:
            return "太棒了！"
        default:
            return "自律达人！"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            flameIcon
            daysCountText
            streakSubtitle
            Spacer(minLength: 0)
            Divider()
                .padding(.horizontal, 20)
            motivationLabel
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard()
        .accessibilityIdentifier("StreakCard")
    }

    // MARK: - Flame Icon

    private var flameIcon: some View {
        Image(systemName: "flame.fill")
            .font(.Jakarta.regular(36))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "#FF6B35"), Color(hex: "#FACC15")],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .shadow(color: Color(hex: "#FF6B35").opacity(0.4), radius: 8, y: 2)
    }

    // MARK: - Days Count Text

    private var daysCountText: some View {
        Text("\(streakDays)")
            .font(.Jakarta.bold(21))
            .foregroundStyle(.primary)
        + Text(" 天")
            .font(.Jakarta.semiBold(12))
            .foregroundStyle(.primary)
    }

    // MARK: - Streak Subtitle

    private var streakSubtitle: some View {
        Text("连续打卡")
            .font(.Jakarta.regular(15))
            .foregroundStyle(.secondary)
    }

    // MARK: - Motivation Label

    private var motivationLabel: some View {
        Text(motivationText)
            .font(.Jakarta.medium(12))
            .foregroundStyle(AppTheme.Colors.primary)
    }
}
