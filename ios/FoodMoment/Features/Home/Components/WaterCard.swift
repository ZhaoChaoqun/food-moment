import SwiftUI

struct WaterCard: View {

    // MARK: - Properties

    let waterAmount: Int
    let dailyGoal: Int
    let progress: Double
    let onAddWater: () -> Void
    let onShowOptions: () -> Void

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Design Constants

    private let cardCornerRadius: CGFloat = 32
    private let iconSize: CGFloat = 40
    private let buttonSize: CGFloat = 32
    private let iconFontSize: CGFloat = 20
    private let progressHeight: CGFloat = 6

    private let waterGradient = LinearGradient(
        colors: [Color(hex: "#93C5FD"), Color(hex: "#3B82F6")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            contentSection
            progressBar
        }
        .padding(20)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .top) {
            waterIcon
            Spacer()
            addButton
        }
    }

    private var waterIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#EFF6FF"))
                .frame(width: iconSize, height: iconSize)

            Image(systemName: "drop.fill")
                .font(.Jakarta.regular(iconFontSize))
                .foregroundStyle(Color(hex: "#3B82F6"))
        }
    }

    private var addButton: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: buttonSize, height: buttonSize)
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)

            Image(systemName: "plus")
                .font(.Jakarta.medium(iconFontSize))
                .foregroundStyle(Color.gray.opacity(0.6))
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            onAddWater()
        }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            onShowOptions()
        })
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("饮水量")
                .font(.Jakarta.medium(12))
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(formattedWater)
                    .font(.Jakarta.bold(24))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text("mL")
                    .font(.Jakarta.medium(12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: progressHeight)

                Capsule()
                    .fill(waterGradient)
                    .frame(
                        width: max(geometry.size.width * CGFloat(min(progress, 1.0)), progressHeight),
                        height: progressHeight
                    )
                    .shadow(color: Color(hex: "#3B82F6").opacity(0.2), radius: 5, y: 0)
                    .animation(.easeOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: progressHeight)
        .padding(.top, 4)
    }

    // MARK: - Card Styling

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius)
            .fill(.white.opacity(0.75))
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(.ultraThinMaterial)
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius)
            .stroke(Color.white.opacity(0.5), lineWidth: 1)
    }

    // MARK: - Computed Properties

    private var formattedWater: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: waterAmount)) ?? "\(waterAmount)"
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        WaterCard(
            waterAmount: 1250,
            dailyGoal: 2500,
            progress: 0.6,
            onAddWater: {},
            onShowOptions: {}
        )
    }
    .padding()
    .background(Color(hex: "#FBFBFB"))
}
