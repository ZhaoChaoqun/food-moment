import Foundation

/// App Groups 共享数据管理器 (Widget Extension 版本)
/// 用于 Widget 读取主 App 共享的数据
final class SharedDataManager: @unchecked Sendable {
    static let shared = SharedDataManager()

    // MARK: - Constants

    static let appGroupIdentifier = "group.com.zhaochaoqun.FoodMoment"
    private static let widgetDataFileName = "widget_data.json"
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

    // MARK: - Load Widget Data

    func loadWidgetData() -> WidgetData? {
        guard let url = widgetDataURL else {
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
            print("[SharedDataManager] Failed to load widget data: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Save Widget Data (for main app)

    func saveWidgetData(_ data: WidgetData) {
        guard let url = widgetDataURL else {
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: url, options: .atomic)
        } catch {
            print("[SharedDataManager] Failed to save widget data: \(error.localizedDescription)")
        }
    }
}
