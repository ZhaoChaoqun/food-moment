# FoodMoment iOS 全页面代码规范审查报告

> **审查日期**: 2026-02-11
> **审查依据**: CODE_STYLE_GUIDE.md v1.1.0
> **覆盖文件**: 80+ Swift 文件（全量）
> **审查版本**: 1.0.0

---

## 审查团队

### Review 小组 A — Home & App 入口
- **Engineer A1**（iOS 架构师）— 负责 HomeView, HomeViewModel, AppState, MainTabView, ContentView, FoodMomentApp
- **Engineer A2**（UI 工程师）— 负责 CalorieRingChart, FoodMomentCarousel, WaterCard, StepsCard, MacroIndicatorRow, WaterTrackingSheet
- **Designer A3**（UI/UX）— 设计系统合规审查

### Review 小组 B — Camera
- **Engineer B1**（相机/AVFoundation 专家）— CameraView, CameraViewModel, CameraPreviewView
- **Engineer B2**（组件工程师）— ShutterButton, FocusReticle, ModeSelector, BarcodeResultOverlay, AIHintBadge, GalleryThumbnail

### Review 小组 C — Analysis
- **Engineer C1**（AI/ML 工程师）— AnalysisView, AnalysisViewModel, SaliencyDetectionService
- **Engineer C2**（可视化工程师）— NutritionRing, NutritionRingsRow, FoodTagPin, FoodTagOverlay, FloatingNutritionPanel, AIInsightCard, LogMealButton

### Review 小组 D — Profile & Statistics
- **Engineer D1**（数据可视化）— StatisticsView, StatisticsViewModel, CalorieTrendChart, MacroDonutChart, CheckinGrid, TimeRangeSelector
- **Engineer D2**（Profile 工程师）— ProfileView, ProfileViewModel, SettingsView, AchievementBadge, AchievementUnlockView, ActivityCalendar, IntakeChartCard, StreakCard, WeightCard, WeightInputSheet

### Review 小组 E — Diary & Search & Auth
- **Engineer E1**（列表/搜索）— DiaryView, DiaryViewModel, FoodSearchView, FoodSearchViewModel
- **Engineer E2**（Auth/入口）— SignInView, AuthViewModel, CustomTabBar, SharedComponents

### Review 小组 F — Models & Core
- **Engineer F1**（数据层架构师）— Models, DTOs, Network, Theme, Extensions
- **Engineer F2**（测试/Mock）— MockDataProvider, PersistenceController

---

## 一、全局问题统计

| 违规类型 | 发现总数 | 严重程度 |
|----------|---------|---------|
| `.font(.system(...))` 应替换为 `.Jakarta` | **34 处** | 🔴 Critical |
| 颜色硬编码 `Color(hex:)` 应使用 `AppTheme.Colors` | **28 处** | 🔴 Critical |
| 缺少 `#Preview` | **18 个文件** | 🟡 Moderate |
| MARK 注释缺失或顺序不规范 | **15 个文件** | 🟡 Moderate |
| 缺少无障碍标注 (`accessibilityLabel`) | **12 处** | 🟡 Moderate |
| `accessibilityLabel` 使用英文而非中文 | **5 处** | 🟡 Moderate |
| 触摸目标小于 44×44pt | **3 处** | 🟡 Moderate |
| 性能问题（body 中创建重对象、无缓存等） | **11 处** | 🔴 Critical |
| Task 未保存引用（无法取消） | **6 处** | 🟡 Moderate |
| `print` 调试日志未移除 | **15+ 处** | 🟡 Moderate |
| DTO 缺少 `Sendable` | **3 处** | 🟡 Moderate |
| 访问控制不规范 | **8 处** | ⚪ Minor |

---

## 二、各模块逐文件审查结果

### 2.1 Home 模块

