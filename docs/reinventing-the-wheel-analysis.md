# FoodMoment iOS 项目"重复造轮子"深度分析报告

> 生成日期: 2026-02-17
> 分析范围: `ios/FoodMoment/` 全部 Swift 源代码
> 分析维度: 网络层、UI 组件层、数据/状态管理层

---

## 一、总览

本报告由三个并行分析 agent 完成，分别覆盖：
1. **网络层与数据持久化** — APIClient、TokenManager、缓存、CoreData 等
2. **UI 组件与视图层** — 自定义 TabBar、Navigation、图表、动画等
3. **数据/状态管理与工具类** — ViewModel 模式、日期工具、本地存储、并发管理等

共发现 **35 处** 可改进的"造轮子"问题，按优先级分类如下。

---

## 二、🔴 高优先级（强烈建议修复）

### 2.1 自定义 TabBar 替代原生 TabView

| 项目 | 说明 |
|------|------|
| **文件** | `App/MainTabView.swift:13-27`, `SharedComponents/CustomTabBar.swift:1-119` |
| **现状** | 完全隐藏系统 TabBar（`UITabBar.appearance().isHidden = true`），自行实现了 `CustomTabBar` 组件，包含自定义样式、动画和布局 |
| **副作用** | UI 测试中无法找到 `ScanTabButton` 等元素（已在测试中暴露），失去系统级无障碍支持、safe area 自动处理 |
| **建议** | 使用 SwiftUI 原生 `TabView` + `.tabViewStyle`，iOS 16+ 可自定义外观 |

### 2.2 使用已弃用的 NavigationView

| 项目 | 说明 |
|------|------|
| **文件** | `Features/Analysis/AnalysisView.swift:346` |
| **现状** | 在 `.sheet()` 中使用 `NavigationView { ... }` |
| **副作用** | Apple 已明确弃用 `NavigationView`，可能在未来 iOS 版本中移除 |
| **建议** | 替换为 `NavigationStack`（iOS 16+） |

### 2.3 手动实现 Multipart Form-Data 编码（两处重复）

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Network/APIClient.swift:284-303`, `Core/Camera/ImageUploadService.swift:98-111` |
| **现状** | 手动拼接 boundary、Content-Disposition 等 HTTP multipart 格式 |
| **副作用** | 代码重复、易出错（编码边界、换行符），且两处实现字段名不同（`image` vs `file`） |
| **建议** | 提取为统一的 `MultipartFormData` 工具类，或引入成熟库 |

### 2.4 手动 JWT Token 解析与 Base64URL 解码

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Network/TokenManager.swift:97-125, 223-237` |
| **现状** | 手动 split(".")、手动 Base64URL→Base64 转换、手动 JSONSerialization 解析 payload |
| **副作用** | 安全敏感代码自行实现风险高，Base64 padding 处理易出错 |
| **建议** | 使用 `JWTDecode` 库；或 iOS 16+ 的 `Data(base64urlDecoded:)` |

### 2.5 手动 Keychain 低级 API 操作

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Network/TokenManager.swift:169-218` |
| **现状** | 直接调用 `SecItemAdd`、`SecItemCopyMatching`、`SecItemDelete`，采用"先删后插"策略 |
| **副作用** | 错误处理不完善（status code 未充分检查），代码冗长 |
| **建议** | 使用 `KeychainAccess` 库，代码量减少约 50% |

### 2.6 NotificationCenter 事件分发（应使用 Combine 或 @Observable）

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Sync/SyncManager.swift:42-45`, `Core/Notification/NotificationManager.swift:420-425` |
| **现状** | 使用 `NotificationCenter.default.post(name:)` 分发事件，接收方需手动注册/注销 |
| **副作用** | 类型不安全、容易遗忘注销导致内存泄漏 |
| **建议** | 使用 Combine `PassthroughSubject` 或 `@Observable` 属性直接观察 |

### 2.7 UserDefaults 手动 getter/setter（应使用 @AppStorage）

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Notification/NotificationManager.swift:17-32` |
| **现状** | 手动编写 `UserDefaults.standard.bool(forKey:)` 计算属性（mealRemindersEnabled、checkinReminderEnabled、waterReminderEnabled） |
| **副作用** | 视图不会自动响应值变化，key 字符串硬编码易出错 |
| **建议** | 使用 `@AppStorage("mealRemindersEnabled") var mealRemindersEnabled = false` |

### 2.8 DateFormatter 缓存机制（应使用 Date.FormatStyle）

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Extensions/Date+Helpers.swift:56-83` |
| **现状** | 使用 `nonisolated(unsafe) static let formatterCache: NSCache<NSString, DateFormatter>` 自行缓存 DateFormatter |
| **副作用** | `nonisolated(unsafe)` 并发不安全，在 Swift 6 strict concurrency 下有风险 |
| **建议** | iOS 15+ 使用 `Date.FormatStyle` / `.formatted()`，天然线程安全且性能更好 |

