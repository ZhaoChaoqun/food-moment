from datetime import date, datetime, time, timedelta

from fastapi import APIRouter
from sqlalchemy import select, func

from app.schemas.stats import DailyStats, WeeklyStats, MonthlyStats, InsightResponse
from app.api.deps import CurrentUserId, DbSession
from app.models.meal import MealRecord
from app.models.water import WaterLog

router = APIRouter(prefix="/stats", tags=["Statistics"])


async def _get_daily_stats(
    db,
    user_id,
    target_date: date,
    tz_offset: int = 0,
) -> DailyStats:
    """Helper to compute daily stats for a given date.

    Args:
        tz_offset: Client timezone offset in seconds from UTC (e.g. 28800 for UTC+8).
    """
    tz_delta = timedelta(seconds=tz_offset)
    day_start = datetime.combine(target_date, time.min) - tz_delta
    day_end = datetime.combine(target_date, time.max) - tz_delta

    # Aggregate meal data
    meal_result = await db.execute(
        select(
            func.count(MealRecord.id).label("meal_count"),
            func.coalesce(func.sum(MealRecord.total_calories), 0).label("total_calories"),
            func.coalesce(func.sum(MealRecord.protein_grams), 0).label("protein_grams"),
            func.coalesce(func.sum(MealRecord.carbs_grams), 0).label("carbs_grams"),
            func.coalesce(func.sum(MealRecord.fat_grams), 0).label("fat_grams"),
            func.coalesce(func.sum(MealRecord.fiber_grams), 0).label("fiber_grams"),
        ).where(
            MealRecord.user_id == user_id,
            MealRecord.meal_time >= day_start,
            MealRecord.meal_time <= day_end,
        )
    )
    meal_row = meal_result.one()

    # Aggregate water data
    water_result = await db.execute(
        select(
            func.coalesce(func.sum(WaterLog.amount_ml), 0).label("total_ml"),
        ).where(
            WaterLog.user_id == user_id,
            WaterLog.recorded_at >= day_start,
            WaterLog.recorded_at <= day_end,
        )
    )
    water_row = water_result.one()

    return DailyStats(
        date=target_date.isoformat(),
        total_calories=int(meal_row.total_calories),
        protein_grams=float(meal_row.protein_grams),
        carbs_grams=float(meal_row.carbs_grams),
        fat_grams=float(meal_row.fat_grams),
        fiber_grams=float(meal_row.fiber_grams),
        meal_count=int(meal_row.meal_count),
        water_ml=int(water_row.total_ml),
    )


@router.get("/daily", response_model=DailyStats)
async def get_daily_stats(
    user_id: CurrentUserId,
    db: DbSession,
    date: str | None = None,
    tz_offset: int = 0,
):
    """Get daily nutrition statistics.

    Args:
        date: Date string in ISO format (YYYY-MM-DD). Defaults to today.
        tz_offset: Client timezone offset in seconds from UTC (e.g. 28800 for UTC+8).
    """
    from datetime import date as date_type

    if date:
        try:
            target_date = date_type.fromisoformat(date)
        except ValueError:
            target_date = date_type.today()
    else:
        target_date = date_type.today()

    return await _get_daily_stats(db, user_id, target_date, tz_offset)


