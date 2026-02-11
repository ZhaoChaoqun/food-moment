# FoodMoment 前后端集成开发计划

## Context

FoodMoment 当前处于开发阶段，iOS 端使用本地 `MockDataProvider` + SwiftData 提供数据。目标是将所有数据获取统一通过后端 API 完成，即使是 demo/mock 数据也从 backend 获取，以确保开发模式与生产环境的数据流一致性。

Backend API 已基本就绪（FastAPI + PostgreSQL），iOS 端网络层（APIClient、APIEndpoint、TokenManager）也已完整搭建。本计划聚焦于如何分阶段将 iOS 端从"本地数据优先"迁移到"API 优先 + 本地缓存"架构。

**补充决策：**
1. **不增加年度统计**（降低复杂度），Statistics 页面的 Year 选项暂时移除或禁用
2. **删除用户登录**，改为设备 UUID 匿名认证 — 首次启动自动生成 UUID 存入 Keychain，后端据此创建/识别用户，用户无需看到任何登录界面

---

## 圆桌会议

### 与会者

**iOS 开发组**
- **iOS-A**（架构/网络层负责人）
- **iOS-B**（ViewModel/数据流负责人）
- **iOS-C**（SwiftData/持久化负责人）
- **iOS-D**（UI/View 层负责人）
- **iOS-E**（测试/质量负责人）

**后端开发组**
- **BE-A**（API 架构/路由负责人）
- **BE-B**（数据库/模型负责人）
- **BE-C**（AI 服务/食物分析负责人）
- **BE-D**（认证/安全负责人）
- **BE-E**（部署/DevOps 负责人）

---

## 一、现状盘点

### 1.1 iOS 端数据流现状

| ViewModel | 数据来源 | MockDataProvider 依赖 | API 调用 | 迁移复杂度 |
|-----------|---------|----------------------|----------|-----------|
| AnalysisViewModel | API (食物分析) + SwiftData (保存) | 仅 Preview 用 `mockAnalysis()` | `APIClient.upload(.analyzeFood)` | **已完成** |
| DiaryViewModel | SwiftData (MealRecord, UserProfile) | 空数据时 fallback | 无 | 低 |
| HomeViewModel | SwiftData (MealRecord, WaterLog, UserProfile) | User, NutritionGoals, Health 等 6 处 | 无 | 中 |
| ProfileViewModel | SwiftData (UserProfile, WeightLog, Achievement, MealRecord) | User, Weight, Streak, Achievements 等多处 | 无 | 中 |
| StatisticsViewModel | 无 SwiftData | 100% mock (随机数据) | 无 | **高** |

### 1.2 后端 API 就绪度

| 模块 | 端点 | 状态 |
|------|------|------|
| Auth | `POST /auth/apple`, `POST /auth/refresh`, `DELETE /auth/account` | 完整 |
| Food | `POST /food/analyze` | 完整（4 级 AI fallback） |
| Food | `GET /food/barcode/{code}`, `GET /food/search` | Stub（本地数据库，外部 API 待接入） |
| Meals | `POST /meals`, `GET /meals`, `PUT /meals/{id}`, `DELETE /meals/{id}` | 完整 |
| Water | `POST /water`, `GET /water` | 完整 |
| Stats | `GET /stats/daily`, `/stats/weekly`, `/stats/monthly` | 完整 |
| Stats | `GET /stats/insights` | 完整（规则引擎，非 LLM） |
| User | `GET /user/profile`, `PUT /user/profile`, `PUT /user/goals` | 完整 |
| User | `GET /user/achievements` | 完整（但无 Pydantic schema，返回 raw dict） |
| User | `POST /user/weight`, `GET /user/streaks` | 完整 |
| Demo | `POST /demo/seed` | **不存在，需新增** |

### 1.3 iOS 网络层现状

已完整搭建，可直接使用：