| 文件 | 状态 | 问题数 | 关键问题 |
|------|------|--------|----------|
| HomeView.swift | ✅ PASS | 0 | — |
| HomeViewModel.swift | ✅ PASS | 0 | — |
| CalorieRingChart.swift | ✅ PASS | 0 | — |
| FoodMomentCarousel.swift | ⚠️ 需改进 | 2 | 硬编码颜色；缺少部分 MARK |
| WaterCard.swift | ✅ PASS | 0 | — |
| StepsCard.swift | ✅ PASS | 0 | — |
| MacroIndicatorRow.swift | ✅ PASS | 0 | — |
| WaterTrackingSheet.swift | ⚠️ 需改进 | 1 | 缺少 `#Preview` |

### 2.2 Camera 模块

| 文件 | 状态 | 问题数 | 关键问题 |
|------|------|--------|----------|
| CameraView.swift | ⚠️ 需改进 | 3 | 2处 `.system` 字体；英文 accessibilityLabel |
| CameraViewModel.swift | ⚠️ 需改进 | 6 | 4处未保存 Task 引用；1处访问控制；1处 extension 位置不当 |
| CameraPreviewView.swift | ⚠️ 需改进 | 1 | 缺少 `#Preview` |
| ShutterButton.swift | ⚠️ 需改进 | 2 | 英文 accessibilityLabel；MARK 顺序 |
| FocusReticle.swift | ⚠️ 需改进 | 2 | MARK 顺序；缺少 accessibilityHidden |
| ModeSelector.swift | ✅ PASS | 0 | — |
| BarcodeResultOverlay.swift | ⚠️ 需改进 | 6 | 4处 `.system` 字体；触摸目标 32×32；缺少无障碍标注 |
| AIHintBadge.swift | ⚠️ 需改进 | 1 | 1处 `.system` 字体 |
| GalleryThumbnail.swift | ⚠️ 需改进 | 3 | `.system` 字体；英文 label；图片内存问题 |

### 2.3 Analysis 模块

| 文件 | 状态 | 问题数 | 关键问题 |
|------|------|--------|----------|
| AnalysisView.swift | 🔴 需修复 | 8 | MARK 不规范；body 内使用 MARK；`UIScreen.main`；缺少 Preview；`Color(.systemGray6)` |
| AnalysisViewModel.swift | 🔴 需修复 | 12 | MARK 不规范；大量 print；ShareableAnalysisView 全使用系统字体和硬编码颜色；缺少 Preview |
| SaliencyDetectionService.swift | ⚠️ 需改进 | 3 | `@MainActor` 应改为 `actor`；print 日志 |
| LogMealButton.swift | ⚠️ 需改进 | 2 | 缺少 MARK；缺少 Preview |
| AIInsightCard.swift | ⚠️ 需改进 | 4 | 2处硬编码颜色；缺少 MARK；缺少 Preview |
| FoodTagPin.swift | ⚠️ 需改进 | 3 | 缺少 MARK；缺少 Preview；GCD asyncAfter |
| NutritionRingsRow.swift | ⚠️ 需改进 | 3 | 硬编码颜色且与规范值不一致；缺少 Preview |
| NutritionRing.swift | ⚠️ 需改进 | 5 | 4处硬编码颜色；缺少 Preview |
| FoodTagOverlay.swift | 🔴 需修复 | 4 | body 中 O(n²) 算法；无意义 GeometryReader；ForEach 用索引做 ID；缺少 Preview |
| FloatingNutritionPanel.swift | ⚠️ 需改进 | 8 | 6处硬编码颜色；系统字体；缺少 Preview |

### 2.4 Profile 模块