---

## 三、🟡 中优先级（建议改进）

### 3.1 重复的 DateFormatter 静态变量

| 项目 | 说明 |
|------|------|
| **文件** | `Features/Home/HomeViewModel.swift:38-42`, `Features/Diary/DiaryViewModel.swift:27-31`, `Features/Statistics/StatisticsViewModel.swift:66-76` |
| **现状** | 三个 ViewModel 各自定义了相同格式的 `private static let dateFormatter` |
| **建议** | 统一到 `Date+Helpers` 扩展，如 `extension Date { var apiDateString: String }` |

### 3.2 重复的 URLSession 配置

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Network/APIClient.swift:31-46`, `Core/Camera/ImageUploadService.swift:72-79`, `Core/ML/CloudVisionService.swift:148-155` |
| **现状** | 三个 Service 各自创建 URLSession，超时时间不一致（30s/60s/120s） |
| **建议** | 创建统一的 `URLSessionConfiguration` 工厂方法，按场景配置 |

### 3.3 重复的 JSONDecoder 配置

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Network/APIClient.swift:39-45`, `Core/Camera/ImageUploadService.swift:125`, `Core/ML/CloudVisionService.swift:260, 280` |
| **现状** | 每处使用不同 decoder 实例，keyDecodingStrategy 不一致 |
| **建议** | 创建全局 decoder 工厂，提供 `.snakeCase` 和 `.camelCase` 两种预配置版本 |

### 3.4 手工绘制图表（vs Swift Charts）

| 项目 | 说明 |
|------|------|
| **文件** | `Features/Profile/Components/WeightInputSheet.swift:204-271` |
| **现状** | 使用 `Path` 低级 API 手工绘制网格线、趋势线和数据点 |
| **副作用** | 项目已在 `CalorieTrendChart.swift` 中使用了 Swift Charts，风格不统一 |
| **建议** | 统一使用 Swift Charts 的 `LineMark` + `PointMark` |

### 3.5 手工绘制进度环（vs Gauge）

| 项目 | 说明 |
|------|------|
| **文件** | `Features/Home/Components/CalorieRingChart.swift:62-143` |
| **现状** | 三层嵌套的 `Circle().trim()` + 手动计算角度和动画 |
| **建议** | 考虑使用 SwiftUI `Gauge` 视图（iOS 16+），或至少抽取可复用的 `RingView` 组件减少重复 |

### 3.6 自定义周日期选择器（vs DatePicker）

| 项目 | 说明 |
|------|------|
| **文件** | `Features/Diary/Components/WeekDatePicker.swift:1-196` |
| **现状** | 完整自行实现了周视图日期选择器，包含 `DateCell` 子组件（196 行代码） |
| **建议** | 使用 SwiftUI `DatePicker(.graphical)` 或 `MultiDatePicker`（iOS 16+） |

### 3.7 问候语逻辑重复实现

| 项目 | 说明 |
|------|------|
| **文件** | `Features/Home/HomeViewModel.swift:50-60`, `Core/Extensions/Date+Helpers.swift:108-120` |
| **现状** | 两处各自实现了基于小时的问候语，且时间段划分不一致（HomeViewModel: `12..<18` vs Date+Helpers: `12..<14` + `14..<18`） |
| **建议** | 统一到 `Date` 扩展，ViewModel 直接调用 `Date().greeting` |

### 3.8 DTO→Model 转换逻辑分散

| 项目 | 说明 |
|------|------|
| **文件** | `Features/Analysis/AnalysisViewModel.swift:235-251`, `Features/Diary/DiaryViewModel.swift:150-168` |
| **现状** | 多个 ViewModel 中内联编写 DTO→Model 的映射代码 |
| **建议** | 创建 `extension MealRecord { static func from(_ dto: MealResponseDTO) -> MealRecord }` 统一入口 |

### 3.9 Task.sleep 防抖（vs Combine debounce）

| 项目 | 说明 |
|------|------|
| **文件** | `Features/Search/FoodSearchViewModel.swift:107-113` |
| **现状** | 使用 `Task.sleep(for: .milliseconds(300))` + `Task.isCancelled` 手动实现防抖 |
| **建议** | 使用 Combine 的 `.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)` |

### 3.10 DispatchQueue 与 Actor 混用

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Sync/SyncManager.swift:18-19` |
| **现状** | 使用 `DispatchQueue(label: "com.foodmoment.sync.monitor")` 管理网络监听 |
| **建议** | 统一使用 `@MainActor` + `actor`，与项目其他部分的并发模型保持一致 |

### 3.11 路由/导航管理（vs NavigationStack）

| 项目 | 说明 |
|------|------|
| **文件** | `App/AppState.swift:22-41` |
| **现状** | 手动管理 `FullScreenDestination` enum + `activeFullScreen` 状态 |
| **建议** | 使用 iOS 16+ 的 `NavigationStack(path:)` + `.navigationDestination(for:)` |

---

## 四、🟢 低优先级（可选优化）

### 4.1 自定义 Shimmer 加载效果

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Extensions/View+Shimmer.swift:3-82` |
| **现状** | 自行实现了 `LinearGradient` + `offset` 动画的闪烁效果 |
| **建议** | 使用 `.redacted(reason: .placeholder)` 修饰符（iOS 14+） |

