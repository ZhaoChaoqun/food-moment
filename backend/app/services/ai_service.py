"""AI food recognition service using Gemini Vision / GPT-4o / Agent Maestro."""

import base64
import json
import logging

import httpx

from app.config import settings
from app.schemas.food import (
    AnalysisResponse,
    NutritionData,
    DetectedFoodResponse,
    BoundingBox,
)

logger = logging.getLogger(__name__)

FOOD_ANALYSIS_PROMPT = """Analyze this food image and identify all food items visible.
For each food item, provide:
1. name (English)
2. name_zh (Chinese name)
3. emoji (a single emoji representing the food)
4. confidence (0.0 to 1.0)
5. bounding_box (approximate x, y, w, h as fractions of image dimensions, 0.0-1.0)
6. calories (estimated kcal for the visible portion)
7. protein_grams
8. carbs_grams
9. fat_grams

Also provide:
- total_calories: sum of all food items
- total_nutrition: { protein_g, carbs_g, fat_g, fiber_g }
- ai_analysis: a brief nutritional analysis in Chinese (2-3 sentences)
- tags: relevant tags like ["high-protein", "low-carb", "balanced", "vegetarian", etc.]

Return ONLY valid JSON in this exact format:
{
  "detected_foods": [
    {
      "name": "Grilled Chicken",
      "name_zh": "烤鸡胸",
      "emoji": "🍗",
      "confidence": 0.95,
      "bounding_box": {"x": 0.1, "y": 0.2, "w": 0.3, "h": 0.3},
      "calories": 250,
      "protein_grams": 30.0,
      "carbs_grams": 0.0,
      "fat_grams": 12.0,
      "color": "#FF6B6B"
    }
  ],
  "total_calories": 250,
  "total_nutrition": {"protein_g": 30.0, "carbs_g": 0.0, "fat_g": 12.0, "fiber_g": 2.0},
  "ai_analysis": "这顿饭蛋白质含量丰富...",
  "tags": ["high-protein"]
}"""


def _get_mock_analysis() -> dict:
    """Return mock analysis data for development when API keys are not configured."""
    return {
        "detected_foods": [
            {
                "name": "Rice",
                "name_zh": "米饭",
                "emoji": "🍚",
                "confidence": 0.92,
                "bounding_box": {"x": 0.1, "y": 0.3, "w": 0.35, "h": 0.35},
                "calories": 200,
                "protein_grams": 4.0,
                "carbs_grams": 45.0,
                "fat_grams": 0.5,
                "color": "#FFF8DC",
            },
            {
                "name": "Stir-fried Vegetables",
                "name_zh": "炒时蔬",
                "emoji": "🥦",
                "confidence": 0.88,
                "bounding_box": {"x": 0.5, "y": 0.2, "w": 0.4, "h": 0.3},
                "calories": 80,
                "protein_grams": 3.0,
                "carbs_grams": 8.0,
                "fat_grams": 5.0,
                "color": "#228B22",
            },
            {
                "name": "Braised Pork",
                "name_zh": "红烧肉",
                "emoji": "🥩",
                "confidence": 0.85,
                "bounding_box": {"x": 0.3, "y": 0.5, "w": 0.3, "h": 0.25},
                "calories": 320,
                "protein_grams": 22.0,
                "carbs_grams": 5.0,
                "fat_grams": 24.0,
                "color": "#8B4513",
            },
        ],
        "total_calories": 600,
        "total_nutrition": {
            "protein_g": 29.0,
            "carbs_g": 58.0,
            "fat_g": 29.5,
            "fiber_g": 4.0,
        },
        "ai_analysis": "这顿饭营养较为均衡，包含主食、蔬菜和蛋白质。红烧肉的脂肪含量较高，建议适量食用。蔬菜提供了良好的膳食纤维。",
        "tags": ["balanced", "chinese-cuisine", "home-cooked"],
    }


def _parse_ai_response(raw: dict) -> AnalysisResponse:
    """Parse raw AI response dict into structured AnalysisResponse."""
    detected_foods = []
    for food_data in raw.get("detected_foods", []):
        bb = food_data.get("bounding_box", {})
        detected_foods.append(
            DetectedFoodResponse(
                name=food_data.get("name", "Unknown"),
                name_zh=food_data.get("name_zh", "未知"),
                emoji=food_data.get("emoji", "🍽"),
                confidence=food_data.get("confidence", 0.5),
                bounding_box=BoundingBox(
                    x=bb.get("x", 0),
                    y=bb.get("y", 0),
                    w=bb.get("w", 0),
                    h=bb.get("h", 0),
                ),
                calories=food_data.get("calories", 0),
                protein_grams=food_data.get("protein_grams", 0),
                carbs_grams=food_data.get("carbs_grams", 0),
                fat_grams=food_data.get("fat_grams", 0),
                color=food_data.get("color", "#FF6B6B"),
            )
        )

    total_nutrition_raw = raw.get("total_nutrition", {})
    total_nutrition = NutritionData(
        protein_g=total_nutrition_raw.get("protein_g", 0),
        carbs_g=total_nutrition_raw.get("carbs_g", 0),
        fat_g=total_nutrition_raw.get("fat_g", 0),
        fiber_g=total_nutrition_raw.get("fiber_g", 0),
    )

    return AnalysisResponse(
        image_url="",
        total_calories=raw.get("total_calories", 0),
        total_nutrition=total_nutrition,
        detected_foods=detected_foods,
        ai_analysis=raw.get("ai_analysis", ""),
        tags=raw.get("tags", []),
    )