| 文件 | 状态 | 问题数 | 关键问题 |
|------|------|--------|----------|
| ProfileView.swift | ⚠️ 需改进 | 2 | 硬编码颜色；部分 MARK 不标准 |
| ProfileViewModel.swift | ⚠️ 需改进 | 3 | `AchievementItem` 定义在 ViewModel 文件中应独立；访问控制 |
| SettingsView.swift | ⚠️ 需改进 | 2 | 系统字体；缺少 Preview |
| AchievementBadge.swift | ✅ PASS | 0 | — |
| AchievementUnlockView.swift | ⚠️ 需改进 | 2 | 硬编码颜色；缺少 Preview |
| ActivityCalendar.swift | ⚠️ 需改进 | 1 | 缺少 Preview |
| IntakeChartCard.swift | ⚠️ 需改进 | 1 | 缺少 Preview |
| StreakCard.swift | ✅ PASS | 0 | — |
| WeightCard.swift | ✅ PASS | 0 | — |
| WeightInputSheet.swift | ⚠️ 需改进 | 1 | 缺少 Preview |

### 2.5 Statistics 模块

| 文件 | 状态 | 问题数 | 关键问题 |
|------|------|--------|----------|
| StatisticsView.swift | ⚠️ 需改进 | 2 | 硬编码颜色；MARK 不标准 |
| StatisticsViewModel.swift | ✅ PASS | 0 | — |
| CalorieTrendChart.swift | ⚠️ 需改进 | 2 | 硬编码渐变颜色；缺少 Preview |
| MacroDonutChart.swift | ⚠️ 需改进 | 1 | 缺少 Preview |
| AIInsightDarkCard.swift | ✅ PASS | 0 | — |
| CheckinGrid.swift | ✅ PASS | 0 | — |
| TimeRangeSelector.swift | ✅ PASS | 0 | — |

### 2.6 Diary 模块

| 文件 | 状态 | 问题数 | 关键问题 |
|------|------|--------|----------|
| DiaryView.swift | ⚠️ 需改进 | 2 | 2处 `.system` 字体 |
| DiaryViewModel.swift | ⚠️ 需改进 | 2 | MARK 区分不够；访问控制 |
| WeekDatePicker.swift | 🔴 需修复 | 3 | MARK 顺序；硬编码颜色；**body 中 7次 SwiftData 查询** |
| TimelineEntry.swift | ⚠️ 需改进 | 2 | 硬编码颜色；缺少 Preview |
| FoodPhotoCard.swift | ⚠️ 需改进 | 2 | body 中同步解码大图；缺少 Preview |
| DailyProgressFloat.swift | ⚠️ 需改进 | 3 | 硬编码颜色；**NumberFormatter 每次新建**；缺少 Preview |

### 2.7 Search & Auth 模块

| 文件 | 状态 | 问题数 | 关键问题 |
|------|------|--------|----------|
| FoodSearchView.swift | 🔴 需修复 | 7 | 大量系统字体；颜色违规；缺少 MARK；FlowLayout 应独立；缺少 Preview |
| FoodSearchViewModel.swift | ⚠️ 需改进 | 4 | MARK 缺失；ChineseFoodDatabase 应独立文件；print 日志；访问控制 |
| SignInView.swift | 🔴 需修复 | 8 | 全部使用系统字体；大量硬编码颜色；body 过大未拆分；缺少 MARK；缺少 Preview |
| AuthViewModel.swift | ⚠️ 需改进 | 4 | MARK 缺失；DTO 缺少 Sendable；defer 模式未用 |

### 2.8 SharedComponents

| 文件 | 状态 | 问题数 | 关键问题 |
|------|------|--------|----------|
| CustomTabBar.swift | ⚠️ 需改进 | 2 | 系统字体；未使用 AppTheme.Animation |
| GlassCard.swift | ✅ PASS | 0 | — |
| GradientButton.swift | ✅ PASS | 0 | — |
| RingShape.swift | ✅ PASS | 0 | — |
| EmptyStateView.swift | ✅ PASS | 0 | — |

### 2.9 App 入口

| 文件 | 状态 | 问题数 | 关键问题 |
|------|------|--------|----------|
| FoodMomentApp.swift | ⚠️ 需改进 | 4 | MARK 顺序；多处 print；NotificationCenter 未移除 |
| ContentView.swift | ✅ PASS | 0 | — |
| MainTabView.swift | ⚠️ 需改进 | 2 | UITabBar.appearance() 全局副作用；代码重复 |
| AppState.swift | ⚠️ 需改进 | 2 | 访问控制；Widget 数据硬编码 0 |

