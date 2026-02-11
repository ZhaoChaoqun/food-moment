# FoodMoment Backend

基于 FastAPI + PostgreSQL 的食物营养追踪后端服务。

## 技术栈

- **框架**: FastAPI 0.128+
- **数据库**: PostgreSQL 16 + SQLAlchemy 2.0 (async)
- **缓存**: Redis 7
- **对象存储**: MinIO (S3 兼容)
- **AI 识别**: Claude (通过 Agent Maestro 代理)
- **认证**: JWT (设备匿名认证 + Apple Sign-In)
- **Python**: >= 3.12
- **包管理**: uv

## 项目结构

```
backend/
├── app/
│   ├── main.py                 # FastAPI 应用入口
│   ├── config.py               # 配置管理 (Pydantic Settings)
│   ├── database.py             # 数据库连接与会话
│   ├── api/
│   │   ├── deps.py             # 依赖注入 (认证、数据库会话)
│   │   └── v1/
│   │       ├── router.py       # 路由注册
│   │       ├── auth.py         # 认证端点
│   │       ├── user.py         # 用户档案与目标
│   │       ├── food.py         # 食物识别与搜索
│   │       ├── meals.py        # 餐食记录 CRUD
│   │       ├── water.py        # 饮水追踪
│   │       ├── stats.py        # 统计与洞察
│   │       └── demo.py         # 演示数据种子
│   ├── models/
│   │   ├── user.py             # User 模型
│   │   ├── meal.py             # MealRecord + DetectedFood 模型
│   │   ├── water.py            # WaterLog + WeightLog 模型
│   │   └── food.py             # 食物数据库模型
│   ├── schemas/                # Pydantic 请求/响应模型
│   │   ├── auth.py
│   │   ├── user.py
│   │   ├── food.py
│   │   ├── meal.py
│   │   ├── water.py
│   │   └── stats.py
│   └── services/
│       ├── auth_service.py     # JWT 生成与验证
│       ├── ai_service.py       # AI 图片分析 (Claude)
│       └── food_db_service.py  # 食物数据库查询
├── pyproject.toml              # 依赖定义
├── uv.lock                     # 依赖锁定
└── .env.example                # 环境变量模板
```

## 快速开始

### 1. 启动基础设施

```bash
# 在项目根目录启动 PostgreSQL、Redis、MinIO
docker-compose up -d
```

服务端口:
- PostgreSQL: `5432`
- Redis: `6379`
- MinIO API: `9000` / 控制台: `9001`

### 2. 配置环境变量

```bash
cd backend
cp .env.example .env
# 按需修改 .env 中的配置
```

### 3. 安装依赖并启动

```bash
uv sync
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 4. 访问 API 文档

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- 健康检查: http://localhost:8000/health

## API 端点

### 认证 `/api/v1/auth`

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/auth/device` | 设备 UUID 匿名认证 |
| POST | `/auth/apple` | Apple Sign-In 认证 |
| POST | `/auth/refresh` | 刷新 access token |
| DELETE | `/auth/account` | 删除账户及所有数据 |

### 用户 `/api/v1/user`

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/user/profile` | 获取用户档案 |
| PUT | `/user/profile` | 更新用户档案 |
| PUT | `/user/goals` | 更新每日营养目标 |
| POST | `/user/weight` | 记录体重 |
| GET | `/user/streaks` | 获取打卡连续天数 |
| GET | `/user/achievements` | 获取成就徽章 |

### 食物识别 `/api/v1/food`

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/food/analyze` | 上传食物图片进行 AI 识别 |
| GET | `/food/barcode/{code}` | 条码查询食物信息 |
| GET | `/food/search?q=...` | 搜索食物数据库 |

图片要求: JPEG / PNG / WebP，最大 10MB

### 餐食记录 `/api/v1/meals`

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/meals` | 创建餐食记录 |
| GET | `/meals?date=2025-02-11` | 按日期查询餐食 |
| PUT | `/meals/{meal_id}` | 更新餐食记录 |
| DELETE | `/meals/{meal_id}` | 删除餐食记录 |

### 饮水追踪 `/api/v1/water`

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/water` | 记录饮水量 |
| GET | `/water?date=2025-02-11` | 查询当日饮水记录 |

### 统计分析 `/api/v1/stats`

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/stats/daily?date=2025-02-11` | 每日营养统计 |
| GET | `/stats/weekly?week=2025-02-10` | 每周统计 (含每日明细) |
| GET | `/stats/monthly?month=2025-02` | 每月统计 (含打卡天数) |
| GET | `/stats/insights` | AI 饮食洞察与建议 |

### 演示数据 `/api/v1/demo`

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/demo/seed` | 插入演示数据 (幂等) |

## 认证机制

所有 API 请求（除 `/auth/*` 和 `/health`）需携带 JWT:

```
Authorization: Bearer <access_token>
```

### 设备匿名认证流程

1. iOS 客户端生成 UUID 存入 Keychain
2. 调用 `POST /auth/device` 发送 `{ "device_id": "uuid-xxx" }`
3. 后端查找或创建用户，返回 JWT access token
4. 后续请求携带该 token

## 数据库模型

| 模型 | 表名 | 说明 |
|------|------|------|
| User | `users` | 用户档案、营养目标、订阅状态 |
| MealRecord | `meal_records` | 餐食记录 (含营养数据、AI 分析) |
| DetectedFood | `detected_foods` | AI 识别的食物条目 (关联 MealRecord) |
| WaterLog | `water_logs` | 饮水记录 |
| WeightLog | `weight_logs` | 体重记录 |

## AI 食物识别

使用 Anthropic Claude 进行食物图片识别:

1. **Claude API** (通过 Agent Maestro 代理) — 首选
2. **Mock 模式** — API 不可用时返回模拟数据

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DATABASE_URL` | `postgresql+asyncpg://...localhost:5432/foodmoment` | 数据库连接串 |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis 连接串 |
| `JWT_SECRET_KEY` | `local-dev-secret-key-...` | JWT 签名密钥 (生产环境必须更换) |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `10080` (7 天) | Token 过期时间 |
| `ANTHROPIC_BASE_URL` | `https://...ngrok-free.dev/api/anthropic` | Claude API 代理地址 |
| `ANTHROPIC_MODEL` | `claude-opus-4.6-fast` | Claude 模型 |
| `ANTHROPIC_ENABLED` | `true` | 启用 Claude AI 识别 |
| `STORAGE_PROVIDER` | `minio` | 存储提供商 (minio/s3/azure) |
| `MINIO_ENDPOINT` | `localhost:9000` | MinIO 地址 |
| `LOG_LEVEL` | `DEBUG` | 日志级别 |

完整配置参见 `.env.example`。

## ngrok 域名分配

| 域名 | 用途 | 部署位置 |
|------|------|---------|
| `<your-backend>.ngrok-free.dev` | 后端服务（端口 9800） | 本机 |
| `<your-ai-proxy>.ngrok-free.dev` | Anthropic API 代理 | 另一台机器 |

> ngrok 免费版每个账户同时只能开一个隧道，因此后端服务和 Anthropic API 代理分别部署在不同机器上，各自使用独立的 ngrok 域名。实际域名在 `.env` 中配置。
