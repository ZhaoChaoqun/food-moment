import logging
from datetime import datetime, time, timedelta, timezone

from fastapi import APIRouter, HTTPException, UploadFile, File, status
from sqlalchemy import select, delete, func, distinct

from app.schemas.user import (
    UserProfileResponse,
    UserProfileUpdate,
    GoalsUpdate,
    WeightLogCreate,
    WeightLogResponse,
    StreakResponse,
    AchievementResponse,
    AvatarUploadResponse,
)
from app.api.deps import CurrentUserId, DbSession
from app.models.user import User
from app.models.meal import MealRecord, DetectedFood
from app.models.water import WaterLog, WeightLog
from app.services.storage_service import storage_service

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

    user.updated_at = datetime.now(timezone.utc)
    await db.flush()

    return UserProfileResponse.model_validate(user)


@router.post("/avatar", response_model=AvatarUploadResponse)
async def upload_avatar(
    user_id: CurrentUserId,
    db: DbSession,
    image: UploadFile = File(...),
):
    """Upload user avatar image."""
    if image.content_type not in ("image/jpeg", "image/png", "image/webp"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported image format. Use JPEG, PNG, or WebP.",
        )

    image_data = await image.read()

    if len(image_data) > 5 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image too large. Maximum size is 5MB.",
        )

    avatar_url = await storage_service.upload_image(image_data, content_type=image.content_type)

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    user.avatar_url = avatar_url
    user.updated_at = datetime.now(timezone.utc)
    await db.flush()

    return AvatarUploadResponse(avatar_url=avatar_url)


