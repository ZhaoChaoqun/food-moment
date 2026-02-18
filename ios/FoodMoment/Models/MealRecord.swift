import Foundation
import SwiftData

/// 餐食记录模型
///
/// 存储用户每餐的详细信息，包括食物图片、营养成分、AI 分析结果等。
/// 通过 `detectedFoods` 关系关联识别到的具体食物。
@Model
final class MealRecord {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 餐次类型（breakfast / lunch / dinner / snack）
    var mealType: String

    /// 用餐时间
    var mealTime: Date

    /// 餐食标题
    var title: String

    /// 餐食描述（可选）
    var descriptionText: String?

    /// 总卡路里
    var totalCalories: Int

    /// 蛋白质（克）
    var proteinGrams: Double

    /// 碳水化合物（克）
    var carbsGrams: Double

    /// 脂肪（克）
    var fatGrams: Double

    /// 膳食纤维（克）
    var fiberGrams: Double

    /// AI 分析结果
    var aiAnalysis: String?

    /// 标签列表
    var tags: [String]

    // MARK: - Media

    /// 远程图片 URL
    var imageURL: String?

    /// 本地 Asset 图片名称（用于演示数据）
    var localAssetName: String?

    /// 本地图片数据（外部存储）
    @Attribute(.externalStorage) var localImageData: Data?

    // MARK: - Metadata

    /// 是否已同步到云端
    var isSynced: Bool = false

    /// 创建时间
    var createdAt: Date = Date()

    /// 更新时间
    var updatedAt: Date = Date()

    // MARK: - Relationships

    /// 识别到的食物列表
    @Relationship(deleteRule: .cascade, inverse: \DetectedFood.mealRecord)
    var detectedFoods: [DetectedFood] = []

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        mealType: String,
        mealTime: Date,
        title: String,
        descriptionText: String? = nil,
        totalCalories: Int,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double,
        fiberGrams: Double = 0,
        aiAnalysis: String? = nil,
        tags: [String] = [],
        imageURL: String? = nil,
        localAssetName: String? = nil,
        localImageData: Data? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.mealType = mealType
        self.mealTime = mealTime
        self.title = title
        self.descriptionText = descriptionText
        self.totalCalories = totalCalories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.aiAnalysis = aiAnalysis
        self.tags = tags
        self.imageURL = imageURL
        self.localAssetName = localAssetName
        self.localImageData = localImageData
        self.isSynced = isSynced
    }

    // MARK: - Nested Types

    /// 餐次枚举
    enum MealType: String, CaseIterable, Codable, Sendable {
        case breakfast
        case lunch
        case dinner
        case snack

        var displayName: String {
            switch self {
            case .breakfast: return "早餐"
            case .lunch: return "午餐"
            case .dinner: return "晚餐"
            case .snack: return "加餐"
            }
        }

        var emoji: String {
            switch self {
            case .breakfast: return "🌅"
            case .lunch: return "☀️"
            case .dinner: return "🌙"
            case .snack: return "🍪"
            }
        }
    }
}

// MARK: - Computed Properties

extension MealRecord {

    /// 获取餐次枚举值
    var mealTypeEnum: MealType? {
        MealType(rawValue: mealType)
    }

    /// 格式化的用餐时间
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: mealTime)
    }

    /// 宏量营养素总计（克）
    var totalMacros: Double {
        proteinGrams + carbsGrams + fatGrams
    }
}
