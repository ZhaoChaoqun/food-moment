"""AI food recognition service using Anthropic Claude."""

import base64
import io
import json
import logging

import httpx
from PIL import Image

from app.config import settings
from app.schemas.food import (
    AnalysisResponse,
    NutritionData,
    DetectedFoodResponse,
    BoundingBox,
)

logger = logging.getLogger(__name__)


def _resize_image(image_data: bytes, max_size: int = 768, quality: int = 60) -> bytes:
    """Resize and compress image to reduce token usage.

    Claude vision recommends images ≤ 1568px per side.
    768px balances quality and token cost (~786 tokens).
    """
    try:
        img = Image.open(io.BytesIO(image_data))

        # Convert to RGB if necessary
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")

        # Resize if larger than max_size
        if max(img.size) > max_size:
            img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)

        # Save to bytes with compression
        buffer = io.BytesIO()
        img.save(buffer, format="JPEG", quality=quality, optimize=True)
        return buffer.getvalue()
    except Exception as e:
        logger.warning(f"Failed to resize image: {e}")
        return image_data


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
10. color (a unique hex color for each food item, use visually distinct colors)

Also provide:
- meal_name: a concise Chinese name for this meal (2-6 characters), summarizing the main dish. Do NOT list all foods. Examples: "烤鸡饭", "蛋糕", "水饺", "牛肉面"
- total_calories: sum of all food items
- total_nutrition: { protein_g, carbs_g, fat_g, fiber_g }
- ai_analysis: a brief nutritional analysis in Chinese (2-3 sentences)
- tags: relevant tags IN CHINESE like ["高蛋白", "低碳水", "营养均衡", "素食", "低卡路里", "高纤维", "低脂", "生酮友好", "中式家常", "轻食"]

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
    },
    {
      "name": "White Rice",
      "name_zh": "白米饭",
      "emoji": "🍚",
      "confidence": 0.90,
      "bounding_box": {"x": 0.5, "y": 0.3, "w": 0.3, "h": 0.3},
      "calories": 200,
      "protein_grams": 4.0,
      "carbs_grams": 45.0,
      "fat_grams": 0.5,
      "color": "#4ECDC4"
    }
  ],
  "total_calories": 450,
  "meal_name": "烤鸡饭",
  "total_nutrition": {"protein_g": 34.0, "carbs_g": 45.0, "fat_g": 12.5, "fiber_g": 2.0},
  "ai_analysis": "这顿饭蛋白质含量丰富...",
  "tags": ["高蛋白"]
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
        "meal_name": "红烧肉饭",
        "total_nutrition": {
            "protein_g": 29.0,
            "carbs_g": 58.0,
            "fat_g": 29.5,
            "fiber_g": 4.0,
        },
        "ai_analysis": "这顿饭营养较为均衡，包含主食、蔬菜和蛋白质。红烧肉的脂肪含量较高，建议适量食用。蔬菜提供了良好的膳食纤维。",
        "tags": ["营养均衡", "中式家常", "家常菜"],
    }


_FOOD_COLORS = [
    "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
    "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
    "#BB8FCE", "#85C1E9", "#F0B27A", "#82E0AA",
]


def _parse_ai_response(raw: dict) -> AnalysisResponse:
    """Parse raw AI response dict into structured AnalysisResponse."""
    detected_foods = []
    for i, food_data in enumerate(raw.get("detected_foods", [])):
        bb = food_data.get("bounding_box", {})
        color = food_data.get("color") or _FOOD_COLORS[i % len(_FOOD_COLORS)]
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
                color=color,
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
        meal_name=raw.get("meal_name"),
        total_nutrition=total_nutrition,
        detected_foods=detected_foods,
        ai_analysis=raw.get("ai_analysis", ""),
        tags=raw.get("tags", []),
    )