@router.get("/weekly", response_model=WeeklyStats)
async def get_weekly_stats(
    user_id: CurrentUserId,
    db: DbSession,
    week: str | None = None,
    tz_offset: int = 0,
):
    """Get weekly nutrition statistics.

    Args:
        week: Start date of the week (YYYY-MM-DD). Defaults to current week (Monday).
        tz_offset: Client timezone offset in seconds from UTC (e.g. 28800 for UTC+8).
    """
    from datetime import date as date_type

    if week:
        try:
            week_start = date_type.fromisoformat(week)
        except ValueError:
            week_start = date_type.today() - timedelta(days=date_type.today().weekday())
    else:
        # Default to current week's Monday
        today = date_type.today()
        week_start = today - timedelta(days=today.weekday())

    week_end = week_start + timedelta(days=6)

    # Get daily stats for each day of the week
    daily_stats = []
    for i in range(7):
        day = week_start + timedelta(days=i)
        stats = await _get_daily_stats(db, user_id, day, tz_offset)
        daily_stats.append(stats)

    # Calculate averages
    days_with_data = [d for d in daily_stats if d.meal_count > 0]
    num_days = len(days_with_data) if days_with_data else 1

    total_calories = sum(d.total_calories for d in daily_stats)
    total_protein = sum(d.protein_grams for d in daily_stats)
    total_carbs = sum(d.carbs_grams for d in daily_stats)
    total_fat = sum(d.fat_grams for d in daily_stats)
    total_meals = sum(d.meal_count for d in daily_stats)

    return WeeklyStats(
        week_start=week_start.isoformat(),
        week_end=week_end.isoformat(),
        avg_calories=round(total_calories / num_days, 1),
        avg_protein=round(total_protein / num_days, 1),
        avg_carbs=round(total_carbs / num_days, 1),
        avg_fat=round(total_fat / num_days, 1),
        total_meals=total_meals,
        daily_stats=daily_stats,
    )


@router.get("/monthly", response_model=MonthlyStats)
async def get_monthly_stats(
    user_id: CurrentUserId,
    db: DbSession,
    month: str | None = None,
    tz_offset: int = 0,
):
    """Get monthly nutrition statistics.

    Args:
        month: Month string (YYYY-MM). Defaults to current month.
        tz_offset: Client timezone offset in seconds from UTC (e.g. 28800 for UTC+8).
    """
    from datetime import date as date_type
    import calendar

    if month:
        try:
            parts = month.split("-")
            year, mon = int(parts[0]), int(parts[1])
        except (ValueError, IndexError):
            today = date_type.today()
            year, mon = today.year, today.month
    else:
        today = date_type.today()
        year, mon = today.year, today.month

    # Get days in month
    _, days_in_month = calendar.monthrange(year, mon)

    # Get daily stats for each day
    daily_stats = []
    streak = 0
    max_streak = 0
    current_streak = 0

    for day_num in range(1, days_in_month + 1):
        day = date_type(year, mon, day_num)
        # Don't query future dates
        if day > date_type.today():
            break
        stats = await _get_daily_stats(db, user_id, day, tz_offset)
        daily_stats.append(stats)

        # Calculate streak
        if stats.meal_count > 0:
            current_streak += 1
            max_streak = max(max_streak, current_streak)
        else:
            current_streak = 0

    # Calculate averages
    days_with_data = [d for d in daily_stats if d.meal_count > 0]
    num_days = len(days_with_data) if days_with_data else 1

    total_calories = sum(d.total_calories for d in daily_stats)
    total_protein = sum(d.protein_grams for d in daily_stats)
    total_carbs = sum(d.carbs_grams for d in daily_stats)
    total_fat = sum(d.fat_grams for d in daily_stats)
    total_meals = sum(d.meal_count for d in daily_stats)

    return MonthlyStats(
        month=f"{year:04d}-{mon:02d}",
        avg_calories=round(total_calories / num_days, 1),
        avg_protein=round(total_protein / num_days, 1),
        avg_carbs=round(total_carbs / num_days, 1),
        avg_fat=round(total_fat / num_days, 1),
        total_meals=total_meals,
        streak_days=max_streak,
        daily_stats=daily_stats,
    )