async def _analyze_with_gemini(image_data: bytes) -> dict | None:
    """Call Google Gemini Vision API to analyze food image.

    Returns:
        Parsed dict on success, None on failure
    """
    if not settings.gemini_api_key:
        return None

    try:
        b64_image = base64.b64encode(image_data).decode("utf-8")
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={settings.gemini_api_key}"

        payload = {
            "contents": [
                {
                    "parts": [
                        {"text": FOOD_ANALYSIS_PROMPT},
                        {
                            "inline_data": {
                                "mime_type": "image/jpeg",
                                "data": b64_image,
                            }
                        },
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.1,
                "maxOutputTokens": 2048,
            },
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            result = response.json()

        # Extract text from Gemini response
        text = result["candidates"][0]["content"]["parts"][0]["text"]
        # Clean up markdown code fences if present
        text = text.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        return json.loads(text)

    except Exception as e:
        logger.error(f"Gemini API call failed: {e}")
        return None


async def _analyze_with_openai(image_data: bytes) -> dict | None:
    """Call OpenAI GPT-4o API to analyze food image (fallback).

    Returns:
        Parsed dict on success, None on failure
    """
    if not settings.openai_api_key:
        return None

    try:
        b64_image = base64.b64encode(image_data).decode("utf-8")
        url = "https://api.openai.com/v1/chat/completions"

        payload = {
            "model": "gpt-4o",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": FOOD_ANALYSIS_PROMPT},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{b64_image}",
                                "detail": "high",
                            },
                        },
                    ],
                }
            ],
            "max_tokens": 2048,
            "temperature": 0.1,
        }

        headers = {
            "Authorization": f"Bearer {settings.openai_api_key}",
            "Content-Type": "application/json",
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=payload, headers=headers)
            response.raise_for_status()
            result = response.json()

        text = result["choices"][0]["message"]["content"]
        # Clean up markdown code fences if present
        text = text.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        return json.loads(text)

    except Exception as e:
        logger.error(f"OpenAI API call failed: {e}")
        return None


async def _analyze_with_agent_maestro(image_data: bytes) -> dict | None:
    """Call Agent Maestro proxy (Anthropic Claude) to analyze food image.

    Returns:
        Parsed dict on success, None on failure
    """
    if not settings.agent_maestro_enabled:
        return None

    try:
        # 检查代理是否可用
        async with httpx.AsyncClient(timeout=5.0) as client:
            try:
                health_check = await client.get("http://localhost:23333/health")
                if health_check.status_code != 200:
                    logger.warning("Agent Maestro proxy not available")
                    return None
            except Exception:
                logger.warning("Agent Maestro proxy not reachable")
                return None

        b64_image = base64.b64encode(image_data).decode("utf-8")

        payload = {
            "model": settings.agent_maestro_model,
            "max_tokens": 2048,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": b64_image,
                            },
                        },
                        {
                            "type": "text",
                            "text": FOOD_ANALYSIS_PROMPT,
                        },
                    ],
                }
            ],
        }

        headers = {
            "Content-Type": "application/json",
            "anthropic-version": "2023-06-01",
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                settings.agent_maestro_endpoint,
                json=payload,
                headers=headers,
            )
            response.raise_for_status()
            result = response.json()

        # 解析 Anthropic 响应格式
        text = ""
        for block in result.get("content", []):
            if block.get("type") == "text":
                text = block.get("text", "")
                break

        # Clean up markdown code fences if present
        text = text.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        return json.loads(text)

    except Exception as e:
        logger.error(f"Agent Maestro API call failed: {e}")
        return None


async def analyze_food_image(image_data: bytes) -> AnalysisResponse:
    """Analyze a food image using cloud AI service.

    Strategy:
    1. Try Agent Maestro proxy (Anthropic Claude) - 本地代理优先
    2. Try Gemini Vision API
    3. Fallback to GPT-4o if Gemini fails
    4. Return mock data if neither is configured
    5. Parse response into structured AnalysisResponse
    """
    # Try Agent Maestro first (本地代理)
    result = await _analyze_with_agent_maestro(image_data)

    # Try Gemini
    if result is None:
        result = await _analyze_with_gemini(image_data)

    # Fallback to OpenAI
    if result is None:
        result = await _analyze_with_openai(image_data)

    # If no AI service available, use mock data
    if result is None:
        logger.info("No AI API available, returning mock analysis data")
        result = _get_mock_analysis()

    return _parse_ai_response(result)
