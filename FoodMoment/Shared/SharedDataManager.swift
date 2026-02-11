import Foundation
import os

/// App Groups 共享数据管理器
/// 用于主 App 与 Widget 之间共享数据
final class SharedDataManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = SharedDataManager()

    private static let logger = Logger(subsystem: "com.foodmoment", category: "SharedDataManager")

    // MARK: - Constants

    /// App Group Identifier - 需要在 Xcode 中配置
    static let appGroupIdentifier = "group.com.zhaochaoqun.FoodMoment"

    /// Widget 数据文件名
    private static let widgetDataFileName = "widget_data.json"

    /// URL Scheme
    static let urlScheme = "foodmoment"

    // MARK: - Shared Container

    private var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        )
    }

    private var widgetDataURL: URL? {
        containerURL?.appendingPathComponent(Self.widgetDataFileName)
    }

    private init() {}

    // MARK: - Widget Data Model

    struct WidgetData: Codable {
        let caloriesConsumed: Int
        let caloriesGoal: Int
        let proteinGrams: Double
        let proteinGoal: Double
        let carbsGrams: Double
        let carbsGoal: Double
        let fatGrams: Double
        let fatGoal: Double
        let waterML: Int
        let waterGoal: Int
        let mealCount: Int
        let lastUpdated: Date

        var caloriesRemaining: Int {
            max(0, caloriesGoal - caloriesConsumed)
        }

        var caloriesProgress: Double {
            guard caloriesGoal > 0 else { return 0 }
            return min(1.0, Double(caloriesConsumed) / Double(caloriesGoal))
        }

        var proteinProgress: Double {
            guard proteinGoal > 0 else { return 0 }
            return min(1.0, proteinGrams / proteinGoal)
        }

        var carbsProgress: Double {
            guard carbsGoal > 0 else { return 0 }
            return min(1.0, carbsGrams / carbsGoal)
        }

        var waterProgress: Double {
            guard waterGoal > 0 else { return 0 }
            return min(1.0, Double(waterML) / Double(waterGoal))
        }

        static let placeholder = WidgetData(
            caloriesConsumed: 1250,
            caloriesGoal: 2000,
            proteinGrams: 65,
            proteinGoal: 120,
            carbsGrams: 180,
            carbsGoal: 250,
            fatGrams: 45,
            fatGoal: 65,
            waterML: 1500,
            waterGoal: 2000,
            mealCount: 2,
            lastUpdated: Date()
        )
    }

    // MARK: - Save & Load

    /// 保存 Widget 数据（主 App 调用）
    func saveWidgetData(_ data: WidgetData) {
        guard let url = widgetDataURL else {
            Self.logger.error("Failed to get widget data URL")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: url, options: .atomic)
            Self.logger.debug("Widget data saved successfully")
        } catch {
            Self.logger.error("Failed to save widget data: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 加载 Widget 数据（Widget 调用）
    func loadWidgetData() -> WidgetData? {
        guard let url = widgetDataURL else {
            Self.logger.error("Failed to get widget data URL")
            return nil
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(WidgetData.self, from: jsonData)
        } catch {
            Self.logger.error("Failed to load widget data: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - UserDefaults (Alternative method)

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    /// 使用 UserDefaults 保存简单数据
    func saveToDefaults(key: String, value: Any) {
        sharedDefaults?.set(value, forKey: key)
    }

    func loadFromDefaults<T>(key: String) -> T? {
        sharedDefaults?.object(forKey: key) as? T
    }

    // MARK: - Keys

    enum DefaultsKey {
        static let lastScanDate = "lastScanDate"
        static let todayCalories = "todayCalories"
        static let calorieGoal = "calorieGoal"
        static let isRecordingMeal = "isRecordingMeal"
        static let recordingMealName = "recordingMealName"
        static let recordingStartTime = "recordingStartTime"
    }
}

// MARK: - Deep Link Actions

extension SharedDataManager {
    enum DeepLinkAction: String {
        case openCamera = "camera"
        case logBreakfast = "log-breakfast"
        case logLunch = "log-lunch"
        case logDinner = "log-dinner"
        case logWater = "log-water"
        case viewStats = "stats"
        case viewDiary = "diary"

        var url: URL? {
            URL(string: "\(SharedDataManager.urlScheme)://\(rawValue)")
        }
    }

    /// 解析 Deep Link
    static func parseDeepLink(_ url: URL) -> DeepLinkAction? {
        guard url.scheme == urlScheme else { return nil }
        return DeepLinkAction(rawValue: url.host ?? "")
    }
}