| 组件 | 文件 | 状态 |
|------|------|------|
| APIClient | `Core/Network/APIClient.swift` | 完整（actor, snake_case 自动转换） |
| APIEndpoint | `Core/Network/APIEndpoint.swift` | 完整（全部端点已定义） |
| TokenManager | `Core/Network/TokenManager.swift` | 完整（Keychain JWT 管理） |
| APIError | `Core/Network/APIError.swift` | 完整（含重试/重认证判断） |
| SyncManager | `Core/Sync/SyncManager.swift` | 基础版（仅同步 MealRecord） |

### 1.4 Backend Pydantic Schema 现状

| Schema 文件 | 已定义 |
|------------|--------|
| `schemas/meal.py` | `MealCreate`, `MealResponse`, `MealUpdate`, `DetectedFoodCreate` |
| `schemas/water.py` | `WaterLogCreate`, `WaterLogResponse`, `DailyWaterResponse` |
| `schemas/user.py` | `UserProfileResponse`, `UserProfileUpdate`, `GoalsUpdate`, `WeightLogCreate`, `WeightLogResponse`, `StreakResponse` |
| `schemas/stats.py` | `DailyStats`, `WeeklyStats`, `MonthlyStats`, `InsightResponse` |
| `schemas/food.py` | `DetectedFoodResponse`, `FoodAnalysisResponse` |
| `schemas/auth.py` | 认证相关 |

**缺失**：`AchievementResponse` schema（当前 `GET /user/achievements` 返回无类型 dict 列表）

---

## 二、圆桌讨论纪要

### 议题 1：目标架构（iOS-A 主持）

**iOS-A**: 目标数据流应为：

```
View → ViewModel → Service (protocol) → APIClient → Backend
                       ↕
                  SwiftData (缓存)
```

引入 Service 协议层的好处：
- ViewModel 依赖 protocol 而非 APIClient 具体实现，便于测试和 Preview
- 缓存逻辑封装在 Service 内部，ViewModel 无需感知

**iOS-B**: 同意。每个 ViewModel 当前直接持有 `ModelContext` 从 SwiftData 读数据。迁移后，ViewModel 持有 Service protocol，Service 内部决定是读缓存还是调 API。

**iOS-C**: SwiftData 的角色从"主数据源"变为"离线缓存"。数据写入流程变为：API 写入成功 → 同步写入 SwiftData 缓存。

### 议题 2：Demo 数据策略（BE-A 主持）

**BE-A**: 建议新增 `POST /api/v1/demo/seed` 端点。首次调用时在数据库中插入演示数据（3 条 Meal 记录、用户档案、水记录、体重记录等），后续通过正常 API 读取。

**BE-B**: 需注意 seed 操作的幂等性 —— 多次调用不应重复插入。可以检查用户是否已有 Meal 记录，有则跳过。

**iOS-D**: iOS 端在开发模式下（`#if DEBUG`），首次启动时自动调用 seed 端点。正式发布时不触发。

**BE-D**: seed 端点需要认证（依赖 `CurrentUserId`），确保数据插入到正确的用户下。

### 议题 3：Schema 对齐（iOS-A, BE-A 联合讨论）

**iOS-A**: APIClient 已配置 `.convertFromSnakeCase`，iOS DTO 用 camelCase 即可自动映射。无需手写 CodingKeys。

**BE-A**: `GET /user/achievements` 当前返回 raw dict，需要补一个 `AchievementResponse` Pydantic model。字段：`id`, `title`, `description`, `emoji`, `unlocked`, `progress`, `target`。

**iOS-B**: iOS 端的 `AchievementItem` 有 `tier`（gold/silver/bronze）和 `category` 属性，但 backend 没有。两个选择：
1. Backend 也加 `tier` 和 `category` 字段
2. iOS 端根据 `progress/target` 比率自行推算 tier

**共识**: 先采用方案 2（iOS 端推算），后续根据需求再扩展 backend。

### 议题 4：迁移顺序（iOS-B 主持）

**iOS-B**: 按复杂度递增排序：

