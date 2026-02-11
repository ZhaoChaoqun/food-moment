import Foundation

/// 统一 Mock 数据管理
///
/// 集中管理所有演示/原型数据，消除各 ViewModel 中的重复定义。
enum MockDataProvider {

    // MARK: - User

    enum User {
        static let displayName = "超群"
        static let avatarAssetName = "avatar_alex"
        static let isPro = true
    }

    // MARK: - Nutrition Goals

    enum NutritionGoals {
        static let dailyCalorieGoal = 1270
        static let dailyProteinGoal = 80
        static let dailyCarbsGoal = 100
        static let dailyFatGoal = 65
        static let dailyWaterGoal = 2000
        static let dailyStepGoal = 8000
    }

    // MARK: - Consumed Nutrition

    enum ConsumedNutrition {
        static let totalCalories = 1080
        static let proteinGrams: Double = 65
        static let carbsGrams: Double = 88
        static let fatGrams: Double = 54
    }

    // MARK: - Health

    enum Health {
        static let waterAmount = 1250
        static let stepCount = 5432
        static let caloriesBurned = 1200
    }

    // MARK: - Weight

    enum Weight {
        static let currentWeight = 68.0
        static let targetWeight = 65.0
        static let weightTrend = "\u{2193} 0.5kg"
    }

    // MARK: - Streak

    enum Streak {
        static let days = 12
    }

    // MARK: - Profile Calories

    enum ProfileCalories {
        static let averageCalories = 1850
        static let calorieChange = "-5%"
        static let dailyCalories = [1800, 1950, 1700, 2100, 1850, 1600, 1900]
    }

    // MARK: - Statistics

    enum Statistics {
        static let baseCalories = 2100
        static let calorieVariationRange = -300...300
        static let calorieMinClamp = 1400
        static let calorieMaxClamp = 2800
        static let checkinLookbackDays = 14

        static let aiInsights = [
            "本周蛋白质摄入偏低，建议增加鸡蛋、鸡胸肉等高蛋白食物。碳水摄入稳定，继续保持！",
            "你的饮食习惯正在改善！本周蔬菜摄入增加了 20%，继续保持均衡饮食。",
            "近期脂肪摄入略高，可以适当减少油炸食品。建议多吃蒸煮类食物。",
            "打卡连续性很好！坚持记录饮食有助于养成健康的饮食习惯。本周热量控制在合理范围内。"
        ]

        enum MacroRanges {
            static let day = (protein: 60.0...120.0, carbs: 180.0...280.0, fat: 50.0...90.0)
            static let week = (protein: 450.0...840.0, carbs: 1200.0...2000.0, fat: 350.0...630.0)
            static let month = (protein: 1800.0...3600.0, carbs: 5400.0...8400.0, fat: 1500.0...2700.0)
            static let year = (protein: 21600.0...43200.0, carbs: 64800.0...100800.0, fat: 18000.0...32400.0)
        }
    }

    // MARK: - Meals

    static func generateMockMeals() -> [MealRecord] {
        let calendar = Calendar.current
        let today = Date()

        return [
            MealRecord(
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
            ),
            MealRecord(
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
            ),
            MealRecord(
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
        ]
    }

    // MARK: - Achievements

    static func generateMockAchievements() -> [AchievementItem] {
        let allTypes = Achievement.AchievementType.allCases

        let earnedSet: [String: (tier: AchievementItem.AchievementTier, daysAgo: Int)] = [
            "first_glimpse": (.gold, 30),
            "streak_7day": (.gold, 5),
            "early_bird": (.bronze, 20),
            "forest_walker": (.silver, 12),
            "protein_hunter": (.silver, 8),
            "midnight_diner": (.bronze, 3),
            "caffeine_fix": (.bronze, 15),
        ]

        return allTypes.map { type in
            let earned = earnedSet[type.rawValue]
            return AchievementItem(
                type: type.rawValue,
                title: type.displayName,
                subtitle: type.subtitle,
                icon: type.icon,
                tier: earned?.tier ?? .bronze,
                isEarned: earned != nil,
                earnedDate: earned.map { Date().addingTimeInterval(-86400 * Double($0.daysAgo)) },
                theme: type.theme,
                category: type.category,
                isHidden: type.isHidden,
                description: type.description,
                badgeAssetName: type.badgeAssetName
            )
        }
    }

    // MARK: - Analysis

    static func generateMockAnalysis() -> AnalysisResponseDTO {
        AnalysisResponseDTO(
            imageUrl: "",
            totalCalories: 485,
            totalNutrition: NutritionDataDTO(
                proteinG: 22,
                carbsG: 45,
                fatG: 18,
                fiberG: 6
            ),
            detectedFoods: [
                DetectedFoodDTO(
                    name: "Poached Egg",
                    nameZh: "水煮蛋",
                    emoji: "\u{1F95A}",
                    confidence: 0.95,
                    boundingBox: BoundingBoxDTO(x: 0.15, y: 0.25, w: 0.25, h: 0.2),
                    calories: 140,
                    proteinGrams: 12,
                    carbsGrams: 1,
                    fatGrams: 10,
                    color: "#4ADE80"
                ),
                DetectedFoodDTO(
                    name: "Avocado",
                    nameZh: "牛油果",
                    emoji: "\u{1F951}",
                    confidence: 0.92,
                    boundingBox: BoundingBoxDTO(x: 0.55, y: 0.20, w: 0.3, h: 0.25),
                    calories: 160,
                    proteinGrams: 2,
                    carbsGrams: 9,
                    fatGrams: 15,
                    color: "#FACC15"
                ),
                DetectedFoodDTO(
                    name: "Toast",
                    nameZh: "吐司",
                    emoji: "\u{1F35E}",
                    confidence: 0.88,
                    boundingBox: BoundingBoxDTO(x: 0.30, y: 0.55, w: 0.35, h: 0.2),
                    calories: 185,
                    proteinGrams: 8,
                    carbsGrams: 35,
                    fatGrams: 2,
                    color: "#FB923C"
                )
            ],
            aiAnalysis: "A well-balanced breakfast with good protein from the poached egg and healthy fats from avocado. The toast provides sustained energy through complex carbohydrates. Consider adding leafy greens for extra vitamins and fiber.",
            tags: ["High Protein", "Healthy Fats", "Balanced"]
        )
    }
}
