import uuid
from datetime import datetime

from pydantic import BaseModel

from app.schemas.food import DetectedFoodResponse


class DetectedFoodCreate(BaseModel):
    name: str
    name_zh: str
    emoji: str
    confidence: float
    bounding_box_x: float = 0
    bounding_box_y: float = 0
    bounding_box_w: float = 0
    bounding_box_h: float = 0
    calories: int
    protein_grams: float
    carbs_grams: float
    fat_grams: float


class MealCreate(BaseModel):
    image_url: str | None = None
    meal_type: str
    meal_time: datetime
    total_calories: int
    protein_grams: float
    carbs_grams: float
    fat_grams: float
    fiber_grams: float = 0
    title: str
    description_text: str | None = None
    ai_analysis: str | None = None
    tags: list[str] = []
    detected_foods: list[DetectedFoodCreate] = []


class MealResponse(BaseModel):
    id: uuid.UUID
    image_url: str | None
    meal_type: str
    meal_time: datetime
    total_calories: int
    protein_grams: float
    carbs_grams: float
    fat_grams: float
    fiber_grams: float
    title: str
    description_text: str | None
    ai_analysis: str | None
    tags: list[str] | None
    detected_foods: list[DetectedFoodResponse]
    created_at: datetime

    model_config = {"from_attributes": True}


class MealUpdate(BaseModel):
    meal_type: str | None = None
    meal_time: datetime | None = None
    total_calories: int | None = None
    protein_grams: float | None = None
    carbs_grams: float | None = None
    fat_grams: float | None = None
    fiber_grams: float | None = None
    title: str | None = None
    description_text: str | None = None
    tags: list[str] | None = None


class WeekDatesResponse(BaseModel):
    dates_with_meals: list[str]
