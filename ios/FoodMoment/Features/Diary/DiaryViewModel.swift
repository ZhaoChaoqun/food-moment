import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class DiaryViewModel {

    // MARK: - Properties

    var selectedDate: Date = Date()
    var searchText: String = ""
    var selectedMeal: MealRecord?
    var mealToEdit: MealRecord?

    /// 当前周中有餐食记录的日期集合（以 "yyyy-MM-dd" 字符串标识）
    var datesWithMeals: Set<String> = []

    // MARK: - Undo State

    /// 撤销 Toast 显示的消息（nil 时隐藏 Toast）
    var undoToastMessage: String?

    /// 待最终删除的餐食（撤销窗口期内保留引用）
    private var pendingDeleteMeal: MealRecord?

    /// 撤销倒计时任务
    private var undoTimerTask: Task<Void, Never>?

    // MARK: - Private

    private let mealService: MealServiceProtocol

    // MARK: - Computed Properties

    /// 当前周的 7 天日期数组（周一到周日），包含 selectedDate 所在的周
    var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = selectedDate.startOfWeek
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    /// 用于头部显示的月份/年份标题
    var monthTitle: String {
        selectedDate.formatted(as: "yyyy年M月")
    }

    // MARK: - Initialization

    init(
        mealService: MealServiceProtocol = MealService.shared
    ) {
        self.mealService = mealService
    }

    // MARK: - Public Methods

    /// 从 API 刷新数据并更新 SwiftData 缓存（Smart Merge：保护未同步的本地记录）
    func refreshFromAPI(modelContext: ModelContext) async {
        let dateString = selectedDate.apiDateString

        // 并发启动所有请求（绿点数据独立获取，不阻塞其他逻辑）
        async let mealsTask = mealService.getMeals(date: dateString)
        async let weekDatesTask: Void = precomputeWeekDatesFromAPI()

        // 等待绿点数据（独立，不影响其他逻辑）
        await weekDatesTask

        do {
            let mealDTOs = try await mealsTask
            let remoteIDs = Set(mealDTOs.map { $0.id })

            let startOfDay = selectedDate.startOfDay
            let endOfDay = selectedDate.endOfDay
            let predicate = #Predicate<MealRecord> { meal in
                meal.mealTime >= startOfDay && meal.mealTime <= endOfDay
            }
            let existing = (try? modelContext.fetch(FetchDescriptor<MealRecord>(predicate: predicate))) ?? []
            let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

            // Upsert：插入新记录或更新已同步记录
            for dto in mealDTOs {
                if let local = existingByID[dto.id] {
                    // 仅更新已同步且非待删除的记录；未同步记录保留本地版本
                    if local.isSynced && !local.pendingDeletion {
                        local.update(from: dto)
                    }
                } else {
                    modelContext.insert(MealRecord.from(dto))
                }
            }

            // 清理：只删除"已同步 + 非待删除 + 服务端已不存在"的记录
            for record in existing {
                if record.isSynced && !record.pendingDeletion && !remoteIDs.contains(record.id) {
                    modelContext.delete(record)
                }
            }

            try? modelContext.save()
        } catch {
            // API 失败时保持 SwiftData 缓存数据
        }
    }

    /// 删除餐食记录（先 API 后本地，支持离线队列）
    func deleteMeal(_ meal: MealRecord, modelContext: ModelContext) async {
        let mealTime = meal.mealTime

        do {
            try await mealService.deleteMeal(id: meal.id.uuidString)
        } catch let error as APIError where error.isNetworkError {
            // 网络错误：标记为待删除，UI 隐藏该记录
            meal.pendingDeletion = true
            try? modelContext.save()
            HapticManager.success()
            await precomputeWeekDatesFromAPI()
            return
        } catch {
            HapticManager.error()
            return
        }

        // API 成功，物理删除本地记录
        modelContext.delete(meal)
        try? modelContext.save()
        HapticManager.success()

        // 异步清理 HealthKit
        Task {
            try? await HealthKitManager.shared.deleteNutrition(at: mealTime)
        }

        await precomputeWeekDatesFromAPI()
    }

    /// 软删除餐食（乐观 UI + 3 秒撤销窗口期，用于列表滑动删除）
    func softDeleteMeal(_ meal: MealRecord, modelContext: ModelContext) {
        // 取消之前的 undo 操作（如果有）
        undoTimerTask?.cancel()

        // 保存引用用于撤销或最终删除
        pendingDeleteMeal = meal
        undoToastMessage = "\"\(meal.title)\" 已删除"

        // 乐观删除本地数据
        modelContext.delete(meal)
        try? modelContext.save()
        HapticManager.success()

        // 启动 3 秒倒计时，到期执行最终删除
        undoTimerTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await finalizeDelete()
        }
    }

    /// 撤销删除，重新插入餐食记录
    func undoDelete(modelContext: ModelContext) {
        undoTimerTask?.cancel()
        undoTimerTask = nil

        if let meal = pendingDeleteMeal {
            modelContext.insert(meal)
            try? modelContext.save()
            HapticManager.success()
        }

        pendingDeleteMeal = nil
        withAnimation(AppTheme.Animation.fastSpring) {
            undoToastMessage = nil
        }
    }

    /// 最终执行 API 删除并清理 undo 状态
    private func finalizeDelete() async {
        guard let meal = pendingDeleteMeal else { return }
        let mealTime = meal.mealTime

        do {
            try await mealService.deleteMeal(id: meal.id.uuidString)
        } catch {
            // API 失败，餐食已从本地删除；记录错误但不阻塞
        }

        // 异步清理 HealthKit
        Task {
            try? await HealthKitManager.shared.deleteNutrition(at: mealTime)
        }

        pendingDeleteMeal = nil
        withAnimation(AppTheme.Animation.fastSpring) {
            undoToastMessage = nil
        }
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
