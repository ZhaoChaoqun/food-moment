from pydantic import BaseModel


class DailyStats(BaseModel):
    date: str
    total_calories: int
    protein_grams: float
    carbs_grams: float
    fat_grams: float
    fiber_grams: float = 0
    meal_count: int
    water_ml: int


class WeeklyStats(BaseModel):
    week_start: str
    week_end: str
    avg_calories: float
    avg_protein: float = 0
    avg_carbs: float = 0
    avg_fat: float = 0
    total_meals: int
    daily_stats: list[DailyStats]


class MonthlyStats(BaseModel):
    month: str
    avg_calories: float
    avg_protein: float = 0
    avg_carbs: float = 0
    avg_fat: float = 0
    total_meals: int
    streak_days: int
    daily_stats: list[DailyStats]


class InsightResponse(BaseModel):
    insight: str
    tips: list[str]
    calorie_trend: str  # "up" / "down" / "stable"
    protein_adequacy: str  # "low" / "adequate" / "high"
