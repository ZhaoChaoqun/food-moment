# FoodMoment 测试计划

> 📋 版本：1.0
> 📅 创建日期：2026-02-09
> 🎯 目标：确保 App 质量，覆盖率 > 80%，零崩溃上线

---

## 一、测试策略概述

### 1.1 测试金字塔

```
                    ╱╲
                   ╱  ╲
                  ╱ E2E╲          ← UI 测试 (10%)
                 ╱──────╲            XCUITest 关键流程
                ╱        ╲
               ╱ 集成测试  ╲       ← 集成测试 (20%)
              ╱────────────╲         API/数据库/HealthKit
             ╱              ╲
            ╱    单元测试     ╲    ← 单元测试 (70%)
           ╱──────────────────╲      ViewModel/Service/Model
          ╱                    ╲
         ╱    Snapshot 测试     ╲  ← 视觉回归
        ╱────────────────────────╲
```

### 1.2 测试目标

| 指标 | 目标值 |
|------|--------|
| 单元测试覆盖率 | > 80% |
| 关键路径 UI 测试覆盖 | 100% |
| 崩溃率 | < 0.1% |
| 启动时间 (冷启动) | < 2s |
| 内存峰值 | < 150MB |
| 电池影响 | 低 |

### 1.3 测试环境

| 环境 | 设备/模拟器 | iOS 版本 |
|------|------------|----------|
| 开发 | iPhone 17 Pro Simulator | iOS 17.0+ |
| 测试 | iPhone 15/16/17 系列 | iOS 17.0 - 18.x |
| 兼容性 | iPhone SE 3 (最小屏) | iOS 17.0 |
| 性能 | iPhone 12 (基准设备) | iOS 17.0 |

---

## 二、单元测试计划

### 2.1 测试目录结构

```
FoodMomentTests/
├── ViewModels/
│   ├── HomeViewModelTests.swift
│   ├── CameraViewModelTests.swift
│   ├── AnalysisViewModelTests.swift
│   ├── DiaryViewModelTests.swift
│   ├── StatisticsViewModelTests.swift
│   ├── ProfileViewModelTests.swift
│   └── AuthViewModelTests.swift
│
├── Services/
│   ├── APIClientTests.swift
│   ├── CameraServiceTests.swift
│   ├── FoodClassifierServiceTests.swift
│   ├── BarcodeScannerServiceTests.swift
│   ├── HealthKitManagerTests.swift
│   ├── CloudSyncManagerTests.swift
│   ├── NotificationManagerTests.swift
│   └── SpotlightIndexerTests.swift
│
├── Models/
│   ├── MealRecordTests.swift
│   ├── DetectedFoodTests.swift
│   ├── UserProfileTests.swift
│   ├── NutritionDataTests.swift
│   └── DTODecodingTests.swift
│
├── Utilities/
│   ├── DateHelpersTests.swift
│   ├── ColorExtensionsTests.swift
│   └── NumberFormatterTests.swift
│
└── Mocks/
    ├── MockAPIClient.swift
    ├── MockCameraService.swift
    ├── MockHealthKitManager.swift
    ├── MockModelContext.swift
    └── MockURLSession.swift
```

### 2.2 ViewModel 测试用例

