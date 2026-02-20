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

    /// 当前周中有餐食记录的日期集合（以 "yyyy-MM-dd" 字符串标识）
    var datesWithMeals: Set<String> = []

    // MARK: - Private

    private let mealService: MealServiceProtocol
    private let userService: UserServiceProtocol

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

    init(
        mealService: MealServiceProtocol = MealService.shared,
        userService: UserServiceProtocol = UserService.shared
    ) {
        self.mealService = mealService
        self.userService = userService
    }

    // MARK: - Public Methods

    /// 从 SwiftData 缓存加载（同步，立即显示）
    func loadMeals(modelContext: ModelContext) {
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

        // 同时从用户配置加载卡路里目标
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(profileDescriptor).first {
            dailyCalorieGoal = profile.dailyCalorieGoal
        }
    }

    /// 从 API 刷新数据并更新 SwiftData 缓存
    func refreshFromAPI(modelContext: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        let dateString = selectedDate.apiDateString

        // 并发启动所有请求（绿点数据独立获取，不阻塞其他逻辑）
        async let mealsTask = mealService.getMeals(date: dateString)
        async let profileTask = userService.getProfile()
        async let weekDatesTask: Void = precomputeWeekDatesFromAPI()

        // 等待绿点数据（独立，不影响其他逻辑）
        await weekDatesTask

        do {
            let (mealDTOs, profile) = try await (mealsTask, profileTask)
            dailyCalorieGoal = profile.dailyCalorieGoal

            // 清除当天旧缓存
            let startOfDay = selectedDate.startOfDay
            let endOfDay = selectedDate.endOfDay
            let predicate = #Predicate<MealRecord> { meal in
                meal.mealTime >= startOfDay && meal.mealTime <= endOfDay
            }
            let existing = (try? modelContext.fetch(FetchDescriptor<MealRecord>(predicate: predicate))) ?? []
            for record in existing {
                modelContext.delete(record)
            }

            // 将 API 数据写入 SwiftData 缓存
            for dto in mealDTOs {
                let record = MealRecord.from(dto)
                modelContext.insert(record)
            }
            try? modelContext.save()

            // 重新从 SwiftData 加载以保持一致性
            loadMeals(modelContext: modelContext)
        } catch {
            // API 失败时保持 SwiftData 缓存数据
        }
    }

    /// 删除餐食记录（先 API 后本地）
    func deleteMeal(_ meal: MealRecord, modelContext: ModelContext) async {
        // 先从 API 删除
        do {
            try await mealService.deleteMeal(id: meal.id.uuidString)
        } catch {
            // API 删除失败，不从本地删除
            return
        }

        // 成功后从本地删除
        modelContext.delete(meal)
        try? modelContext.save()
        loadMeals(modelContext: modelContext)
        await precomputeWeekDatesFromAPI()
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

    /// 检查指定日期在当前周是否有餐食记录（基于预计算缓存，无数据库查询）
    func dateHasMealsFromCache(_ date: Date) -> Bool {
        datesWithMeals.contains(date.apiDateString)
    }

    // MARK: - Helper Methods

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

    // MARK: - Private Methods

    /// 从 API 单次查询当前周有餐食记录的日期
    private func precomputeWeekDatesFromAPI() async {
        guard let weekStart = weekDates.first else { return }

        do {
            let response = try await mealService.getWeekDates(week: weekStart.apiDateString)
            datesWithMeals = Set(response.datesWithMeals)
        } catch {
            // API 失败时保持 SwiftData 缓存数据
        }
    }
}
