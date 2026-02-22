import uuid
from datetime import datetime

from pydantic import BaseModel

from app.schemas.base import AppBaseModel


class WaterLogCreate(BaseModel):
    amount_ml: int = 250


class WaterLogResponse(AppBaseModel):
    id: uuid.UUID
    amount_ml: int
    recorded_at: datetime
    created_at: datetime
    updated_at: datetime


class DailyWaterResponse(BaseModel):
    date: str
    total_ml: int
    goal_ml: int = 2000
    logs: list[WaterLogResponse]
