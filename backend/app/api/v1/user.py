import logging
from datetime import datetime, time, timedelta

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select, delete, func, distinct

from app.schemas.user import (
    UserProfileResponse,
    UserProfileUpdate,
    GoalsUpdate,
    WeightLogCreate,
    WeightLogResponse,
    StreakResponse,
)
from app.api.deps import CurrentUserId, DbSession
from app.models.user import User
from app.models.meal import MealRecord
from app.models.water import WaterLog, WeightLog

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/user", tags=["User"])


@router.get("/profile", response_model=UserProfileResponse)
async def get_profile(user_id: CurrentUserId, db: DbSession):
    """Get current user profile."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    return UserProfileResponse.model_validate(user)


@router.put("/profile", response_model=UserProfileResponse)
async def update_profile(
    user_id: CurrentUserId,
    db: DbSession,
    profile: UserProfileUpdate,
):
    """Update user profile.

    Only updates fields that are provided (non-None).
    """
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    update_data = profile.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)

    user.updated_at = datetime.utcnow()
    await db.flush()

    return UserProfileResponse.model_validate(user)


@router.get("/achievements")
async def get_achievements(user_id: CurrentUserId, db: DbSession):
    """Get user achievements based on tracking data.

    Returns a list of achievements with their unlock status.
    """
    from datetime import date as date_type

    # Count total meals
    meal_count_result = await db.execute(
        select(func.count(MealRecord.id)).where(MealRecord.user_id == user_id)
    )
    total_meals = meal_count_result.scalar() or 0

    # Count distinct days with meals
    days_result = await db.execute(
        select(func.count(distinct(func.date(MealRecord.meal_time)))).where(
            MealRecord.user_id == user_id
        )
    )
    total_days = days_result.scalar() or 0

    # Count total water logs
    water_result = await db.execute(
        select(func.count(WaterLog.id)).where(WaterLog.user_id == user_id)
    )
    total_water_logs = water_result.scalar() or 0

    # Define achievements
    achievements = [
        {
            "id": "first_meal",
            "title": "First Bite",
            "description": "Log your first meal",
            "emoji": "🍽",
            "unlocked": total_meals >= 1,
            "progress": min(total_meals, 1),
            "target": 1,
        },
        {
            "id": "meals_10",
            "title": "Regular Tracker",
            "description": "Log 10 meals",
            "emoji": "📝",
            "unlocked": total_meals >= 10,
            "progress": min(total_meals, 10),
            "target": 10,
        },
        {
            "id": "meals_50",
            "title": "Dedicated Tracker",
            "description": "Log 50 meals",
            "emoji": "⭐",
            "unlocked": total_meals >= 50,
            "progress": min(total_meals, 50),
            "target": 50,
        },
        {
            "id": "meals_100",
            "title": "Nutrition Expert",
            "description": "Log 100 meals",
            "emoji": "🏆",
            "unlocked": total_meals >= 100,
            "progress": min(total_meals, 100),
            "target": 100,
        },
        {
            "id": "days_7",
            "title": "Week Warrior",
            "description": "Track meals for 7 different days",
            "emoji": "📅",
            "unlocked": total_days >= 7,
            "progress": min(total_days, 7),
            "target": 7,
        },
        {
            "id": "days_30",
            "title": "Monthly Master",
            "description": "Track meals for 30 different days",
            "emoji": "🗓",
            "unlocked": total_days >= 30,
            "progress": min(total_days, 30),
            "target": 30,
        },
        {
            "id": "hydration_start",
            "title": "Stay Hydrated",
            "description": "Log water for the first time",
            "emoji": "💧",
            "unlocked": total_water_logs >= 1,
            "progress": min(total_water_logs, 1),
            "target": 1,
        },
        {
            "id": "hydration_50",
            "title": "Water Champion",
            "description": "Log water 50 times",
            "emoji": "🌊",
            "unlocked": total_water_logs >= 50,
            "progress": min(total_water_logs, 50),
            "target": 50,
        },
    ]

    return achievements


@router.put("/goals")
async def update_goals(
    user_id: CurrentUserId,
    db: DbSession,
    goals: GoalsUpdate,
):
    """Update daily nutrition goals."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    update_data = goals.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)

    user.updated_at = datetime.utcnow()
    await db.flush()

    return {
        "daily_calorie_goal": user.daily_calorie_goal,
        "daily_protein_goal": user.daily_protein_goal,
        "daily_carbs_goal": user.daily_carbs_goal,
        "daily_fat_goal": user.daily_fat_goal,
    }


@router.post("/weight", response_model=WeightLogResponse, status_code=201)
async def log_weight(
    user_id: CurrentUserId,
    db: DbSession,
    weight: WeightLogCreate,
):
    """Log a weight measurement."""
    weight_log = WeightLog(
        user_id=user_id,
        weight_kg=weight.weight_kg,
        recorded_at=weight.recorded_at,
    )
    db.add(weight_log)
    await db.flush()

    return WeightLogResponse.model_validate(weight_log)


@router.get("/streaks", response_model=StreakResponse)
async def get_streaks(user_id: CurrentUserId, db: DbSession):
    """Get user streak information.

    Calculates current streak, longest streak, and total days logged
    based on meal records.
    """
    from datetime import date as date_type

    # Get all distinct dates with meal records, ordered
    result = await db.execute(
        select(func.date(MealRecord.meal_time).label("meal_date"))
        .where(MealRecord.user_id == user_id)
        .group_by(func.date(MealRecord.meal_time))
        .order_by(func.date(MealRecord.meal_time).desc())
    )
    dates = [row.meal_date for row in result.all()]

    if not dates:
        return StreakResponse(current_streak=0, longest_streak=0, total_days_logged=0)

    total_days_logged = len(dates)

    # Calculate current streak (from today going backwards)
    today = date_type.today()
    current_streak = 0

    # Check if today or yesterday has data (allow for not having logged today yet)
    if dates and (dates[0] == today or dates[0] == today - timedelta(days=1)):
        current_streak = 1
        for i in range(1, len(dates)):
            expected_date = dates[0] - timedelta(days=i)
            if dates[i] == expected_date:
                current_streak += 1
            else:
                break

    # Calculate longest streak
    longest_streak = 1 if dates else 0
    current_run = 1

    # Sort dates ascending for longest streak calculation
    sorted_dates = sorted(dates)
    for i in range(1, len(sorted_dates)):
        if sorted_dates[i] == sorted_dates[i - 1] + timedelta(days=1):
            current_run += 1
            longest_streak = max(longest_streak, current_run)
        else:
            current_run = 1

    return StreakResponse(
        current_streak=current_streak,
        longest_streak=longest_streak,
        total_days_logged=total_days_logged,
    )


@router.delete("/account", status_code=204)
async def delete_account(user_id: CurrentUserId, db: DbSession):
    """Delete user account and all data (GDPR compliance).

    Deletes all user data including meals, water logs, weight logs,
    and the user record itself.
    """
    # Delete water logs
    await db.execute(delete(WaterLog).where(WaterLog.user_id == user_id))

    # Delete weight logs
    await db.execute(delete(WeightLog).where(WeightLog.user_id == user_id))

    # Delete meal records (cascade will delete detected_foods)
    await db.execute(delete(MealRecord).where(MealRecord.user_id == user_id))

    # Delete user
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    await db.delete(user)

    logger.info(f"User account deleted via user endpoint: {user_id}")
