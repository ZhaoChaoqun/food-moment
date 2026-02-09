import SwiftUI

struct StreakCard: View {

    // MARK: - Properties

    let streakDays: Int

    // MARK: - Computed Properties

    private var motivationText: String {
        switch streakDays {
        case 0:
            return "Start today!"
        case 1...3:
            return "Nice start!"
        case 4...7:
            return "Great momentum!"
        case 8...14:
            return "Keep it up!"
        case 15...30:
            return "Amazing streak!"
        default:
            return "Incredible discipline!"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            flameIcon
            daysCountText
            streakSubtitle
            Divider()
                .padding(.horizontal, 20)
            motivationLabel
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassCard()
        .accessibilityIdentifier("StreakCard")
    }

    // MARK: - Flame Icon

    private var flameIcon: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 36))
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
            .font(.system(size: 21, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
        + Text(" Days")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
    }

    // MARK: - Streak Subtitle

    private var streakSubtitle: some View {
        Text("Streak")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    // MARK: - Motivation Label

    private var motivationLabel: some View {
        Text(motivationText)
            .font(.caption.weight(.medium))
            .foregroundStyle(AppTheme.Colors.primary)
    }
}