#### 2.2.1 HomeViewModel

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_initialState_isCorrect` | 验证初始状态：卡路里、营养素、饮水量 | P0 |
| `test_loadTodayData_success` | 加载今日数据成功 | P0 |
| `test_loadTodayData_emptyData` | 无数据时显示默认值 | P0 |
| `test_addWater_updatesTotal` | 添加饮水更新总量 | P0 |
| `test_addWater_writesToHealthKit` | 饮水同步到 HealthKit | P1 |
| `test_caloriesRemaining_calculation` | 剩余卡路里计算正确 | P0 |
| `test_macroProgress_percentage` | 宏量营养素百分比计算 | P0 |
| `test_greeting_basedOnTime` | 根据时间显示问候语 | P2 |
| `test_refresh_reloadsAllData` | 下拉刷新重新加载 | P1 |

```swift
// 示例测试代码
final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!
    var mockHealthKit: MockHealthKitManager!
    var mockModelContext: MockModelContext!

    override func setUp() {
        super.setUp()
        mockHealthKit = MockHealthKitManager()
        mockModelContext = MockModelContext()
        sut = HomeViewModel(
            healthKitManager: mockHealthKit,
            modelContext: mockModelContext
        )
    }

    func test_caloriesRemaining_calculation() {
        // Given
        sut.dailyCalorieGoal = 2000
        sut.consumedCalories = 1200

        // When
        let remaining = sut.caloriesRemaining

        // Then
        XCTAssertEqual(remaining, 800)
    }

    func test_addWater_updatesTotal() async {
        // Given
        sut.waterIntake = 500

        // When
        await sut.addWater(amount: 250)

        // Then
        XCTAssertEqual(sut.waterIntake, 750)
    }
}
```

#### 2.2.2 CameraViewModel

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_initialState_scanMode` | 初始模式为 Scan | P0 |
| `test_switchMode_toBarcode` | 切换到条形码模式 | P0 |
| `test_capturePhoto_success` | 拍照成功返回图片 | P0 |
| `test_capturePhoto_permissionDenied` | 相机权限被拒绝 | P0 |
| `test_toggleFlash_cyclesThroughModes` | 闪光灯模式循环切换 | P1 |
| `test_barcodeDetected_triggersCallback` | 条形码检测触发回调 | P0 |
| `test_selectFromGallery_success` | 从相册选择图片 | P1 |

#### 2.2.3 AnalysisViewModel

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_analyzeFood_success` | 食物分析成功 | P0 |
| `test_analyzeFood_networkError` | 网络错误处理 | P0 |
| `test_analyzeFood_invalidImage` | 无效图片处理 | P1 |
| `test_totalCalories_sumOfFoods` | 总卡路里为各食物之和 | P0 |
| `test_editFood_updatesCalories` | 编辑食物更新卡路里 | P0 |
| `test_logMeal_savesToSwiftData` | 记录餐食保存到数据库 | P0 |
| `test_logMeal_writesToHealthKit` | 记录餐食写入 HealthKit | P1 |
| `test_logMeal_triggersSync` | 记录后触发云端同步 | P1 |
| `test_shareImage_generated` | 分享图片生成成功 | P2 |

#### 2.2.4 DiaryViewModel

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_loadMeals_forSelectedDate` | 加载选中日期的餐食 | P0 |
| `test_loadMeals_emptyDate` | 无记录日期显示空状态 | P0 |
| `test_deleteMeal_removesFromList` | 删除餐食从列表移除 | P0 |
| `test_deleteMeal_updatesStatistics` | 删除后统计更新 | P1 |
| `test_searchMeals_byFoodName` | 按食物名搜索 | P1 |
| `test_filterByMealType_works` | 按餐次类型筛选 | P2 |
| `test_weekDatePicker_navigation` | 周日期选择器导航 | P1 |
| `test_dailyProgress_percentage` | 每日达标百分比计算 | P0 |

#### 2.2.5 StatisticsViewModel

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_loadWeeklyData_aggregation` | 周数据聚合正确 | P0 |
| `test_loadMonthlyData_aggregation` | 月数据聚合正确 | P0 |
| `test_averageCalories_calculation` | 平均卡路里计算 | P0 |
| `test_trendPercentage_increase` | 环比增长百分比 | P1 |
| `test_trendPercentage_decrease` | 环比下降百分比 | P1 |
| `test_checkinStreak_continuous` | 连续打卡天数计算 | P1 |
| `test_exportCSV_format` | CSV 导出格式正确 | P2 |
| `test_timeRangeChange_reloadsData` | 切换时间范围重新加载 | P0 |

#### 2.2.6 ProfileViewModel

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_loadProfile_success` | 加载用户资料成功 | P0 |
| `test_updateWeight_savesToHealthKit` | 更新体重保存到 HealthKit | P0 |
| `test_weightTrend_calculation` | 体重趋势计算 | P1 |
| `test_streakDays_calculation` | 打卡天数计算 | P1 |
| `test_achievements_unlocked` | 成就解锁判断 | P2 |
| `test_deleteAccount_clearsAllData` | 删除账户清除所有数据 | P0 |
| `test_signOut_clearsSession` | 登出清除会话 | P0 |

### 2.3 Service 测试用例

