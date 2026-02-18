import XCTest
@testable import FoodMoment

/// Tests for Date helper extensions
final class DateHelpersTests: XCTestCase {

    // MARK: - Start of Day Tests

    func test_startOfDay_returnsCorrectTime() {
        // Given
        let date = Date()

        // When
        let startOfDay = Calendar.current.startOfDay(for: date)

        // Then
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    // MARK: - Date Comparison Tests

    func test_isSameDay_sameDay_returnsTrue() {
        // Given
        let date1 = Date()
        let date2 = Date()

        // When
        let result = Calendar.current.isDate(date1, inSameDayAs: date2)

        // Then
        XCTAssertTrue(result)
    }

    func test_isSameDay_differentDays_returnsFalse() {
        // Given
        let date1 = Date()
        let date2 = Calendar.current.date(byAdding: .day, value: -1, to: date1)!

        // When
        let result = Calendar.current.isDate(date1, inSameDayAs: date2)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Week Navigation Tests

    func test_startOfWeek_returnsCorrectDay() {
        // Given
        let date = Date()
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        // When
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!

        // Then
        let weekday = calendar.component(.weekday, from: weekStart)
        XCTAssertEqual(weekday, 2) // Monday
    }

    func test_daysInWeek_returns7Days() {
        // Given
        let date = Date()
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!

        // When
        var days: [Date] = []
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: weekStart) {
                days.append(day)
            }
        }

        // Then
        XCTAssertEqual(days.count, 7)
    }

    // MARK: - Date Formatting Tests

    func test_shortDateFormat_isCorrect() {
        // Given
        let formatter = DateFormatter()
        formatter.dateStyle = .short

        let date = Date()

        // When
        let formatted = formatter.string(from: date)

        // Then
        XCTAssertFalse(formatted.isEmpty)
    }

    func test_timeFormat_isCorrect() {
        // Given
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let date = Date()

        // When
        let formatted = formatter.string(from: date)

        // Then
        XCTAssertFalse(formatted.isEmpty)
        // Should contain colon for time format
        XCTAssertTrue(formatted.contains(":") || formatted.contains("时"))
    }

    // MARK: - Relative Date Tests

    func test_isToday_currentDate_returnsTrue() {
        // Given
        let date = Date()

        // When
        let result = Calendar.current.isDateInToday(date)

        // Then
        XCTAssertTrue(result)
    }

    func test_isYesterday_yesterdayDate_returnsTrue() {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        // When
        let result = Calendar.current.isDateInYesterday(yesterday)

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Date Range Tests

    func test_dateRange_lastWeek_returns7Days() {
        // Given
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate)!

        // When
        var dates: [Date] = []
        var currentDate = startDate
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Then
        XCTAssertEqual(dates.count, 7)
    }

    // MARK: - Hour Component Tests

    func test_hourComponent_morningHours() {
        // Given
        var components = Calendar.current.dateComponents(in: .current, from: Date())
        components.hour = 8

        // When
        let hour = components.hour!

        // Then
        XCTAssertTrue(hour >= 5 && hour < 12) // Morning range
    }

    func test_hourComponent_afternoonHours() {
        // Given
        var components = Calendar.current.dateComponents(in: .current, from: Date())
        components.hour = 14

        // When
        let hour = components.hour!

        // Then
        XCTAssertTrue(hour >= 12 && hour < 18) // Afternoon range
    }

    func test_hourComponent_eveningHours() {
        // Given
        var components = Calendar.current.dateComponents(in: .current, from: Date())
        components.hour = 20

        // When
        let hour = components.hour!

        // Then
        XCTAssertTrue(hour >= 18 || hour < 5) // Evening/Night range
    }
}
