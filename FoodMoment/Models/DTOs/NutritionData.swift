import Foundation

/// 营养数据 DTO
///
/// 包含食物的宏量营养素信息（蛋白质、碳水化合物、脂肪、膳食纤维）。
struct NutritionDataDTO: Codable, Sendable {

    // MARK: - Properties

    /// 蛋白质（克）
    let proteinG: Double

    /// 碳水化合物（克）
    let carbsG: Double

    /// 脂肪（克）
    let fatG: Double

    /// 膳食纤维（克）
    let fiberG: Double
}

// MARK: - Computed Properties

extension NutritionDataDTO {

    /// 宏量营养素总计（克）
    var totalMacros: Double {
        proteinG + carbsG + fatG
    }

    /// 估算卡路里
    /// 蛋白质和碳水 4 kcal/g，脂肪 9 kcal/g
    var estimatedCalories: Int {
        Int(proteinG * 4 + carbsG * 4 + fatG * 9)
    }
}
