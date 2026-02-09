import SwiftUI

struct CheckinGrid: View {

    // MARK: - Properties

    let checkinDays: [Date]
    let isCheckedIn: (Date) -> Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let calendar = Calendar.current

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            weekdayHeadersSection
            dayGridSection
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, 20)
        .accessibilityIdentifier("CheckinGrid")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Text("Check-in Consistency")
                .font(.Jakarta.semiBold(18))
                .foregroundStyle(.primary)

            Spacer()

            Text("\(checkedInCount)/14 days")
                .font(.Jakarta.medium(13))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Weekday Headers Section

    private var weekdayHeadersSection: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.Jakarta.medium(11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day Grid Section

    private var dayGridSection: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(last14Days, id: \.self) { date in
                dayCircleView(for: date)
            }
        }
    }

    // MARK: - Day Circle View

    private func dayCircleView(for date: Date) -> some View {
        let isChecked = isCheckedIn(date)
        return Circle()
            .fill(isChecked ? AppTheme.Colors.primary : Color.gray.opacity(0.2))
            .opacity(isChecked ? 1.0 : 0.2)
            .frame(width: 32, height: 32)
            .overlay {
                Text("\(calendar.component(.day, from: date))")
                    .font(.Jakarta.medium(11))
                    .foregroundStyle(isChecked ? .white : .secondary)
            }
            .accessibilityIdentifier("CheckinGrid.Day.\(calendar.component(.day, from: date))")
    }

    // MARK: - Computed Properties

    private var last14Days: [Date] {
        let today = Date()
        return (0..<14).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
    }

    private var checkedInCount: Int {
        last14Days.filter { isCheckedIn($0) }.count
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday - 1
        return Array(symbols[firstWeekday...]) + Array(symbols[..<firstWeekday])
    }
}
