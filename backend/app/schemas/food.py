from pydantic import BaseModel


class BoundingBox(BaseModel):
    x: float
    y: float
    w: float
    h: float


class DetectedFoodResponse(BaseModel):
    name: str
    name_zh: str
    emoji: str
    confidence: float
    bounding_box: BoundingBox
    calories: int
    protein_grams: float
    carbs_grams: float
    fat_grams: float
    color: str = "#FF6B6B"


class NutritionData(BaseModel):
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: float


class AnalysisResponse(BaseModel):
    image_url: str
    total_calories: int
    total_nutrition: NutritionData
    detected_foods: list[DetectedFoodResponse]
    ai_analysis: str
    tags: list[str]


class FoodSearchResult(BaseModel):
    name: str
    name_zh: str
    calories_per_100g: int
    protein_per_100g: float
    carbs_per_100g: float
    fat_per_100g: float
    source: str = "local"


class FoodSearchResponse(BaseModel):
    query: str
    results: list[FoodSearchResult]


class BarcodeResponse(BaseModel):
    code: str
    found: bool
    food: FoodSearchResult | None = None
