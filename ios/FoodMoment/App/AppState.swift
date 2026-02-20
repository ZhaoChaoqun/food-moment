import SwiftUI
import UIKit

/// 全局应用状态管理
@MainActor
@Observable
final class AppState {

    // MARK: - Properties

    /// 用户认证状态
    var isAuthenticated: Bool = false

    /// 当前登录用户
    var currentUser: UserProfile?

    /// 当前选中的 Tab
    var selectedTab: TabItem = .home

    /// 是否隐藏底部 TabBar（详情页 push 时隐藏）
    var isTabBarHidden: Bool = false

    // MARK: - Full Screen Presentation

    /// 全屏呈现目标
    enum FullScreenDestination: Identifiable {
        case camera
        case analysis(UIImage)

        var id: String {
            switch self {
            case .camera: return "camera"
            case .analysis: return "analysis"
            }
        }
    }

    /// 当前活跃的全屏覆盖层
    var activeFullScreen: FullScreenDestination?

    /// 从相机过渡到分析页
    func showAnalysis(image: UIImage) {
        activeFullScreen = .analysis(image)
    }

    // MARK: - Deep Link States

    enum DeepLinkAction {
        case openCamera(mealType: MealRecord.MealType? = nil)
        case showWaterSheet
        case highlightMeal(UUID)
    }

    /// 待处理的深链接动作
    var pendingDeepLink: DeepLinkAction?

    // MARK: - Achievement Unlock States

    /// 成就解锁弹窗队列
    var achievementUnlockQueue: [AchievementItem] = []

    /// 当前正在显示的解锁成就
    var currentUnlockAchievement: AchievementItem?

    /// 显示队列中的下一个解锁成就弹窗
    func showNextUnlockAchievement() {
        guard !achievementUnlockQueue.isEmpty else {
            currentUnlockAchievement = nil
            return
        }
        currentUnlockAchievement = achievementUnlockQueue.removeFirst()
    }

    /// 关闭当前弹窗并尝试显示下一个
    func dismissCurrentUnlockAchievement() {
        currentUnlockAchievement = nil
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            showNextUnlockAchievement()
        }
    }

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
        pendingDeepLink = nil
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
            case .home: return "首页"
            case .statistics: return "统计"
            case .camera: return "扫描"
            case .diary: return "记录"
            case .profile: return "我的"
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
            switch self {
            case .home:
                return "HomeTabButton"
            case .statistics:
                return "StatsTabButton"
            case .camera:
                return "ScanTabButton"
            case .diary:
                return "DiaryTabButton"
            case .profile:
                return "ProfileTabButton"
            }
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
