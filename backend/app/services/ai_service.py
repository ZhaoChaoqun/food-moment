"""AI food recognition service using Gemini Vision / GPT-4o / Agent Maestro."""

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


def _resize_image(image_data: bytes, max_size: int = 512, quality: int = 70) -> bytes:
    """Resize and compress image to reduce token usage."""
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
10. color (a unique hex color for each food item, use visually distinct colors)

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
  "total_nutrition": {"protein_g": 34.0, "carbs_g": 45.0, "fat_g": 12.5, "fiber_g": 2.0},
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
        logger.info("Gemini API Key 未配置，跳过")
        return None

    try:
        b64_image = base64.b64encode(image_data).decode("utf-8")
        logger.info(f"Gemini: 图片 base64 长度: {len(b64_image)} 字符")
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={settings.gemini_api_key[:8]}..."

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

        real_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={settings.gemini_api_key}"
        async with httpx.AsyncClient(timeout=30.0) as client:
            logger.info("发送请求到 Gemini Vision API...")
            response = await client.post(real_url, json=payload)
            logger.info(f"Gemini 响应状态码: {response.status_code}")
            if response.status_code != 200:
                logger.error(f"Gemini 错误响应: {response.text[:1000]}")
            response.raise_for_status()
            result = response.json()

        # Extract text from Gemini response
        text = result["candidates"][0]["content"]["parts"][0]["text"]
        logger.info(f"Gemini 原始响应 (完整): {text}")
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
        logger.info(f"Gemini JSON 解析成功，包含 {len(parsed.get('detected_foods', []))} 种食物")
        return parsed

    except Exception as e:
        logger.error(f"Gemini API 调用失败: {e}")
        import traceback
        logger.error(f"完整堆栈: {traceback.format_exc()}")
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
    """Call Agent Maestro proxy (Gemini API) to analyze food image.

    Returns:
        Parsed dict on success, None on failure
    """
    if not settings.agent_maestro_enabled:
        logger.info("Agent Maestro 未启用 (agent_maestro_enabled=False)")
        return None

    try:
        # Resize image to reduce token usage
        logger.info(f"压缩前图片大小: {len(image_data)} bytes")
        resized_image = _resize_image(image_data, max_size=512, quality=70)
        logger.info(f"压缩后图片大小: {len(resized_image)} bytes (max_size=512, quality=70)")

        # 记录压缩后的图片信息
        try:
            resized_img = Image.open(io.BytesIO(resized_image))
            logger.info(f"压缩后图片尺寸: {resized_img.size[0]}x{resized_img.size[1]}, 模式: {resized_img.mode}")
        except Exception:
            pass

        b64_image = base64.b64encode(resized_image).decode("utf-8")
        logger.info(f"Base64 编码后长度: {len(b64_image)} 字符")

        url = f"{settings.agent_maestro_gemini_base_url}/v1beta/models/{settings.agent_maestro_gemini_model}:generateContent"

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

        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": "agent-maestro",
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            logger.info(f"发送请求到 Agent Maestro: {url}")
            logger.info(f"模型: {settings.agent_maestro_gemini_model}")
            logger.info(f"Prompt 长度: {len(FOOD_ANALYSIS_PROMPT)} 字符")
            response = await client.post(url, json=payload, headers=headers)
            logger.info(f"响应状态码: {response.status_code}")
            if response.status_code != 200:
                logger.error(f"响应内容: {response.text[:1000]}")
            response.raise_for_status()
            result = response.json()

        # Extract and concatenate text from all parts (Gemini may split response into multiple parts)
        parts = result["candidates"][0]["content"]["parts"]
        logger.info(f"响应包含 {len(parts)} 个 parts")
        text = "".join(part.get("text", "") for part in parts)
        logger.info(f"AI 原始响应文本 (完整): {text}")

        # Clean up markdown code fences if present
        text = text.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        logger.info(f"清理后 JSON 文本: {text}")
        parsed = json.loads(text)
        logger.info(f"JSON 解析成功，包含 {len(parsed.get('detected_foods', []))} 种食物")
        return parsed

    except json.JSONDecodeError as e:
        logger.error(f"Agent Maestro JSON 解析失败: {e}")
        logger.error(f"无法解析的文本: {text if 'text' in dir() else 'N/A'}")
        return None
    except Exception as e:
        logger.error(f"Agent Maestro (Gemini) API 调用失败: {e}")
        logger.error(f"错误类型: {type(e).__name__}")
        import traceback
        logger.error(f"完整堆栈: {traceback.format_exc()}")
        return None


