import SwiftUI

/// 全局应用状态管理
@Observable
final class AppState {

    // MARK: - Properties

    /// 用户认证状态
    var isAuthenticated: Bool = false

    /// 当前登录用户
    var currentUser: UserProfile?

    /// 当前选中的 Tab
    var selectedTab: TabItem = .home

    // MARK: - Deep Link States

    /// 是否需要打开相机
    var shouldOpenCamera: Bool = false

    /// 是否需要显示喝水记录 Sheet
    var shouldShowWaterSheet: Bool = false

    /// 待处理的餐次类型
    var pendingMealType: MealRecord.MealType?

    /// 高亮显示的餐食 ID
    var highlightedMealID: UUID?

    // MARK: - Sync States

    /// 是否正在同步
    var isSyncing: Bool = false

    /// 同步错误信息
    var syncError: String?

    // MARK: - UI Testing Support

    /// 是否处于 UI 测试模式
    var isUITesting: Bool = false

    // MARK: - Initialization

    init() {}

    // MARK: - Factory Methods

    /// 创建用于 UI 测试的 AppState
    static func forUITesting() -> AppState {
        let state = AppState()
        state.isAuthenticated = true
        state.isUITesting = true
        state.currentUser = nil
        return state
    }

    // MARK: - Public Methods

    /// 重置所有深链接相关状态
    func resetDeepLinkStates() {
        shouldOpenCamera = false
        shouldShowWaterSheet = false
        pendingMealType = nil
        highlightedMealID = nil
    }
}

// MARK: - TabItem

extension AppState {

    /// Tab 选项枚举
    enum TabItem: Int, CaseIterable {
        case home = 0
        case statistics = 1
        case camera = 2
        case diary = 3
        case profile = 4

        // MARK: - Computed Properties

        var title: String {
            switch self {
            case .home: return "Home"
            case .statistics: return "Stats"
            case .camera: return "Scan"
            case .diary: return "Log"
            case .profile: return "Profile"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .statistics: return "chart.bar.fill"
            case .camera: return "plus"
            case .diary: return "book.fill"
            case .profile: return "person.fill"
            }
        }

        var accessibilityID: String {
            "\(title)TabButton"
        }
    }
}

// MARK: - Widget Data

extension AppState {

    var todayCalories: Int { 0 }
    var calorieGoal: Int { 2000 }
    var todayProtein: Double { 0 }
    var proteinGoal: Double { 120 }
    var todayCarbs: Double { 0 }
    var carbsGoal: Double { 250 }
    var todayFat: Double { 0 }
    var fatGoal: Double { 65 }
    var todayWater: Int { 0 }
    var waterGoal: Int { 2000 }
    var todayMealCount: Int { 0 }
}
