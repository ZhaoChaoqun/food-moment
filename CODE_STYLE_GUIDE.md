# FoodMoment iOS 代码规范

> 本规范由资深 iOS 开发工程师制定，旨在确保代码质量、可维护性和团队协作效率。
>
> **版本**: 1.0.0
> **最后更新**: 2026-02-09
> **适用范围**: FoodMoment iOS 客户端

---

## 目录

1. [项目架构](#1-项目架构)
2. [命名规范](#2-命名规范)
3. [代码格式](#3-代码格式)
4. [SwiftUI 规范](#4-swiftui-规范)
5. [MVVM 架构规范](#5-mvvm-架构规范)
6. [数据模型规范](#6-数据模型规范)
7. [网络层规范](#7-网络层规范)
8. [错误处理](#8-错误处理)
9. [并发与线程安全](#9-并发与线程安全)
10. [注释与文档](#10-注释与文档)
11. [性能优化](#11-性能优化)
12. [安全规范](#12-安全规范)
13. [Git 提交规范](#13-git-提交规范)
14. [代码审查清单](#14-代码审查清单)

---

## 1. 项目架构

### 1.1 目录结构

```
FoodMoment/
├── App/                          # 应用入口与全局状态
│   ├── FoodMomentApp.swift       # @main 入口
│   ├── AppState.swift            # 全局状态管理
│   ├── ContentView.swift         # 根视图
│   └── MainTabView.swift         # Tab 容器
│
├── Core/                         # 核心基础设施（业务无关）
│   ├── Network/                  # 网络层
│   │   ├── APIClient.swift
│   │   ├── APIEndpoint.swift
│   │   ├── APIError.swift
│   │   └── TokenManager.swift
│   ├── Storage/                  # 数据持久化
│   ├── Theme/                    # 主题配置
│   │   ├── AppTheme.swift
│   │   ├── Color+Brand.swift
│   │   └── Font+Custom.swift
│   ├── Extensions/               # 全局扩展
│   ├── Camera/                   # 相机服务
│   ├── ML/                       # 机器学习
│   ├── HealthKit/                # 健康数据
│   ├── Notification/             # 通知管理
│   ├── Sync/                     # 数据同步
│   ├── Spotlight/                # 系统搜索
│   └── Intents/                  # Siri 快捷指令
│
├── Models/                       # 数据模型
│   ├── DTOs/                     # 数据传输对象
│   │   ├── AnalysisResponse.swift
│   │   ├── NutritionData.swift
│   │   └── FoodSearchResult.swift
│   ├── MealRecord.swift          # SwiftData 模型
│   ├── UserProfile.swift
│   ├── DetectedFood.swift
│   ├── WaterLog.swift
│   ├── WeightLog.swift
│   └── Achievement.swift
│
├── Features/                     # 功能模块（按业务划分）
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── Components/
│   │       ├── CalorieRingChart.swift
│   │       ├── WaterCard.swift
│   │       ├── StepsCard.swift
│   │       └── FoodMomentCarousel.swift
│   ├── Statistics/
│   ├── Camera/
│   ├── Diary/
│   ├── Profile/
│   ├── Auth/
│   ├── Analysis/
│   └── Search/
│
├── SharedComponents/             # 全局复用组件
│   ├── CustomTabBar.swift
│   ├── GlassCard.swift
│   ├── GradientButton.swift
│   ├── EmptyStateView.swift
│   └── RingShape.swift
│
├── Shared/                       # App Group 共享
│   └── SharedDataManager.swift
│
└── Resources/                    # 资源文件
    ├── Assets.xcassets
    ├── Fonts/
    └── Localizable.strings
```

### 1.2 架构原则

| 原则 | 说明 |
|------|------|
| **单一职责** | 每个类/结构体只负责一件事 |
| **依赖倒置** | 依赖抽象（协议），而非具体实现 |
| **开闭原则** | 对扩展开放，对修改关闭 |
| **最小知识** | 模块间通过明确接口通信，避免过度耦合 |

### 1.3 模块依赖规则

```
┌─────────────────────────────────────────────────┐
│                    Features                      │
│  (Home, Statistics, Camera, Diary, Profile...)  │
└─────────────────────┬───────────────────────────┘
                      │ 可以依赖
                      ▼
┌─────────────────────────────────────────────────┐
│              SharedComponents                    │
│     (CustomTabBar, GlassCard, RingShape...)     │
└─────────────────────┬───────────────────────────┘
                      │ 可以依赖
                      ▼
┌─────────────────────────────────────────────────┐
│           Core + Models                          │
│  (Network, Theme, Extensions, SwiftData Models) │
└─────────────────────────────────────────────────┘
```

**禁止**：
- ❌ Core 依赖 Features
- ❌ Models 依赖 Features
- ❌ Features 之间直接依赖（通过 AppState 通信）

---

## 2. 命名规范

### 2.1 通用命名规则

| 类型 | 规范 | 正确示例 | 错误示例 |
|------|------|----------|----------|
| **类/结构体** | PascalCase | `HomeViewModel` | `homeViewModel` |
| **协议** | PascalCase + 形容词/名词 | `Configurable`, `DataSource` | `ConfigurableProtocol` |
| **枚举** | PascalCase | `CameraFlashMode` | `cameraFlashMode` |
| **枚举 case** | camelCase | `.breakfast`, `.autoFocus` | `.Breakfast` |
| **函数/方法** | camelCase + 动词开头 | `loadData()`, `capturePhoto()` | `dataLoad()` |
| **变量/常量** | camelCase | `userName`, `dailyGoal` | `UserName`, `daily_goal` |
| **静态常量** | camelCase | `static let shared` | `static let SHARED` |

### 2.2 布尔值命名

布尔属性必须使用 `is`、`has`、`should`、`can`、`will` 等前缀：

```swift
// ✅ 正确
var isLoading: Bool
var hasAuthorization: Bool
var shouldRefresh: Bool
var canEdit: Bool
var willAppear: Bool

// ❌ 错误
var loading: Bool
var authorized: Bool
var refresh: Bool
var editable: Bool  // 形容词不够清晰
```

### 2.3 文件命名

| 类型 | 命名规则 | 示例 |
|------|----------|------|
| **View** | 功能 + View | `HomeView.swift`, `ProfileView.swift` |
| **ViewModel** | 功能 + ViewModel | `HomeViewModel.swift` |
| **Model** | 实体名称 | `MealRecord.swift`, `UserProfile.swift` |
| **扩展** | 类型 + 功能 | `View+Glass.swift`, `Date+Helpers.swift` |
| **组件** | 描述性名称 | `CalorieRingChart.swift`, `WaterCard.swift` |
| **服务** | 功能 + Service/Manager | `CameraService.swift`, `TokenManager.swift` |

### 2.4 缩写规范

常见缩写保持大写：

```swift
// ✅ 正确
let imageURL: URL
let userID: String
let apiClient: APIClient
let htmlContent: String

// ❌ 错误
let imageUrl: URL
let userId: String
let apiClient: ApiClient
let htmlContent: String  // HTML 应全大写，但作为后缀可小写
```

---

## 3. 代码格式

### 3.1 缩进与空格

```swift
// ✅ 使用 4 个空格缩进（Swift 标准）
func loadStatistics() {
    isLoading = true
    defer { isLoading = false }

    let calendar = Calendar.current
    let startOfWeek = calendar.startOfWeek(for: Date())
}

// ✅ 运算符两侧各一个空格
let total = calories + protein * 4

// ✅ 冒号后一个空格，前无空格
let name: String
let dict: [String: Any]
func process(data: Data) -> Result

// ✅ 逗号后一个空格
let array = [1, 2, 3, 4]
func setup(name: String, age: Int)
```

### 3.2 空行规范

```swift
import SwiftUI
import SwiftData
// 空一行
struct HomeView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    // 空一行
    // MARK: - Body
    var body: some View {
        // 实现
    }
    // 空一行
    // MARK: - Private Methods
    private func loadData() {
        // 实现
    }
}
```

**空行规则**：
- import 语句后空一行
- MARK 注释前空一行
- 函数/方法之间空一行
- 逻辑段落之间空一行
- 禁止连续超过一个空行

### 3.3 行长度

- **软限制**：100 字符
- **硬限制**：120 字符
- 超长时换行处理：

```swift
// ✅ 函数参数过长时，每个参数独占一行
func configureCell(
    title: String,
    subtitle: String,
    imageURL: URL?,
    calories: Int,
    isHighlighted: Bool
) {
    // 实现
}

// ✅ 链式调用过长时换行
let result = array
    .filter { $0.isValid }
    .map { $0.name }
    .sorted()
    .joined(separator: ", ")

// ✅ 条件语句过长时换行
if userProfile.isAuthenticated
    && userProfile.hasCompletedOnboarding
    && !userProfile.isAccountLocked {
    // 实现
}
```

### 3.4 大括号

```swift
// ✅ 左大括号不换行（K&R 风格）
func calculate() {
    if condition {
        // 实现
    } else {
        // 实现
    }
}

// ✅ 单行闭包可省略大括号换行
let names = users.map { $0.name }

// ✅ 多行闭包大括号换行
let names = users.map { user in
    let firstName = user.firstName
    let lastName = user.lastName
    return "\(firstName) \(lastName)"
}
```

### 3.5 访问控制

```swift
// ✅ 默认 internal，只显式标注其他级别
final class HomeViewModel {
    // public 属性（如有需要）
    var userName: String = "User"

    // private 属性必须显式标注
    private var cancellables = Set<AnyCancellable>()
    private let sessionQueue = DispatchQueue(label: "session")

    // fileprivate 用于同文件内扩展访问
    fileprivate var internalState: State = .idle
}

// ✅ 访问控制顺序：访问级别 → 修饰符 → 声明
private static let shared = Manager()
public override func viewDidLoad()
```

---

## 4. SwiftUI 规范

### 4.1 视图结构模板

```swift
import SwiftUI
import SwiftData

struct FeatureView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    // MARK: - State
    @State private var viewModel = FeatureViewModel()
    @State private var isShowingSheet = false

    // MARK: - Properties
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    contentSection
                    footerSection
                }
                .padding(.bottom, 100) // TabBar 安全区
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadData(modelContext: modelContext)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Title")
                .font(.Jakarta.extraBold(32))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    // MARK: - Content Section
    private var contentSection: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(viewModel.items) { item in
                ItemCard(item: item)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Footer Section
    @ViewBuilder
    private var footerSection: some View {
        if viewModel.hasMoreContent {
            LoadMoreButton {
                viewModel.loadMore()
            }
        }
    }
}
```

### 4.2 修饰符顺序

按以下顺序排列修饰符，确保一致性：

```swift
Text("Hello")
    // 1. 内容修饰
    .font(.Jakarta.bold(16))
    .foregroundStyle(.primary)
    .lineLimit(2)

    // 2. 布局修饰
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)

    // 3. 背景与边框
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
    )

    // 4. 阴影与视觉效果
    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

    // 5. 交互
    .onTapGesture { }
    .gesture(DragGesture())

    // 6. 动画
    .animation(.spring(), value: isExpanded)

    // 7. 生命周期
    .onAppear { }
    .onDisappear { }
    .task { }

    // 8. 辅助功能
    .accessibilityIdentifier("HelloText")
    .accessibilityLabel("问候语")
```

### 4.3 计算属性提取规则

**必须提取为计算属性的情况**：
- 代码超过 5 行
- 包含复杂逻辑（条件、循环）
- 可能被复用
- 需要 MARK 注释标识的逻辑块

```swift
// ✅ 正确：复杂视图提取为计算属性
private var calorieRingCard: some View {
    VStack(spacing: 16) {
        ZStack {
            CalorieRingChart(progress: viewModel.progress)
                .frame(width: 200, height: 200)

            VStack(spacing: 4) {
                Text("\(viewModel.caloriesLeft)")
                    .font(.Jakarta.extraBold(48))
                Text("KCAL LEFT")
                    .font(.Jakarta.semiBold(11))
            }
        }

        Text("每日目标: \(viewModel.dailyGoal)")
            .font(.Jakarta.medium(12))
    }
    .padding(24)
    .glassCard()
}

// ✅ 正确：简单视图可内联
var body: some View {
    VStack {
        Text("Title").font(.headline)  // 简单，可内联
        calorieRingCard                // 复杂，已提取
    }
}
```

### 4.4 @ViewBuilder 使用

```swift
// ✅ 条件内容使用 @ViewBuilder
@ViewBuilder
private var statusView: some View {
    if viewModel.isLoading {
        ProgressView()
    } else if let error = viewModel.error {
        ErrorView(message: error)
    } else {
        ContentView(data: viewModel.data)
    }
}

// ✅ 自定义容器组件
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        cornerRadius: CGFloat = AppTheme.CornerRadius.medium,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
```

### 4.5 列表与集合

```swift
// ✅ ForEach 必须配合 Identifiable 或显式 id
ForEach(items) { item in  // item 遵循 Identifiable
    ItemRow(item: item)
}

ForEach(items, id: \.uniqueID) { item in  // 显式指定 id
    ItemRow(item: item)
}

// ❌ 禁止使用索引作为唯一 ID（除非数据不变）
ForEach(0..<items.count, id: \.self) { index in  // 危险！
    ItemRow(item: items[index])
}

// ✅ LazyVStack/LazyVGrid 用于大量数据
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(meals) { meal in
            MealCard(meal: meal)
        }
    }
}
```

---

## 5. MVVM 架构规范

### 5.1 ViewModel 模板

```swift
import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class FeatureViewModel {

    // MARK: - Published Properties
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Private Properties
    private var currentPage = 1
    private let pageSize = 20

    // MARK: - Computed Properties
    var isEmpty: Bool {
        items.isEmpty && !isLoading
    }

    var hasMorePages: Bool {
        items.count >= currentPage * pageSize
    }

    // MARK: - Initialization
    init() {
        // 轻量级初始化，避免耗时操作
    }

    // MARK: - Public Methods
    func loadData(modelContext: ModelContext) {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<Item>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            items = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }

    func refresh(modelContext: ModelContext) {
        currentPage = 1
        loadData(modelContext: modelContext)
    }

    func loadMore(modelContext: ModelContext) {
        guard hasMorePages, !isLoading else { return }
        currentPage += 1
        // 加载更多逻辑
    }

    // MARK: - Private Methods
    private func processData(_ rawData: [RawItem]) -> [Item] {
        rawData.compactMap { Item(from: $0) }
    }
}
```

### 5.2 View-ViewModel 通信

```swift
// ✅ 正确：通过方法调用
struct FeatureView: View {
    @State private var viewModel = FeatureViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List(viewModel.items) { item in
            ItemRow(item: item)
        }
        .refreshable {
            viewModel.refresh(modelContext: modelContext)
        }
        .onAppear {
            viewModel.loadData(modelContext: modelContext)
        }
    }
}

// ❌ 错误：View 直接操作数据
struct FeatureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]  // 简单场景可用，复杂逻辑应封装到 ViewModel

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
                .onTapGesture {
                    // ❌ 业务逻辑不应在 View 中
                    modelContext.delete(item)
                    try? modelContext.save()
                }
        }
    }
}
```

### 5.3 状态管理

```swift
// ✅ AppState 用于全局状态
@Observable
final class AppState {
    // 认证状态
    var isAuthenticated = false
    var currentUser: UserProfile?

    // 导航状态
    var selectedTab: TabItem = .home
    var navigationPath = NavigationPath()

    // 深链接
    var pendingDeepLink: URL?
    var shouldOpenCamera = false

    // 同步状态
    var isSyncing = false
    var lastSyncDate: Date?

    // MARK: - Convenience
    static func forUITesting() -> AppState {
        let state = AppState()
        state.isAuthenticated = true
        return state
    }
}

// ✅ 在 App 入口注入
@main
struct FoodMomentApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(for: [MealRecord.self, UserProfile.self])
    }
}

// ✅ 在 View 中使用
struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState  // 需要绑定时

        TabView(selection: $appState.selectedTab) {
            // tabs
        }
    }
}
```

---

## 6. 数据模型规范

### 6.1 SwiftData 模型模板

```swift
import Foundation
import SwiftData

@Model
final class MealRecord {
    // MARK: - Primary Key
    @Attribute(.unique) var id: UUID

    // MARK: - Properties
    var mealType: String
    var mealTime: Date
    var totalCalories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double
    var fiberGrams: Double
    var title: String
    var descriptionText: String?
    var aiAnalysis: String?
    var tags: [String]

    // MARK: - Media
    var imageURL: String?
    @Attribute(.externalStorage) var localImageData: Data?

    // MARK: - Metadata
    var isSynced: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \DetectedFood.mealRecord)
    var detectedFoods: [DetectedFood] = []

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        imageURL: String? = nil,
        localImageData: Data? = nil,
        mealType: String,
        mealTime: Date,
        totalCalories: Int,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double,
        fiberGrams: Double = 0,
        title: String,
        descriptionText: String? = nil,
        aiAnalysis: String? = nil,
        tags: [String] = [],
        isSynced: Bool = false
    ) {
        self.id = id
        self.imageURL = imageURL
        self.localImageData = localImageData
        self.mealType = mealType
        self.mealTime = mealTime
        self.totalCalories = totalCalories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.title = title
        self.descriptionText = descriptionText
        self.aiAnalysis = aiAnalysis
        self.tags = tags
        self.isSynced = isSynced
    }

    // MARK: - Nested Types
    enum MealType: String, CaseIterable, Codable {
        case breakfast
        case lunch
        case dinner
        case snack

        var displayName: String {
            switch self {
            case .breakfast: return "早餐"
            case .lunch: return "午餐"
            case .dinner: return "晚餐"
            case .snack: return "加餐"
            }
        }

        var emoji: String {
            switch self {
            case .breakfast: return "🌅"
            case .lunch: return "☀️"
            case .dinner: return "🌙"
            case .snack: return "🍪"
            }
        }
    }
}

// MARK: - Computed Properties
extension MealRecord {
    var mealTypeEnum: MealType? {
        MealType(rawValue: mealType)
    }

    var formattedTime: String {
        mealTime.formatted(as: "HH:mm")
    }

    var totalMacros: Double {
        proteinGrams + carbsGrams + fatGrams
    }
}
```

### 6.2 DTO 模板

```swift
import Foundation

/// API 响应：食物分析结果
struct AnalysisResponse: Codable, Sendable {
    let requestId: String
    let status: Status
    let result: AnalysisResult?
    let error: ErrorInfo?

    enum Status: String, Codable {
        case success
        case processing
        case failed
    }

    struct AnalysisResult: Codable, Sendable {
        let foods: [DetectedFoodDTO]
        let totalCalories: Int
        let totalProtein: Double
        let totalCarbs: Double
        let totalFat: Double
        let confidence: Double
        let suggestions: [String]?
    }

    struct ErrorInfo: Codable, Sendable {
        let code: String
        let message: String
    }
}

struct DetectedFoodDTO: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let localizedName: String?
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let servingSize: String?
    let confidence: Double
    let boundingBox: BoundingBox?

    struct BoundingBox: Codable, Sendable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
}
```

### 6.3 模型转换

```swift
// ✅ 使用扩展实现 DTO → Model 转换
extension MealRecord {
    convenience init(from response: AnalysisResponse, imageURL: String?, mealType: String) {
        guard let result = response.result else {
            fatalError("Cannot create MealRecord from failed response")
        }

        self.init(
            imageURL: imageURL,
            mealType: mealType,
            mealTime: Date(),
            totalCalories: result.totalCalories,
            proteinGrams: result.totalProtein,
            carbsGrams: result.totalCarbs,
            fatGrams: result.totalFat,
            title: result.foods.first?.localizedName ?? "未知食物"
        )

        // 转换检测到的食物
        self.detectedFoods = result.foods.map { DetectedFood(from: $0) }
    }
}

extension DetectedFood {
    convenience init(from dto: DetectedFoodDTO) {
        self.init(
            name: dto.localizedName ?? dto.name,
            calories: dto.calories,
            protein: dto.protein,
            carbs: dto.carbs,
            fat: dto.fat,
            confidence: dto.confidence
        )
    }
}
```

---

## 7. 网络层规范

### 7.1 APIClient 架构

```swift
import Foundation

/// 网络请求客户端（线程安全）
actor APIClient {
    // MARK: - Singleton
    static let shared = APIClient()

    // MARK: - Properties
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Public API

    /// 执行 API 请求
    /// - Parameters:
    ///   - endpoint: API 端点
    ///   - body: 请求体（可选）
    /// - Returns: 解码后的响应
    /// - Throws: APIError
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        body: (any Encodable)? = nil
    ) async throws -> T {
        let request = try await buildRequest(endpoint, body: body)
        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// 上传文件
    func upload(
        _ endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) async throws -> UploadResponse {
        let boundary = UUID().uuidString
        var request = try await buildRequest(endpoint, body: nil)
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        let body = createMultipartBody(
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            boundary: boundary
        )
        request.httpBody = body

        let (data, response) = try await performRequest(request)
        try validateResponse(response, data: data)

        return try decoder.decode(UploadResponse.self, from: data)
    }

    // MARK: - Private Methods

    private func buildRequest(
        _ endpoint: APIEndpoint,
        body: (any Encodable)?
    ) async throws -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 添加认证令牌
        if endpoint.requiresAuth,
           let token = await TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 编码请求体
        if let body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.encodingError(error)
            }
        }

        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch {
            throw APIError.unknown
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return // 成功
        case 401:
            throw APIError.unauthorized
        case 400..<500:
            let message = try? decoder.decode(ErrorResponse.self, from: data).message
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        case 500..<600:
            throw APIError.serverError("服务器错误，请稍后重试")
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }
    }
}
```

### 7.2 API 端点定义

```swift
import Foundation

enum APIEndpoint {
    // 认证
    case signIn(email: String, password: String)
    case signUp(email: String, password: String, name: String)
    case refreshToken
    case signOut

    // 食物
    case analyzeFood
    case searchFood(query: String)
    case getFoodDetail(id: String)

    // 记录
    case getMeals(date: Date)
    case createMeal(MealRecord)
    case updateMeal(id: String, MealRecord)
    case deleteMeal(id: String)

    // 用户
    case getProfile
    case updateProfile(UserProfile)

    // MARK: - URL Construction

    private static let baseURL = URL(string: "https://api.foodmoment.app/v1")!

    var url: URL {
        switch self {
        case .signIn:
            return Self.baseURL.appendingPathComponent("auth/signin")
        case .signUp:
            return Self.baseURL.appendingPathComponent("auth/signup")
        case .refreshToken:
            return Self.baseURL.appendingPathComponent("auth/refresh")
        case .signOut:
            return Self.baseURL.appendingPathComponent("auth/signout")
        case .analyzeFood:
            return Self.baseURL.appendingPathComponent("food/analyze")
        case .searchFood(let query):
            var components = URLComponents(url: Self.baseURL.appendingPathComponent("food/search"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "q", value: query)]
            return components.url!
        case .getFoodDetail(let id):
            return Self.baseURL.appendingPathComponent("food/\(id)")
        case .getMeals(let date):
            var components = URLComponents(url: Self.baseURL.appendingPathComponent("meals"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "date", value: ISO8601DateFormatter().string(from: date))]
            return components.url!
        case .createMeal:
            return Self.baseURL.appendingPathComponent("meals")
        case .updateMeal(let id, _):
            return Self.baseURL.appendingPathComponent("meals/\(id)")
        case .deleteMeal(let id):
            return Self.baseURL.appendingPathComponent("meals/\(id)")
        case .getProfile:
            return Self.baseURL.appendingPathComponent("user/profile")
        case .updateProfile:
            return Self.baseURL.appendingPathComponent("user/profile")
        }
    }

    var method: HTTPMethod {
        switch self {
        case .signIn, .signUp, .refreshToken, .analyzeFood, .createMeal:
            return .POST
        case .signOut, .deleteMeal:
            return .DELETE
        case .updateMeal, .updateProfile:
            return .PUT
        default:
            return .GET
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .signIn, .signUp, .refreshToken:
            return false
        default:
            return true
        }
    }
}

enum HTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}
```

### 7.3 错误定义

```swift
import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case unauthorized
    case serverError(String)
    case rateLimited(retryAfter: TimeInterval?)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .invalidResponse:
            return "服务器响应无效"
        case .httpError(let code, let message):
            return message ?? "请求失败 (错误码: \(code))"
        case .decodingError:
            return "数据解析失败"
        case .encodingError:
            return "请求数据编码失败"
        case .networkError(let error):
            return "网络连接失败: \(error.localizedDescription)"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .serverError(let message):
            return message
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "请求过于频繁，请 \(Int(seconds)) 秒后重试"
            }
            return "请求过于频繁，请稍后重试"
        case .unknown:
            return "未知错误"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .rateLimited:
            return true
        default:
            return false
        }
    }
}
```

---

## 8. 错误处理

### 8.1 基本原则

```swift
// ✅ 明确的错误类型
enum ValidationError: LocalizedError {
    case emptyField(String)
    case invalidFormat(String)
    case outOfRange(field: String, min: Int, max: Int)

    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field)不能为空"
        case .invalidFormat(let field):
            return "\(field)格式不正确"
        case .outOfRange(let field, let min, let max):
            return "\(field)必须在 \(min) 到 \(max) 之间"
        }
    }
}

// ✅ 使用 Result 类型处理可预期错误
func validate(email: String) -> Result<String, ValidationError> {
    guard !email.isEmpty else {
        return .failure(.emptyField("邮箱"))
    }
    guard email.contains("@") else {
        return .failure(.invalidFormat("邮箱"))
    }
    return .success(email)
}

// ✅ 使用 throws 处理可恢复错误
func saveData(_ data: Data) throws {
    guard !data.isEmpty else {
        throw ValidationError.emptyField("数据")
    }
    try data.write(to: fileURL)
}
```

### 8.2 async/await 错误处理

```swift
// ✅ 正确的异步错误处理
@MainActor
func loadUserData() async {
    isLoading = true
    errorMessage = nil

    do {
        let profile: UserProfile = try await APIClient.shared.request(.getProfile)
        self.userProfile = profile
    } catch APIError.unauthorized {
        // 特定错误处理
        await handleUnauthorized()
    } catch APIError.networkError {
        // 网络错误可重试
        errorMessage = "网络连接失败，请检查网络设置"
        canRetry = true
    } catch {
        // 通用错误处理
        errorMessage = error.localizedDescription
        canRetry = false
    }

    isLoading = false
}

// ✅ 使用 defer 确保清理
func processImage(_ image: UIImage) async throws -> ProcessedImage {
    isProcessing = true
    defer { isProcessing = false }

    let compressed = try await compressImage(image)
    let analyzed = try await analyzeImage(compressed)
    return analyzed
}
```

### 8.3 SwiftData 错误处理

```swift
// ✅ 数据操作错误处理
func saveMeal(_ meal: MealRecord, modelContext: ModelContext) {
    modelContext.insert(meal)

    do {
        try modelContext.save()
    } catch {
        // 回滚操作
        modelContext.rollback()

        // 记录错误
        print("Failed to save meal: \(error)")

        // 通知用户
        errorMessage = "保存失败，请重试"
    }
}

// ✅ 查询错误处理
func fetchTodayMeals(modelContext: ModelContext) -> [MealRecord] {
    let startOfDay = Calendar.current.startOfDay(for: Date())
    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

    let predicate = #Predicate<MealRecord> { meal in
        meal.mealTime >= startOfDay && meal.mealTime < endOfDay
    }

    let descriptor = FetchDescriptor<MealRecord>(
        predicate: predicate,
        sortBy: [SortDescriptor(\.mealTime)]
    )

    do {
        return try modelContext.fetch(descriptor)
    } catch {
        print("Failed to fetch meals: \(error)")
        return []
    }
}
```

---

## 9. 并发与线程安全

### 9.1 Actor 模式

```swift
// ✅ 使用 actor 确保线程安全
actor TokenManager {
    static let shared = TokenManager()

    private var _accessToken: String?
    private var _refreshToken: String?

    var accessToken: String? {
        _accessToken
    }

    func setTokens(access: String, refresh: String) {
        _accessToken = access
        _refreshToken = refresh
        saveToKeychain()
    }

    func clearTokens() {
        _accessToken = nil
        _refreshToken = nil
        removeFromKeychain()
    }

    private func saveToKeychain() {
        // Keychain 操作
    }
}

// ✅ 调用 actor 方法
Task {
    await TokenManager.shared.setTokens(access: token, refresh: refreshToken)
}
```

### 9.2 MainActor

```swift
// ✅ ViewModel 必须标注 @MainActor
@MainActor
@Observable
final class HomeViewModel {
    var items: [Item] = []  // UI 绑定属性
    var isLoading = false

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // 网络请求（自动在后台执行）
        let data = try? await APIClient.shared.request(.getData)

        // 更新 UI（已在主线程）
        self.items = data ?? []
    }
}

// ✅ 非主线程任务明确标注
nonisolated func processInBackground(_ data: Data) async -> ProcessedData {
    // 后台处理
    return ProcessedData(data)
}
```

### 9.3 Task 管理

```swift
struct FeatureView: View {
    @State private var viewModel = FeatureViewModel()
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        List(viewModel.items) { item in
            ItemRow(item: item)
        }
        .onAppear {
            // ✅ 保存 Task 引用以便取消
            loadTask = Task {
                await viewModel.loadData()
            }
        }
        .onDisappear {
            // ✅ 视图消失时取消任务
            loadTask?.cancel()
        }
        .refreshable {
            // ✅ refreshable 自动处理 Task 生命周期
            await viewModel.refresh()
        }
    }
}

// ✅ 在 ViewModel 中检查取消状态
@MainActor
func loadData() async {
    isLoading = true
    defer { isLoading = false }

    for await batch in dataStream {
        // 检查是否已取消
        guard !Task.isCancelled else { return }

        items.append(contentsOf: batch)
    }
}
```

### 9.4 Sendable 约束

```swift
// ✅ DTO 必须是 Sendable
struct UserDTO: Codable, Sendable {
    let id: String
    let name: String
    let email: String
}

// ✅ 枚举自动 Sendable
enum LoadingState: Sendable {
    case idle
    case loading
    case success
    case failure(Error)
}

// ✅ 类需要显式遵循（通常使用 actor 替代）
final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0

    var count: Int {
        lock.withLock { _count }
    }

    func increment() {
        lock.withLock { _count += 1 }
    }
}
```

---

## 10. 注释与文档

### 10.1 MARK 注释

```swift
// MARK: - 分隔符（带横线）
// MARK: 无横线分隔符

// 标准顺序
class FeatureViewModel {
    // MARK: - Properties

    // MARK: - Computed Properties

    // MARK: - Initialization

    // MARK: - Public Methods

    // MARK: - Private Methods

    // MARK: - Helper Methods
}

struct FeatureView: View {
    // MARK: - Environment

    // MARK: - State

    // MARK: - Properties

    // MARK: - Body

    // MARK: - Subviews

    // MARK: - Actions
}
```

### 10.2 文档注释

```swift
/// 分析食物图片并返回营养信息
///
/// 该方法会将图片上传到服务器进行 AI 分析，识别图片中的食物
/// 并估算其营养成分。
///
/// - Parameters:
///   - image: 要分析的食物图片
///   - mealType: 餐次类型（早餐、午餐、晚餐、加餐）
///
/// - Returns: 包含识别结果的 `AnalysisResponse`
///
/// - Throws:
///   - `APIError.unauthorized`: 用户未登录或登录已过期
///   - `APIError.networkError`: 网络连接失败
///   - `APIError.serverError`: 服务器处理失败
///
/// - Note: 图片会被压缩到 1MB 以下再上传
///
/// - Important: 此方法需要网络连接
///
/// ## 示例
/// ```swift
/// let response = try await analyzeFood(image: foodImage, mealType: .lunch)
/// print("识别到 \(response.result?.foods.count ?? 0) 种食物")
/// ```
func analyzeFood(image: UIImage, mealType: MealRecord.MealType) async throws -> AnalysisResponse {
    // 实现
}
```

### 10.3 TODO/FIXME 注释

```swift
// TODO: 实现离线缓存功能
// FIXME: 内存泄漏问题，需要检查闭包引用
// HACK: 临时解决方案，等待后端修复后移除
// NOTE: 此处使用硬编码值是因为设计要求固定尺寸
```

### 10.4 中文注释规范

```swift
// ✅ 业务逻辑使用中文注释
// 计算每日剩余卡路里：目标摄入量 - 已摄入量
var caloriesLeft: Int {
    max(dailyCalorieGoal - consumedCalories, 0)
}

// ✅ 复杂算法说明
// 使用加权平均计算本周营养评分
// 权重：蛋白质 0.4，碳水 0.3，脂肪 0.3
func calculateWeeklyScore() -> Double {
    // 实现
}

// ❌ 避免无意义的注释
// 设置名称
self.name = name  // 这种注释没有价值
```

---

## 11. 性能优化

### 11.1 SwiftUI 性能

```swift
// ✅ 使用 Lazy 容器处理大量数据
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}

// ✅ 合理使用 @State 和 @Binding
struct ParentView: View {
    @State private var count = 0

    var body: some View {
        // 只传递需要的数据
        ChildView(count: $count)  // ✅ Binding
        DisplayView(count: count)  // ✅ 值传递（只读）
    }
}

// ✅ 避免在 body 中进行计算
struct ItemRow: View {
    let item: Item

    // ✅ 使用计算属性缓存格式化结果
    private var formattedDate: String {
        item.date.formatted(as: "MM月dd日")
    }

    var body: some View {
        Text(formattedDate)  // ✅ 不会每次重新计算
    }
}

// ✅ 使用 EquatableView 优化重绘
struct OptimizedRow: View, Equatable {
    let title: String
    let value: Int

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.title == rhs.title && lhs.value == rhs.value
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
        }
    }
}
```

### 11.2 图片优化

```swift
// ✅ 异步加载网络图片
AsyncImage(url: URL(string: imageURL)) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    case .failure:
        Image(systemName: "photo")
            .foregroundColor(.secondary)
    @unknown default:
        EmptyView()
    }
}
.frame(width: 100, height: 100)
.clipShape(RoundedRectangle(cornerRadius: 12))

// ✅ 图片压缩
extension UIImage {
    func compressed(maxSizeKB: Int = 1024) -> Data? {
        var compression: CGFloat = 1.0
        let maxBytes = maxSizeKB * 1024

        guard var data = jpegData(compressionQuality: compression) else {
            return nil
        }

        while data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            guard let newData = jpegData(compressionQuality: compression) else {
                return data
            }
            data = newData
        }

        return data
    }
}

// ✅ 图片缓存
actor ImageCacheManager {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    func setImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url.absoluteString as NSString)
    }
}
```

### 11.3 数据加载优化

```swift
// ✅ 分页加载
@MainActor
@Observable
final class PaginatedViewModel {
    var items: [Item] = []
    var isLoading = false
    var hasMore = true

    private var currentPage = 0
    private let pageSize = 20

    func loadMore() async {
        guard !isLoading, hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let newItems: [Item] = try await APIClient.shared.request(
                .getItems(page: currentPage, size: pageSize)
            )

            items.append(contentsOf: newItems)
            hasMore = newItems.count == pageSize
            currentPage += 1
        } catch {
            // 错误处理
        }
    }
}

// ✅ 预加载
struct ItemList: View {
    @State private var viewModel = PaginatedViewModel()

    var body: some View {
        List(viewModel.items) { item in
            ItemRow(item: item)
                .onAppear {
                    // 距离底部 5 个时预加载
                    if item == viewModel.items.suffix(5).first {
                        Task {
                            await viewModel.loadMore()
                        }
                    }
                }
        }
    }
}
```

---

## 12. 安全规范

### 12.1 敏感数据存储

```swift
// ✅ 使用 Keychain 存储敏感信息
import Security

enum KeychainHelper {
    static func save(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else {
            return nil
        }
        return result as? Data
    }

    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// ❌ 禁止使用 UserDefaults 存储敏感信息
// UserDefaults.standard.set(password, forKey: "password")  // 危险！
```

### 12.2 网络安全

```swift
// ✅ 强制 HTTPS
// 在 Info.plist 中配置 App Transport Security
// <key>NSAppTransportSecurity</key>
// <dict>
//     <key>NSAllowsArbitraryLoads</key>
//     <false/>
// </dict>

// ✅ 证书固定（可选，高安全场景）
class PinnedSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // 验证证书
        let serverCertData = SecCertificateCopyData(certificate) as Data
        let pinnedCertData = loadPinnedCertificate()

        if serverCertData == pinnedCertData {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

### 12.3 输入验证

```swift
// ✅ 永远不信任用户输入
extension String {
    var sanitized: String {
        // 移除潜在危险字符
        replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    var isValidPassword: Bool {
        // 至少 8 位，包含大小写字母和数字
        let pattern = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}

// ✅ 使用验证器
struct InputValidator {
    static func validateEmail(_ email: String) -> Result<String, ValidationError> {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(.emptyField("邮箱"))
        }
        guard trimmed.isValidEmail else {
            return .failure(.invalidFormat("邮箱"))
        }
        return .success(trimmed)
    }
}
```

---

## 13. Git 提交规范

### 13.1 提交信息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 13.2 Type 类型

| Type | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(camera): 添加条形码扫描功能` |
| `fix` | Bug 修复 | `fix(home): 修复卡路里计算错误` |
| `docs` | 文档更新 | `docs: 更新 README 安装说明` |
| `style` | 代码格式（不影响逻辑） | `style: 统一缩进为 4 空格` |
| `refactor` | 重构（不新增功能或修复 bug） | `refactor(api): 重构网络层为 actor 模式` |
| `perf` | 性能优化 | `perf(list): 使用 LazyVStack 优化滚动性能` |
| `test` | 测试相关 | `test(auth): 添加登录流程单元测试` |
| `chore` | 构建/工具变动 | `chore: 更新 Xcode 到 16.0` |

### 13.3 提交示例

```
feat(analysis): 添加食物营养分析功能

- 集成 AI 图像识别 API
- 支持识别多种食物并估算营养成分
- 添加分析结果展示页面
- 支持保存分析结果到本地数据库

Closes #123
```

```
fix(tabbar): 修复底部导航栏重叠问题

系统 TabBar 未完全隐藏导致与自定义 TabBar 重叠。
通过在 init 中设置 UITabBar.appearance().isHidden = true 解决。

Fixes #456
```

### 13.4 分支命名

| 类型 | 格式 | 示例 |
|------|------|------|
| 功能分支 | `feature/<功能名>` | `feature/food-analysis` |
| 修复分支 | `fix/<问题描述>` | `fix/tabbar-overlap` |
| 发布分支 | `release/<版本号>` | `release/1.2.0` |
| 热修复 | `hotfix/<问题描述>` | `hotfix/crash-on-launch` |

---

## 14. 代码审查清单

### 14.1 提交前自检

#### 命名与格式
- [ ] 类名使用 PascalCase
- [ ] 方法/变量使用 camelCase
- [ ] 布尔属性使用 is/has/should 前缀
- [ ] 缩进统一为 4 空格
- [ ] 无多余空行（最多一个）
- [ ] 行长度不超过 120 字符

#### 架构与设计
- [ ] ViewModel 标注 `@MainActor` + `@Observable`
- [ ] 服务类使用 `actor` 确保线程安全
- [ ] 模块依赖方向正确（Features → Core）
- [ ] 无循环依赖

#### SwiftUI
- [ ] 修饰符按规范顺序排列
- [ ] 复杂视图提取为计算属性
- [ ] 使用 `LazyVStack`/`LazyVGrid` 处理大量数据
- [ ] `ForEach` 使用正确的 ID

#### 数据与网络
- [ ] SwiftData 模型使用 `@Model final class`
- [ ] API 错误有完整处理
- [ ] 敏感数据使用 Keychain 存储

#### 安全
- [ ] 无硬编码密钥/密码
- [ ] 用户输入已验证
- [ ] 网络请求使用 HTTPS

#### 性能
- [ ] 图片已压缩
- [ ] 大数据列表使用分页
- [ ] 无内存泄漏（检查闭包引用）

### 14.2 审查者检查项

- [ ] 代码符合本规范
- [ ] 逻辑正确，无明显 bug
- [ ] 有适当的错误处理
- [ ] 有必要的注释和文档
- [ ] 测试覆盖关键路径
- [ ] 无安全漏洞
- [ ] 性能影响可接受

---

## 附录

### A. 快捷键（Xcode）

| 功能 | 快捷键 |
|------|--------|
| 格式化代码 | `Ctrl + I` |
| 添加文档注释 | `Cmd + Option + /` |
| 跳转到定义 | `Cmd + Click` |
| 查找引用 | `Cmd + Shift + F` |
| 重命名 | `Cmd + Ctrl + E` |
| 折叠代码 | `Cmd + Option + ←` |

### B. 推荐工具

- **SwiftLint**: 代码风格检查
- **SwiftFormat**: 代码格式化
- **Instruments**: 性能分析
- **Charles/Proxyman**: 网络调试

### C. 参考资源

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

---

> **最后更新**: 2026-02-09
> **维护者**: FoodMoment iOS Team
> **版本**: 1.0.0
