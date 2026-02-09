import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class DiaryViewModel {

    // MARK: - Properties

    var selectedDate: Date = Date()
    var meals: [MealRecord] = []
    var searchText: String = ""
    var isLoading = false
    var dailyCalorieGoal: Int = 2000
    var selectedMeal: MealRecord?
    var mealToEdit: MealRecord?

    // MARK: - Computed Properties

    /// 当前周的 7 天日期数组（周一到周日），包含 selectedDate 所在的周
    var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = selectedDate.startOfWeek
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    /// 选中日期的总摄入卡路里
    var dailyCalories: Int {
        meals.reduce(0) { $0 + $1.totalCalories }
    }

    /// 每日进度比例（0.0 - 1.0+）
    var dailyProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0 }
        return Double(dailyCalories) / Double(dailyCalorieGoal)
    }

    /// 每日蛋白质总量
    var dailyProtein: Double {
        meals.reduce(0) { $0 + $1.proteinGrams }
    }

    /// 每日碳水总量
    var dailyCarbs: Double {
        meals.reduce(0) { $0 + $1.carbsGrams }
    }

    /// 每日脂肪总量
    var dailyFat: Double {
        meals.reduce(0) { $0 + $1.fatGrams }
    }

    /// 按搜索文本过滤并按用餐时间升序排列的餐食列表
    var filteredMeals: [MealRecord] {
        let sorted = meals.sorted { $0.mealTime < $1.mealTime }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { meal in
            meal.title.localizedCaseInsensitiveContains(searchText)
                || (meal.descriptionText?.localizedCaseInsensitiveContains(searchText) ?? false)
                || meal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    /// 用于头部显示的月份/年份标题
    var monthTitle: String {
        selectedDate.formatted(as: "yyyy年M月")
    }

    // MARK: - Initialization

    init() {
        // 轻量级初始化，避免耗时操作
    }

    // MARK: - Public Methods

    /// 从 SwiftData 加载选中日期的餐食记录
    /// 当数据库为空时，自动加载演示数据
    func loadMeals(modelContext: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        let startOfDay = selectedDate.startOfDay
        let endOfDay = selectedDate.endOfDay

        let predicate = #Predicate<MealRecord> { meal in
            meal.mealTime >= startOfDay && meal.mealTime <= endOfDay
        }
        let descriptor = FetchDescriptor<MealRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.mealTime, order: .forward)]
        )

        do {
            meals = try modelContext.fetch(descriptor)

            // 如果当天没有数据且是今天，加载演示数据
            if meals.isEmpty && Calendar.current.isDateInToday(selectedDate) {
                loadDemoDataIfNeeded(modelContext: modelContext)
            }
        } catch {
            meals = []
        }

        // 同时从用户配置加载卡路里目标
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(profileDescriptor).first {
            dailyCalorieGoal = profile.dailyCalorieGoal
        }
    }

    /// 加载演示数据（仅当数据库完全为空时）
    private func loadDemoDataIfNeeded(modelContext: ModelContext) {
        // 检查数据库是否完全为空
        let countDescriptor = FetchDescriptor<MealRecord>()
        let totalCount = (try? modelContext.fetchCount(countDescriptor)) ?? 0

        // 只有数据库完全为空时才插入演示数据
        guard totalCount == 0 else { return }

        let mockMeals = Self.generateMockMeals()
        for meal in mockMeals {
            modelContext.insert(meal)
        }

        // 设置演示模式的卡路里目标（使进度显示约 85%）
        // 总摄入 1080 kcal，目标 1270 kcal ≈ 85%
        dailyCalorieGoal = 1270

        try? modelContext.save()

        // 重新加载当天数据
        let startOfDay = selectedDate.startOfDay
        let endOfDay = selectedDate.endOfDay
        let predicate = #Predicate<MealRecord> { meal in
            meal.mealTime >= startOfDay && meal.mealTime <= endOfDay
        }
        let descriptor = FetchDescriptor<MealRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.mealTime, order: .forward)]
        )
        meals = (try? modelContext.fetch(descriptor)) ?? []
    }

    /// 删除餐食记录
    func deleteMeal(_ meal: MealRecord, modelContext: ModelContext) {
        modelContext.delete(meal)
        try? modelContext.save()
        loadMeals(modelContext: modelContext)
    }

    /// 选择指定日期
    func selectDate(_ date: Date) {
        selectedDate = date
    }

    /// 导航到上一周
    func previousWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }

    /// 导航到下一周
    func nextWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }

    // MARK: - Helper Methods

    /// 检查指定日期是否有餐食记录（用于指示点显示）
    func dateHasMeals(_ date: Date, modelContext: ModelContext) -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?
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

    /// 从 MealRecord 的原始字符串解析 MealType
    static func mealType(for record: MealRecord) -> MealRecord.MealType {
        MealRecord.MealType(rawValue: record.mealType) ?? .snack
    }

    /// 获取餐食类型对应的颜色
    static func mealColor(for record: MealRecord) -> Color {
        let type = mealType(for: record)
        switch type {
        case .breakfast: return AppTheme.Colors.breakfast
        case .lunch: return AppTheme.Colors.lunch
        case .dinner: return AppTheme.Colors.dinner
        case .snack: return AppTheme.Colors.snack
        }
    }

    // MARK: - Mock Data

    /// 生成模拟餐食数据，用于 UI 开发和预览
    /// 数据基于原型图设计，展示典型的一日饮食记录
    static func generateMockMeals() -> [MealRecord] {
        let calendar = Calendar.current
        let today = Date()

        // 早餐 08:30 - 牛油果全麦吐司 (350 kcal)
        let breakfast = MealRecord(
            mealType: MealRecord.MealType.breakfast.rawValue,
            mealTime: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: today)!,
            title: "牛油果全麦吐司",
            descriptionText: "新鲜牛油果搭配全麦吐司和溏心蛋，营养均衡的早餐选择",
            totalCalories: 350,
            proteinGrams: 15,
            carbsGrams: 38,
            fatGrams: 18,
            fiberGrams: 6,
            aiAnalysis: "健康的早餐组合，富含健康脂肪和复合碳水化合物",
            tags: ["高蛋白", "低GI"],
            localAssetName: "meal_avocado_toast"
        )

        // 午餐 12:30 - 香煎三文鱼佐芦笋 (520 kcal)
        let lunch = MealRecord(
            mealType: MealRecord.MealType.lunch.rawValue,
            mealTime: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
            title: "香煎三文鱼佐芦笋",
            descriptionText: "挪威三文鱼配新鲜芦笋，富含Omega-3脂肪酸",
            totalCalories: 520,
            proteinGrams: 42,
            carbsGrams: 15,
            fatGrams: 32,
            fiberGrams: 4,
            aiAnalysis: "优质蛋白质来源，Omega-3有助于心脑血管健康",
            tags: ["Omega-3", "无麸质"],
            localAssetName: "meal_salmon"
        )

        // 加餐 15:45 - 混合浆果奶昔 (210 kcal)
        let snack = MealRecord(
            mealType: MealRecord.MealType.snack.rawValue,
            mealTime: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: today)!,
            title: "混合浆果奶昔",
            descriptionText: "蓝莓、草莓、覆盆子搭配希腊酸奶",
            totalCalories: 210,
            proteinGrams: 8,
            carbsGrams: 35,
            fatGrams: 4,
            fiberGrams: 5,
            aiAnalysis: "富含抗氧化物质的健康加餐",
            tags: ["抗氧化", "低脂"],
            localAssetName: "meal_berry_smoothie"
        )

        return [breakfast, lunch, snack]
    }
}
