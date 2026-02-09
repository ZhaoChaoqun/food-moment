from fastapi import APIRouter

from app.api.v1 import auth, food, meals, stats, user, water

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(food.router)
api_router.include_router(meals.router)
api_router.include_router(stats.router)
api_router.include_router(user.router)
api_router.include_router(water.router)
