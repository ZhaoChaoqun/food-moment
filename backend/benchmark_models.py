"""Benchmark script to compare latency across AI models for food recognition.

Usage:
    uv run python benchmark_models.py <image_path>

Tests three models:
1. gemini-3-pro-preview (via Agent Maestro proxy)
2. gemini-3-flash-preview (via Agent Maestro proxy)
3. claude-opus-4.6-fast (via Anthropic proxy)
"""

import asyncio
import base64
import io
import json
import sys
import time

import httpx
from PIL import Image

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
    }
  ],
  "total_calories": 250,
  "total_nutrition": {"protein_g": 30.0, "carbs_g": 0.0, "fat_g": 12.0, "fiber_g": 1.0},
  "ai_analysis": "这顿饭蛋白质含量丰富...",
  "tags": ["high-protein"]
}"""


def resize_image(image_data: bytes, max_size: int = 512, quality: int = 70) -> bytes:
    img = Image.open(io.BytesIO(image_data))
    if img.mode in ("RGBA", "P"):
        img = img.convert("RGB")
    if max(img.size) > max_size:
        img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
    buffer = io.BytesIO()
    img.save(buffer, format="JPEG", quality=quality, optimize=True)
    return buffer.getvalue()


def clean_json_text(text: str) -> str:
    text = text.strip()
    if text.startswith("```json"):
        text = text[7:]
    if text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    return text.strip()


async def test_gemini(b64_image: str, model: str) -> dict:
    """Test a Gemini model via Agent Maestro proxy."""
    url = f"http://localhost:23333/api/gemini/v1beta/models/{model}:generateContent"

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

    start = time.perf_counter()
    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(url, json=payload, headers=headers)
        elapsed = time.perf_counter() - start

    if response.status_code != 200:
        return {"error": f"HTTP {response.status_code}: {response.text[:200]}", "latency": elapsed}

    result = response.json()
    parts = result["candidates"][0]["content"]["parts"]
    text = "".join(part.get("text", "") for part in parts)
    text = clean_json_text(text)

    try:
        parsed = json.loads(text)
        return {"result": parsed, "latency": elapsed}
    except json.JSONDecodeError as e:
        return {"error": f"JSON parse error: {e}", "raw_text": text[:500], "latency": elapsed}


async def test_anthropic(b64_image: str, model: str) -> dict:
    """Test Anthropic Claude model via proxy."""
    url = "http://localhost:23333/api/anthropic/v1/messages"

    payload = {
        "model": model,
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

    start = time.perf_counter()
    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(url, json=payload, headers=headers)
        elapsed = time.perf_counter() - start

    if response.status_code != 200:
        return {"error": f"HTTP {response.status_code}: {response.text[:200]}", "latency": elapsed}

    result = response.json()
    text = ""
    for block in result.get("content", []):
        if block.get("type") == "text":
            text += block.get("text", "")

    text = clean_json_text(text)

    try:
        parsed = json.loads(text)
        return {"result": parsed, "latency": elapsed}
    except json.JSONDecodeError as e:
        return {"error": f"JSON parse error: {e}", "raw_text": text[:500], "latency": elapsed}


def print_result(name: str, data: dict):
    print(f"\n{'='*60}")
    print(f"  {name}")
    print(f"{'='*60}")
    print(f"  Latency: {data['latency']:.2f}s")

    if "error" in data:
        print(f"  ERROR: {data['error']}")
        if "raw_text" in data:
            print(f"  Raw: {data['raw_text'][:200]}")
        return

    result = data["result"]
    foods = result.get("detected_foods", [])
    print(f"  Detected foods: {len(foods)}")
    for f in foods:
        print(f"    {f.get('emoji','')} {f.get('name','')} ({f.get('name_zh','')}) - {f.get('calories',0)} kcal")
    print(f"  Total calories: {result.get('total_calories', 0)}")
    nutrition = result.get("total_nutrition", {})
    print(f"  Nutrition: P={nutrition.get('protein_g',0):.1f}g C={nutrition.get('carbs_g',0):.1f}g F={nutrition.get('fat_g',0):.1f}g")
    print(f"  AI Analysis: {result.get('ai_analysis', '')[:100]}")


async def main():
    if len(sys.argv) < 2:
        print("Usage: uv run python benchmark_models.py <image_path>")
        print("\nYou can also use: uv run python benchmark_models.py --use-api")
        print("  This will upload via the /api/v1/food/analyze endpoint instead")
        sys.exit(1)

    image_path = sys.argv[1]

    # Read and prepare image
    with open(image_path, "rb") as f:
        image_data = f.read()

    print(f"Original image size: {len(image_data)/1024:.1f} KB")

    resized = resize_image(image_data, max_size=512, quality=70)
    b64_image = base64.b64encode(resized).decode("utf-8")
    print(f"Resized image size: {len(resized)/1024:.1f} KB")
    print(f"Base64 length: {len(b64_image)} chars")

    models = [
        ("Gemini 3 Pro Preview", "gemini", "gemini-3-pro-preview"),
        ("Gemini 3 Flash Preview", "gemini", "gemini-3-flash-preview"),
        ("Claude Opus 4.6 Fast", "anthropic", "claude-opus-4.6-fast"),
    ]

    results = {}

    for name, provider, model in models:
        print(f"\n--- Testing: {name} ({model}) ---")
        try:
            if provider == "gemini":
                data = await test_gemini(b64_image, model)
            else:
                data = await test_anthropic(b64_image, model)
            results[name] = data
            print_result(name, data)
        except Exception as e:
            results[name] = {"error": str(e), "latency": 0}
            print(f"  FAILED: {e}")

    # Summary
    print(f"\n{'='*60}")
    print("  LATENCY COMPARISON SUMMARY")
    print(f"{'='*60}")
    for name, data in results.items():
        status = "OK" if "result" in data else "FAIL"
        foods_count = len(data.get("result", {}).get("detected_foods", [])) if "result" in data else 0
        calories = data.get("result", {}).get("total_calories", "-") if "result" in data else "-"
        print(f"  {name:30s} | {data['latency']:6.2f}s | {status:4s} | {foods_count} foods | {calories} kcal")
    print(f"{'='*60}")


if __name__ == "__main__":
    asyncio.run(main())