@router.get("/achievements", response_model=list[AchievementResponse])
async def get_achievements(user_id: CurrentUserId, db: DbSession):
    """Get user achievements based on tracking data.

    Returns all 12 achievements aligned with iOS AchievementType definitions.
    IDs match Achievement.AchievementType.rawValue on iOS.
    """
    from datetime import date as date_type
    from sqlalchemy import case as sql_case, cast, Date, extract

    # ── Shared queries ──

    # Total meals
    total_meals = (
        await db.execute(
            select(func.count(MealRecord.id)).where(MealRecord.user_id == user_id)
        )
    ).scalar() or 0

    # Longest streak (same logic as get_streaks)
    result = await db.execute(
        select(func.date(MealRecord.meal_time).label("meal_date"))
        .where(MealRecord.user_id == user_id)
        .group_by(func.date(MealRecord.meal_time))
        .order_by(func.date(MealRecord.meal_time))
    )
    sorted_dates = [row.meal_date for row in result.all()]
    longest_streak = 0
    if sorted_dates:
        current_run = 1
        for i in range(1, len(sorted_dates)):
            if sorted_dates[i] == sorted_dates[i - 1] + timedelta(days=1):
                current_run += 1
            else:
                current_run = 1
            longest_streak = max(longest_streak, current_run)
        longest_streak = max(longest_streak, current_run)

    # User goals for macro checks
    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    calorie_goal = user.daily_calorie_goal if user else 2000
    protein_goal = user.daily_protein_goal if user else 50
    carbs_goal = user.daily_carbs_goal if user else 250
    fat_goal = user.daily_fat_goal if user else 65

    # ── Per-achievement detection ──

    # protein_hunter: cumulative protein >= 1000g
    total_protein = (
        await db.execute(
            select(func.coalesce(func.sum(MealRecord.protein_grams), 0)).where(
                MealRecord.user_id == user_id
            )
        )
    ).scalar() or 0

    # sugar_controller: days where carbs <= goal
    low_carb_days = (
        await db.execute(
            select(func.count()).select_from(
                select(
                    func.date(MealRecord.meal_time).label("d"),
                    func.sum(MealRecord.carbs_grams).label("daily_carbs"),
                )
                .where(MealRecord.user_id == user_id)
                .group_by(func.date(MealRecord.meal_time))
                .having(func.sum(MealRecord.carbs_grams) <= carbs_goal)
                .subquery()
            )
        )
    ).scalar() or 0

    # perfect_loop: days where all 3 macros within ±5% of goal
    if protein_goal > 0 and carbs_goal > 0 and fat_goal > 0:
        perfect_days = (
            await db.execute(
                select(func.count()).select_from(
                    select(func.date(MealRecord.meal_time).label("d"))
                    .where(MealRecord.user_id == user_id)
                    .group_by(func.date(MealRecord.meal_time))
                    .having(
                        func.abs(func.sum(MealRecord.protein_grams) - protein_goal)
                        <= protein_goal * 0.05
                    )
                    .having(
                        func.abs(func.sum(MealRecord.carbs_grams) - carbs_goal)
                        <= carbs_goal * 0.05
                    )
                    .having(
                        func.abs(func.sum(MealRecord.fat_grams) - fat_goal)
                        <= fat_goal * 0.05
                    )
                    .subquery()
                )
            )
        ).scalar() or 0
    else:
        perfect_days = 0

    # midnight_diner: has a meal after 22:00 with calories < 300
    midnight_meals = (
        await db.execute(
            select(func.count(MealRecord.id)).where(
                MealRecord.user_id == user_id,
                extract("hour", MealRecord.meal_time) >= 22,
                MealRecord.total_calories < 300,
            )
        )
    ).scalar() or 0

    # early_bird: days with a meal before 08:00
    early_days = (
        await db.execute(
            select(func.count(distinct(func.date(MealRecord.meal_time)))).where(
                MealRecord.user_id == user_id,
                extract("hour", MealRecord.meal_time) < 8,
            )
        )
    ).scalar() or 0

    # food_encyclopedia: distinct food names
    distinct_foods = (
        await db.execute(
            select(func.count(distinct(DetectedFood.name))).where(
                DetectedFood.meal_record_id.in_(
                    select(MealRecord.id).where(MealRecord.user_id == user_id)
                )
            )
        )
    ).scalar() or 0

    # cheat_day: days where calories > goal * 1.2
    cheat_days = (
        await db.execute(
            select(func.count()).select_from(
                select(
                    func.date(MealRecord.meal_time).label("d"),
                    func.sum(MealRecord.total_calories).label("daily_cal"),
                )
                .where(MealRecord.user_id == user_id)
                .group_by(func.date(MealRecord.meal_time))
                .having(func.sum(MealRecord.total_calories) > calorie_goal * 1.2)
                .subquery()
            )
        )
    ).scalar() or 0

    # caffeine_fix: coffee-related detected foods
    coffee_keywords = ["%coffee%", "%咖啡%", "%拿铁%", "%latte%", "%americano%", "%美式%", "%cappuccino%", "%卡布奇诺%", "%espresso%", "%摩卡%", "%mocha%"]
    coffee_conditions = [DetectedFood.name.ilike(kw) for kw in coffee_keywords]
    from sqlalchemy import or_
    caffeine_count = (
        await db.execute(
            select(func.count(DetectedFood.id)).where(
                DetectedFood.meal_record_id.in_(
                    select(MealRecord.id).where(MealRecord.user_id == user_id)
                ),
                or_(*coffee_conditions),
            )
        )
    ).scalar() or 0

    # forest_walker: distinct green vegetable names
    green_veggie_keywords = [
        "%菠菜%", "%西兰花%", "%broccoli%", "%生菜%", "%lettuce%", "%芹菜%", "%celery%",
        "%青椒%", "%黄瓜%", "%cucumber%", "%豌豆%", "%毛豆%", "%秋葵%", "%韭菜%",
        "%油菜%", "%空心菜%", "%小白菜%", "%青菜%", "%芦笋%", "%asparagus%",
        "%西葫芦%", "%zucchini%", "%四季豆%", "%荷兰豆%", "%蒜苗%", "%苦瓜%",
        "%kale%", "%羽衣甘蓝%", "%spinach%", "%green bean%",
    ]
    green_conditions = [DetectedFood.name.ilike(kw) for kw in green_veggie_keywords]
    green_veggies = (
        await db.execute(
            select(func.count(distinct(DetectedFood.name))).where(
                DetectedFood.meal_record_id.in_(
                    select(MealRecord.id).where(MealRecord.user_id == user_id)
                ),
                or_(*green_conditions),
            )
        )
    ).scalar() or 0

    # rainbow_diet: max number of color categories in a single day
    # Color categories based on food name keywords
    color_categories = {
        "red": ["%番茄%", "%草莓%", "%西瓜%", "%红椒%", "%樱桃%", "%红枣%", "%红豆%", "%辣椒%", "%tomato%", "%strawberry%"],
        "orange": ["%胡萝卜%", "%南瓜%", "%橙%", "%芒果%", "%木瓜%", "%柿子%", "%carrot%", "%pumpkin%", "%mango%", "%orange%"],
        "yellow": ["%玉米%", "%香蕉%", "%柠檬%", "%菠萝%", "%corn%", "%banana%", "%lemon%", "%pineapple%"],
        "green": ["%菠菜%", "%西兰花%", "%黄瓜%", "%生菜%", "%青椒%", "%芹菜%", "%broccoli%", "%spinach%", "%lettuce%"],
        "purple": ["%茄子%", "%蓝莓%", "%葡萄%", "%紫薯%", "%紫甘蓝%", "%eggplant%", "%blueberry%", "%grape%"],
        "white": ["%豆腐%", "%牛奶%", "%鸡蛋%", "%米饭%", "%面条%", "%馒头%", "%tofu%", "%milk%", "%egg%", "%rice%"],
        "brown": ["%牛肉%", "%猪肉%", "%鸡肉%", "%面包%", "%巧克力%", "%坚果%", "%beef%", "%pork%", "%chicken%", "%bread%"],
    }

    # For each day, count how many color categories appear
    max_colors_in_day = 0
    if total_meals > 0:
        # Get all user's detected foods with dates
        food_rows = (
            await db.execute(
                select(
                    func.date(MealRecord.meal_time).label("meal_date"),
                    DetectedFood.name,
                )
                .join(MealRecord, DetectedFood.meal_record_id == MealRecord.id)
                .where(MealRecord.user_id == user_id)
            )
        ).all()

        # Group by date and count color categories
        from collections import defaultdict
        foods_by_date: dict[object, list[str]] = defaultdict(list)
        for row in food_rows:
            foods_by_date[row.meal_date].append(row.name.lower())

        for date_key, food_names in foods_by_date.items():
            colors_found = set()
            for color, keywords in color_categories.items():
                for kw in keywords:
                    clean_kw = kw.strip("%").lower()
                    if any(clean_kw in name for name in food_names):
                        colors_found.add(color)
                        break
            max_colors_in_day = max(max_colors_in_day, len(colors_found))

    # ── Build response ──

    achievements = [
        # 习惯养成 (habit)
        {
            "id": "first_glimpse",
            "unlocked": total_meals >= 1,
            "progress": min(total_meals, 1),
            "target": 1,
            "category": "habit",
        },
        {
            "id": "streak_7day",
            "unlocked": longest_streak >= 7,
            "progress": min(longest_streak, 7),
            "target": 7,
            "category": "habit",
        },
        {
            "id": "perfect_loop",
            "unlocked": perfect_days >= 1,
            "progress": min(perfect_days, 1),
            "target": 1,
            "category": "habit",
        },
        # 营养探索 (nutrition_explorer)
        {
            "id": "protein_hunter",
            "unlocked": total_protein >= 1000,
            "progress": min(int(total_protein), 1000),
            "target": 1000,
            "category": "nutrition_explorer",
        },
        {
            "id": "forest_walker",
            "unlocked": green_veggies >= 10,
            "progress": min(green_veggies, 10),
            "target": 10,
            "category": "nutrition_explorer",
        },
        {
            "id": "rainbow_diet",
            "unlocked": max_colors_in_day >= 5,
            "progress": min(max_colors_in_day, 5),
            "target": 5,
            "category": "nutrition_explorer",
        },
        {
            "id": "sugar_controller",
            "unlocked": low_carb_days >= 7,
            "progress": min(low_carb_days, 7),
            "target": 7,
            "category": "nutrition_explorer",
        },
        # 摄影美学 (aesthetic)
        {
            "id": "midnight_diner",
            "unlocked": midnight_meals >= 1,
            "progress": min(midnight_meals, 1),
            "target": 1,
            "category": "aesthetic",
        },
        {
            "id": "early_bird",
            "unlocked": early_days >= 5,
            "progress": min(early_days, 5),
            "target": 5,
            "category": "aesthetic",
        },
        {
            "id": "food_encyclopedia",
            "unlocked": distinct_foods >= 100,
            "progress": min(distinct_foods, 100),
            "target": 100,
            "category": "aesthetic",
        },
        # 隐藏彩蛋 (easter_egg)
        {
            "id": "cheat_day",
            "unlocked": cheat_days >= 1,
            "progress": min(cheat_days, 1),
            "target": 1,
            "category": "easter_egg",
        },
        {
            "id": "caffeine_fix",
            "unlocked": caffeine_count >= 50,
            "progress": min(caffeine_count, 50),
            "target": 50,
            "category": "easter_egg",
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

    user.updated_at = datetime.now(timezone.utc)
    await db.flush()

    return {
        "daily_calorie_goal": user.daily_calorie_goal,
        "daily_protein_goal": user.daily_protein_goal,
        "daily_carbs_goal": user.daily_carbs_goal,
        "daily_fat_goal": user.daily_fat_goal,
        "daily_water_goal": user.daily_water_goal,
        "daily_step_goal": user.daily_step_goal,
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