1. **DiaryViewModel** — 最简单，仅需 `MealService.getMeals()` + `UserService.getProfile()`
2. **HomeViewModel** — 复用 Phase 1 的 Service，增加 `WaterService`
3. **ProfileViewModel** — 多个独立 API（profile, weight, streaks, achievements）
4. **StatisticsViewModel** — 最复杂，100% mock 需全部替换

**iOS-E**: 每个 Phase 完成后需验证：正常网络、断网、弱网三种场景。

### 议题 5：离线策略（iOS-C 主持）

**iOS-C**: 采用"缓存优先展示，异步刷新"策略：

1. ViewModel 加载时先从 SwiftData 读缓存，立即展示
2. 同时发起 API 请求获取最新数据
3. API 成功后更新 SwiftData 缓存 + 刷新 UI
4. API 失败时保持缓存数据不变

**写操作**（addWater, logWeight, saveMeal）：
- 在线时：API 写入 → 成功后写 SwiftData（`isSynced = true`）
- 离线时：先写 SwiftData（`isSynced = false`）→ 网络恢复后 SyncManager 重传

### 议题 6：匿名认证方案（BE-D, iOS-A 联合讨论）

**BE-D**: 删除 Apple Sign-In，改为设备 UUID 匿名认证。流程：

1. iOS 首次启动时生成 UUID，存入 Keychain（卸载重装不丢失）
2. 调用 `POST /auth/device` 发送 `{ device_id: "uuid-xxx" }`
3. Backend 查找是否存在该 `device_id` 的用户：
   - 存在 → 返回 JWT access token
   - 不存在 → 创建新用户 → 返回 JWT access token
4. iOS 收到 token 后存入 Keychain（复用现有 `TokenManager`）
5. 后续所有 API 请求照常携带 `Bearer {token}`

**iOS-A**: 这样 `TokenManager`、`APIClient` 的 token 注入逻辑、`deps.py` 的 `CurrentUserId` 依赖都不需要改——JWT 机制完全保留，只是获取 token 的方式从 Apple Sign-In 变成设备 UUID 注册。

**iOS-D**: 用户无需看到任何登录界面。App 启动时自动完成设备注册，直接进入主界面。`ContentView.swift` 中的 `isAuthenticated` 判断可以移除，`SignInView` 可以删除。

**BE-B**: User 模型中 `apple_user_id` 字段改为 `device_id`，仍保持 UNIQUE + INDEXED。

**共识**: 此方案简洁可靠。缺点是换设备会丢数据，但当前阶段可接受。未来可加可选 Apple Sign-In 实现跨设备同步。

---

## 三、分阶段实施计划

### Phase 0：基础设施准备

#### 0.1 Backend：新增 Demo Seed 端点

**新建文件**: `backend/app/api/v1/demo.py`

```python
@router.post("/seed")
async def seed_demo_data(user_id: CurrentUserId, db: DbSession):
    # 1. 检查用户是否已有 Meal 记录（幂等）
    # 2. 插入 3 条演示 Meal (与 MockDataProvider 数据一致)
    # 3. 插入当日 WaterLog (1250ml)
    # 4. 插入 WeightLog (68.0kg)
    # 5. 返回 {"seeded": true, "meals": 3, "water_logs": 1}
```

**修改文件**: `backend/app/api/v1/router.py` — 注册 demo router

#### 0.2 Backend：规范 Achievements Schema

**修改文件**: `backend/app/schemas/user.py`

新增：
```python
class AchievementResponse(BaseModel):
    id: str
    title: str
    description: str
    emoji: str
    unlocked: bool
    progress: int
    target: int
```

**修改文件**: `backend/app/api/v1/user.py:69` — 添加 `response_model=list[AchievementResponse]`

#### 0.3 Backend：匿名设备认证端点

**修改文件**: `backend/app/api/v1/auth.py`

新增 `POST /auth/device` 端点（替代 Apple Sign-In 作为主要认证方式）：

