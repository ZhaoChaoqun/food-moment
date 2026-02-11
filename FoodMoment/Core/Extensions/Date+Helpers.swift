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

    /// DateFormatter 缓存，避免高频调用时重复创建
    private nonisolated(unsafe) static let formatterCache: NSCache<NSString, DateFormatter> = {
        let cache = NSCache<NSString, DateFormatter>()
        cache.countLimit = 10
        return cache
    }()

    private static func cachedFormatter(for format: String) -> DateFormatter {
        let key = format as NSString
        if let cached = formatterCache.object(forKey: key) {
            return cached
        }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        formatterCache.setObject(formatter, forKey: key)
        return formatter
    }

    /// 使用指定格式格式化日期
    ///
    /// - Parameter format: 日期格式字符串
    /// - Returns: 格式化后的日期字符串
    func formatted(as format: String) -> String {
        Self.cachedFormatter(for: format).string(from: self)
    }

    /// 餐食时间字符串（HH:mm）
    var mealTimeString: String {
        formatted(as: "HH:mm")
    }

    /// 日期字符串（M月d日）
    var dayString: String {
        formatted(as: "M月d日")
    }

    /// 完整日期字符串（yyyy年M月d日）
    var fullDateString: String {
        formatted(as: "yyyy年M月d日")
    }

    /// ISO 8601 日期字符串（用于 API 请求）
    var iso8601String: String {
        formatted(as: "yyyy-MM-dd")
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
