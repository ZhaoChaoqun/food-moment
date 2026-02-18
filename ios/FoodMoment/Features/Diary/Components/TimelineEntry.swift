import SwiftUI

/// 单条时间线条目，左侧显示垂直线和圆点节点，右侧显示 FoodPhotoCard
struct TimelineEntry: View {

    // MARK: - Properties

    let meal: MealRecord
    let isFirst: Bool
    let isLast: Bool
    let onDelete: () -> Void

    // MARK: - Computed Properties

    private var mealColor: Color {
        DiaryViewModel.mealColor(for: meal)
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            timelineSpine
                .frame(width: 24)

            mealContent
        }
        .padding(.horizontal, 20)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
        .accessibilityIdentifier("TimelineEntry.\(meal.id)")
    }

    // MARK: - Meal Content

    private var mealContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            timeLabel
            FoodPhotoCard(meal: meal)
        }
    }

    private var timeLabel: some View {
        Text(meal.mealTime.mealTimeString)
            .font(.Jakarta.medium(12))
            .foregroundColor(.secondary)
            .padding(.bottom, 8)
            .accessibilityIdentifier("TimelineEntry.TimeLabel")
    }

    // MARK: - Timeline Spine

    private var timelineSpine: some View {
        GeometryReader { geometry in
            let midY: CGFloat = 20
            let height = geometry.size.height

            ZStack(alignment: .top) {
                lineAboveDot(midY: midY)
                lineBelowDot(midY: midY, height: height)
                dotNode(midY: midY)
            }
        }
    }

    // MARK: - Timeline Components

    @ViewBuilder
    private func lineAboveDot(midY: CGFloat) -> some View {
        if !isFirst {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1)
                .frame(height: midY)
                .position(x: 12, y: midY / 2)
        }
    }

    @ViewBuilder
    private func lineBelowDot(midY: CGFloat, height: CGFloat) -> some View {
        if !isLast {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1)
                .frame(height: height - midY - 8)
                .position(x: 12, y: midY + 8 + (height - midY - 8) / 2)
        }
    }

    private func dotNode(midY: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [mealColor, mealColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .fill(mealColor.opacity(0.2))
                    .frame(width: 18, height: 18)
            )
            .shadow(color: mealColor.opacity(0.3), radius: 4, y: 1)
            .position(x: 12, y: midY)
    }
}

#Preview {
    TimelineEntry(
        meal: MealRecord(
            mealType: "lunch",
            mealTime: Date(),
            title: "番茄炒蛋盖饭",
            descriptionText: "美味的午餐",
            totalCalories: 450,
            proteinGrams: 20.0,
            carbsGrams: 55.0,
            fatGrams: 12.0,
            fiberGrams: 3.0,
            tags: ["home-cooked", "balanced"]
        ),
        isFirst: true,
        isLast: false,
        onDelete: {}
    )
    .modelContainer(for: [MealRecord.self], inMemory: true)
}