```python
class DeviceAuthRequest(BaseModel):
    device_id: str  # iOS 生成的 UUID

@router.post("/device", response_model=TokenResponse)
async def device_auth(request: DeviceAuthRequest, db: DbSession):
    # 1. 按 device_id 查找用户
    # 2. 不存在则创建（display_name 默认 "用户"）
    # 3. 生成 JWT access_token（复用 auth_service.create_access_token）
    # 4. 返回 TokenResponse
```

**修改文件**: `backend/app/schemas/auth.py` — 新增 `DeviceAuthRequest`

**修改文件**: `backend/app/models/user.py`
- `apple_user_id` 字段改为 `device_id`（类型不变，仍为 UNIQUE + INDEXED）
- 或保留 `apple_user_id` 并新增 `device_id` 字段（便于未来恢复 Apple Sign-In）

**修改文件**: `backend/app/services/auth_service.py`
- 新增 `find_or_create_user_by_device_id(device_id, db)` 方法
- Apple 相关的 token 验证方法可保留但不再是主流程

#### 0.4 iOS：匿名认证改造

**修改文件**: `FoodMoment/Core/Network/TokenManager.swift`

新增设备 UUID 管理（复用现有 Keychain 基础设施）：

```swift
// 在 TokenManager 中新增
private static let deviceIdKey = "fm_device_uuid"

var deviceId: String {
    if let existing = readFromKeychain(key: Self.deviceIdKey) {
        return existing
    }
    let newId = UUID().uuidString
    saveToKeychain(key: Self.deviceIdKey, value: newId)
    return newId
}
```

**修改文件**: `FoodMoment/Core/Network/APIEndpoint.swift`
- 新增 `case deviceAuth` → `POST /auth/device`
- `appleSignIn` 端点保留但不再使用

**修改文件**: `FoodMoment/App/ContentView.swift`
- 删除 `isAuthenticated` 条件判断，直接展示 `MainTabView`
- 在 `.task` 中自动执行设备注册：

```swift
var body: some View {
    MainTabView()
        .task {
            await autoRegisterDevice()
        }
}

private func autoRegisterDevice() async {
    // 若已有有效 token 则跳过
    guard await !TokenManager.shared.isTokenValid else { return }
    let deviceId = await TokenManager.shared.deviceId
    // 调用 POST /auth/device
    // 存储返回的 access_token
}
```

**修改文件**: `FoodMoment/App/AppState.swift`
- `isAuthenticated` 属性可保留用于标记设备注册是否完成，但不再控制 UI 路由

**删除文件**:
- `FoodMoment/Features/Auth/SignInView.swift` — 不再需要登录界面
- `FoodMoment/Features/Auth/AuthViewModel.swift` — Apple 认证逻辑不再需要

**修改文件**: `FoodMoment/Features/Profile/SettingsView.swift`
- 删除"退出登录"按钮和相关 alert（第 195-206 行）
- "删除账户"按钮保留（GDPR/App Store 要求），但行为改为清除本地数据 + 调用 `DELETE /auth/account`

**修改文件**: `FoodMoment/Features/Profile/ProfileViewModel.swift`
- 删除 `signOut(appState:)` 方法

#### 0.5 iOS：新建 Response DTO 层

**目录**: `FoodMoment/Models/DTOs/`（已有 `AnalysisResponse.swift`, `NutritionData.swift`）

| 新建文件 | DTO 类型 | 对应 Backend Schema |
|---------|---------|-------------------|
| `MealResponseDTO.swift` | `MealResponseDTO` | `MealResponse` |
| `WaterResponseDTO.swift` | `DailyWaterResponseDTO`, `WaterLogResponseDTO` | `DailyWaterResponse`, `WaterLogResponse` |
| `UserProfileDTO.swift` | `UserProfileResponseDTO` | `UserProfileResponse` |
| `StatsDTO.swift` | `DailyStatsDTO`, `WeeklyStatsDTO`, `MonthlyStatsDTO` | 各 Stats Schema |
| `InsightDTO.swift` | `InsightResponseDTO` | `InsightResponse` |
| `AchievementDTO.swift` | `AchievementResponseDTO` | `AchievementResponse` |
| `StreakDTO.swift` | `StreakResponseDTO` | `StreakResponse` |