@router.get("/insights", response_model=InsightResponse)
async def get_insights(
    user_id: CurrentUserId,
    db: DbSession,
    tz_offset: int = 0,
):
    """Get AI-powered dietary insights based on recent data.

    Analyzes the past 7 days of data to generate insights without calling an LLM.

    Args:
        tz_offset: Client timezone offset in seconds from UTC (e.g. 28800 for UTC+8).
    """
    from datetime import date as date_type

    today = date_type.today()

    # Get last 7 days of stats
    recent_stats = []
    for i in range(7):
        day = today - timedelta(days=i)
        stats = await _get_daily_stats(db, user_id, day, tz_offset)
        recent_stats.append(stats)

    days_with_data = [d for d in recent_stats if d.meal_count > 0]

    if not days_with_data:
        return InsightResponse(
            insight="Start tracking your meals to get personalized insights!",
            tips=[
                "Try to log every meal to get accurate nutritional data",
                "Use the food scanner to quickly record what you eat",
                "Set daily nutrition goals in your profile",
            ],
            calorie_trend="stable",
            protein_adequacy="adequate",
        )

    # Calculate trends
    avg_calories = sum(d.total_calories for d in days_with_data) / len(days_with_data)
    avg_protein = sum(d.protein_grams for d in days_with_data) / len(days_with_data)
    avg_carbs = sum(d.carbs_grams for d in days_with_data) / len(days_with_data)
    avg_fat = sum(d.fat_grams for d in days_with_data) / len(days_with_data)
    avg_water = sum(d.water_ml for d in days_with_data) / len(days_with_data)

    # Determine calorie trend (compare first half to second half)
    if len(days_with_data) >= 4:
        mid = len(days_with_data) // 2
        first_half_avg = sum(d.total_calories for d in days_with_data[:mid]) / mid
        second_half_avg = sum(d.total_calories for d in days_with_data[mid:]) / (len(days_with_data) - mid)
        if second_half_avg > first_half_avg * 1.1:
            calorie_trend = "up"
        elif second_half_avg < first_half_avg * 0.9:
            calorie_trend = "down"
        else:
            calorie_trend = "stable"
    else:
        calorie_trend = "stable"

    # Determine protein adequacy (50g/day is the general RDA baseline)
    if avg_protein < 40:
        protein_adequacy = "low"
    elif avg_protein > 80:
        protein_adequacy = "high"
    else:
        protein_adequacy = "adequate"

    # Generate tips
    tips = []
    if avg_protein < 50:
        tips.append("Consider adding more protein-rich foods like chicken, fish, eggs, or tofu to your meals")
    if avg_water < 1500:
        tips.append("You're not drinking enough water. Aim for at least 2000ml per day")
    if avg_fat > 75:
        tips.append("Your fat intake is on the higher side. Consider reducing fried foods and choosing lean proteins")
    if avg_carbs > 300:
        tips.append("Your carb intake is quite high. Consider replacing some refined carbs with whole grains")
    if len(days_with_data) < 5:
        tips.append("Try to log meals consistently every day for more accurate insights")
    if avg_calories < 1200:
        tips.append("Your calorie intake seems low. Make sure you're eating enough to fuel your body")
    if avg_calories > 2500:
        tips.append("Your calorie intake is above average. Consider portion control if weight loss is a goal")

    # Ensure at least 2 tips
    if len(tips) < 2:
        tips.append("Keep up the great work tracking your meals!")
        tips.append("A balanced diet includes a variety of fruits, vegetables, proteins, and whole grains")

    # Generate insight summary
    insight = (
        f"Over the past {len(days_with_data)} days, you've averaged "
        f"{int(avg_calories)} calories/day with {int(avg_protein)}g protein, "
        f"{int(avg_carbs)}g carbs, and {int(avg_fat)}g fat. "
    )
    if calorie_trend == "up":
        insight += "Your calorie intake has been trending upward recently."
    elif calorie_trend == "down":
        insight += "Your calorie intake has been decreasing - make sure you're still eating enough."
    else:
        insight += "Your calorie intake has been relatively stable."

    return InsightResponse(
        insight=insight,
        tips=tips[:5],  # Max 5 tips
        calorie_trend=calorie_trend,
        protein_adequacy=protein_adequacy,
    )
