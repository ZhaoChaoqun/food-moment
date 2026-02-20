import uuid
from datetime import datetime

from pydantic import BaseModel


class UserProfileResponse(BaseModel):
    id: uuid.UUID
    display_name: str
    email: str | None
    avatar_url: str | None
    is_pro: bool
    daily_calorie_goal: int
    daily_protein_goal: int
    daily_carbs_goal: int
    daily_fat_goal: int
    target_weight: float | None
    gender: str | None = None
    birth_year: int | None = None
    height_cm: float | None = None
    activity_level: str | None = None
    daily_water_goal: int = 2500
    daily_step_goal: int = 10000
    created_at: datetime

    model_config = {"from_attributes": True}


class UserProfileUpdate(BaseModel):
    display_name: str | None = None
    avatar_url: str | None = None
    daily_calorie_goal: int | None = None
    daily_protein_goal: int | None = None
    daily_carbs_goal: int | None = None
    daily_fat_goal: int | None = None
    target_weight: float | None = None
    gender: str | None = None
    birth_year: int | None = None
    height_cm: float | None = None
    activity_level: str | None = None
    daily_water_goal: int | None = None
    daily_step_goal: int | None = None


class GoalsUpdate(BaseModel):
    daily_calorie_goal: int | None = None
    daily_protein_goal: int | None = None
    daily_carbs_goal: int | None = None
    daily_fat_goal: int | None = None
    daily_water_goal: int | None = None
    daily_step_goal: int | None = None


class WeightLogCreate(BaseModel):
    weight_kg: float
    recorded_at: datetime


class WeightLogResponse(BaseModel):
    id: uuid.UUID
    weight_kg: float
    recorded_at: datetime
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class StreakResponse(BaseModel):
    current_streak: int
    longest_streak: int
    total_days_logged: int


class AchievementResponse(BaseModel):
    id: str
    title: str
    description: str
    emoji: str
    unlocked: bool
    progress: int
    target: int


class AvatarUploadResponse(BaseModel):
    avatar_url: str
