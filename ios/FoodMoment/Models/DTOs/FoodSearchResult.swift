import Foundation

/// 食物搜索 API 响应 DTO
///
/// 包含搜索查询和匹配的食物列表。
struct FoodSearchAPIResult: Codable, Sendable {

    // MARK: - Properties

    /// 搜索关键词
    let query: String

    /// 搜索结果列表
    let results: [FoodItemDTO]
}

/// 食物条目 DTO
///
/// 食物数据库中单个食物的详细信息，包括每 100g 的营养成分和默认份量。
struct FoodItemDTO: Codable, Sendable, Identifiable {

    // MARK: - Properties

    /// 唯一标识符
    let id: String

    /// 食物英文名称
    let name: String

    /// 食物中文名称
    let nameZh: String

    /// 每 100g 卡路里
    let caloriesPer100g: Int

    /// 每 100g 蛋白质（克）
    let proteinPer100g: Double

    /// 每 100g 碳水化合物（克）
    let carbsPer100g: Double

    /// 每 100g 脂肪（克）
    let fatPer100g: Double

    /// 默认份量大小
    let servingSize: Double

    /// 份量单位
    let servingUnit: String

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nameZh = "name_zh"
        case caloriesPer100g = "calories_per_100g"
        case proteinPer100g = "protein_per_100g"
        case carbsPer100g = "carbs_per_100g"
        case fatPer100g = "fat_per_100g"
        case servingSize = "serving_size"
        case servingUnit = "serving_unit"
    }
}

// MARK: - Computed Properties

extension FoodItemDTO {

    /// 显示名称（优先使用中文名）
    var displayName: String {
        nameZh.isEmpty ? name : nameZh
    }

    /// 默认份量的卡路里
    var caloriesPerServing: Int {
        Int(Double(caloriesPer100g) * servingSize / 100.0)
    }

    /// 默认份量的蛋白质（克）
    var proteinPerServing: Double {
        proteinPer100g * servingSize / 100.0
    }

    /// 默认份量的碳水化合物（克）
    var carbsPerServing: Double {
        carbsPer100g * servingSize / 100.0
    }

    /// 默认份量的脂肪（克）
    var fatPerServing: Double {
        fatPer100g * servingSize / 100.0
    }

    /// 格式化的份量描述
    var formattedServing: String {
        if servingSize == floor(servingSize) {
            return "\(Int(servingSize)) \(servingUnit)"
        } else {
            return String(format: "%.1f %@", servingSize, servingUnit)
        }
    }
}
