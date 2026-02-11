from fastapi import APIRouter, UploadFile, File, HTTPException, status
import logging

from app.schemas.food import AnalysisResponse, FoodSearchResponse, BarcodeResponse
from app.services import ai_service, food_db_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/food", tags=["Food Recognition"])


@router.post("/analyze", response_model=AnalysisResponse)
async def analyze_food(
    image: UploadFile = File(...),
):
    """Upload a food image for AI recognition and nutrition analysis."""
    logger.info("========== /food/analyze 收到请求 ==========")
    logger.info(f"文件名: {image.filename}")
    logger.info(f"Content-Type: {image.content_type}")

    # Validate file type
    if image.content_type not in ("image/jpeg", "image/png", "image/webp"):
        logger.warning(f"不支持的图片格式: {image.content_type}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported image format. Use JPEG, PNG, or WebP.",
        )

    # Read image data
    image_data = await image.read()
    logger.info(f"读取图片数据: {len(image_data)} bytes ({len(image_data)/1024:.1f} KB)")

    # Validate size (max 10MB)
    if len(image_data) > 10 * 1024 * 1024:
        logger.warning(f"图片过大: {len(image_data)} bytes")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image too large. Maximum size is 10MB.",
        )

    # Call AI analysis service
    logger.info("调用 AI 分析服务...")
    analysis = await ai_service.analyze_food_image(image_data)

    logger.info(f"分析完成，返回 {len(analysis.detected_foods)} 种食物，总热量 {analysis.total_calories} kcal")
    logger.info("========== /food/analyze 请求完成 ==========")

    return analysis


@router.get("/barcode/{code}", response_model=BarcodeResponse)
async def lookup_barcode(code: str):
    """Look up food information by barcode.

    Searches a local barcode database. Future integration with
    Open Food Facts API is planned.
    """
    food = await food_db_service.lookup_barcode(code)
    return BarcodeResponse(
        code=code,
        found=food is not None,
        food=food,
    )


@router.get("/search", response_model=FoodSearchResponse)
async def search_food(q: str = "", limit: int = 20):
    """Search food database by name.

    Searches both English and Chinese food names in the local database.
    Future integration with USDA FoodData Central API is planned.
    """
    if not q.strip():
        return FoodSearchResponse(query=q, results=[])

    results = await food_db_service.search_food(query=q, limit=limit)
    return FoodSearchResponse(query=q, results=results)
