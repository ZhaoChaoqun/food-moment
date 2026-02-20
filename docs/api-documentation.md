# FoodMoment API 文档

> 版本: v1.0.0
> 更新日期: 2026-02-09
> 基础 URL: `https://api.foodmoment.app/api/v1`

---

## 目录

1. [概述](#1-概述)
2. [认证机制](#2-认证机制)
3. [通用规范](#3-通用规范)
4. [API 端点](#4-api-端点)
   - [4.1 认证 (Auth)](#41-认证-auth)
   - [4.2 食物识别 (Food)](#42-食物识别-food)
   - [4.3 餐食记录 (Meals)](#43-餐食记录-meals)
   - [4.4 统计分析 (Stats)](#44-统计分析-stats)
   - [4.5 用户 (User)](#45-用户-user)
   - [4.6 饮水记录 (Water)](#46-饮水记录-water)
5. [数据模型](#5-数据模型)
6. [错误处理](#6-错误处理)
7. [业务流程](#7-业务流程)
8. [附录](#8-附录)
9. [日志系统](#9-日志系统)

---

## 1. 概述

### 1.1 项目简介

FoodMoment 是一款基于 AI 的智能饮食管理应用，通过拍照识别食物、自动计算营养成分，帮助用户轻松追踪每日饮食并获得个性化健康建议。

### 1.2 技术架构

| 组件 | 技术栈 |
|------|--------|
| 后端框架 | Python FastAPI |
| 数据库 | PostgreSQL + SQLAlchemy 2.0 (async) |
| 认证 | JWT + Sign in with Apple |
| AI 服务 | Google Gemini Vision / OpenAI GPT-4o |
| 对象存储 | 阿里云 OSS / AWS S3 |

### 1.3 API 版本

当前版本: **v1**

所有 API 端点均以 `/api/v1` 为前缀。

---

## 2. 认证机制

### 2.1 认证方式

API 使用 **Bearer Token** 认证。在每个需要认证的请求中，必须在 HTTP Header 中包含：

```http
Authorization: Bearer <access_token>
```

### 2.2 Token 说明

| Token 类型 | 有效期 | 用途 |
|------------|--------|------|
| Access Token | 7 天 | API 请求认证 |
| Refresh Token | 30 天 | 刷新 Access Token |

### 2.3 Token 获取流程

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   iOS 客户端    │      │   Apple Server   │      │   后端服务器    │
└────────┬────────┘      └────────┬────────┘      └────────┬────────┘
         │                        │                        │
         │ 1. Sign in with Apple  │                        │
         │───────────────────────>│                        │
         │                        │                        │
         │ 2. identity_token      │                        │
         │<───────────────────────│                        │
         │                        │                        │
         │ 3. POST /auth/apple    │                        │
         │─────────────────────────────────────────────────>│
         │                        │                        │
         │                        │   4. 验证 identity_token
         │                        │<───────────────────────│
         │                        │                        │
         │                        │   5. 验证成功           │
         │                        │───────────────────────>│
         │                        │                        │
         │ 6. access_token + refresh_token                 │
         │<─────────────────────────────────────────────────│
         │                        │                        │
```

---

## 3. 通用规范

### 3.1 请求格式

- **Content-Type**: `application/json`（除文件上传外）
- **字符编码**: UTF-8
- **时间格式**: ISO 8601 (`YYYY-MM-DDTHH:mm:ss.sssZ`)
- **UUID 格式**: 标准 UUID v4

### 3.2 响应格式

所有成功响应返回 JSON 格式数据：

```json
{
  "data": { ... },
  "message": "操作成功"
}
```

### 3.3 分页参数

支持分页的端点使用以下查询参数：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `page` | integer | 1 | 页码（从 1 开始） |
| `page_size` | integer | 20 | 每页数量（最大 100） |

分页响应格式：

```json
{
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_count": 156,
    "total_pages": 8
  }
}
```

### 3.4 HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 204 | 删除成功（无返回内容） |
| 400 | 请求参数错误 |
| 401 | 未认证或 Token 无效 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 422 | 请求体验证失败 |
| 429 | 请求频率超限 |
| 500 | 服务器内部错误 |

---

## 4. API 端点

### 4.1 认证 (Auth)

#### 4.1.1 Apple ID 登录

使用 Apple ID 进行登录或注册。

**请求**

```http
POST /auth/apple
Content-Type: application/json
```

**请求体**

```json
{
  "identity_token": "eyJraWQiOiJXNldjT0...",
  "authorization_code": "c1234567890abcdef...",
  "full_name": "张三",
  "email": "zhangsan@icloud.com"
}
```

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `identity_token` | string | ✅ | Apple 返回的 JWT identity token |
| `authorization_code` | string | ✅ | Apple 返回的授权码 |
| `full_name` | string | ❌ | 用户全名（仅首次登录时 Apple 返回） |
| `email` | string | ❌ | 用户邮箱（仅首次登录时 Apple 返回） |

**响应**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "token_type": "bearer",
  "expires_in": 604800
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `access_token` | string | 访问令牌 |
| `refresh_token` | string | 刷新令牌 |
| `token_type` | string | 令牌类型，固定为 "bearer" |
| `expires_in` | integer | 过期时间（秒），默认 604800（7天） |

---

#### 4.1.2 刷新 Token

使用 refresh_token 获取新的 access_token。

**请求**

```http
POST /auth/refresh
Content-Type: application/json
```

**请求体**

```json
{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."
}
```

**响应**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "bmV3IHJlZnJlc2ggdG9rZW4...",
  "token_type": "bearer",
  "expires_in": 604800
}
```

---

#### 4.1.3 删除账户

永久删除用户账户及所有关联数据（GDPR 合规）。

**请求**

```http
DELETE /auth/account
Authorization: Bearer <access_token>
```

**响应**

```http
HTTP/1.1 204 No Content
```

**说明**

- 此操作不可逆，将删除用户的所有数据
- 包括：用户档案、餐食记录、饮水记录、体重记录、成就等
- 删除后 Token 立即失效

---

### 4.2 食物识别 (Food)

#### 4.2.1 AI 图像分析

上传食物图片，使用 AI 识别食物并分析营养成分。

**请求**

```http
POST /food/analyze
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**请求参数**

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `image` | file | ✅ | 食物图片文件 |
| `meal_type` | string | ❌ | 餐食类型，默认根据时间自动判断 |

**图片要求**

- 格式：JPEG, PNG, HEIC
- 最大尺寸：10 MB
- 推荐分辨率：1080x1080 以上

**响应**

```json
{
  "image_url": "https://cdn.foodmoment.app/uploads/2026/02/abc123.jpg",
  "total_calories": 650,
  "total_nutrition": {
    "protein_grams": 25.5,
    "carbs_grams": 78.2,
    "fat_grams": 22.3,
    "fiber_grams": 8.5
  },
  "detected_foods": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Fried Rice",
      "name_zh": "炒饭",
      "emoji": "🍚",
      "confidence": 0.95,
      "bounding_box": {
        "x": 0.15,
        "y": 0.20,
        "width": 0.60,
        "height": 0.55
      },
      "calories": 520,
      "protein_grams": 18.0,
      "carbs_grams": 68.0,
      "fat_grams": 18.5,
      "color": "#FF9500"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "name": "Fried Egg",
      "name_zh": "煎蛋",
      "emoji": "🍳",
      "confidence": 0.92,
      "bounding_box": {
        "x": 0.65,
        "y": 0.30,
        "width": 0.25,
        "height": 0.20
      },
      "calories": 130,
      "protein_grams": 7.5,
      "carbs_grams": 10.2,
      "fat_grams": 3.8,
      "color": "#FFCC00"
    }
  ],
  "ai_analysis": "这是一份营养均衡的午餐，包含主食（炒饭）和蛋白质（煎蛋）。建议搭配蔬菜以增加膳食纤维摄入。",
  "tags": ["中式", "主食", "高碳水"]
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| `image_url` | string | 上传后的图片 CDN 地址 |
| `total_calories` | integer | 总热量（千卡） |
| `total_nutrition` | object | 总营养成分 |
| `detected_foods` | array | 识别到的食物列表 |
| `ai_analysis` | string | AI 生成的分析建议 |
| `tags` | array | 自动标签 |

**detected_foods 字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string (UUID) | 识别食物的唯一标识 |
| `name` | string | 食物英文名 |
| `name_zh` | string | 食物中文名 |
| `emoji` | string | 食物对应的 emoji |
| `confidence` | float | 识别置信度 (0.0-1.0) |
| `bounding_box` | object | 食物在图片中的位置（归一化坐标） |
| `calories` | integer | 热量（千卡） |
| `protein_grams` | float | 蛋白质（克） |
| `carbs_grams` | float | 碳水化合物（克） |
| `fat_grams` | float | 脂肪（克） |
| `color` | string | 展示颜色（HEX 格式） |

---

#### 4.2.2 条形码查询

通过条形码查询预包装食品信息。

**请求**

```http
GET /food/barcode/{barcode}
```

**路径参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| `barcode` | string | 商品条形码（EAN-13 或 UPC-A） |

**响应**

```json
{
  "barcode": "6901234567890",
  "name": "康师傅红烧牛肉面",
  "name_en": "Kangshifu Braised Beef Noodles",
  "brand": "康师傅",
  "serving_size": "100g",
  "calories": 458,
  "protein_grams": 9.2,
  "carbs_grams": 62.5,
  "fat_grams": 18.8,
  "fiber_grams": 2.1,
  "sodium_mg": 1850,
  "image_url": "https://cdn.foodmoment.app/products/6901234567890.jpg"
}
```

**错误响应**

```json
{
  "error": {
    "code": "BARCODE_NOT_FOUND",
    "message": "未找到该条形码对应的食品信息"
  }
}
```

---

#### 4.2.3 食物搜索

搜索食物数据库。

**请求**

```http
GET /food/search?q={keyword}&page={page}&page_size={page_size}
```

**查询参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `q` | string | ✅ | 搜索关键词（支持中英文） |
| `page` | integer | ❌ | 页码，默认 1 |
| `page_size` | integer | ❌ | 每页数量，默认 20 |

**响应**

```json
{
  "data": [
    {
      "id": "food_001",
      "name": "Apple",
      "name_zh": "苹果",
      "emoji": "🍎",
      "category": "水果",
      "serving_size": "1个 (182g)",
      "calories": 95,
      "protein_grams": 0.5,
      "carbs_grams": 25.0,
      "fat_grams": 0.3
    },
    {
      "id": "food_002",
      "name": "Apple Juice",
      "name_zh": "苹果汁",
      "emoji": "🧃",
      "category": "饮品",
      "serving_size": "1杯 (240ml)",
      "calories": 114,
      "protein_grams": 0.2,
      "carbs_grams": 28.0,
      "fat_grams": 0.3
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_count": 45,
    "total_pages": 3
  }
}
```

---

### 4.3 餐食记录 (Meals)

#### 4.3.1 创建餐食记录

保存一条餐食记录。

**请求**

```http
POST /meals
Authorization: Bearer <access_token>
Content-Type: application/json
```

**请求体**

```json
{
  "image_url": "https://cdn.foodmoment.app/uploads/2026/02/abc123.jpg",
  "meal_type": "lunch",
  "meal_time": "2026-02-09T12:30:00Z",
  "title": "午餐 - 炒饭套餐",
  "description_text": "公司食堂的炒饭，加了一个煎蛋",
  "total_calories": 650,
  "protein_grams": 25.5,
  "carbs_grams": 78.2,
  "fat_grams": 22.3,
  "fiber_grams": 8.5,
  "ai_analysis": "这是一份营养均衡的午餐...",
  "tags": ["中式", "主食", "高碳水"],
  "detected_foods": [
    {
      "name": "Fried Rice",
      "name_zh": "炒饭",
      "emoji": "🍚",
      "confidence": 0.95,
      "bounding_box_x": 0.15,
      "bounding_box_y": 0.20,
      "bounding_box_w": 0.60,
      "bounding_box_h": 0.55,
      "calories": 520,
      "protein_grams": 18.0,
      "carbs_grams": 68.0,
      "fat_grams": 18.5
    },
    {
      "name": "Fried Egg",
      "name_zh": "煎蛋",
      "emoji": "🍳",
      "confidence": 0.92,
      "bounding_box_x": 0.65,
      "bounding_box_y": 0.30,
      "bounding_box_w": 0.25,
      "bounding_box_h": 0.20,
      "calories": 130,
      "protein_grams": 7.5,
      "carbs_grams": 10.2,
      "fat_grams": 3.8
    }
  ]
}
```

**请求体字段说明**

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `image_url` | string | ❌ | 图片 URL |
| `meal_type` | string | ✅ | 餐食类型：`breakfast`, `lunch`, `dinner`, `snack` |
| `meal_time` | string | ✅ | 用餐时间（ISO 8601 格式） |
| `title` | string | ✅ | 餐食标题 |
| `description_text` | string | ❌ | 描述文字 |
| `total_calories` | integer | ✅ | 总热量（千卡） |
| `protein_grams` | float | ✅ | 蛋白质（克） |
| `carbs_grams` | float | ✅ | 碳水化合物（克） |
| `fat_grams` | float | ✅ | 脂肪（克） |
| `fiber_grams` | float | ❌ | 膳食纤维（克），默认 0 |
| `ai_analysis` | string | ❌ | AI 分析建议 |
| `tags` | array | ❌ | 标签列表 |
| `detected_foods` | array | ❌ | 识别到的食物列表 |

**响应**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "image_url": "https://cdn.foodmoment.app/uploads/2026/02/abc123.jpg",
  "meal_type": "lunch",
  "meal_time": "2026-02-09T12:30:00Z",
  "title": "午餐 - 炒饭套餐",
  "description_text": "公司食堂的炒饭，加了一个煎蛋",
  "total_calories": 650,
  "protein_grams": 25.5,
  "carbs_grams": 78.2,
  "fat_grams": 22.3,
  "fiber_grams": 8.5,
  "ai_analysis": "这是一份营养均衡的午餐...",
  "tags": ["中式", "主食", "高碳水"],
  "detected_foods": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Fried Rice",
      "name_zh": "炒饭",
      "emoji": "🍚",
      "confidence": 0.95,
      "bounding_box": {
        "x": 0.15,
        "y": 0.20,
        "width": 0.60,
        "height": 0.55
      },
      "calories": 520,
      "protein_grams": 18.0,
      "carbs_grams": 68.0,
      "fat_grams": 18.5
    }
  ],
  "created_at": "2026-02-09T12:35:00Z",
  "updated_at": "2026-02-09T12:35:00Z"
}
```

---

#### 4.3.2 查询餐食记录

获取指定日期的餐食记录列表。

**请求**

```http
GET /meals?date={date}&meal_type={meal_type}
Authorization: Bearer <access_token>
```

**查询参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `date` | string | ❌ | 日期（YYYY-MM-DD），默认今天 |
| `meal_type` | string | ❌ | 筛选餐食类型 |
| `start_date` | string | ❌ | 开始日期（用于范围查询） |
| `end_date` | string | ❌ | 结束日期（用于范围查询） |

**响应**

```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "image_url": "https://cdn.foodmoment.app/uploads/2026/02/breakfast.jpg",
      "meal_type": "breakfast",
      "meal_time": "2026-02-09T07:30:00Z",
      "title": "早餐 - 牛奶面包",
      "total_calories": 380,
      "protein_grams": 12.0,
      "carbs_grams": 52.0,
      "fat_grams": 14.0,
      "fiber_grams": 3.0,
      "detected_foods": [ ... ],
      "created_at": "2026-02-09T07:35:00Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "image_url": "https://cdn.foodmoment.app/uploads/2026/02/lunch.jpg",
      "meal_type": "lunch",
      "meal_time": "2026-02-09T12:30:00Z",
      "title": "午餐 - 炒饭套餐",
      "total_calories": 650,
      "protein_grams": 25.5,
      "carbs_grams": 78.2,
      "fat_grams": 22.3,
      "fiber_grams": 8.5,
      "detected_foods": [ ... ],
      "created_at": "2026-02-09T12:35:00Z"
    }
  ],
  "summary": {
    "total_calories": 1030,
    "total_protein": 37.5,
    "total_carbs": 130.2,
    "total_fat": 36.3,
    "meal_count": 2
  }
}
```

---

#### 4.3.3 获取单条餐食记录

**请求**

```http
GET /meals/{meal_id}
Authorization: Bearer <access_token>
```

**响应**

返回单条完整的餐食记录（结构同创建响应）。

---

#### 4.3.4 更新餐食记录

**请求**

```http
PUT /meals/{meal_id}
Authorization: Bearer <access_token>
Content-Type: application/json
```

**请求体**

支持部分更新，只需传递需要修改的字段：

```json
{
  "title": "午餐 - 炒饭套餐（已编辑）",
  "total_calories": 700,
  "tags": ["中式", "主食", "已编辑"]
}
```

**响应**

返回更新后的完整餐食记录。

---

#### 4.3.5 删除餐食记录

**请求**

```http
DELETE /meals/{meal_id}
Authorization: Bearer <access_token>
```

**响应**

```http
HTTP/1.1 204 No Content
```

---

### 4.4 统计分析 (Stats)

#### 4.4.1 每日统计

获取指定日期的营养摄入统计。

**请求**

```http
GET /stats/daily?date={date}
Authorization: Bearer <access_token>
```

**查询参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `date` | string | ❌ | 日期（YYYY-MM-DD），默认今天 |

**响应**

```json
{
  "date": "2026-02-09",
  "total_calories": 1850,
  "protein_grams": 75.5,
  "carbs_grams": 220.0,
  "fat_grams": 68.5,
  "fiber_grams": 25.0,
  "meal_count": 4,
  "water_ml": 1500,
  "goals": {
    "calorie_goal": 2000,
    "calorie_percentage": 92.5,
    "protein_goal": 50,
    "protein_percentage": 151.0,
    "carbs_goal": 250,
    "carbs_percentage": 88.0,
    "fat_goal": 65,
    "fat_percentage": 105.4,
    "water_goal": 2000,
    "water_percentage": 75.0
  },
  "meals_by_type": {
    "breakfast": {
      "count": 1,
      "calories": 380
    },
    "lunch": {
      "count": 1,
      "calories": 650
    },
    "dinner": {
      "count": 1,
      "calories": 720
    },
    "snack": {
      "count": 1,
      "calories": 100
    }
  }
}
```

---

#### 4.4.2 周统计

获取指定周的营养摄入统计。

**请求**

```http
GET /stats/weekly?week={date}
Authorization: Bearer <access_token>
```

**查询参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `week` | string | ❌ | 周内任意一天（YYYY-MM-DD），默认本周 |

**响应**

```json
{
  "week_start": "2026-02-03",
  "week_end": "2026-02-09",
  "avg_calories": 1920,
  "avg_protein": 72.5,
  "avg_carbs": 235.0,
  "avg_fat": 62.0,
  "avg_fiber": 22.0,
  "total_meals": 25,
  "daily_stats": [
    {
      "date": "2026-02-03",
      "day_of_week": "Monday",
      "day_of_week_zh": "周一",
      "total_calories": 1850,
      "protein_grams": 70.0,
      "carbs_grams": 220.0,
      "fat_grams": 58.0,
      "meal_count": 3,
      "water_ml": 1800
    },
    {
      "date": "2026-02-04",
      "day_of_week": "Tuesday",
      "day_of_week_zh": "周二",
      "total_calories": 2100,
      "protein_grams": 85.0,
      "carbs_grams": 260.0,
      "fat_grams": 72.0,
      "meal_count": 4,
      "water_ml": 2000
    }
    // ... 更多天数
  ],
  "calorie_trend": {
    "direction": "stable",
    "change_percentage": 2.5
  }
}
```

---

#### 4.4.3 月统计

获取指定月的营养摄入统计。

**请求**

```http
GET /stats/monthly?month={month}
Authorization: Bearer <access_token>
```

**查询参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `month` | string | ❌ | 月份（YYYY-MM），默认本月 |

**响应**

```json
{
  "month": "2026-02",
  "month_name": "February",
  "month_name_zh": "二月",
  "avg_calories": 1950,
  "avg_protein": 75.0,
  "avg_carbs": 240.0,
  "avg_fat": 65.0,
  "total_meals": 85,
  "total_days_logged": 9,
  "weekly_stats": [
    {
      "week_number": 1,
      "week_start": "2026-02-01",
      "week_end": "2026-02-02",
      "avg_calories": 1900,
      "total_meals": 6
    },
    {
      "week_number": 2,
      "week_start": "2026-02-03",
      "week_end": "2026-02-09",
      "avg_calories": 1920,
      "total_meals": 25
    }
  ],
  "top_foods": [
    {
      "name_zh": "米饭",
      "emoji": "🍚",
      "count": 15,
      "total_calories": 3900
    },
    {
      "name_zh": "鸡蛋",
      "emoji": "🥚",
      "count": 12,
      "total_calories": 1560
    }
  ]
}
```

---

#### 4.4.4 AI 洞察

获取 AI 生成的个性化健康洞察和建议。

**请求**

```http
GET /stats/insights?days={days}
Authorization: Bearer <access_token>
```

**查询参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `days` | integer | ❌ | 分析天数，默认 7，最大 30 |

**响应**

```json
{
  "generated_at": "2026-02-09T15:30:00Z",
  "analysis_period": {
    "start_date": "2026-02-02",
    "end_date": "2026-02-09",
    "days_with_data": 7
  },
  "insight": "过去一周您的饮食整体均衡，蛋白质摄入充足，但膳食纤维略有不足。建议增加蔬菜和全谷物的摄入。",
  "highlights": [
    {
      "type": "positive",
      "icon": "✅",
      "title": "蛋白质达标",
      "description": "平均每日摄入 75g 蛋白质，超过目标 50%"
    },
    {
      "type": "warning",
      "icon": "⚠️",
      "title": "纤维不足",
      "description": "平均每日仅摄入 18g 膳食纤维，建议增加至 25g"
    },
    {
      "type": "info",
      "icon": "💧",
      "title": "饮水良好",
      "description": "平均每日饮水 1.8L，接近目标"
    }
  ],
  "tips": [
    "早餐可以添加一份水果，如苹果或香蕉",
    "午餐尝试将部分白米饭替换为糙米",
    "下午茶时间可以选择坚果代替零食",
    "晚餐增加一份绿叶蔬菜",
    "保持每日 8 杯水的饮水习惯"
  ],
  "nutrition_trends": {
    "calories": {
      "trend": "stable",
      "avg_value": 1920,
      "goal": 2000,
      "deviation_percentage": -4.0
    },
    "protein": {
      "trend": "up",
      "avg_value": 75.0,
      "goal": 50,
      "deviation_percentage": 50.0
    },
    "carbs": {
      "trend": "stable",
      "avg_value": 235.0,
      "goal": 250,
      "deviation_percentage": -6.0
    },
    "fat": {
      "trend": "down",
      "avg_value": 62.0,
      "goal": 65,
      "deviation_percentage": -4.6
    }
  }
}
```

---

### 4.5 用户 (User)

#### 4.5.1 获取用户档案

**请求**

```http
GET /user/profile
Authorization: Bearer <access_token>
```

**响应**

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "display_name": "张三",
  "email": "zhangsan@icloud.com",
  "avatar_url": "https://cdn.foodmoment.app/avatars/user123.jpg",
  "is_pro": false,
  "daily_calorie_goal": 2000,
  "daily_protein_goal": 50,
  "daily_carbs_goal": 250,
  "daily_fat_goal": 65,
  "daily_water_goal": 2000,
  "target_weight": 70.0,
  "current_weight": 75.5,
  "height_cm": 175,
  "birth_date": "1995-06-15",
  "gender": "male",
  "activity_level": "moderate",
  "created_at": "2026-01-15T10:30:00Z",
  "updated_at": "2026-02-09T08:00:00Z"
}
```

---

#### 4.5.2 更新用户档案

**请求**

```http
PUT /user/profile
Authorization: Bearer <access_token>
Content-Type: application/json
```

**请求体**

```json
{
  "display_name": "张三（已改名）",
  "height_cm": 175,
  "birth_date": "1995-06-15",
  "gender": "male",
  "activity_level": "moderate"
}
```

**可更新字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `display_name` | string | 显示名称 |
| `avatar_url` | string | 头像 URL |
| `height_cm` | integer | 身高（厘米） |
| `birth_date` | string | 出生日期（YYYY-MM-DD） |
| `gender` | string | 性别：`male`, `female`, `other` |
| `activity_level` | string | 活动水平：`sedentary`, `light`, `moderate`, `active`, `very_active` |

**响应**

返回更新后的完整用户档案。

---

#### 4.5.3 更新营养目标

**请求**

```http
PUT /user/goals
Authorization: Bearer <access_token>
Content-Type: application/json
```

**请求体**

```json
{
  "daily_calorie_goal": 1800,
  "daily_protein_goal": 60,
  "daily_carbs_goal": 200,
  "daily_fat_goal": 55,
  "daily_water_goal": 2500,
  "target_weight": 68.0
}
```

**响应**

```json
{
  "message": "目标已更新",
  "goals": {
    "daily_calorie_goal": 1800,
    "daily_protein_goal": 60,
    "daily_carbs_goal": 200,
    "daily_fat_goal": 55,
    "daily_water_goal": 2500,
    "target_weight": 68.0
  }
}
```

---

#### 4.5.4 记录体重

**请求**

```http
POST /user/weight
Authorization: Bearer <access_token>
Content-Type: application/json
```

**请求体**

```json
{
  "weight_kg": 74.8,
  "recorded_at": "2026-02-09T07:00:00Z"
}
```

**响应**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440010",
  "weight_kg": 74.8,
  "recorded_at": "2026-02-09T07:00:00Z",
  "created_at": "2026-02-09T07:05:00Z"
}
```

---

#### 4.5.5 获取体重历史

**请求**

```http
GET /user/weight?start_date={start}&end_date={end}
Authorization: Bearer <access_token>
```

**查询参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `start_date` | string | ❌ | 开始日期，默认 30 天前 |
| `end_date` | string | ❌ | 结束日期，默认今天 |

**响应**

```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440010",
      "weight_kg": 74.8,
      "recorded_at": "2026-02-09T07:00:00Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440009",
      "weight_kg": 75.0,
      "recorded_at": "2026-02-08T07:00:00Z"
    }
  ],
  "summary": {
    "current_weight": 74.8,
    "start_weight": 76.0,
    "target_weight": 68.0,
    "change": -1.2,
    "change_percentage": -1.6,
    "trend": "down"
  }
}
```

---

#### 4.5.6 获取成就列表

**请求**

```http
GET /user/achievements
Authorization: Bearer <access_token>
```

**响应**

```json
{
  "earned": [
    {
      "id": "ach_001",
      "type": "streak_7day",
      "name": "七日坚持",
      "name_en": "7-Day Streak",
      "description": "连续记录饮食 7 天",
      "icon": "🔥",
      "tier": "bronze",
      "earned_at": "2026-02-05T23:59:59Z"
    },
    {
      "id": "ach_002",
      "type": "first_meal",
      "name": "第一餐",
      "name_en": "First Meal",
      "description": "记录第一餐食物",
      "icon": "🎉",
      "tier": "bronze",
      "earned_at": "2026-01-15T12:00:00Z"
    }
  ],
  "available": [
    {
      "type": "streak_30day",
      "name": "三十日坚持",
      "name_en": "30-Day Streak",
      "description": "连续记录饮食 30 天",
      "icon": "🔥",
      "tier": "gold",
      "progress": {
        "current": 12,
        "target": 30,
        "percentage": 40
      }
    },
    {
      "type": "veggie_lover",
      "name": "蔬菜达人",
      "name_en": "Veggie Lover",
      "description": "累计记录 100 份蔬菜",
      "icon": "🥬",
      "tier": "silver",
      "progress": {
        "current": 45,
        "target": 100,
        "percentage": 45
      }
    }
  ]
}
```

---

#### 4.5.7 获取连续打卡记录

**请求**

```http
GET /user/streaks
Authorization: Bearer <access_token>
```

**响应**

```json
{
  "current_streak": 12,
  "longest_streak": 21,
  "total_days_logged": 45,
  "streak_start_date": "2026-01-28",
  "last_logged_date": "2026-02-09",
  "calendar": {
    "2026-02": [1, 2, 3, 4, 5, 6, 7, 8, 9],
    "2026-01": [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]
  }
}
```

---

### 4.6 饮水记录 (Water)

#### 4.6.1 记录饮水

**请求**

```http
POST /water
Authorization: Bearer <access_token>
Content-Type: application/json
```

**请求体**

```json
{
  "amount_ml": 250,
  "recorded_at": "2026-02-09T10:30:00Z"
}
```

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `amount_ml` | integer | ❌ | 饮水量（毫升），默认 250 |
| `recorded_at` | string | ❌ | 记录时间，默认当前时间 |

**响应**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440020",
  "amount_ml": 250,
  "recorded_at": "2026-02-09T10:30:00Z",
  "created_at": "2026-02-09T10:30:05Z"
}
```

---

#### 4.6.2 查询每日饮水记录

**请求**

```http
GET /water?date={date}
Authorization: Bearer <access_token>
```

**查询参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `date` | string | ❌ | 日期（YYYY-MM-DD），默认今天 |

**响应**

```json
{
  "date": "2026-02-09",
  "total_ml": 1500,
  "goal_ml": 2000,
  "percentage": 75,
  "remaining_ml": 500,
  "logs": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440020",
      "amount_ml": 250,
      "recorded_at": "2026-02-09T07:00:00Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440021",
      "amount_ml": 300,
      "recorded_at": "2026-02-09T09:30:00Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440022",
      "amount_ml": 250,
      "recorded_at": "2026-02-09T10:30:00Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440023",
      "amount_ml": 350,
      "recorded_at": "2026-02-09T12:00:00Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440024",
      "amount_ml": 350,
      "recorded_at": "2026-02-09T15:00:00Z"
    }
  ]
}
```

---

#### 4.6.3 删除饮水记录

**请求**

```http
DELETE /water/{log_id}
Authorization: Bearer <access_token>
```

**响应**

```http
HTTP/1.1 204 No Content
```

---

## 5. 数据模型

### 5.1 用户 (User)

```typescript
interface User {
  id: string;                    // UUID
  apple_user_id: string;         // Apple ID 唯一标识
  display_name: string;          // 显示名称
  email?: string;                // 邮箱（可选）
  avatar_url?: string;           // 头像 URL
  is_pro: boolean;               // 是否为 Pro 用户

  // 每日目标
  daily_calorie_goal: number;    // 热量目标（千卡）
  daily_protein_goal: number;    // 蛋白质目标（克）
  daily_carbs_goal: number;      // 碳水目标（克）
  daily_fat_goal: number;        // 脂肪目标（克）
  daily_water_goal: number;      // 饮水目标（毫升）

  // 身体数据
  target_weight?: number;        // 目标体重（公斤）
  height_cm?: number;            // 身高（厘米）
  birth_date?: string;           // 出生日期
  gender?: 'male' | 'female' | 'other';
  activity_level?: 'sedentary' | 'light' | 'moderate' | 'active' | 'very_active';

  created_at: string;            // 创建时间
  updated_at: string;            // 更新时间
}
```

### 5.2 餐食记录 (MealRecord)

```typescript
interface MealRecord {
  id: string;                    // UUID
  user_id: string;               // 用户 ID
  image_url?: string;            // 图片 URL
  meal_type: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  meal_time: string;             // 用餐时间
  title: string;                 // 标题
  description_text?: string;     // 描述

  // 营养数据
  total_calories: number;        // 总热量
  protein_grams: number;         // 蛋白质
  carbs_grams: number;           // 碳水化合物
  fat_grams: number;             // 脂肪
  fiber_grams: number;           // 膳食纤维

  ai_analysis?: string;          // AI 分析
  tags: string[];                // 标签
  is_synced: boolean;            // 是否已同步

  detected_foods: DetectedFood[]; // 识别到的食物

  created_at: string;
  updated_at: string;
}
```

### 5.3 识别食物 (DetectedFood)

```typescript
interface DetectedFood {
  id: string;                    // UUID
  meal_record_id: string;        // 关联的餐食记录 ID
  name: string;                  // 英文名
  name_zh: string;               // 中文名
  emoji: string;                 // Emoji
  confidence: number;            // 置信度 (0.0-1.0)

  // 边界框（归一化坐标）
  bounding_box: {
    x: number;                   // 左上角 X (0.0-1.0)
    y: number;                   // 左上角 Y (0.0-1.0)
    width: number;               // 宽度 (0.0-1.0)
    height: number;              // 高度 (0.0-1.0)
  };

  // 营养数据
  calories: number;
  protein_grams: number;
  carbs_grams: number;
  fat_grams: number;

  color?: string;                // 展示颜色（HEX）
}
```

### 5.4 饮水记录 (WaterLog)

```typescript
interface WaterLog {
  id: string;                    // UUID
  user_id: string;               // 用户 ID
  amount_ml: number;             // 饮水量（毫升）
  recorded_at: string;           // 记录时间
  created_at: string;            // 创建时间
}
```

### 5.5 体重记录 (WeightLog)

```typescript
interface WeightLog {
  id: string;                    // UUID
  user_id: string;               // 用户 ID
  weight_kg: number;             // 体重（公斤）
  recorded_at: string;           // 记录时间
  created_at: string;            // 创建时间
}
```

### 5.6 成就 (Achievement)

```typescript
interface Achievement {
  id: string;                    // UUID
  user_id: string;               // 用户 ID
  type: string;                  // 成就类型
  tier: 'bronze' | 'silver' | 'gold';
  earned_at: string;             // 获得时间
}
```

**成就类型列表**

| type | 名称 | 描述 | 等级 |
|------|------|------|------|
| `first_meal` | 第一餐 | 记录第一餐食物 | bronze |
| `streak_7day` | 七日坚持 | 连续记录 7 天 | bronze |
| `streak_30day` | 三十日坚持 | 连续记录 30 天 | gold |
| `streak_100day` | 百日坚持 | 连续记录 100 天 | gold |
| `meal_100` | 百餐达成 | 累计记录 100 餐 | silver |
| `meal_500` | 五百餐达成 | 累计记录 500 餐 | gold |
| `veggie_lover` | 蔬菜达人 | 累计记录 100 份蔬菜 | silver |
| `protein_master` | 蛋白质大师 | 连续 7 天蛋白质达标 | silver |
| `water_champion` | 饮水冠军 | 连续 7 天饮水达标 | bronze |
| `early_bird` | 早餐达人 | 连续 14 天记录早餐 | silver |

---

## 6. 错误处理

### 6.1 错误响应格式

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述信息",
    "details": {
      "field": "具体字段",
      "reason": "详细原因"
    }
  }
}
```

### 6.2 通用错误码

| HTTP 状态码 | 错误码 | 说明 |
|-------------|--------|------|
| 400 | `BAD_REQUEST` | 请求参数格式错误 |
| 400 | `INVALID_PARAMETER` | 参数值无效 |
| 401 | `UNAUTHORIZED` | 未提供认证信息 |
| 401 | `TOKEN_EXPIRED` | Token 已过期 |
| 401 | `TOKEN_INVALID` | Token 无效 |
| 403 | `FORBIDDEN` | 无权限访问该资源 |
| 404 | `NOT_FOUND` | 资源不存在 |
| 404 | `USER_NOT_FOUND` | 用户不存在 |
| 404 | `MEAL_NOT_FOUND` | 餐食记录不存在 |
| 409 | `CONFLICT` | 资源冲突 |
| 422 | `VALIDATION_ERROR` | 请求体验证失败 |
| 429 | `RATE_LIMIT_EXCEEDED` | 请求频率超限 |
| 500 | `INTERNAL_ERROR` | 服务器内部错误 |
| 503 | `SERVICE_UNAVAILABLE` | 服务暂时不可用 |

### 6.3 业务错误码

| 错误码 | 说明 |
|--------|------|
| `APPLE_AUTH_FAILED` | Apple ID 验证失败 |
| `APPLE_TOKEN_INVALID` | Apple identity_token 无效 |
| `IMAGE_TOO_LARGE` | 图片文件过大（超过 10MB） |
| `IMAGE_FORMAT_UNSUPPORTED` | 不支持的图片格式 |
| `AI_ANALYSIS_FAILED` | AI 分析失败 |
| `BARCODE_NOT_FOUND` | 条形码未找到对应食品 |
| `DAILY_LIMIT_EXCEEDED` | 超出每日使用限制（非 Pro 用户） |

### 6.4 错误处理示例

**Token 过期**

```json
{
  "error": {
    "code": "TOKEN_EXPIRED",
    "message": "访问令牌已过期，请刷新令牌"
  }
}
```

客户端应调用 `/auth/refresh` 刷新 Token。

**验证失败**

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "请求参数验证失败",
    "details": [
      {
        "field": "meal_type",
        "reason": "必须是 breakfast, lunch, dinner, snack 之一"
      },
      {
        "field": "total_calories",
        "reason": "必须为正整数"
      }
    ]
  }
}
```

---

## 7. 业务流程

### 7.1 拍照识别流程

```
┌────────────────────────────────────────────────────────────────────┐
│                          用户拍照流程                               │
└────────────────────────────────────────────────────────────────────┘

1. 用户打开相机拍照
   │
   ▼
2. [iOS 端] 图片预处理
   - 压缩至合适尺寸（≤10MB）
   - 转换为 JPEG 格式
   │
   ▼
3. [API] POST /food/analyze
   - 上传图片（multipart/form-data）
   - 返回：image_url, detected_foods, total_nutrition, ai_analysis
   │
   ▼
4. [iOS 端] 展示分析结果页
   - 显示识别到的食物列表
   - 显示各食物的边界框
   - 显示总营养数据
   │
   ▼
5. 用户可编辑
   - 修改食物名称/数量
   - 添加/删除食物
   - 调整营养数据
   │
   ▼
6. [API] POST /meals
   - 保存餐食记录
   - 关联 detected_foods
   │
   ▼
7. [iOS 端] 本地持久化
   - 保存到 SwiftData
   - 写入 HealthKit（如已授权）
   │
   ▼
8. 完成
```

### 7.2 数据同步流程

```
┌────────────────────────────────────────────────────────────────────┐
│                          离线同步流程                               │
└────────────────────────────────────────────────────────────────────┘

[离线状态]
   │
   ▼
1. 用户创建/修改记录
   - 保存到本地 SwiftData
   - 标记 is_synced = false
   - 生成本地 UUID
   │
   ▼
[网络恢复]
   │
   ▼
2. 检测网络状态变化
   - 使用 NWPathMonitor 监听
   │
   ▼
3. 获取待同步记录
   - 查询 is_synced = false 的记录
   │
   ▼
4. 批量上传
   - POST /meals (新记录)
   - PUT /meals/{id} (更新记录)
   │
   ▼
5. 更新本地状态
   - 设置 is_synced = true
   - 更新服务器返回的 ID
   │
   ▼
6. 拉取服务器更新
   - GET /meals?updated_since={last_sync_time}
   │
   ▼
7. 合并冲突（如有）
   - 策略：服务器优先 or 最后修改优先
   │
   ▼
8. 同步完成
```

### 7.3 认证与 Token 刷新流程

```
┌────────────────────────────────────────────────────────────────────┐
│                       Token 刷新流程                                │
└────────────────────────────────────────────────────────────────────┘

1. API 请求返回 401 (TOKEN_EXPIRED)
   │
   ▼
2. 检查是否有 refresh_token
   │
   ├─── 无 ──► 跳转登录页面
   │
   ▼ 有
3. POST /auth/refresh
   │
   ├─── 成功 ──► 保存新 Token，重试原请求
   │
   ▼ 失败
4. 清除本地 Token
   │
   ▼
5. 跳转登录页面
```

---

## 8. 附录

### 8.1 餐食类型 (MealType)

| 值 | 说明 | 典型时间范围 |
|-----|------|-------------|
| `breakfast` | 早餐 | 06:00 - 10:00 |
| `lunch` | 午餐 | 11:00 - 14:00 |
| `dinner` | 晚餐 | 17:00 - 21:00 |
| `snack` | 加餐/零食 | 任意时间 |

### 8.2 活动水平 (ActivityLevel)

| 值 | 说明 | 运动频率 |
|-----|------|---------|
| `sedentary` | 久坐 | 几乎不运动 |
| `light` | 轻度活动 | 每周 1-3 次轻度运动 |
| `moderate` | 中度活动 | 每周 3-5 次中等强度运动 |
| `active` | 活跃 | 每周 6-7 次运动 |
| `very_active` | 非常活跃 | 每天高强度运动或体力劳动 |

### 8.3 营养素参考摄入量

| 营养素 | 成年男性 | 成年女性 | 单位 |
|--------|---------|---------|------|
| 热量 | 2000-2500 | 1600-2000 | kcal |
| 蛋白质 | 65 | 55 | g |
| 碳水化合物 | 250-300 | 200-250 | g |
| 脂肪 | 55-65 | 45-55 | g |
| 膳食纤维 | 25-30 | 25-30 | g |
| 水 | 2500-3000 | 2000-2500 | ml |

### 8.4 请求频率限制

| 端点类型 | 限制 | 时间窗口 |
|---------|------|---------|
| 认证端点 | 10 次 | 1 分钟 |
| AI 分析 | 30 次 | 1 小时 |
| 普通 API | 100 次 | 1 分钟 |
| 搜索 API | 60 次 | 1 分钟 |

### 8.5 图片上传规范

| 参数 | 值 |
|------|-----|
| 支持格式 | JPEG, PNG, HEIC, WebP |
| 最大文件大小 | 10 MB |
| 推荐分辨率 | 1080x1080 - 4096x4096 |
| 最小分辨率 | 320x320 |

### 8.6 时区处理

- 所有 API 返回的时间均为 **UTC 时间**（ISO 8601 格式）
- 客户端需要根据用户时区进行转换显示
- 日期查询参数（如 `date=2026-02-09`）基于用户本地时区
- 服务器会根据请求头 `X-Timezone` 或用户设置进行日期边界计算

### 8.7 API 变更日志

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| v1.0.0 | 2026-02-09 | 初始版本发布 |

---

## 9. 日志系统

### 9.1 技术方案

| 组件 | 技术 | 用途 |
|------|------|------|
| 结构化日志 | [structlog](https://www.structlog.org/) | 将标准库 logging 输出转为结构化格式 |
| 文件持久化 | RotatingFileHandler | 日志写入文件，自动轮转 |
| 请求追踪 | FastAPI Middleware + contextvars | 自动为每个请求注入 request_id |

### 9.2 配置文件

| 文件 | 说明 |
|------|------|
| `backend/app/logging_config.py` | 日志核心配置（structlog + handler 设置） |
| `backend/app/config.py` | `log_level` 和 `log_dir` 环境变量 |
| `backend/app/main.py` | `setup_logging()` 调用 + 请求上下文中间件 |

### 9.3 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `LOG_LEVEL` | `INFO` | 日志级别（DEBUG / INFO / WARNING / ERROR） |
| `LOG_DIR` | `logs` | 日志文件存放目录 |
| `DEBUG` | `false` | 设为 `true` 时控制台输出彩色格式，否则输出 JSON |

### 9.4 输出格式

**开发环境**（`DEBUG=true`，彩色控制台）：

```
2026-02-20T10:30:45Z [info     ] Claude 响应状态码: 200  [app.services.ai_service] request_id=a3f2c1d8 path=/api/v1/food/analyze method=POST
```

**日志文件**（`logs/app.log`，始终 JSON）：

```json
{"event":"Claude 响应状态码: 200","level":"info","logger":"app.services.ai_service","timestamp":"2026-02-20T10:30:45Z","request_id":"a3f2c1d8","path":"/api/v1/food/analyze","method":"POST"}
```

### 9.5 日志文件轮转

| 配置项 | 值 |
|--------|-----|
| 文件路径 | `backend/logs/app.log` |
| 单文件大小上限 | 10 MB |
| 保留备份数 | 5 个（`app.log.1` ~ `app.log.5`） |
| 编码 | UTF-8 |

### 9.6 请求上下文追踪

每个 HTTP 请求自动注入以下字段到所有日志：

| 字段 | 来源 | 示例 |
|------|------|------|
| `request_id` | 请求头 `X-Request-ID` 或自动生成 | `a3f2c1d8` |
| `path` | 请求路径 | `/api/v1/food/analyze` |
| `method` | HTTP 方法 | `POST` |

### 9.7 常用查询

```bash
# 查看所有错误
jq 'select(.level == "error")' backend/logs/app.log

# 追踪单个请求的完整链路
jq 'select(.request_id == "a3f2c1d8")' backend/logs/app.log

# 查看 AI 服务日志
jq 'select(.logger == "app.services.ai_service")' backend/logs/app.log

# 实时监控日志
tail -f backend/logs/app.log | jq .
```

### 9.8 第三方库日志过滤

以下库的日志级别被设为 WARNING，避免刷屏：

- `uvicorn.access`
- `httpx` / `httpcore`
- `sqlalchemy.engine`

### 9.9 生产环境扩展

当前方案使用标准库 `logging` 作为底层，未来部署到 Azure 后可无缝接入 Application Insights：

```python
# 仅生产环境
if os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING"):
    from azure.monitor.opentelemetry import configure_azure_monitor
    configure_azure_monitor()
```

无需修改任何应用层代码。

---

## 联系方式

- 技术支持：support@foodmoment.app
- API 问题反馈：api-feedback@foodmoment.app
- 文档更新建议：docs@foodmoment.app

---

> **版权声明**
> 本文档版权归 FoodMoment 团队所有。未经授权，禁止转载或用于商业用途。
