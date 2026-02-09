import SwiftUI
import SwiftData

struct ActivityCalendar: View {

    // MARK: - State

    @State private var displayedMonth: Date = Date()

    // MARK: - Properties

    let activeDays: Set<Int>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // MARK: - Computed Properties

    private var calendar: Calendar { Calendar.current }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: displayedMonth)
    }

    private var daysInMonth: Int {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)
        return range?.count ?? 30
    }

    private var firstWeekdayOffset: Int {
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.day = 1
        guard let firstDay = calendar.date(from: components) else { return 0 }
        // Monday = 0, Sunday = 6
        let weekday = calendar.component(.weekday, from: firstDay)
        return (weekday + 5) % 7
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            monthNavigationHeader
            weekdayHeaderGrid
            dayGrid
        }
        .padding(20)
        .glassCard(cornerRadius: 32)
        .accessibilityIdentifier("ActivityCalendar")
    }

    // MARK: - Month Navigation Header

    private var monthNavigationHeader: some View {
        HStack {
            previousMonthButton
            Spacer()
            monthTitleText
            Spacer()
            nextMonthButton
        }
        .padding(.horizontal, 4)
    }

    private var previousMonthButton: some View {
        Button {
            withAnimation(AppTheme.Animation.defaultSpring) {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .accessibilityIdentifier("PreviousMonthButton")
    }

    private var nextMonthButton: some View {
        Button {
            withAnimation(AppTheme.Animation.defaultSpring) {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            }
        } label: {
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .accessibilityIdentifier("NextMonthButton")
    }

    private var monthTitleText: some View {
        Text(monthTitle)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    // MARK: - Weekday Header Grid

    private var weekdayHeaderGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // Empty cells for offset
            ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                Color.clear
                    .frame(height: 36)
            }

            // Day cells
            ForEach(1...daysInMonth, id: \.self) { day in
                dayCell(for: day)
            }
        }
    }

    private func dayCell(for day: Int) -> some View {
        let isActive = activeDays.contains(day)

        return Text("\(day)")
            .font(.caption.weight(isActive ? .bold : .regular))
            .foregroundStyle(isActive ? .white : .secondary)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(isActive ? AppTheme.Colors.primary : Color.gray.opacity(0.1))
            )
            .accessibilityIdentifier("DayCell_\(day)")
    }
}
