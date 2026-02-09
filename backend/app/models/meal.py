import uuid
from datetime import datetime

from sqlalchemy import String, Integer, Float, DateTime, Boolean, Text, ForeignKey, ARRAY
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class MealRecord(Base):
    __tablename__ = "meal_records"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), index=True)
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    meal_type: Mapped[str] = mapped_column(String(20))  # breakfast / lunch / dinner / snack
    meal_time: Mapped[datetime] = mapped_column(DateTime, index=True)
    total_calories: Mapped[int] = mapped_column(Integer)
    protein_grams: Mapped[float] = mapped_column(Float)
    carbs_grams: Mapped[float] = mapped_column(Float)
    fat_grams: Mapped[float] = mapped_column(Float)
    fiber_grams: Mapped[float] = mapped_column(Float, default=0)
    title: Mapped[str] = mapped_column(String(200))
    description_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_analysis: Mapped[str | None] = mapped_column(Text, nullable=True)
    tags: Mapped[list[str] | None] = mapped_column(ARRAY(String), nullable=True)
    is_synced: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    detected_foods: Mapped[list["DetectedFood"]] = relationship(
        back_populates="meal_record", cascade="all, delete-orphan"
    )


class DetectedFood(Base):
    __tablename__ = "detected_foods"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    meal_record_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("meal_records.id"), index=True)
    name: Mapped[str] = mapped_column(String(100))
    name_zh: Mapped[str] = mapped_column(String(100))
    emoji: Mapped[str] = mapped_column(String(10))
    confidence: Mapped[float] = mapped_column(Float)
    bounding_box_x: Mapped[float] = mapped_column(Float)
    bounding_box_y: Mapped[float] = mapped_column(Float)
    bounding_box_w: Mapped[float] = mapped_column(Float)
    bounding_box_h: Mapped[float] = mapped_column(Float)
    calories: Mapped[int] = mapped_column(Integer)
    protein_grams: Mapped[float] = mapped_column(Float)
    carbs_grams: Mapped[float] = mapped_column(Float)
    fat_grams: Mapped[float] = mapped_column(Float)

    meal_record: Mapped["MealRecord"] = relationship(back_populates="detected_foods")