#### 2.3.1 APIClient

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_request_success` | 请求成功返回数据 | P0 |
| `test_request_decodingError` | JSON 解析错误处理 | P0 |
| `test_request_networkError` | 网络错误处理 | P0 |
| `test_request_unauthorized` | 401 触发 token 刷新 | P0 |
| `test_request_serverError` | 5xx 服务器错误处理 | P0 |
| `test_request_timeout` | 超时错误处理 | P1 |
| `test_tokenRefresh_success` | Token 刷新成功 | P0 |
| `test_tokenRefresh_failure` | Token 刷新失败登出 | P0 |

```swift
final class APIClientTests: XCTestCase {
    var sut: APIClient!
    var mockSession: MockURLSession!

    func test_request_success() async throws {
        // Given
        let expectedData = """
        {"id": 1, "name": "Test Food"}
        """.data(using: .utf8)!
        mockSession.data = expectedData
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // When
        let result: FoodItem = try await sut.request(.foodSearch(query: "test"))

        // Then
        XCTAssertEqual(result.id, 1)
        XCTAssertEqual(result.name, "Test Food")
    }

    func test_request_unauthorized_triggersRefresh() async {
        // Given
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )

        // When/Then
        do {
            let _: FoodItem = try await sut.request(.foodSearch(query: "test"))
            XCTFail("Should throw unauthorized error")
        } catch APIError.unauthorized {
            XCTAssertTrue(mockSession.refreshTokenCalled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
```

#### 2.3.2 FoodClassifierService

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_classify_validImage` | 有效图片返回识别结果 | P0 |
| `test_classify_invalidImage` | 无效图片返回错误 | P0 |
| `test_classify_noFoodDetected` | 未检测到食物 | P1 |
| `test_classify_multipleFoods` | 检测到多个食物 | P0 |
| `test_boundingBox_normalized` | 边界框坐标归一化 | P1 |
| `test_confidence_threshold` | 置信度阈值过滤 | P1 |
| `test_nutritionMapping_exists` | 营养数据映射存在 | P0 |

#### 2.3.3 HealthKitManager

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_requestAuthorization_granted` | 授权成功 | P0 |
| `test_requestAuthorization_denied` | 授权被拒绝 | P0 |
| `test_saveNutrition_success` | 保存营养数据成功 | P0 |
| `test_saveWater_success` | 保存饮水数据成功 | P0 |
| `test_saveWeight_success` | 保存体重数据成功 | P0 |
| `test_readSteps_today` | 读取今日步数 | P0 |
| `test_readWeight_latest` | 读取最新体重 | P1 |

### 2.4 Model 测试用例

#### 2.4.1 MealRecord

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_init_defaultValues` | 初始化默认值正确 | P0 |
| `test_totalCalories_fromDetectedFoods` | 总卡路里从食物计算 | P0 |
| `test_mealType_fromTime` | 根据时间推断餐次 | P1 |
| `test_relationship_detectedFoods` | 食物关联关系 | P0 |

#### 2.4.2 DTO Decoding

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_AnalysisResponseDTO_decoding` | 分析响应解码 | P0 |
| `test_NutritionDataDTO_decoding` | 营养数据解码 | P0 |
| `test_DetectedFoodDTO_decoding` | 检测食物解码 | P0 |
| `test_partialData_decoding` | 部分字段缺失处理 | P1 |
| `test_invalidJSON_throwsError` | 无效 JSON 抛错 | P0 |

```swift
final class DTODecodingTests: XCTestCase {
    func test_AnalysisResponseDTO_decoding() throws {
        // Given
        let json = """
        {
            "image_url": "https://example.com/food.jpg",
            "total_calories": 485,
            "total_nutrition": {
                "protein_g": 22,
                "carbs_g": 45,
                "fat_g": 18,
                "fiber_g": 6
            },
            "detected_foods": [
                {
                    "name": "Poached Egg",
                    "name_zh": "水波蛋",
                    "emoji": "🥚",
                    "confidence": 0.95,
                    "bounding_box": {"x": 0.55, "y": 0.15, "w": 0.2, "h": 0.15},
                    "calories": 140,
                    "color": "#FACC15"
                }
            ],
            "ai_analysis": "营养均衡的一餐！"
        }
        """.data(using: .utf8)!

        // When
        let result = try JSONDecoder().decode(AnalysisResponseDTO.self, from: json)

        // Then
        XCTAssertEqual(result.totalCalories, 485)
        XCTAssertEqual(result.totalNutrition.proteinG, 22)
        XCTAssertEqual(result.detectedFoods.count, 1)
        XCTAssertEqual(result.detectedFoods[0].name, "Poached Egg")
    }
}
```

---

## 三、UI 测试计划 (XCUITest)

### 3.1 测试目录结构

```
FoodMomentUITests/
├── Flows/
│   ├── OnboardingFlowTests.swift
│   ├── CaptureToLogFlowTests.swift
│   ├── DiaryBrowsingFlowTests.swift
│   └── SettingsFlowTests.swift
│
├── Screens/
│   ├── HomeScreenTests.swift
│   ├── CameraScreenTests.swift
│   ├── AnalysisScreenTests.swift
│   ├── DiaryScreenTests.swift
│   ├── StatisticsScreenTests.swift
│   └── ProfileScreenTests.swift
│
├── Accessibility/
│   └── AccessibilityTests.swift
│
└── Helpers/
    ├── XCUIApplication+Launch.swift
    ├── XCUIElement+Wait.swift
    └── TestData.swift
```

### 3.2 关键流程测试

#### 3.2.1 核心用户旅程：拍照 → 识别 → 记录

```swift
final class CaptureToLogFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-camera"]
        app.launch()
    }

    func test_completeFlow_captureAnalyzeLog() {
        // 1. 点击中间的扫描按钮
        let scanButton = app.buttons["ScanTabButton"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: 5))
        scanButton.tap()

        // 2. 等待相机界面出现
        let shutterButton = app.buttons["ShutterButton"]
        XCTAssertTrue(shutterButton.waitForExistence(timeout: 5))

        // 3. 拍照
        shutterButton.tap()

        // 4. 等待分析结果页面
        let totalEnergy = app.staticTexts["TOTAL ENERGY"]
        XCTAssertTrue(totalEnergy.waitForExistence(timeout: 10))

        // 5. 验证营养素圆环显示
        XCTAssertTrue(app.otherElements["ProteinRing"].exists)
        XCTAssertTrue(app.otherElements["CarbsRing"].exists)
        XCTAssertTrue(app.otherElements["FatRing"].exists)

        // 6. 点击记录按钮
        let logButton = app.buttons["LogMealButton"]
        XCTAssertTrue(logButton.exists)
        logButton.tap()

        // 7. 验证返回首页并更新数据
        let homeTab = app.buttons["HomeTabButton"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))

