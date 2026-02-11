import SwiftUI
import SwiftData

/// 水平周日期选择器，显示 7 天及选中状态和餐食指示器
struct WeekDatePicker: View {

    // MARK: - Properties

    @Binding var selectedDate: Date
    let weekDates: [Date]
    let onPreviousWeek: () -> Void
    let onNextWeek: () -> Void

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Private Properties

    private let calendar = Calendar.current

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            weekNavigationBar
            dateCellsRow
        }
        .padding(.vertical, 8)
        .accessibilityIdentifier("WeekDatePicker")
    }

    // MARK: - Week Navigation Bar

    private var weekNavigationBar: some View {
        HStack {
            previousWeekButton

            Spacer()

            Text(weekRangeText)
                .font(.Jakarta.medium(13))
                .foregroundColor(.secondary)
                .accessibilityIdentifier("WeekDatePicker.WeekRangeText")

            Spacer()

            nextWeekButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var previousWeekButton: some View {
        Button(action: onPreviousWeek) {
            Image(systemName: "chevron.left")
                .font(.Jakarta.medium(14))
                .foregroundColor(.secondary)
        }
        .accessibilityIdentifier("WeekDatePicker.PreviousWeekButton")
        .accessibilityLabel("上一周")
    }

    private var nextWeekButton: some View {
        Button(action: onNextWeek) {
            Image(systemName: "chevron.right")
                .font(.Jakarta.medium(14))
                .foregroundColor(.secondary)
        }
        .accessibilityIdentifier("WeekDatePicker.NextWeekButton")
        .accessibilityLabel("下一周")
    }

    // MARK: - Date Cells Row

    private var dateCellsRow: some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                DateCell(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: date.isToday,
                    hasMeals: dateHasMeals(date)
                )
                .onTapGesture {
                    withAnimation(AppTheme.Animation.defaultSpring) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Computed Properties

    private var weekRangeText: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        let startStr = first.formatted(as: "M/d")
        let endStr = last.formatted(as: "M/d")
        return "\(startStr) - \(endStr)"
    }

    // MARK: - Helper Methods

    private func dateHasMeals(_ date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)?
            .addingTimeInterval(-1) else {
            return false
        }
        let predicate = #Predicate<MealRecord> { meal in
            meal.mealTime >= startOfDay && meal.mealTime <= endOfDay
        }
        var descriptor = FetchDescriptor<MealRecord>(predicate: predicate)
        descriptor.fetchLimit = 1
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count > 0
    }
}

// MARK: - Date Cell

private struct DateCell: View {

    // MARK: - Properties

    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasMeals: Bool

    // MARK: - Private Properties

    private let calendar = Calendar.current

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {
            weekdayLabel
            dateNumberLabel
            mealIndicator
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(backgroundView)
        .contentShape(Rectangle())
        .accessibilityIdentifier("DateCell.\(calendar.component(.day, from: date))")
        .accessibilityLabel(accessibilityDateLabel)
    }

    // MARK: - Subviews

    private var weekdayLabel: some View {
        Text(weekdayAbbreviation)
            .font(.Jakarta.medium(11))
            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
    }

    private var dateNumberLabel: some View {
        Text("\(calendar.component(.day, from: date))")
            .font(.Jakarta.bold(16))
            .foregroundColor(dateNumberColor)
    }

    private var mealIndicator: some View {
        Circle()
            .fill(hasMeals ? AppTheme.Colors.primary : Color.clear)
            .frame(width: 5, height: 5)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                isSelected
                    ? AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: "#1A1A2E"), Color(hex: "#16213E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ))
                    : AnyShapeStyle(Color.clear)
            )
            .shadow(color: isSelected ? Color.black.opacity(0.15) : .clear, radius: 6, y: 3)
    }

    // MARK: - Computed Properties

    private var dateNumberColor: Color {
        if isSelected {
            return .white
        }
        if isToday {
            return AppTheme.Colors.primary
        }
        return .primary
    }

    private var weekdayAbbreviation: String {
        let weekday = calendar.component(.weekday, from: date)
        let symbols = ["日", "一", "二", "三", "四", "五", "六"]
        return symbols[weekday - 1]
    }

    private var accessibilityDateLabel: String {
        let day = calendar.component(.day, from: date)
        let weekday = weekdayAbbreviation
        var label = "\(day)日 星期\(weekday)"
        if isToday {
            label += " 今天"
        }
        if hasMeals {
            label += " 有记录"
        }
        return label
    }
}
