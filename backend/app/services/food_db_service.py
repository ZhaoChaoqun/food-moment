"""Food database service - local search with USDA API placeholder."""

import logging

from app.schemas.food import FoodSearchResult

logger = logging.getLogger(__name__)

# Local food database for common Chinese and Western foods
# This serves as a fallback when external APIs are unavailable
_LOCAL_FOOD_DB: list[dict] = [
    {"name": "Rice", "name_zh": "米饭", "calories_per_100g": 130, "protein_per_100g": 2.7, "carbs_per_100g": 28.2, "fat_per_100g": 0.3},
    {"name": "Noodles", "name_zh": "面条", "calories_per_100g": 138, "protein_per_100g": 4.5, "carbs_per_100g": 25.2, "fat_per_100g": 2.1},
    {"name": "Steamed Bun", "name_zh": "馒头", "calories_per_100g": 221, "protein_per_100g": 7.0, "carbs_per_100g": 44.2, "fat_per_100g": 1.1},
    {"name": "Dumpling", "name_zh": "饺子", "calories_per_100g": 240, "protein_per_100g": 10.0, "carbs_per_100g": 25.0, "fat_per_100g": 11.0},
    {"name": "Fried Rice", "name_zh": "炒饭", "calories_per_100g": 186, "protein_per_100g": 5.0, "carbs_per_100g": 25.0, "fat_per_100g": 7.0},
    {"name": "Congee", "name_zh": "粥", "calories_per_100g": 46, "protein_per_100g": 1.1, "carbs_per_100g": 9.8, "fat_per_100g": 0.2},
    {"name": "Tofu", "name_zh": "豆腐", "calories_per_100g": 76, "protein_per_100g": 8.1, "carbs_per_100g": 1.9, "fat_per_100g": 4.2},
    {"name": "Chicken Breast", "name_zh": "鸡胸肉", "calories_per_100g": 165, "protein_per_100g": 31.0, "carbs_per_100g": 0.0, "fat_per_100g": 3.6},
    {"name": "Pork Belly", "name_zh": "五花肉", "calories_per_100g": 518, "protein_per_100g": 9.3, "carbs_per_100g": 0.0, "fat_per_100g": 53.0},
    {"name": "Beef", "name_zh": "牛肉", "calories_per_100g": 250, "protein_per_100g": 26.0, "carbs_per_100g": 0.0, "fat_per_100g": 15.0},
    {"name": "Salmon", "name_zh": "三文鱼", "calories_per_100g": 208, "protein_per_100g": 20.0, "carbs_per_100g": 0.0, "fat_per_100g": 13.0},
    {"name": "Shrimp", "name_zh": "虾", "calories_per_100g": 99, "protein_per_100g": 24.0, "carbs_per_100g": 0.2, "fat_per_100g": 0.3},
    {"name": "Egg", "name_zh": "鸡蛋", "calories_per_100g": 155, "protein_per_100g": 13.0, "carbs_per_100g": 1.1, "fat_per_100g": 11.0},
    {"name": "Milk", "name_zh": "牛奶", "calories_per_100g": 42, "protein_per_100g": 3.4, "carbs_per_100g": 5.0, "fat_per_100g": 1.0},
    {"name": "Yogurt", "name_zh": "酸奶", "calories_per_100g": 59, "protein_per_100g": 3.5, "carbs_per_100g": 7.0, "fat_per_100g": 1.5},
    {"name": "Broccoli", "name_zh": "西兰花", "calories_per_100g": 34, "protein_per_100g": 2.8, "carbs_per_100g": 7.0, "fat_per_100g": 0.4},
    {"name": "Spinach", "name_zh": "菠菜", "calories_per_100g": 23, "protein_per_100g": 2.9, "carbs_per_100g": 3.6, "fat_per_100g": 0.4},
    {"name": "Tomato", "name_zh": "番茄", "calories_per_100g": 18, "protein_per_100g": 0.9, "carbs_per_100g": 3.9, "fat_per_100g": 0.2},
    {"name": "Potato", "name_zh": "土豆", "calories_per_100g": 77, "protein_per_100g": 2.0, "carbs_per_100g": 17.0, "fat_per_100g": 0.1},
    {"name": "Sweet Potato", "name_zh": "红薯", "calories_per_100g": 86, "protein_per_100g": 1.6, "carbs_per_100g": 20.0, "fat_per_100g": 0.1},
    {"name": "Apple", "name_zh": "苹果", "calories_per_100g": 52, "protein_per_100g": 0.3, "carbs_per_100g": 14.0, "fat_per_100g": 0.2},
    {"name": "Banana", "name_zh": "香蕉", "calories_per_100g": 89, "protein_per_100g": 1.1, "carbs_per_100g": 23.0, "fat_per_100g": 0.3},
    {"name": "Orange", "name_zh": "橙子", "calories_per_100g": 47, "protein_per_100g": 0.9, "carbs_per_100g": 12.0, "fat_per_100g": 0.1},
    {"name": "Bread", "name_zh": "面包", "calories_per_100g": 265, "protein_per_100g": 9.0, "carbs_per_100g": 49.0, "fat_per_100g": 3.2},
    {"name": "Pizza", "name_zh": "披萨", "calories_per_100g": 266, "protein_per_100g": 11.0, "carbs_per_100g": 33.0, "fat_per_100g": 10.0},
    {"name": "Hamburger", "name_zh": "汉堡", "calories_per_100g": 295, "protein_per_100g": 17.0, "carbs_per_100g": 24.0, "fat_per_100g": 14.0},
    {"name": "Stir-fried Vegetables", "name_zh": "炒时蔬", "calories_per_100g": 65, "protein_per_100g": 2.5, "carbs_per_100g": 6.0, "fat_per_100g": 4.0},
    {"name": "Hot and Sour Soup", "name_zh": "酸辣汤", "calories_per_100g": 35, "protein_per_100g": 2.0, "carbs_per_100g": 4.0, "fat_per_100g": 1.0},
    {"name": "Mapo Tofu", "name_zh": "麻婆豆腐", "calories_per_100g": 112, "protein_per_100g": 7.5, "carbs_per_100g": 4.0, "fat_per_100g": 7.5},
    {"name": "Kung Pao Chicken", "name_zh": "宫保鸡丁", "calories_per_100g": 180, "protein_per_100g": 16.0, "carbs_per_100g": 10.0, "fat_per_100g": 9.0},
]


async def search_food(query: str, limit: int = 20) -> list[FoodSearchResult]:
    """Search food database by name.

    Searches both English name and Chinese name.
    Uses local database first, with USDA API as a future extension.

    Args:
        query: Search query string
        limit: Maximum number of results

    Returns:
        List of matching FoodSearchResult
    """
    if not query or not query.strip():
        return []

    query_lower = query.lower().strip()
    results: list[FoodSearchResult] = []

    for food in _LOCAL_FOOD_DB:
        # Match against English name or Chinese name
        if (
            query_lower in food["name"].lower()
            or query_lower in food["name_zh"]
        ):
            results.append(
                FoodSearchResult(
                    name=food["name"],
                    name_zh=food["name_zh"],
                    calories_per_100g=food["calories_per_100g"],
                    protein_per_100g=food["protein_per_100g"],
                    carbs_per_100g=food["carbs_per_100g"],
                    fat_per_100g=food["fat_per_100g"],
                    source="local",
                )
            )
            if len(results) >= limit:
                break

    # TODO: If local results are insufficient, query USDA FoodData Central API
    # url = f"https://api.nal.usda.gov/fdc/v1/foods/search?query={query}&api_key={usda_api_key}"

    return results
