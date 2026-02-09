import uuid
from datetime import datetime

from pydantic import BaseModel


class WaterLogCreate(BaseModel):
    amount_ml: int = 250


class WaterLogResponse(BaseModel):
    id: uuid.UUID
    amount_ml: int
    recorded_at: datetime

    model_config = {"from_attributes": True}


class DailyWaterResponse(BaseModel):
    date: str
    total_ml: int
    goal_ml: int = 2000
    logs: list[WaterLogResponse]