所有 DTO 使用 camelCase 属性名，利用 APIClient 的 `.convertFromSnakeCase` 自动映射。

#### 0.6 iOS：新建 Service 协议层

**新建目录**: `FoodMoment/Core/Services/`

| 文件 | Protocol | 实现类 | 职责 |
|------|----------|-------|------|
| `MealService.swift` | `MealServiceProtocol` | `MealService` | getMeals, createMeal, updateMeal, deleteMeal |
| `WaterService.swift` | `WaterServiceProtocol` | `WaterService` | logWater, getWater |
| `UserService.swift` | `UserServiceProtocol` | `UserService` | getProfile, updateProfile, getAchievements, getStreaks, logWeight, updateGoals |
| `StatsService.swift` | `StatsServiceProtocol` | `StatsService` | getDailyStats, getWeeklyStats, getMonthlyStats, getInsights |

参考模式 — AnalysisViewModel 中的 `APIClient.shared.upload(.analyzeFood)` (`AnalysisViewModel.swift:99`)

#### 0.7 iOS：APIEndpoint 补充

**修改文件**: `FoodMoment/Core/Network/APIEndpoint.swift`

需新增：
- `case seedDemo` — `POST /demo/seed`
- `case deviceAuth` — `POST /auth/device`

其余端点已全部定义，无需修改。

---

### Phase 1：DiaryViewModel 迁移

**改造文件**: `FoodMoment/Features/Diary/DiaryViewModel.swift`

#### 改动清单

| 方法 | 当前实现 | 改为 |
|------|---------|------|
| `loadMeals()` | SwiftData 查询 MealRecord | `MealService.getMeals(date:)` + 缓存 |
| `precomputeDatesWithMeals()` | SwiftData 周查询 | `MealService.getMeals(date:)` 遍历一周 |
| `deleteMeal()` | SwiftData delete | `MealService.deleteMeal(id:)` + 本地删除 |
| `loadDemoDataIfNeeded()` | MockDataProvider | **删除**（demo 数据由 seed 端点提供） |
| `dailyCalorieGoal` | MockDataProvider fallback | `UserService.getProfile()` |

#### 关键变更

- `loadMeals(modelContext:)` 签名改为 `loadMeals(modelContext:) async`
- View 层 `.onAppear { viewModel.loadMeals(...) }` 改为 `.task { await viewModel.loadMeals(...) }`
- 新增 `MealResponseDTO → MealRecord` 转换逻辑

---

### Phase 2：HomeViewModel 迁移

**改造文件**: `FoodMoment/Features/Home/HomeViewModel.swift`

#### 改动清单

| 方法 | 当前实现 | 改为 |
|------|---------|------|
| `loadTodayData()` | 调 5 个本地方法 | 并发调 `MealService` + `WaterService` + `UserService` |
| `fetchTodayMeals()` | SwiftData | 复用 Phase 1 的 `MealService` |
| `fetchTodayWaterLogs()` | SwiftData | `WaterService.getWater(date:)` |
| `loadUserProfile()` | SwiftData + mock fallback | `UserService.getProfile()` |
| `addWater()` | 直接写 SwiftData | `WaterService.logWater()` + 写缓存 |
| `loadMockUserData()` 等 6 个 mock 方法 | MockDataProvider | **全部删除** |
| `loadDemoDataIfNeeded()` | MockDataProvider | **删除** |

#### 并发请求模式

```swift
async let meals = mealService.getMeals(date: todayString)
async let water = waterService.getWater(date: todayString)
async let profile = userService.getProfile()
let (m, w, p) = try await (meals, water, profile)
```

#### 注意

- `stepCount` 和 `caloriesBurned` 来自 HealthKit，不走 backend，保持不变

---

### Phase 3：ProfileViewModel 迁移

