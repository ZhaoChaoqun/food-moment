import uuid
from datetime import datetime, timezone

from sqlalchemy import String, Boolean, Integer, Float, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    apple_user_id: Mapped[str | None] = mapped_column(String(255), unique=True, index=True, nullable=True)
    device_id: Mapped[str | None] = mapped_column(String(255), unique=True, index=True, nullable=True)
    display_name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_pro: Mapped[bool] = mapped_column(Boolean, default=False)
    daily_calorie_goal: Mapped[int] = mapped_column(Integer, default=2000)
    daily_protein_goal: Mapped[int] = mapped_column(Integer, default=50)
    daily_carbs_goal: Mapped[int] = mapped_column(Integer, default=250)
    daily_fat_goal: Mapped[int] = mapped_column(Integer, default=65)
    target_weight: Mapped[float | None] = mapped_column(Float, nullable=True)
    gender: Mapped[str | None] = mapped_column(String(20), nullable=True)
    birth_year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    height_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    activity_level: Mapped[str | None] = mapped_column(String(30), nullable=True)
    daily_water_goal: Mapped[int] = mapped_column(Integer, default=2500)
    daily_step_goal: Mapped[int] = mapped_column(Integer, default=10000)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)
