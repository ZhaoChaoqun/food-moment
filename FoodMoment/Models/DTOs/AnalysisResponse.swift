import Foundation

/// 食物分析 API 响应 DTO
///
/// 包含 AI 分析的完整结果，包括识别到的食物列表、总营养成分和建议。
struct AnalysisResponseDTO: Codable, Sendable {

    // MARK: - Properties

    /// 上传图片的 URL
    let imageURL: String

    /// 总卡路里
    let totalCalories: Int

    /// 总营养成分
    let totalNutrition: NutritionDataDTO

    /// 识别到的食物列表
    let detectedFoods: [DetectedFoodDTO]

    /// AI 分析建议
    let aiAnalysis: String

    /// 标签列表
    let tags: [String]

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
        case totalCalories = "total_calories"
        case totalNutrition = "total_nutrition"
        case detectedFoods = "detected_foods"
        case aiAnalysis = "ai_analysis"
        case tags
    }
}

/// 识别食物 DTO
///
/// 单个识别食物的详细信息，包括名称、营养成分和在图片中的位置。
struct DetectedFoodDTO: Codable, Sendable, Identifiable {

    // MARK: - Properties

    /// 食物英文名称（作为标识符）
    var id: String { name }

    /// 食物英文名称
    let name: String

    /// 食物中文名称
    let nameZh: String

    /// 食物表情符号
    let emoji: String

    /// 识别置信度（0.0 - 1.0）
    let confidence: Double

    /// 边界框位置
    let boundingBox: BoundingBoxDTO

    /// 卡路里
    let calories: Int

    /// 蛋白质（克）
    let proteinGrams: Double

    /// 碳水化合物（克）
    let carbsGrams: Double

    /// 脂肪（克）
    let fatGrams: Double

    /// 显示颜色（十六进制）
    let color: String

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case name
        case nameZh = "name_zh"
        case emoji
        case confidence
        case boundingBox = "bounding_box"
        case calories
        case proteinGrams = "protein_grams"
        case carbsGrams = "carbs_grams"
        case fatGrams = "fat_grams"
        case color
    }
}

/// 边界框 DTO
///
/// 描述食物在图片中的位置，使用归一化坐标（0.0 - 1.0）。
struct BoundingBoxDTO: Codable, Sendable {

    // MARK: - Properties

    /// X 坐标（归一化）
    let x: Double

    /// Y 坐标（归一化）
    let y: Double

    /// 宽度（归一化）
    let w: Double

    /// 高度（归一化）
    let h: Double
}