### 2.10 Models & Core

| 文件 | 状态 | 问题数 | 关键问题 |
|------|------|--------|----------|
| MealRecord.swift | ✅ PASS | 0 | — |
| UserProfile.swift | ✅ PASS | 0 | — |
| Achievement.swift | ✅ PASS | 0 | — |
| DetectedFood.swift | ✅ PASS | 0 | — |
| WeightLog.swift | ✅ PASS | 0 | — |
| WaterLog.swift | ✅ PASS | 0 | — |
| AnalysisResponse.swift (DTO) | ✅ PASS | 0 | — |
| NutritionData.swift (DTO) | ✅ PASS | 0 | — |
| FoodSearchResult.swift (DTO) | ✅ PASS | 0 | — |
| APIClient.swift | ✅ PASS | 0 | — |
| APIEndpoint.swift | ✅ PASS | 0 | — |
| APIError.swift | ✅ PASS | 0 | — |
| TokenManager.swift | ✅ PASS | 0 | — |
| AppTheme.swift | ✅ PASS | 0 | — |
| Color+Brand.swift | ✅ PASS | 0 | — |
| Font+Custom.swift | ✅ PASS | 0 | — |
| View+Glass.swift | ✅ PASS | 0 | — |
| View+Accessibility.swift | ✅ PASS | 0 | — |
| View+Shimmer.swift | ✅ PASS | 0 | — |
| View+Performance.swift | ✅ PASS | 0 | — |
| Date+Helpers.swift | ⚠️ 需改进 | 1 | `formatted(as:)` 每次创建 DateFormatter |
| MockDataProvider.swift | ✅ PASS | 0 | — |

---

## 三、Top 5 高频违规模式

### 1. 系统字体未替换 (34 处)

**规范要求**: 所有文本必须使用 `.Jakarta` 命名空间字体，禁止 `.system()` / `.title` / `.caption` 等。

**重灾区文件**: SignInView (6处), FoodSearchView (6处), BarcodeResultOverlay (4处), AnalysisViewModel/ShareableAnalysisView (8处)

**统一修复方案**:
```swift
// ❌ Before
.font(.system(size: 28, weight: .bold))
.font(.system(size: 16))
.font(.caption)

// ✅ After
.font(.Jakarta.bold(28))
.font(.Jakarta.regular(16))
.font(.Jakarta.medium(12))
```

### 2. 颜色硬编码 (28 处)

**规范要求**: 所有颜色从 `AppTheme.Colors` 获取，禁止 `Color(hex:)` 和 `.green` / `.blue` 等系统色。

**需补充到 AppTheme.Colors 的语义色**:
```swift
enum Colors {
    // 已有...

    // 需新增：文本语义色
    static let textPrimary = Color(hex: "#0F172A")     // 主文本
    static let textSecondary = Color(hex: "#64748B")   // 次文本
    static let textTertiary = Color(hex: "#475569")    // 辅助文本

    // 需新增：通用 UI 色
    static let trackGray = Color(hex: "#E2E8F0")       // 进度条底色
    static let divider = Color(hex: "#F1F5F9")         // 分割线
}
```

### 3. 缺少 #Preview (18 个文件)

**规范要求**: 每个 View 文件必须包含至少一个 `#Preview`。

**缺失文件清单**: AnalysisView, LogMealButton, AIInsightCard, FoodTagPin, NutritionRingsRow, NutritionRing, FoodTagOverlay, FloatingNutritionPanel, WeekDatePicker, TimelineEntry, FoodPhotoCard, DailyProgressFloat, FoodSearchView, SignInView, SettingsView, AchievementUnlockView, ActivityCalendar, WeightInputSheet

### 4. MARK 注释不规范 (15 个文件)

**规范要求**:
- View: `// MARK: - Environment` → `State` → `Properties` → `Body` → `Subviews` → `Actions` → `Preview`
- ViewModel: `// MARK: - Published Properties` → `Private Properties` → `Computed Properties` → `Initialization` → `Public Methods` → `Private Methods`