### 4.2 自定义玻璃态背景

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Extensions/View+Glass.swift:5-109` |
| **现状** | 多层 `.background(.white.opacity(0.6))` + `.background(.ultraThinMaterial)` 组合 |
| **建议** | 简化为单层 `.background(.ultraThinMaterial)` + `.clipShape()` + `.shadow()` |

### 4.3 自行实现图片缓存

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Extensions/View+Performance.swift:129-188` |
| **现状** | 使用 `NSCache<NSURL, UIImage>` 实现内存缓存，`getCacheSize()` 返回 0（NSCache 不支持精确统计） |
| **建议** | 使用 `URLCache.shared` 磁盘缓存 + `AsyncImage` 内置缓存（iOS 15+） |

### 4.4 自行实现图片预取

| 项目 | 说明 |
|------|------|
| **文件** | `Core/Extensions/View+Performance.swift:300-359` |
| **现状** | 手动管理 `prefetchedURLs: Set<URL>` 和 `prefetchTasks: [URL: Task]` |
| **建议** | 配合 `AsyncImage` 使用 `.onAppear` 预加载，或使用 `URLSession.prefetchDownloads` |

### 4.5 JSONSerialization 与 Codable 混用

| 项目 | 说明 |
|------|------|
| **文件** | `Core/ML/CloudVisionService.swift:200` |
| **现状** | 使用 `JSONSerialization.data(withJSONObject:)` 构建请求体 |
| **建议** | 定义 `Codable` 结构体，使用 `JSONEncoder` 编码 |

### 4.6 HealthKit Continuation 包装

| 项目 | 说明 |
|------|------|
| **文件** | `Core/HealthKit/HealthKitManager.swift:37-47` |
| **现状** | 使用 `withCheckedThrowingContinuation` 包装 HealthKit 回调 |
| **建议** | iOS 17.5+ HealthKit 已原生支持 async/await |

### 4.7 CSV 导出手动字符串拼接

| 项目 | 说明 |
|------|------|
| **文件** | `Features/Statistics/StatisticsViewModel.swift:198-213` |
| **现状** | 手动拼接 CSV 字符串，未处理特殊字符转义 |
| **建议** | 至少添加引号转义：`.map { "\"\($0)\"" }.joined(separator: ",")` |

### 4.8 SwiftData + UserDefaults 混合持久化

| 项目 | 说明 |
|------|------|
| **文件** | `Shared/SharedDataManager.swift:134-158` |
| **现状** | 同时使用 SwiftData 和 UserDefaults，职责划分不清晰 |
| **建议** | 简单数据统一用 `@AppStorage(store: UserDefaults(suiteName: appGroupID))` |

---

## 五、推荐引入的依赖

| 库名 | 用途 | 替代的自实现代码 |
|-----|------|----------------|
| `JWTDecode` | JWT 解析 | TokenManager 中的手动解析 |
| `KeychainAccess` | Keychain 封装 | TokenManager 中的 SecItem* 调用 |

> 注意：项目目前零第三方依赖，引入应谨慎评估。上述两个库都很轻量且维护活跃。

---

## 六、优先修复路线图

### 第一阶段：安全与兼容性
1. NavigationView → NavigationStack
2. JWT 手动解析 → JWTDecode 库
3. Keychain 低级 API → KeychainAccess 库
4. Multipart 编码统一 → 提取工具类

### 第二阶段：代码质量
5. DateFormatter 缓存 → Date.FormatStyle
6. 重复的 DateFormatter/URLSession/JSONDecoder → 统一工厂
7. NotificationCenter → Combine/Observable
8. UserDefaults → @AppStorage
9. 问候语逻辑统一

### 第三阶段：体验优化
10. 手绘图表 → Swift Charts 统一
11. 自定义 TabBar 评估是否回归原生
12. Shimmer → .redacted()
13. 图片缓存 → AsyncImage + URLCache

---

## 七、总体评价

项目整体架构良好，使用了 SwiftUI + SwiftData + Swift Concurrency 等现代技术栈。"造轮子"问题主要集中在：

- **安全敏感领域**（JWT、Keychain）— 强烈建议用成熟库替代
- **重复代码**（DateFormatter、URLSession、Multipart）— 可通过抽取工具类解决
- **过时 API**（NavigationView）— 应尽快迁移
- **UI 定制化**（TabBar、进度环、日期选择器）— 部分属于有意为之的设计选择，可根据实际需求评估

建议按路线图分阶段推进，优先处理安全和兼容性问题。
