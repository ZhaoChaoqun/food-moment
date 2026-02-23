import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field, field_validator

from app.schemas.base import AppBaseModel


class UserProfileResponse(AppBaseModel):
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
    birth_date: date | None = None
    height_cm: float | None = None
    activity_level: str | None = None
    daily_water_goal: int = 2500
    daily_step_goal: int = 10000
    created_at: datetime
    updated_at: datetime


class UserProfileUpdate(BaseModel):
    display_name: str | None = Field(None, min_length=1, max_length=16)
    avatar_url: str | None = None
    daily_calorie_goal: int | None = None
    daily_protein_goal: int | None = None
    daily_carbs_goal: int | None = None
    daily_fat_goal: int | None = None
    target_weight: float | None = None
    gender: str | None = None
    birth_year: int | None = None
    birth_date: date | None = None
    height_cm: float | None = None
    activity_level: str | None = None
    daily_water_goal: int | None = None
    daily_step_goal: int | None = None

    @field_validator("display_name")
    @classmethod
    def display_name_not_blank(cls, v: str | None) -> str | None:
        if v is not None and not v.strip():
            raise ValueError("昵称不能为空白字符")
        return v


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


class WeightLogResponse(AppBaseModel):
    id: uuid.UUID
    weight_kg: float
    recorded_at: datetime
    created_at: datetime
    updated_at: datetime


class StreakResponse(BaseModel):
    current_streak: int
    longest_streak: int
    total_days_logged: int


class AchievementResponse(BaseModel):
    id: str
    unlocked: bool
    progress: int
    target: int
    category: str


class AvatarUploadResponse(BaseModel):
    avatar_url: str
