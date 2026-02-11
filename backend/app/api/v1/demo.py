import logging
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter

from app.api.deps import CurrentUserId, DbSession
from app.models.meal import MealRecord, DetectedFood
from app.models.water import WaterLog, WeightLog
from sqlalchemy import select, func

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/demo", tags=["Demo"])


@router.post("/seed")
async def seed_demo_data(user_id: CurrentUserId, db: DbSession):
    """Seed demo data for development/testing.

    Idempotent: skips if user already has meal records.
    Inserts 3 demo meals, 1 water log, and 1 weight log.
    """
    # Check if user already has data (idempotent)
    meal_count_result = await db.execute(
        select(func.count(MealRecord.id)).where(MealRecord.user_id == user_id)
    )
    existing_meals = meal_count_result.scalar() or 0

    if existing_meals > 0:
        return {"seeded": False, "message": "User already has data", "meals": existing_meals}

    now = datetime.now(timezone.utc)
    today_8am = now.replace(hour=8, minute=0, second=0, microsecond=0)
    today_12pm = now.replace(hour=12, minute=30, second=0, microsecond=0)
    today_6pm = now.replace(hour=18, minute=0, second=0, microsecond=0)

    # Meal 1: 牛油果全麦吐司 (Breakfast)
    meal1 = MealRecord(
        user_id=user_id,
        meal_type="breakfast",
        meal_time=today_8am,
        total_calories=350,
        protein_grams=12.0,
        carbs_grams=38.0,
        fat_grams=18.0,
        fiber_grams=6.0,
        title="牛油果全麦吐司",
        description_text="新鲜牛油果搭配全麦吐司，撒上少许海盐和黑胡椒",
        ai_analysis="这是一份营养均衡的早餐，富含健康脂肪和膳食纤维。牛油果提供优质不饱和脂肪酸，全麦吐司提供复合碳水化合物。",
        tags=["早餐", "健康", "高纤维"],
    )
    db.add(meal1)
    await db.flush()

    db.add(DetectedFood(
        meal_record_id=meal1.id,
        name="Avocado Toast",
        name_zh="牛油果吐司",
        emoji="🥑",
        confidence=0.95,
        bounding_box_x=0.1,
        bounding_box_y=0.1,
        bounding_box_w=0.8,
        bounding_box_h=0.8,
        calories=350,
        protein_grams=12.0,
        carbs_grams=38.0,
        fat_grams=18.0,
    ))

    # Meal 2: 香煎三文鱼佐芦笋 (Lunch)
    meal2 = MealRecord(
        user_id=user_id,
        meal_type="lunch",
        meal_time=today_12pm,
        total_calories=520,
        protein_grams=42.0,
        carbs_grams=15.0,
        fat_grams=32.0,
        fiber_grams=4.0,
        title="香煎三文鱼佐芦笋",
        description_text="挪威三文鱼煎至金黄，搭配嫩烤芦笋和柠檬汁",
        ai_analysis="高蛋白低碳的优质午餐。三文鱼富含Omega-3脂肪酸，有助于心血管健康。芦笋是低热量高纤维蔬菜。",
        tags=["午餐", "高蛋白", "Omega-3"],
    )
    db.add(meal2)
    await db.flush()

    db.add(DetectedFood(
        meal_record_id=meal2.id,
        name="Grilled Salmon",
        name_zh="煎三文鱼",
        emoji="🐟",
        confidence=0.92,
        bounding_box_x=0.05,
        bounding_box_y=0.2,
        bounding_box_w=0.6,
        bounding_box_h=0.6,
        calories=420,
        protein_grams=38.0,
        carbs_grams=2.0,
        fat_grams=28.0,
    ))
    db.add(DetectedFood(
        meal_record_id=meal2.id,
        name="Asparagus",
        name_zh="芦笋",
        emoji="🌿",
        confidence=0.88,
        bounding_box_x=0.6,
        bounding_box_y=0.3,
        bounding_box_w=0.35,
        bounding_box_h=0.4,
        calories=100,
        protein_grams=4.0,
        carbs_grams=13.0,
        fat_grams=4.0,
    ))

    # Meal 3: 混合浆果奶昔 (Snack)
    meal3 = MealRecord(
        user_id=user_id,
        meal_type="snack",
        meal_time=today_6pm,
        total_calories=210,
        protein_grams=8.0,
        carbs_grams=35.0,
        fat_grams=5.0,
        fiber_grams=4.0,
        title="混合浆果奶昔",
        description_text="蓝莓、草莓、覆盆子与希腊酸奶混合而成的奶昔",
        ai_analysis="富含抗氧化物的健康零食选择。浆果类水果维生素C含量高，希腊酸奶提供优质蛋白质和益生菌。",
        tags=["零食", "抗氧化", "低脂"],
    )
    db.add(meal3)
    await db.flush()

    db.add(DetectedFood(
        meal_record_id=meal3.id,
        name="Berry Smoothie",
        name_zh="浆果奶昔",
        emoji="🫐",
        confidence=0.90,
        bounding_box_x=0.15,
        bounding_box_y=0.05,
        bounding_box_w=0.7,
        bounding_box_h=0.9,
        calories=210,
        protein_grams=8.0,
        carbs_grams=35.0,
        fat_grams=5.0,
    ))

    # Water log: 1250ml
    db.add(WaterLog(
        user_id=user_id,
        amount_ml=250,
        recorded_at=today_8am,
    ))
    db.add(WaterLog(
        user_id=user_id,
        amount_ml=500,
        recorded_at=today_12pm,
    ))
    db.add(WaterLog(
        user_id=user_id,
        amount_ml=500,
        recorded_at=today_6pm,
    ))

    # Weight log: 68.0kg
    db.add(WeightLog(
        user_id=user_id,
        weight_kg=68.0,
        recorded_at=now,
    ))

    await db.flush()

    logger.info(f"Demo data seeded for user: {user_id}")

    return {"seeded": True, "meals": 3, "water_logs": 3, "weight_logs": 1}