**改造文件**: `FoodMoment/Features/Profile/ProfileViewModel.swift`

#### 改动清单

| 方法 | 当前实现 | 改为 |
|------|---------|------|
| `loadProfile()` | 调 6 个子方法（全 SwiftData） | 并发调 `UserService.getProfile/getStreaks/getAchievements` |
| `loadWeightData()` | SwiftData WeightLog | 从 `getProfile()` 响应中取 `targetWeight` + API 获取最新体重 |
| `loadStreakData()` | SwiftData MealRecord 计算 | `UserService.getStreaks()` |
| `loadAchievements()` | SwiftData + mock fallback | `UserService.getAchievements()` |
| `loadCalorieData()` | SwiftData MealRecord 聚合 | `StatsService.getWeeklyStats()` |
| `loadDailyActivities()` | SwiftData MealRecord 月查询 | `StatsService.getMonthlyStats()` 的 `dailyStats` |
| `logWeight()` | 写 SwiftData + HealthKit | `UserService.logWeight()` + 写缓存 + HealthKit |

#### AchievementResponseDTO → AchievementItem 映射

```swift
func mapAchievement(_ dto: AchievementResponseDTO) -> AchievementItem {
    let tier: Achievement.AchievementTier = switch Double(dto.progress) / Double(dto.target) {
        case 1.0: .gold
        case 0.5...: .silver
        default: .bronze
    }
    return AchievementItem(type: dto.id, title: dto.title, ...)
}
```

---

### Phase 4：StatisticsViewModel 迁移

**改造文件**: `FoodMoment/Features/Statistics/StatisticsViewModel.swift`

这是最复杂的迁移，当前 100% mock 数据。

#### 改动清单

| 方法 | 当前实现 | 改为 |
|------|---------|------|
| `loadStatistics()` | 调 4 个 mock 方法 | 根据 `selectedRange` 调不同 StatsService 方法 |
| `loadMockData()` | 随机生成卡路里数据 | `StatsService.getDaily/Weekly/MonthlyStats()` |
| `loadMockMacros()` | MockDataProvider.MacroRanges | 从 Stats 响应中提取 macro 数据 |
| `loadMockCheckins()` | 随机日期生成 | 从 `MonthlyStats.dailyStats` 过滤 `mealCount > 0` 的日期 |
| `loadMockAIInsight()` | MockDataProvider 随机选取 | `StatsService.getInsights()` |

#### TimeRange → API 映射

| TimeRange | API 调用 |
|-----------|---------|
| `.day` | `StatsService.getDailyStats(date:)` |
| `.week` | `StatsService.getWeeklyStats(week:)` |
| `.month` | `StatsService.getMonthlyStats(month:)` |
| `.year` | **暂不支持，UI 层禁用或隐藏该选项** |

#### 数据映射

```swift
// WeeklyStatsDTO → calorieData
calorieData = stats.dailyStats.map { daily in
    DailyCalorie(date: parseDate(daily.date), calories: daily.totalCalories,
                 protein: daily.proteinGrams, carbs: daily.carbsGrams, fat: daily.fatGrams)
}
weeklyAverage = Int(stats.avgCalories)
```

---

### Phase 5：清理与收尾

#### 5.1 删除 MockDataProvider

**删除文件**: `FoodMoment/Core/MockData/MockDataProvider.swift`

验证：`grep -r "MockDataProvider" FoodMoment/` 返回空

#### 5.2 AnalysisViewModel 对齐

**修改文件**: `FoodMoment/Features/Analysis/AnalysisViewModel.swift`

当前 `saveMeal()` 直接写 SwiftData 再由 SyncManager 上传。改为：
- 在线时：先调 `MealService.createMeal()` → 成功后写 SwiftData（`isSynced = true`）
- 离线时：先写 SwiftData（`isSynced = false`）→ SyncManager 排队重传

#### 5.3 SyncManager 增强

**修改文件**: `FoodMoment/Core/Sync/SyncManager.swift`