async def _analyze_with_anthropic(image_data: bytes) -> dict | None:
    """Call Anthropic Claude API (via proxy) to analyze food image.

    Returns:
        Parsed dict on success, None on failure
    """
    if not settings.anthropic_enabled:
        logger.info("Anthropic Claude 未启用")
        return None

    try:
        resized_image = _resize_image(image_data)
        b64_image = base64.b64encode(resized_image).decode("utf-8")
        logger.info(f"Claude: 压缩后图片大小: {len(resized_image)} bytes, base64 长度: {len(b64_image)}")

        url = f"{settings.anthropic_base_url}/v1/messages"

        payload = {
            "model": settings.anthropic_model,
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
            "x-api-key": "agent-maestro",
            "anthropic-version": "2023-06-01",
        }

        if settings.anthropic_proxy_key:
            headers["X-Proxy-Key"] = settings.anthropic_proxy_key

        async with httpx.AsyncClient(timeout=60.0) as client:
            logger.info(f"发送请求到 Claude: {url}")
            logger.info(f"模型: {settings.anthropic_model}")
            response = await client.post(url, json=payload, headers=headers)
            logger.info(f"Claude 响应状态码: {response.status_code}")
            if response.status_code != 200:
                logger.error(f"Claude 错误响应: {response.text[:1000]}")
            response.raise_for_status()
            result = response.json()

        # Extract text from Claude response
        text = ""
        for block in result.get("content", []):
            if block.get("type") == "text":
                text += block.get("text", "")

        logger.info(f"Claude 原始响应 (完整): {text}")

        # Clean up markdown code fences if present
        text = text.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        parsed = json.loads(text)
        logger.info(f"Claude JSON 解析成功，包含 {len(parsed.get('detected_foods', []))} 种食物")
        return parsed

    except json.JSONDecodeError as e:
        logger.error(f"Claude JSON 解析失败: {e}")
        return None
    except Exception as e:
        logger.error(f"Claude API 调用失败: {e}")
        import traceback
        logger.error(f"完整堆栈: {traceback.format_exc()}")
        return None


async def analyze_food_image(image_data: bytes) -> AnalysisResponse:
    """Analyze a food image using Claude AI.

    Strategy:
    1. Try Anthropic Claude
    2. Fallback to mock data if unavailable
    """
    logger.info("========== 开始食物图片分析 ==========")
    logger.info(f"收到图片数据: {len(image_data)} bytes ({len(image_data)/1024:.1f} KB)")

    # 记录图片基本信息
    try:
        img = Image.open(io.BytesIO(image_data))
        logger.info(f"图片格式: {img.format}, 模式: {img.mode}, 尺寸: {img.size[0]}x{img.size[1]}")
    except Exception as e:
        logger.warning(f"无法解析图片元数据: {e}")

    logger.info(f"Claude 启用: {settings.anthropic_enabled}")
    logger.info(f"Claude 模型: {settings.anthropic_model}")
    logger.info(f"Claude API: {settings.anthropic_base_url}")

    # Try Claude
    logger.info("--- 尝试 Claude ---")
    result = await _analyze_with_anthropic(image_data)
    if result is not None:
        logger.info("Claude 返回成功")
    else:
        logger.warning("Claude 未返回结果，使用 mock 数据")

    # If Claude unavailable, use mock data
    if result is None:
        logger.warning("AI 服务不可用，使用 mock 数据！")
        result = _get_mock_analysis()

    # 打印原始 AI 返回结果
    logger.info(f"AI 原始结果 (detected_foods 数量): {len(result.get('detected_foods', []))}")
    for i, food in enumerate(result.get("detected_foods", [])):
        logger.info(
            f"  [{i}] {food.get('emoji','')} {food.get('name','')} ({food.get('name_zh','')}) "
            f"置信度={food.get('confidence',0):.2f} "
            f"热量={food.get('calories',0)} kcal "
            f"bbox=({food.get('bounding_box',{}).get('x',0):.3f}, {food.get('bounding_box',{}).get('y',0):.3f}, "
            f"{food.get('bounding_box',{}).get('w',0):.3f}, {food.get('bounding_box',{}).get('h',0):.3f})"
        )
    logger.info(f"总热量: {result.get('total_calories', 0)}")
    logger.info(f"AI分析: {result.get('ai_analysis', '')}")
    logger.info(f"标签: {result.get('tags', [])}")

    parsed = _parse_ai_response(result)
    logger.info("========== 食物分析完成 ==========")
    return parsed