        // 8. 验证今日食刻更新
        let foodMomentCard = app.otherElements["FoodMomentCard"].firstMatch
        XCTAssertTrue(foodMomentCard.waitForExistence(timeout: 5))
    }

    func test_editFood_beforeLogging() {
        // 导航到分析页面...

        // 点击食物标签编辑
        let foodTag = app.buttons["FoodTagButton_0"]
        foodTag.tap()

        // 修改卡路里
        let caloriesField = app.textFields["CaloriesTextField"]
        caloriesField.clearAndEnterText("200")

        // 保存
        app.buttons["SaveEditButton"].tap()

        // 验证总卡路里更新
        // ...
    }
}
```

#### 3.2.2 饮食日记浏览流程

```swift
final class DiaryBrowsingFlowTests: XCTestCase {
    func test_browseByDate() {
        // 1. 切换到日记 Tab
        app.buttons["DiaryTabButton"].tap()

        // 2. 验证日期选择器
        let datePicker = app.otherElements["WeekDatePicker"]
        XCTAssertTrue(datePicker.exists)

        // 3. 选择昨天
        let yesterdayButton = app.buttons["DateButton_yesterday"]
        yesterdayButton.tap()

        // 4. 验证数据更新
        // ...
    }

    func test_deleteMeal_withSwipe() {
        // 1. 导航到日记
        app.buttons["DiaryTabButton"].tap()

        // 2. 找到餐食卡片
        let mealCard = app.otherElements["MealCard_0"]
        XCTAssertTrue(mealCard.waitForExistence(timeout: 5))

        // 3. 左滑删除
        mealCard.swipeLeft()

        // 4. 点击删除按钮
        app.buttons["Delete"].tap()

        // 5. 确认删除
        app.alerts.buttons["确认"].tap()

        // 6. 验证卡片消失
        XCTAssertFalse(mealCard.exists)
    }