扩展同步范围：从仅同步 MealRecord 扩展到 WaterLog 和 WeightLog。

#### 5.4 iOS 端 Demo 模式自动 Seed

**修改文件**: `FoodMoment/App/ContentView.swift`

在 `autoRegisterDevice()` 完成后（Phase 0.4 中实现），`#if DEBUG` 模式下自动调用 `POST /demo/seed`：

```swift
private func autoRegisterDevice() async {
    // 1. 设备注册/登录
    guard await !TokenManager.shared.isTokenValid else { return }
    let deviceId = await TokenManager.shared.deviceId
    let response: TokenResponseDTO = try await APIClient.shared.request(.deviceAuth, body: ...)
    await TokenManager.shared.setAccessToken(response.accessToken)

    // 2. DEBUG 模式下 seed demo 数据
    #if DEBUG
    try? await APIClient.shared.requestVoid(.seedDemo)
    #endif
}
```

#### 5.5 Preview 支持

为 SwiftUI Preview 创建 Mock Service 实现：

**新建目录**: `FoodMoment/Core/Preview/`

| 文件 | 用途 |
|------|------|
| `PreviewMealService.swift` | 返回硬编码 MealResponseDTO |
| `PreviewWaterService.swift` | 返回硬编码 DailyWaterResponseDTO |
| `PreviewUserService.swift` | 返回硬编码 User/Achievement/Streak 数据 |
| `PreviewStatsService.swift` | 返回硬编码 Stats 数据 |

这些文件替代 `MockDataProvider`，仅用于 Preview，不参与正式构建。

---

## 四、关键文件清单

### Backend 需修改/新建

| 文件 | 操作 | Phase |
|------|------|-------|
| `backend/app/api/v1/demo.py` | **新建** | 0 |
| `backend/app/api/v1/auth.py` | 修改（新增 `POST /auth/device` 端点） | 0 |
| `backend/app/schemas/auth.py` | 修改（新增 `DeviceAuthRequest`） | 0 |
| `backend/app/services/auth_service.py` | 修改（新增 `find_or_create_user_by_device_id`） | 0 |
| `backend/app/models/user.py` | 修改（新增 `device_id` 字段） | 0 |
| `backend/app/api/v1/router.py` | 修改（注册 demo router） | 0 |
| `backend/app/schemas/user.py` | 修改（新增 AchievementResponse） | 0 |
| `backend/app/api/v1/user.py:69` | 修改（添加 response_model） | 0 |

### iOS 需修改/新建

