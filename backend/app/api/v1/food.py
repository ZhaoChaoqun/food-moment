from fastapi import APIRouter, UploadFile, File, HTTPException, status

from app.schemas.food import AnalysisResponse, FoodSearchResponse, BarcodeResponse
from app.api.deps import CurrentUserId
from app.services import ai_service, food_db_service

router = APIRouter(prefix="/food", tags=["Food Recognition"])


@router.post("/analyze", response_model=AnalysisResponse)
async def analyze_food(
    user_id: CurrentUserId,
    image: UploadFile = File(...),
):
    """Upload a food image for AI recognition and nutrition analysis.

    Accepts JPEG/PNG images. The image is analyzed using Gemini Vision API
    (primary) or GPT-4o (fallback). If no AI API key is configured,
    returns mock data for development.
    """
    # Validate file type
    if image.content_type not in ("image/jpeg", "image/png", "image/webp"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported image format. Use JPEG, PNG, or WebP.",
        )

    # Read image data
    image_data = await image.read()

    # Validate size (max 10MB)
    if len(image_data) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image too large. Maximum size is 10MB.",
        )

    # Call AI analysis service
    analysis = await ai_service.analyze_food_image(image_data)

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