    func test_searchMeals() {
        app.buttons["DiaryTabButton"].tap()

        // 搜索
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("鸡蛋")

        // 验证搜索结果
        let results = app.cells.matching(identifier: "MealSearchResult")
        XCTAssertTrue(results.count > 0)
    }
}
```

#### 3.2.3 设置与账户流程

```swift
final class SettingsFlowTests: XCTestCase {
    func test_changeNotificationSettings() {
        // 1. 导航到设置
        app.buttons["ProfileTabButton"].tap()
        app.buttons["SettingsButton"].tap()

        // 2. 修改通知设置
        let mealReminderSwitch = app.switches["MealReminderSwitch"]
        mealReminderSwitch.tap()

        // 3. 验证状态改变
        XCTAssertFalse(mealReminderSwitch.isOn)
    }

    func test_deleteAccount_requiresConfirmation() {
        app.buttons["ProfileTabButton"].tap()
        app.buttons["SettingsButton"].tap()

        // 滚动到底部
        app.swipeUp()

        // 点击删除账户
        app.buttons["DeleteAccountButton"].tap()

        // 验证确认对话框
        XCTAssertTrue(app.alerts["删除账户"].exists)
        XCTAssertTrue(app.alerts.staticTexts["此操作不可撤销"].exists)

        // 取消
        app.alerts.buttons["取消"].tap()
    }
}
```

### 3.3 各页面元素测试

#### 3.3.1 首页

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_calorieRing_displayed` | 卡路里环形图显示 | P0 |
| `test_waterCard_addWater` | 点击添加饮水 | P0 |
| `test_stepsCard_displayed` | 步数卡片显示 | P1 |
| `test_foodCarousel_scroll` | 食刻轮播可滑动 | P0 |
| `test_pullToRefresh_works` | 下拉刷新有效 | P1 |

#### 3.3.2 相机

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_cameraPreview_displayed` | 相机预览显示 | P0 |
| `test_modeSelector_switch` | 模式切换有效 | P0 |
| `test_flashToggle_works` | 闪光灯切换有效 | P1 |
| `test_galleryButton_opensPhotos` | 相册按钮打开照片选择 | P0 |
| `test_barcodeMode_scanningUI` | 条形码模式 UI 切换 | P1 |

#### 3.3.3 分析结果

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_foodTags_displayed` | 食物标签显示 | P0 |
| `test_bottomSheet_expandable` | 底部弹窗可展开 | P0 |
| `test_nutritionRings_animated` | 营养素圆环动画 | P1 |
| `test_aiInsight_displayed` | AI 建议显示 | P1 |
| `test_shareButton_works` | 分享按钮有效 | P2 |

### 3.4 无障碍测试

```swift
final class AccessibilityTests: XCTestCase {
    func test_voiceOver_homeScreen() {
        // 验证所有交互元素都有 accessibility label
        let app = XCUIApplication()
        app.launch()

        // 卡路里环形图
        let calorieRing = app.otherElements["CalorieRingChart"]
        XCTAssertNotNil(calorieRing.label)
        XCTAssertTrue(calorieRing.label.contains("卡路里"))

        // 饮水卡片
        let waterCard = app.otherElements["WaterCard"]
        XCTAssertNotNil(waterCard.label)
        XCTAssertTrue(waterCard.label.contains("饮水"))
    }

    func test_dynamicType_largeText() {
        let app = XCUIApplication()
        app.launchArguments.append("-UIPreferredContentSizeCategoryName")
        app.launchArguments.append("UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge")
        app.launch()

        // 验证文字不被截断
        let greeting = app.staticTexts["GreetingText"]
        XCTAssertTrue(greeting.isHittable)
    }
}
```

---

## 四、Snapshot 测试计划

### 4.1 测试框架

使用 `swift-snapshot-testing` 库进行视觉回归测试。

### 4.2 需要截图的页面

| 页面 | Light Mode | Dark Mode | 优先级 |
|------|:----------:|:---------:|--------|
| 首页仪表盘 | ✅ | ✅ | P0 |
| 相机界面 | ✅ | ✅ | P0 |
| 分析结果页 | ✅ | ✅ | P0 |
| 饮食日记 | ✅ | ✅ | P0 |
| 统计洞察 | ✅ | ✅ | P0 |
| 个人中心 | ✅ | ✅ | P0 |
| 设置页 | ✅ | ✅ | P1 |
| 空状态 | ✅ | ✅ | P1 |
| 登录页 | ✅ | ✅ | P1 |

### 4.3 Snapshot 测试代码