### 5. 性能问题 (11 处)

详见第四章《性能优化方案》。

---

## 四、性能优化方案

### P0 — 必须立即修复

| # | 位置 | 问题 | 影响 | 修复方案 |
|---|------|------|------|----------|
| 1 | `WeekDatePicker.swift:106-119` | **每次 body 求值为 7 个日期各执行 1 次 SwiftData fetchCount 查询** | 每次渲染 7 次数据库 I/O | 在 DiaryViewModel 中预计算 `datesWithMeals: Set<Date>`，一次查询 7 天范围，通过 Binding 传入 |
| 2 | `FoodTagOverlay.swift:26` | **body 中执行 O(n² × 5) 的 resolveOverlaps() 算法** | 每次状态变化触发重计算 | 将 `resolvedPositions` 改为 `@State`，通过 `onChange(of: detectedFoods)` 触发重算 |
| 3 | `DailyProgressFloat.swift:120-124` | **每次调用 formattedCalories() 都新建 NumberFormatter** | NumberFormatter 是重量级对象 | 提取为 `private static let formatter` |
| 4 | `FoodPhotoCard.swift:71` | **body 中同步 UIImage(data:) 解码大图** | 主线程解码 12MP+ 照片卡顿 | 使用 `byPreparingThumbnail(ofSize:)` 后台解码；缓存 UIImage |

### P1 — 本迭代修复

| # | 位置 | 问题 | 影响 | 修复方案 |
|---|------|------|------|----------|
| 5 | `GalleryThumbnail.swift:90-97` | 加载全分辨率图片作缩略图 | 内存峰值 30MB+ | 使用 `byPreparingThumbnail(ofSize: CGSize(width:200, height:200))` |
| 6 | `CameraViewModel.swift` 多处 | 创建 Task 但未保存引用 | 无法取消；可能访问已释放对象 | 保存到 `private var pendingTask: Task<Void, Never>?`，stopSession 时统一 cancel |
| 7 | `AnalysisView.swift:25,31,47` | 多处使用 `UIScreen.main.bounds` | iPad 多窗口下不准确 | 统一从 GeometryReader proxy 获取 |
| 8 | `FoodTagOverlay.swift:28` | GeometryReader 的 proxy 未使用 | 不必要地改变布局行为 | 替换为 ZStack |
| 9 | `FoodTagOverlay.swift:29` | `ForEach(enumerated(), id: \.offset)` 用索引做 ID | 数组变化时动画/diff 异常 | 使用 `\.element.id` |
| 10 | `Date+Helpers.swift:62-66` | `formatted(as:)` 每次创建 DateFormatter | 高频调用场景性能差 | 使用 `DateFormatter` 缓存池或 `private static` |

### P2 — 后续迭代优化

| # | 位置 | 问题 | 影响 | 修复方案 |
|---|------|------|------|----------|
| 11 | `AnalysisViewModel.swift:67-115` | 大量 `print` 调试日志 | I/O 开销；信息泄露风险 | 替换为 `os.Logger`，设置级别为 `.debug` |
| 12 | `AnalysisViewModel.swift:311-321` | `ImageRenderer` 在主线程生成大图 | 可能卡 UI | 考虑后台线程或显示加载指示器 |
| 13 | `FoodSearchView.swift:152-155` | `quickAccessFoods` 计算属性每次求值重做 `.prefix(12).map { $0.toDTO() }` | 不必要的重复计算 | 缓存到 ViewModel |
| 14 | 全项目 `print` | 15+ 处 print 语句 | Release 构建影响性能 | 统一使用 `os.Logger` 或 `#if DEBUG` 包裹 |

---

## 五、设计系统合规审查（UI/UX 设计师意见）

### 5.1 颜色一致性审查

