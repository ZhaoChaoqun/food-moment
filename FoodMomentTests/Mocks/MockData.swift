import Foundation
@testable import FoodMoment

/// Mock data for testing
enum MockData {

    // MARK: - Analysis Response
    // Note: Keys match AnalysisResponseDTO CodingKeys (snake_case for most fields)

    static let analysisResponseJSON = """
    {
        "image_url": "https://example.com/food.jpg",
        "total_calories": 485,
        "total_nutrition": {
            "protein_g": 22,
            "carbs_g": 45,
            "fat_g": 18,
            "fiber_g": 6
        },
        "detected_foods": [
            {
                "name": "Poached Egg",
                "name_zh": "水波蛋",
                "emoji": "🥚",
                "confidence": 0.95,
                "bounding_box": {"x": 0.55, "y": 0.15, "w": 0.2, "h": 0.15},
                "calories": 140,
                "protein_grams": 12,
                "carbs_grams": 1,
                "fat_grams": 10,
                "color": "#FACC15"
            },
            {
                "name": "Avocado Toast",
                "name_zh": "牛油果吐司",
                "emoji": "🥑",
                "confidence": 0.92,
                "bounding_box": {"x": 0.2, "y": 0.4, "w": 0.3, "h": 0.25},
                "calories": 345,
                "protein_grams": 10,
                "carbs_grams": 44,
                "fat_grams": 8,
                "color": "#4ADE80"
            }
        ],
        "ai_analysis": "营养均衡的一餐！牛油果提供优质脂肪，鸡蛋富含蛋白质。",
        "tags": ["高蛋白", "优质脂肪"]
    }
    """

    static var analysisResponseData: Data {
        analysisResponseJSON.data(using: .utf8)!
    }

    // MARK: - User Profile

    static let userProfileJSON = """
    {
        "id": "user_123",
        "display_name": "张三",
        "avatar_url": "https://example.com/avatar.jpg",
        "is_pro": false,
        "daily_calorie_goal": 2000,
        "daily_protein_goal": 60,
        "daily_carbs_goal": 250,
        "daily_fat_goal": 65,
        "target_weight": 65.0
    }
    """

    static var userProfileData: Data {
        userProfileJSON.data(using: .utf8)!
    }

    // MARK: - Food Search

    static let foodSearchResultJSON = """
    {
        "results": [
            {
                "id": "food_001",
                "name": "白米饭",
                "name_en": "White Rice",
                "emoji": "🍚",
                "calories_per_100g": 130,
                "protein_per_100g": 2.7,
                "carbs_per_100g": 28,
                "fat_per_100g": 0.3,
                "serving_size": 150,
                "serving_unit": "克"
            },
            {
                "id": "food_002",
                "name": "鸡胸肉",
                "name_en": "Chicken Breast",
                "emoji": "🍗",
                "calories_per_100g": 165,
                "protein_per_100g": 31,
                "carbs_per_100g": 0,
                "fat_per_100g": 3.6,
                "serving_size": 100,
                "serving_unit": "克"
            }
        ]
    }
    """

    static var foodSearchResultData: Data {
        foodSearchResultJSON.data(using: .utf8)!
    }

    // MARK: - Statistics

    static let dailyStatsJSON = """
    {
        "date": "2026-02-09",
        "total_calories": 1850,
        "total_protein": 85,
        "total_carbs": 220,
        "total_fat": 55,
        "total_fiber": 25,
        "total_water_ml": 2000,
        "meal_count": 3,
        "calorie_goal": 2000,
        "goal_percentage": 92.5
    }
    """

    static var dailyStatsData: Data {
        dailyStatsJSON.data(using: .utf8)!
    }

    // MARK: - Invalid JSON for testing error handling

    static let invalidJSON = """
    { invalid json }
    """

    static var invalidJSONData: Data {
        invalidJSON.data(using: .utf8)!
    }
}