```swift
import XCTest
import SnapshotTesting
@testable import FoodMoment

final class SnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // isRecording = true // 首次运行生成基准图
    }

    func test_homeView_lightMode() {
        let view = HomeView()
            .environmentObject(MockHomeViewModel())
            .environment(\.colorScheme, .light)

        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone15Pro))
        )
    }

    func test_homeView_darkMode() {
        let view = HomeView()
            .environmentObject(MockHomeViewModel())
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone15Pro))
        )
    }

    func test_analysisView_withResults() {
        let mockResult = AnalysisResponseDTO.mock
        let view = AnalysisView(
            image: UIImage(named: "test_food")!,
            result: mockResult
        )

        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone15Pro))
        )
    }

    func test_diaryView_emptyState() {
        let view = DiaryView()
            .environmentObject(MockDiaryViewModel(meals: []))

        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone15Pro)),
            named: "empty_state"
        )
    }
}
```

---

## 五、集成测试计划

### 5.1 API 集成测试

| 测试用例 | 描述 | 优先级 |
|---------|------|--------|
| `test_foodAnalysis_e2e` | 上传图片 → 获取分析结果 | P0 |
| `test_mealRecord_crud` | 餐食记录增删改查 | P0 |
| `test_userAuth_flow` | 登录 → Token → 刷新 → 登出 | P0 |
| `test_syncFlow_offline` | 离线记录 → 联网同步 | P1 |

### 5.2 数据库集成测试

```swift
final class SwiftDataIntegrationTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: MealRecord.self, DetectedFood.self, UserProfile.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    func test_mealRecord_withDetectedFoods() throws {
        // Given
        let meal = MealRecord(
            mealType: "lunch",
            mealTime: Date(),
            totalCalories: 500
        )
        let food1 = DetectedFood(name: "Rice", calories: 300)
        let food2 = DetectedFood(name: "Chicken", calories: 200)
        meal.detectedFoods = [food1, food2]

        // When
        context.insert(meal)
        try context.save()

        // Then
        let fetchDescriptor = FetchDescriptor<MealRecord>()
        let meals = try context.fetch(fetchDescriptor)

        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals[0].detectedFoods.count, 2)
        XCTAssertEqual(meals[0].totalCalories, 500)
    }

    func test_queryMeals_byDateRange() throws {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let meal1 = MealRecord(mealTime: today, totalCalories: 500)
        let meal2 = MealRecord(mealTime: yesterday, totalCalories: 600)

        context.insert(meal1)
        context.insert(meal2)
        try context.save()

        // When
        let startOfToday = Calendar.current.startOfDay(for: today)
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!

        let predicate = #Predicate<MealRecord> { meal in
            meal.mealTime >= startOfToday && meal.mealTime < endOfToday
        }
        let descriptor = FetchDescriptor<MealRecord>(predicate: predicate)
        let todayMeals = try context.fetch(descriptor)

        // Then
        XCTAssertEqual(todayMeals.count, 1)
        XCTAssertEqual(todayMeals[0].totalCalories, 500)
    }
}
```

### 5.3 HealthKit 集成测试

```swift
final class HealthKitIntegrationTests: XCTestCase {
    var healthKitManager: HealthKitManager!

    override func setUp() {
        super.setUp()
        healthKitManager = HealthKitManager.shared
    }

    func test_saveAndReadNutrition() async throws {
        // Skip if HealthKit not available (CI environment)
        guard HKHealthStore.isHealthDataAvailable() else {
            throw XCTSkip("HealthKit not available")
        }

        // Given
        let calories: Double = 500
        let protein: Double = 25
        let date = Date()

        // When
        try await healthKitManager.saveNutrition(
            calories: calories,
            protein: protein,
            carbs: 50,
            fat: 20,
            date: date
        )

        // Then
        let savedCalories = try await healthKitManager.readCalories(for: date)
        XCTAssertEqual(savedCalories, calories, accuracy: 1)
    }
}
```

---

## 六、性能测试计划

### 6.1 Instruments 检测项目

| 工具 | 检测内容 | 通过标准 |
|------|---------|---------|
| Time Profiler | CPU 使用率 | 滑动时 < 60% |
| Allocations | 内存分配 | 峰值 < 150MB |
| Leaks | 内存泄漏 | 0 泄漏 |
| Core Animation | 帧率 | 稳定 60fps |
| Energy Log | 电池消耗 | 低影响 |
| Network | 网络请求 | 无重复请求 |

