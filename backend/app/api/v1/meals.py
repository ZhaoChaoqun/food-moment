import uuid
from datetime import date, datetime, time

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.schemas.meal import MealCreate, MealResponse, MealUpdate
from app.schemas.food import DetectedFoodResponse, BoundingBox
from app.api.deps import CurrentUserId, DbSession
from app.models.meal import MealRecord, DetectedFood

router = APIRouter(prefix="/meals", tags=["Meal Records"])


def _meal_to_response(meal: MealRecord) -> MealResponse:
    """Convert a MealRecord ORM model to MealResponse schema."""
    detected_foods = []
    for df in meal.detected_foods:
        detected_foods.append(
            DetectedFoodResponse(
                name=df.name,
                name_zh=df.name_zh,
                emoji=df.emoji,
                confidence=df.confidence,
                bounding_box=BoundingBox(
                    x=df.bounding_box_x,
                    y=df.bounding_box_y,
                    w=df.bounding_box_w,
                    h=df.bounding_box_h,
                ),
                calories=df.calories,
                protein_grams=df.protein_grams,
                carbs_grams=df.carbs_grams,
                fat_grams=df.fat_grams,
            )
        )

    return MealResponse(
        id=meal.id,
        image_url=meal.image_url,
        meal_type=meal.meal_type,
        meal_time=meal.meal_time,
        total_calories=meal.total_calories,
        protein_grams=meal.protein_grams,
        carbs_grams=meal.carbs_grams,
        fat_grams=meal.fat_grams,
        fiber_grams=meal.fiber_grams,
        title=meal.title,
        description_text=meal.description_text,
        ai_analysis=meal.ai_analysis,
        tags=meal.tags,
        detected_foods=detected_foods,
        created_at=meal.created_at,
    )


@router.post("", response_model=MealResponse, status_code=201)
async def create_meal(
    user_id: CurrentUserId,
    db: DbSession,
    meal: MealCreate,
):
    """Record a meal with associated detected foods."""
    # Create MealRecord
    meal_record = MealRecord(
        user_id=user_id,
        image_url=meal.image_url,
        meal_type=meal.meal_type,
        meal_time=meal.meal_time,
        total_calories=meal.total_calories,
        protein_grams=meal.protein_grams,
        carbs_grams=meal.carbs_grams,
        fat_grams=meal.fat_grams,
        fiber_grams=meal.fiber_grams,
        title=meal.title,
        description_text=meal.description_text,
        ai_analysis=meal.ai_analysis,
        tags=meal.tags if meal.tags else None,
    )
    db.add(meal_record)
    await db.flush()  # Get the meal_record.id

    # Create associated DetectedFood entries
    for food_data in meal.detected_foods:
        detected_food = DetectedFood(
            meal_record_id=meal_record.id,
            name=food_data.name,
            name_zh=food_data.name_zh,
            emoji=food_data.emoji,
            confidence=food_data.confidence,
            bounding_box_x=food_data.bounding_box_x,
            bounding_box_y=food_data.bounding_box_y,
            bounding_box_w=food_data.bounding_box_w,
            bounding_box_h=food_data.bounding_box_h,
            calories=food_data.calories,
            protein_grams=food_data.protein_grams,
            carbs_grams=food_data.carbs_grams,
            fat_grams=food_data.fat_grams,
        )
        db.add(detected_food)

    await db.flush()

    # Reload with relationships
    result = await db.execute(
        select(MealRecord)
        .options(selectinload(MealRecord.detected_foods))
        .where(MealRecord.id == meal_record.id)
    )
    meal_record = result.scalar_one()

    return _meal_to_response(meal_record)


@router.get("", response_model=list[MealResponse])
async def get_meals(
    user_id: CurrentUserId,
    db: DbSession,
    date: date | None = None,
):
    """Get meals for a specific date.

    If no date is provided, returns all meals for the user (most recent first).
    """
    query = (
        select(MealRecord)
        .options(selectinload(MealRecord.detected_foods))
        .where(MealRecord.user_id == user_id)
    )

    if date is not None:
        # Filter by date: match meal_time within the day boundary (UTC)
        day_start = datetime.combine(date, time.min)
        day_end = datetime.combine(date, time.max)
        query = query.where(
            MealRecord.meal_time >= day_start,
            MealRecord.meal_time <= day_end,
        )

    query = query.order_by(MealRecord.meal_time.desc())
    result = await db.execute(query)
    meals = result.scalars().all()

    return [_meal_to_response(m) for m in meals]


@router.put("/{meal_id}", response_model=MealResponse)
async def update_meal(
    meal_id: str,
    user_id: CurrentUserId,
    db: DbSession,
    meal: MealUpdate,
):
    """Update a meal record.

    Only updates fields that are provided (non-None).
    """
    try:
        meal_uuid = uuid.UUID(meal_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid meal ID format",
        )

    # Fetch the meal with ownership check
    result = await db.execute(
        select(MealRecord)
        .options(selectinload(MealRecord.detected_foods))
        .where(MealRecord.id == meal_uuid, MealRecord.user_id == user_id)
    )
    meal_record = result.scalar_one_or_none()

    if meal_record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Meal record not found",
        )

    # Update only provided fields
    update_data = meal.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(meal_record, field, value)

    await db.flush()

    return _meal_to_response(meal_record)


@router.delete("/{meal_id}", status_code=204)
async def delete_meal(
    meal_id: str,
    user_id: CurrentUserId,
    db: DbSession,
):
    """Delete a meal record (with ownership verification)."""
    try:
        meal_uuid = uuid.UUID(meal_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid meal ID format",
        )

    # Fetch with ownership check
    result = await db.execute(
        select(MealRecord).where(
            MealRecord.id == meal_uuid,
            MealRecord.user_id == user_id,
        )
    )
    meal_record = result.scalar_one_or_none()

    if meal_record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Meal record not found",
        )

    # cascade="all, delete-orphan" handles deleting detected_foods
    await db.delete(meal_record)
