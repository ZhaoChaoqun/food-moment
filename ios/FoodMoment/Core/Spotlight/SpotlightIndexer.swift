import Foundation
import CoreSpotlight
import CoreServices
import UniformTypeIdentifiers
import os

/// Spotlight 索引管理器
/// 将食物记录编入系统搜索
@MainActor
final class SpotlightIndexer {
    static let shared = SpotlightIndexer()

    private nonisolated static let logger = Logger(subsystem: "com.foodmoment", category: "SpotlightIndexer")

    private let domainIdentifier = "com.zhaochaoqun.FoodMoment.meals"
    private let index = CSSearchableIndex.default()

    private init() {}

    // MARK: - Index Single Meal

    /// 索引单条餐食记录
    func indexMealRecord(_ meal: MealRecord) {
        let logger = Self.logger
        let mealTitle = meal.title
        let attributeSet = createAttributeSet(for: meal)
        let uniqueIdentifier = "meal-\(meal.id.uuidString)"

        let searchableItem = CSSearchableItem(
            uniqueIdentifier: uniqueIdentifier,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )

        // 设置过期时间（30天后）
        searchableItem.expirationDate = Calendar.current.date(
            byAdding: .day,
            value: 30,
            to: Date()
        )

        index.indexSearchableItems([searchableItem]) { error in
            if let error {
                logger.error("[Spotlight] Failed to index meal: \(error.localizedDescription, privacy: .public)")
            } else {
                logger.debug("[Spotlight] Successfully indexed meal: \(mealTitle, privacy: .public)")
            }
        }
    }

    // MARK: - Index Multiple Meals

    /// 批量索引餐食记录
    func indexMealRecords(_ meals: [MealRecord]) {
        let logger = Self.logger
        let mealCount = meals.count
        let items = meals.map { meal -> CSSearchableItem in
            let attributeSet = createAttributeSet(for: meal)
            let uniqueIdentifier = "meal-\(meal.id.uuidString)"

            let item = CSSearchableItem(
                uniqueIdentifier: uniqueIdentifier,
                domainIdentifier: domainIdentifier,
                attributeSet: attributeSet
            )
            item.expirationDate = Calendar.current.date(
                byAdding: .day,
                value: 30,
                to: Date()
            )
            return item
        }

        index.indexSearchableItems(items) { error in
            if let error {
                logger.error("[Spotlight] Failed to batch index meals: \(error.localizedDescription, privacy: .public)")
            } else {
                logger.debug("[Spotlight] Successfully indexed \(mealCount, privacy: .public) meals")
            }
        }
    }

    // MARK: - Remove Index

    /// 移除单条记录的索引
    func removeMealIndex(mealId: UUID) {
        let logger = Self.logger
        let uniqueIdentifier = "meal-\(mealId.uuidString)"
        index.deleteSearchableItems(withIdentifiers: [uniqueIdentifier]) { error in
            if let error {
                logger.error("[Spotlight] Failed to remove index: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// 移除所有餐食索引
    func removeAllMealIndexes() {
        let logger = Self.logger
        index.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
            if let error {
                logger.error("[Spotlight] Failed to remove all indexes: \(error.localizedDescription, privacy: .public)")
            } else {
                logger.debug("[Spotlight] All meal indexes removed")
            }
        }
    }

    /// 重建所有索引
    func rebuildAllIndexes(meals: [MealRecord]) async {
        let logger = Self.logger
        do {
            try await index.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
            indexMealRecords(meals)
        } catch {
            logger.error("[Spotlight] Failed to clear indexes: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Create Attribute Set

    private func createAttributeSet(for meal: MealRecord) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)

        // 标题：餐次类型 + 食物名称
        let mealTypeName = MealRecord.MealType(rawValue: meal.mealType)?.displayName ?? meal.mealType
        attributeSet.title = "\(mealTypeName) - \(meal.title)"

        // 描述内容
        var description = "\(meal.totalCalories) 千卡"
        if let aiAnalysis = meal.aiAnalysis, !aiAnalysis.isEmpty {
            description += " | \(aiAnalysis)"
        }
        if let descText = meal.descriptionText, !descText.isEmpty {
            description += " | \(descText)"
        }
        attributeSet.contentDescription = description

        // 关键词：包含食物名称、标签、餐次类型
        var keywords = [meal.title, mealTypeName]
        keywords.append(contentsOf: meal.tags)

        // 添加检测到的食物名称作为关键词
        for food in meal.detectedFoods {
            keywords.append(food.name)
        }
        attributeSet.keywords = keywords

        // 日期
        attributeSet.contentCreationDate = meal.mealTime
        attributeSet.contentModificationDate = meal.createdAt

        // 缩略图（如果有本地图片数据）
        if let imageData = meal.localImageData {
            attributeSet.thumbnailData = imageData
        }

        // 其他元数据
        attributeSet.rating = NSNumber(value: min(5, Int(Double(meal.totalCalories) / 400)))
        attributeSet.supportsNavigation = true

        return attributeSet
    }

    // MARK: - Handle Spotlight Selection

    /// 处理用户从 Spotlight 点击进入
    /// 返回餐食 ID 用于导航
    static func parseMealId(from activityIdentifier: String) -> UUID? {
        guard activityIdentifier.hasPrefix("meal-") else { return nil }
        let uuidString = String(activityIdentifier.dropFirst(5))
        return UUID(uuidString: uuidString)
    }
}

// MARK: - CSSearchableItemAttributeSet Extension

extension CSSearchableItemAttributeSet {
    /// 便捷初始化方法
    static func mealAttributeSet() -> CSSearchableItemAttributeSet {
        CSSearchableItemAttributeSet(contentType: .content)
    }
}