| 文件 | 操作 | Phase |
|------|------|-------|
| `FoodMoment/Core/Network/TokenManager.swift` | 修改（新增 deviceId 管理） | 0 |
| `FoodMoment/Core/Network/APIEndpoint.swift` | 修改（+2 端点: deviceAuth, seedDemo） | 0 |
| `FoodMoment/App/ContentView.swift` | 修改（删除登录判断，新增自动注册） | 0 |
| `FoodMoment/App/AppState.swift` | 修改（简化 isAuthenticated 角色） | 0 |
| `FoodMoment/Features/Auth/SignInView.swift` | **删除** | 0 |
| `FoodMoment/Features/Auth/AuthViewModel.swift` | **删除** | 0 |
| `FoodMoment/Features/Profile/SettingsView.swift` | 修改（删除退出登录按钮） | 0 |
| `FoodMoment/Features/Profile/ProfileViewModel.swift` | 修改（删除 signOut 方法） | 0 |
| `FoodMoment/Models/DTOs/MealResponseDTO.swift` | **新建** | 0 |
| `FoodMoment/Models/DTOs/WaterResponseDTO.swift` | **新建** | 0 |
| `FoodMoment/Models/DTOs/UserProfileDTO.swift` | **新建** | 0 |
| `FoodMoment/Models/DTOs/StatsDTO.swift` | **新建** | 0 |
| `FoodMoment/Models/DTOs/InsightDTO.swift` | **新建** | 0 |
| `FoodMoment/Models/DTOs/AchievementDTO.swift` | **新建** | 0 |
| `FoodMoment/Models/DTOs/StreakDTO.swift` | **新建** | 0 |
| `FoodMoment/Core/Services/MealService.swift` | **新建** | 0 |
| `FoodMoment/Core/Services/WaterService.swift` | **新建** | 0 |
| `FoodMoment/Core/Services/UserService.swift` | **新建** | 0 |
| `FoodMoment/Core/Services/StatsService.swift` | **新建** | 0 |
| `FoodMoment/Features/Diary/DiaryViewModel.swift` | 修改 | 1 |
| `FoodMoment/Features/Diary/DiaryView.swift` | 修改（.onAppear → .task） | 1 |
| `FoodMoment/Features/Home/HomeViewModel.swift` | 修改 | 2 |
| `FoodMoment/Features/Home/HomeView.swift` | 修改（.onAppear → .task） | 2 |
| `FoodMoment/Features/Profile/ProfileViewModel.swift` | 修改 | 3 |
| `FoodMoment/Features/Profile/ProfileView.swift` | 修改（.onAppear → .task） | 3 |
| `FoodMoment/Features/Statistics/StatisticsViewModel.swift` | 修改 | 4 |
| `FoodMoment/Features/Statistics/StatisticsView.swift` | 修改（禁用 Year 选项） | 4 |
| `FoodMoment/Features/Analysis/AnalysisViewModel.swift` | 修改（saveMeal 对齐） | 5 |
| `FoodMoment/Core/Sync/SyncManager.swift` | 修改（扩展同步范围） | 5 |
| `FoodMoment/Core/MockData/MockDataProvider.swift` | **删除** | 5 |
| `FoodMoment/Core/Preview/*.swift` | **新建**（4 个 Preview Service） | 5 |

---

## 五、验证方案

### 每个 Phase 的验证清单

| Phase | 验证项 | 方法 |
|-------|-------|------|
| 0 | 设备 UUID 认证流程 | 首次启动自动注册 → 获取 token → 后续 API 请求正常 |
| 0 | Backend 新端点可用 | `curl` 测试 device auth, demo/seed, achievements schema |
| 0 | iOS DTO 解码正确 | 用 backend 实际 JSON 响应编写单元测试 |
| 0 | Service 层调用正确 | Mock APIClient 的单元测试 |
| 1 | DiaryView 数据正常展示 | 启动 backend + seed → 打开日记页验证 |
| 2 | HomeView 全部数据正确 | 验证卡路里、水量、Meal 列表、用户名 |
| 3 | ProfileView 完整 | 验证 achievements、streaks、weight、calorie chart |
| 4 | StatisticsView 图表 | 验证 Day/Week/Month 三种模式数据加载 |
| 5 | 全局无 MockDataProvider | `grep -r "MockDataProvider" FoodMoment/` 返回空 |

### 离线场景验证（每个 Phase）

1. 断开网络 → app 正常展示 SwiftData 缓存数据
2. 恢复网络 → 数据自动刷新
3. 断网时写操作（addWater, logWeight, saveMeal）→ 数据不丢失，恢复后自动同步

---

## 六、风险与缓解

| 风险 | 缓解措施 |
|------|---------|
| Backend 未启动时 app 无数据 | Offline-first：先展示 SwiftData 缓存 |
| snake_case/camelCase 映射出错 | Phase 0 编写 JSON 解码单元测试覆盖所有 DTO |
| Achievement schema iOS/Backend 不匹配 | Phase 0 先对齐，backend 补全 Pydantic schema |
| 同步改异步影响 View 层 | 统一将 `.onAppear` 改为 `.task` modifier |
| 换设备丢失数据 | 当前阶段可接受，未来可加 Apple Sign-In 可选绑定 |
| Demo seed 重复插入 | 幂等检查：已有数据则跳过 |
| Keychain 首次访问权限 | 设备 UUID 生成放在 app 启动最早时机 |