### 6.2 性能基准测试

```swift
final class PerformanceTests: XCTestCase {
    func test_homeView_scrollPerformance() {
        let app = XCUIApplication()
        app.launch()

        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            let scrollView = app.scrollViews.firstMatch
            scrollView.swipeUp(velocity: .fast)
            scrollView.swipeDown(velocity: .fast)
        }
    }

    func test_diaryView_loadPerformance() {
        measure {
            let viewModel = DiaryViewModel()
            viewModel.loadMeals(for: Date())
        }
    }

    func test_imageAnalysis_performance() {
        let image = UIImage(named: "test_food_large")!
        let service = FoodClassifierService()

        measure {
            let expectation = expectation(description: "Analysis")
            Task {
                _ = try? await service.classify(image: image)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5)
        }
    }
}
```

### 6.3 启动时间测试

```swift
func test_appLaunch_coldStart() {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
    }
}

func test_appLaunch_warmStart() {
    let app = XCUIApplication()
    app.launch()
    app.terminate()

    measure(metrics: [XCTApplicationLaunchMetric()]) {
        app.launch()
    }
}
```

---

## 七、后端 API 测试计划

### 7.1 API 测试用例

| 端点 | 方法 | 测试用例 | 优先级 |
|------|------|---------|--------|
| `/api/v1/auth/apple` | POST | 有效 Apple ID Token | P0 |
| `/api/v1/auth/apple` | POST | 无效 Token | P0 |
| `/api/v1/food/analyze` | POST | 有效食物图片 | P0 |
| `/api/v1/food/analyze` | POST | 非食物图片 | P1 |
| `/api/v1/food/analyze` | POST | 图片过大 (>10MB) | P1 |
| `/api/v1/meals` | POST | 创建餐食记录 | P0 |
| `/api/v1/meals` | GET | 按日期查询 | P0 |
| `/api/v1/meals/{id}` | PUT | 更新餐食 | P0 |
| `/api/v1/meals/{id}` | DELETE | 删除餐食 | P0 |
| `/api/v1/stats/daily` | GET | 每日统计 | P0 |
| `/api/v1/stats/weekly` | GET | 每周统计 | P0 |
| `/api/v1/user/profile` | GET | 获取用户资料 | P0 |
| `/api/v1/user/account` | DELETE | 删除账户 | P0 |

### 7.2 使用 pytest 测试后端

```python
# tests/test_food_analysis.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_analyze_food_success():
    async with AsyncClient(app=app, base_url="http://test") as client:
        with open("tests/fixtures/food_image.jpg", "rb") as f:
            response = await client.post(
                "/api/v1/food/analyze",
                files={"image": ("food.jpg", f, "image/jpeg")},
                headers={"Authorization": "Bearer test_token"}
            )

    assert response.status_code == 200
    data = response.json()
    assert "total_calories" in data
    assert "detected_foods" in data
    assert len(data["detected_foods"]) > 0

@pytest.mark.asyncio
async def test_analyze_non_food_image():
    async with AsyncClient(app=app, base_url="http://test") as client:
        with open("tests/fixtures/landscape.jpg", "rb") as f:
            response = await client.post(
                "/api/v1/food/analyze",
                files={"image": ("landscape.jpg", f, "image/jpeg")},
                headers={"Authorization": "Bearer test_token"}
            )

    assert response.status_code == 200
    data = response.json()
    assert data["detected_foods"] == []
    assert "no_food_detected" in data.get("message", "").lower()
```

---

## 八、测试执行计划

### 8.1 CI/CD 集成

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  unit-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app

      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -project FoodMoment.xcodeproj \
            -scheme FoodMoment \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
            -enableCodeCoverage YES \
            -resultBundlePath TestResults.xcresult

      - name: Upload Coverage
        uses: codecov/codecov-action@v4
        with:
          xcode: true
          xcode_archive_path: TestResults.xcresult

  ui-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Run UI Tests
        run: |
          xcodebuild test \
            -project FoodMoment.xcodeproj \
            -scheme FoodMomentUITests \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
            -resultBundlePath UITestResults.xcresult

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: ui-test-results
          path: UITestResults.xcresult

  snapshot-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Run Snapshot Tests
        run: |
          xcodebuild test \
            -project FoodMoment.xcodeproj \
            -scheme FoodMomentSnapshotTests \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### 8.2 测试执行时机

