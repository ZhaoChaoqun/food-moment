from datetime import date, datetime, time

from fastapi import APIRouter
from sqlalchemy import select, func

from app.api.deps import CurrentUserId, DbSession
from app.models.water import WaterLog
from app.schemas.water import WaterLogCreate, WaterLogResponse, DailyWaterResponse

router = APIRouter(prefix="/water", tags=["Water Tracking"])


@router.post("", response_model=WaterLogResponse, status_code=201)
async def log_water(
    user_id: CurrentUserId,
    db: DbSession,
    water: WaterLogCreate,
):
    """Log water intake.

    Args:
        amount_ml: Amount of water in milliliters (default 250ml = 1 glass)
    """
    water_log = WaterLog(
        user_id=user_id,
        amount_ml=water.amount_ml,
    )
    db.add(water_log)
    await db.flush()

    return WaterLogResponse(
        id=water_log.id,
        amount_ml=water_log.amount_ml,
        recorded_at=water_log.recorded_at,
    )


@router.get("", response_model=DailyWaterResponse)
async def get_water(
    user_id: CurrentUserId,
    db: DbSession,
    date: date | None = None,
):
    """Get water intake for a specific date.

    If no date is provided, defaults to today.
    Returns individual logs and the total for the day.
    """
    from datetime import date as date_type

    target_date = date if date is not None else date_type.today()
    day_start = datetime.combine(target_date, time.min)
    day_end = datetime.combine(target_date, time.max)

    # Query water logs for the day
    result = await db.execute(
        select(WaterLog)
        .where(
            WaterLog.user_id == user_id,
            WaterLog.recorded_at >= day_start,
            WaterLog.recorded_at <= day_end,
        )
        .order_by(WaterLog.recorded_at.asc())
    )
    logs = result.scalars().all()

    # Calculate total
    total_ml = sum(log.amount_ml for log in logs)

    return DailyWaterResponse(
        date=target_date.isoformat(),
        total_ml=total_ml,
        logs=[
            WaterLogResponse(
                id=log.id,
                amount_ml=log.amount_ml,
                recorded_at=log.recorded_at,
            )
            for log in logs
        ],
    )
