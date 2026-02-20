import Foundation

// MARK: - Date Helpers

extension Date {

    // MARK: - Date Comparisons

    /// 日期是否为今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 日期是否为昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// 日期是否为本周
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// 日期是否为本月
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Date Boundaries

    /// 当天开始时间（00:00:00）
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 当天结束时间（23:59:59）
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            .addingTimeInterval(-1)
    }

    /// 本周开始时间
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }

    /// 本月开始时间
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }

    // MARK: - Formatting

    /// API 请求用日期字符串（yyyy-MM-dd）
    var apiDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter.string(from: self)
    }

    /// API 请求用月份字符串（yyyy-MM）
    var apiMonthString: String {
        formatted(Date.FormatStyle().year(.defaultDigits).month(.twoDigits))
            .replacingOccurrences(of: "/", with: "-")
    }

    /// 餐食时间字符串（HH:mm）
    var mealTimeString: String {
        formatted(date: .omitted, time: .shortened)
    }

    /// 日期字符串（M月d日）
    var dayString: String {
        formatted(Date.FormatStyle().month(.defaultDigits).day(.defaultDigits).locale(Locale(identifier: "zh_CN")))
    }

    /// 完整日期字符串（yyyy年M月d日）
    var fullDateString: String {
        formatted(Date.FormatStyle().year(.defaultDigits).month(.defaultDigits).day(.defaultDigits).locale(Locale(identifier: "zh_CN")))
    }

    /// 使用指定格式格式化日期（兼容旧调用点）
    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }

    /// 从 API 日期字符串（yyyy-MM-dd）解析日期
    static func fromAPIDateString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }

    // MARK: - Greeting

    /// 根据时间返回问候语
    var greetingTime: String {
        let hour = Calendar.current.component(.hour, from: self)
        switch hour {
        case 5..<12:
            return "早安"
        case 12..<14:
            return "午好"
        case 14..<18:
            return "下午好"
        default:
            return "晚好"
        }
    }

    // MARK: - Date Arithmetic

    /// 添加指定天数
    ///
    /// - Parameter days: 要添加的天数（可为负数）
    /// - Returns: 新的日期
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    /// 添加指定周数
    ///
    /// - Parameter weeks: 要添加的周数（可为负数）
    /// - Returns: 新的日期
    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self)!
    }

    /// 添加指定月数
    ///
    /// - Parameter months: 要添加的月数（可为负数）
    /// - Returns: 新的日期
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self)!
    }
}