| 时机 | 测试类型 | 频率 |
|------|---------|------|
| 每次提交 | 单元测试 | 自动 |
| 每次 PR | 单元测试 + UI 测试 | 自动 |
| 每日构建 | 全部测试 + 性能测试 | 自动 |
| 发版前 | 全部测试 + 手动回归 | 手动 |

### 8.3 测试报告

使用 `xcresult` 生成测试报告，包含：
- 测试通过/失败数量
- 代码覆盖率报告
- 失败截图
- 性能指标

---

## 九、测试数据管理

### 9.1 Mock 数据

```swift
// Mocks/MockData.swift
enum MockData {
    static let analysisResponse = AnalysisResponseDTO(
        imageURL: "https://example.com/food.jpg",
        totalCalories: 485,
        totalNutrition: NutritionDataDTO(
            proteinG: 22,
            carbsG: 45,
            fatG: 18,
            fiberG: 6
        ),
        detectedFoods: [
            DetectedFoodDTO(
                name: "Poached Egg",
                nameZh: "水波蛋",
                emoji: "🥚",
                confidence: 0.95,
                boundingBox: BoundingBox(x: 0.55, y: 0.15, w: 0.2, h: 0.15),
                calories: 140,
                color: "#FACC15"
            ),
            DetectedFoodDTO(
                name: "Avocado Toast",
                nameZh: "牛油果吐司",
                emoji: "🥑",
                confidence: 0.92,
                boundingBox: BoundingBox(x: 0.2, y: 0.4, w: 0.3, h: 0.25),
                calories: 345,
                color: "#4ADE80"
            )
        ],
        aiAnalysis: "营养均衡的一餐！牛油果提供优质脂肪，鸡蛋富含蛋白质。"
    )

    static let mealRecords: [MealRecord] = [
        MealRecord(
            mealType: "breakfast",
            mealTime: Date().addingTimeInterval(-7200),
            totalCalories: 350,
            title: "健康早餐"
        ),
        MealRecord(
            mealType: "lunch",
            mealTime: Date().addingTimeInterval(-3600),
            totalCalories: 650,
            title: "工作午餐"
        )
    ]
}
```

### 9.2 测试环境隔离

```swift
// 使用内存数据库进行测试
extension ModelContainer {
    static var testing: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(
            for: MealRecord.self, DetectedFood.self, UserProfile.self,
            WaterLog.self, WeightLog.self, Achievement.self,
            configurations: config
        )
    }
}
```

---

## 十、测试验收标准

### 10.1 上线前必须通过

| 检查项 | 标准 | 状态 |
|--------|------|------|
| 单元测试覆盖率 | > 80% | ⬜ |
| 单元测试通过率 | 100% | ⬜ |
| UI 测试通过率 | 100% | ⬜ |
| Snapshot 测试通过 | 无差异 | ⬜ |
| 内存泄漏 | 0 | ⬜ |
| 崩溃 | 0 | ⬜ |
| 启动时间 | < 2s | ⬜ |
| 滑动帧率 | 60fps | ⬜ |
| 无障碍检查 | 通过 | ⬜ |
| 深色模式 | 完整适配 | ⬜ |
| 国际化 | 中英文完整 | ⬜ |

### 10.2 TestFlight 内测检查清单

- [ ] 基本功能流程可用
- [ ] 相机权限正常请求
- [ ] HealthKit 权限正常请求
- [ ] 通知权限正常请求
- [ ] Widget 正常显示
- [ ] 深色模式正常
- [ ] 横竖屏切换正常（如支持）
- [ ] 网络断开时的离线体验
- [ ] 不同 iPhone 机型适配
- [ ] 低电量模式下正常运行

---

## 十一、问题跟踪

### Bug 报告模板

```markdown
## Bug 描述
[简短描述问题]

## 复现步骤
1. 打开 App
2. 导航到 XXX
3. 点击 XXX
4. 出现问题

## 预期行为
[应该发生什么]

## 实际行为
[实际发生了什么]

## 环境
- 设备: iPhone XX
- iOS 版本: XX.X
- App 版本: X.X.X
- 网络状态: WiFi/蜂窝/无网络

## 截图/录屏
[附加截图或录屏]

## 日志
[相关日志信息]
```

---

> 📌 **下一步行动：** 创建测试目录结构，开始编写核心 ViewModel 的单元测试。
