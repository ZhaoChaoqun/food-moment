import AppIntents
import SwiftUI
import SwiftData

// MARK: - App Shortcuts Provider

struct FoodMomentShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMealIntent(),
            phrases: [
                "记录\(.applicationName)餐食",
                "用\(.applicationName)记录早餐",
                "用\(.applicationName)记录午餐",
                "用\(.applicationName)记录晚餐",
                "\(.applicationName)拍照记录",
            ],
            shortTitle: "记录餐食",
            systemImageName: "camera.fill"
        )

        AppShortcut(
            intent: GetTodayCaloriesIntent(),
            phrases: [
                "\(.applicationName)今日卡路里",
                "查看\(.applicationName)今天摄入",
                "今天吃了多少\(.applicationName)",
            ],
            shortTitle: "今日卡路里",
            systemImageName: "flame.fill"
        )

        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "\(.applicationName)记录饮水",
                "用\(.applicationName)喝水打卡",
            ],
            shortTitle: "记录饮水",
            systemImageName: "drop.fill"
        )
    }
}

// MARK: - Meal Type Enum for Intents

enum MealTypeOption: String, AppEnum {
    case breakfast
    case lunch
    case dinner
    case snack

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "餐次类型"
    }

    static var caseDisplayRepresentations: [MealTypeOption: DisplayRepresentation] {
        [
            .breakfast: DisplayRepresentation(title: "早餐", image: .init(systemName: "sunrise.fill")),
            .lunch: DisplayRepresentation(title: "午餐", image: .init(systemName: "sun.max.fill")),
            .dinner: DisplayRepresentation(title: "晚餐", image: .init(systemName: "moon.fill")),
            .snack: DisplayRepresentation(title: "加餐", image: .init(systemName: "carrot.fill")),
        ]
    }
}

// MARK: - Log Meal Intent

struct LogMealIntent: AppIntent {
    static let title: LocalizedStringResource = "记录餐食"
    static let description = IntentDescription("打开相机拍照记录餐食")

    @Parameter(title: "餐次类型", default: .lunch)
    var mealType: MealTypeOption

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        // 通过 URL Scheme 打开对应页面
        let urlString = "foodmoment://log-\(mealType.rawValue)"
        if let url = URL(string: urlString) {
            // 存储选择的餐次类型供 App 使用
            UserDefaults.standard.set(mealType.rawValue, forKey: "pendingMealType")
        }

        return .result()
    }
}

// MARK: - Get Today Calories Intent

struct GetTodayCaloriesIntent: AppIntent {
    static let title: LocalizedStringResource = "今日卡路里"
    static let description = IntentDescription("查看今日卡路里摄入情况")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // 从 App Groups 读取数据
        let data = SharedDataManager.shared.loadWidgetData()

        let consumed = data?.caloriesConsumed ?? 0
        let goal = data?.caloriesGoal ?? 2000
        let remaining = max(0, goal - consumed)

        let resultText = "今日已摄入 \(consumed) 千卡，目标 \(goal) 千卡，剩余 \(remaining) 千卡"

        return .result(
            value: resultText,
            dialog: IntentDialog(stringLiteral: resultText)
        )
    }
}

// MARK: - Log Water Intent

enum WaterAmountOption: Int, AppEnum {
    case small = 250
    case medium = 500
    case large = 750

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "饮水量"
    }

    static var caseDisplayRepresentations: [WaterAmountOption: DisplayRepresentation] {
        [
            .small: DisplayRepresentation(title: "250 mL", subtitle: "小杯"),
            .medium: DisplayRepresentation(title: "500 mL", subtitle: "中杯"),
            .large: DisplayRepresentation(title: "750 mL", subtitle: "大杯"),
        ]
    }
}

struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "记录饮水"
    static let description = IntentDescription("记录饮水量")

    @Parameter(title: "饮水量", default: .medium)
    var amount: WaterAmountOption

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 记录到 HealthKit
        do {
            try await HealthKitManager.shared.saveWaterIntake(
                milliliters: Double(amount.rawValue),
                date: Date()
            )
        } catch {
            return .result(
                dialog: IntentDialog("饮水记录失败：\(error.localizedDescription)")
            )
        }

        return .result(
            dialog: IntentDialog("已记录 \(amount.rawValue) mL 饮水")
        )
    }
}

// MARK: - Get Nutrition Summary Intent

struct GetNutritionSummaryIntent: AppIntent {
    static let title: LocalizedStringResource = "营养摘要"
    static let description = IntentDescription("查看今日营养素摄入详情")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let data = SharedDataManager.shared.loadWidgetData()

        guard let data else {
            return .result(
                value: "暂无数据",
                dialog: IntentDialog("今日暂无饮食记录")
            )
        }

        let summary = """
        今日营养摘要：
        卡路里：\(data.caloriesConsumed)/\(data.caloriesGoal) kcal
        蛋白质：\(Int(data.proteinGrams))/\(Int(data.proteinGoal)) g
        碳水化合物：\(Int(data.carbsGrams))/\(Int(data.carbsGoal)) g
        脂肪：\(Int(data.fatGrams))/\(Int(data.fatGoal)) g
        饮水：\(data.waterML)/\(data.waterGoal) mL
        已记录 \(data.mealCount) 餐
        """

        return .result(
            value: summary,
            dialog: IntentDialog(stringLiteral: summary)
        )
    }
}

// MARK: - Quick Log Breakfast Intent

struct QuickLogBreakfastIntent: AppIntent {
    static let title: LocalizedStringResource = "记录早餐"
    static let description = IntentDescription("快速打开相机记录早餐")

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        UserDefaults.standard.set("breakfast", forKey: "pendingMealType")
        return .result()
    }
}

// MARK: - Quick Log Lunch Intent

struct QuickLogLunchIntent: AppIntent {
    static let title: LocalizedStringResource = "记录午餐"
    static let description = IntentDescription("快速打开相机记录午餐")

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        UserDefaults.standard.set("lunch", forKey: "pendingMealType")
        return .result()
    }
}

// MARK: - Quick Log Dinner Intent

struct QuickLogDinnerIntent: AppIntent {
    static let title: LocalizedStringResource = "记录晚餐"
    static let description = IntentDescription("快速打开相机记录晚餐")

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        UserDefaults.standard.set("dinner", forKey: "pendingMealType")
        return .result()
    }
}
