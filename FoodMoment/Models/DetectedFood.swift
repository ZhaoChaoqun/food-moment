import Foundation
import SwiftData

/// 识别食物模型
///
/// 存储通过 AI 识别的单个食物信息，包括名称、营养成分、置信度和边界框位置。
/// 通过 `mealRecord` 关系关联到所属的餐食记录。
@Model
final class DetectedFood {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 食物英文名称
    var name: String

    /// 食物中文名称
    var nameZh: String

    /// 食物表情符号
    var emoji: String

    /// 识别置信度（0.0 - 1.0）
    var confidence: Double

    // MARK: - Bounding Box

    /// 边界框 X 坐标（归一化 0.0 - 1.0）
    var boundingBoxX: Double

    /// 边界框 Y 坐标（归一化 0.0 - 1.0）
    var boundingBoxY: Double

    /// 边界框宽度（归一化 0.0 - 1.0）
    var boundingBoxW: Double

    /// 边界框高度（归一化 0.0 - 1.0）
    var boundingBoxH: Double

    // MARK: - Nutrition

    /// 卡路里
    var calories: Int

    /// 蛋白质（克）
    var proteinGrams: Double

    /// 碳水化合物（克）
    var carbsGrams: Double

    /// 脂肪（克）
    var fatGrams: Double

    // MARK: - Relationships

    /// 所属餐食记录
    var mealRecord: MealRecord?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        nameZh: String,
        emoji: String,
        confidence: Double,
        boundingBoxX: Double,
        boundingBoxY: Double,
        boundingBoxW: Double = 0.2,
        boundingBoxH: Double = 0.2,
        calories: Int,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double
    ) {
        self.id = id
        self.name = name
        self.nameZh = nameZh
        self.emoji = emoji
        self.confidence = confidence
        self.boundingBoxX = boundingBoxX
        self.boundingBoxY = boundingBoxY
        self.boundingBoxW = boundingBoxW
        self.boundingBoxH = boundingBoxH
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
    }
}

// MARK: - Computed Properties

extension DetectedFood {

    /// 显示名称（优先使用中文名）
    var displayName: String {
        nameZh.isEmpty ? name : nameZh
    }

    /// 置信度百分比字符串
    var confidencePercentage: String {
        String(format: "%.0f%%", confidence * 100)
    }

    /// 宏量营养素总计（克）
    var totalMacros: Double {
        proteinGrams + carbsGrams + fatGrams
    }

    /// 是否高置信度（大于 80%）
    var isHighConfidence: Bool {
        confidence >= 0.8
    }
}