| 组件 | 代码中使用的颜色 | AppTheme 定义值 | 是否一致 |
|------|-----------------|----------------|---------|
| NutritionRingsRow — 碳水 | `#3B82F6`（蓝色） | `#FACC15`（黄色） | ❌ **不一致** |
| NutritionRingsRow — 脂肪 | `#F97316` | `#FB923C` | ❌ **不一致** |
| NutritionRingsRow — 蛋白质 | `AppTheme.Colors.primary (#13EC5B)` | `AppTheme.Colors.protein (#4ADE80)` | ❌ **使用了错误的 token** |
| DailyProgressFloat — 热量警告 | `#F87171` | `AppTheme.Colors.dinner (#F87171)` | ⚠️ 值相同但语义错误（应语义化） |

**设计师建议**: NutritionRingsRow 的颜色与设计稿不一致，导致碳水化合物在分析页显示为蓝色，在其他页面显示为黄色，用户体验不一致。需统一为 `AppTheme.Colors.carbs`。

### 5.2 需要补充的设计令牌

```
AppTheme.Colors.textPrimary    — #0F172A  — 主文本色（目前 12 处硬编码）
AppTheme.Colors.textSecondary  — #64748B  — 次文本色（目前 8 处硬编码）
AppTheme.Colors.textTertiary   — #475569  — 辅助文本色（目前 4 处硬编码）
AppTheme.Colors.trackGray      — #E2E8F0  — 进度条底色（目前 3 处硬编码）
```

### 5.3 触摸目标审查

| 组件 | 当前尺寸 | 规范要求 | 是否合规 |
|------|---------|---------|---------|
| BarcodeResultOverlay 关闭按钮 | 32×32 | 44×44 | ❌ |
| FoodTagPin | ~30×24 | 44×44 | ❌ |
| WeekDatePicker 日期单元格 | 动态 | 44×44 | ⚠️ 需验证 |

---

## 六、无障碍合规审查

### 6.1 accessibilityLabel 语言不一致

| 文件 | 当前值 | 建议值 |
|------|--------|--------|
| CameraView.swift | `"Switch Camera"` | `"切换摄像头"` |
| ShutterButton.swift | `"Capture Photo"` | `"拍照"` |
| GalleryThumbnail.swift | `"Photo Library"` | `"照片库"` |

### 6.2 缺少 accessibilityLabel 的可交互元素

- BarcodeResultOverlay: 关闭按钮、复制按钮、重新扫描按钮
- FloatingNutritionPanel: 所有营养素行
- FoodTagPin: 食物标签点击区域
- CalorieTrendChart: 图表数据点

---

## 七、行动计划

### Sprint 1（本周）— P0 性能修复
- [ ] 修复 WeekDatePicker 7 次数据库查询
- [ ] 修复 FoodTagOverlay body 中 O(n²) 算法
- [ ] 修复 DailyProgressFloat NumberFormatter 创建
- [ ] 修复 FoodPhotoCard 主线程大图解码

### Sprint 2（下周）— 设计系统统一
- [ ] 补充 AppTheme.Colors 文本语义色
- [ ] 全局替换 34 处系统字体为 Jakarta
- [ ] 全局替换 28 处硬编码颜色为 AppTheme.Colors
- [ ] 修复 NutritionRingsRow 颜色不一致问题

### Sprint 3 — 规范补全
- [ ] 为 18 个文件补充 #Preview
- [ ] 统一 15 个文件的 MARK 注释
- [ ] 补充无障碍标注
- [ ] 替换 print 为 os.Logger

---

> **审查结论**: 项目整体架构设计良好，MVVM 模式、SwiftData 使用规范、网络层和 Models 层质量较高。主要问题集中在 **UI 层的设计令牌使用一致性** 和 **个别视图的渲染性能**。建议按上述行动计划分三个 Sprint 逐步整改，优先解决 P0 性能问题。
>
> **合规率**: PASS 文件 40/80+（~50%），主要不合规文件集中在 Analysis、Search、Auth 三个模块。

---

> **审查者**: FoodMoment iOS Review Team (2026-02-11)