async def _analyze_with_anthropic(image_data: bytes) -> dict | None:
    """Call Anthropic Claude API (via proxy) to analyze food image.

    Returns:
        Parsed dict on success, None on failure
    """
    if not settings.anthropic_enabled:
        logger.info("Anthropic Claude 未启用")
        return None

    try:
        resized_image = _resize_image(image_data, max_size=512, quality=70)
        b64_image = base64.b64encode(resized_image).decode("utf-8")
        logger.info(f"Anthropic: 压缩后图片大小: {len(resized_image)} bytes, base64 长度: {len(b64_image)}")

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

        async with httpx.AsyncClient(timeout=60.0) as client:
            logger.info(f"发送请求到 Anthropic Claude: {url}")
            logger.info(f"模型: {settings.anthropic_model}")
            response = await client.post(url, json=payload, headers=headers)
            logger.info(f"Anthropic 响应状态码: {response.status_code}")
            if response.status_code != 200:
                logger.error(f"Anthropic 错误响应: {response.text[:1000]}")
            response.raise_for_status()
            result = response.json()

        # Extract text from Claude response
        text = ""
        for block in result.get("content", []):
            if block.get("type") == "text":
                text += block.get("text", "")

        logger.info(f"Anthropic 原始响应 (完整): {text}")

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
        logger.info(f"Anthropic JSON 解析成功，包含 {len(parsed.get('detected_foods', []))} 种食物")
        return parsed

    except json.JSONDecodeError as e:
        logger.error(f"Anthropic JSON 解析失败: {e}")
        return None
    except Exception as e:
        logger.error(f"Anthropic Claude API 调用失败: {e}")
        import traceback
        logger.error(f"完整堆栈: {traceback.format_exc()}")
        return None


async def analyze_food_image(image_data: bytes) -> AnalysisResponse:
    """Analyze a food image using cloud AI service.

    Strategy:
    1. Try Anthropic Claude (fastest, ~3.6s) - 首选
    2. Try Agent Maestro proxy (Gemini) - 备选
    3. Try Gemini Vision API (direct)
    4. Fallback to GPT-4o
    5. Return mock data if none available
    """
    logger.info("========== 开始食物图片分析 ==========")
    logger.info(f"收到图片数据: {len(image_data)} bytes ({len(image_data)/1024:.1f} KB)")

    # 记录图片基本信息
    try:
        img = Image.open(io.BytesIO(image_data))
        logger.info(f"图片格式: {img.format}, 模式: {img.mode}, 尺寸: {img.size[0]}x{img.size[1]}")
    except Exception as e:
        logger.warning(f"无法解析图片元数据: {e}")

    # 记录可用的 AI 服务
    logger.info(f"Anthropic Claude 启用: {settings.anthropic_enabled}")
    logger.info(f"Agent Maestro 启用: {settings.agent_maestro_enabled}")
    logger.info(f"Gemini API Key 已配置: {bool(settings.gemini_api_key)}")
    logger.info(f"OpenAI API Key 已配置: {bool(settings.openai_api_key)}")

    # 1. Try Anthropic Claude first (最快)
    logger.info("--- 尝试 Anthropic Claude ---")
    result = await _analyze_with_anthropic(image_data)
    if result is not None:
        logger.info("Anthropic Claude 返回成功")
    else:
        logger.info("Anthropic Claude 未返回结果，尝试下一个")

    # 2. Try Agent Maestro (Gemini proxy)
    if result is None:
        logger.info("--- 尝试 Agent Maestro (Gemini) ---")
        result = await _analyze_with_agent_maestro(image_data)
        if result is not None:
            logger.info("Agent Maestro 返回成功")
        else:
            logger.info("Agent Maestro 未返回结果，尝试下一个")

    # 3. Try Gemini direct
    if result is None:
        logger.info("--- 尝试 Gemini Vision API ---")
        result = await _analyze_with_gemini(image_data)
        if result is not None:
            logger.info("Gemini 返回成功")
        else:
            logger.info("Gemini 未返回结果，尝试下一个")

    # 4. Fallback to OpenAI
    if result is None:
        logger.info("--- 尝试 OpenAI GPT-4o ---")
        result = await _analyze_with_openai(image_data)
        if result is not None:
            logger.info("OpenAI 返回成功")
        else:
            logger.info("OpenAI 未返回结果")

    # If no AI service available, use mock data
    if result is None:
        logger.warning("所有 AI 服务均不可用，使用 mock 数据！")
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
