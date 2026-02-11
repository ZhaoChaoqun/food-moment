import SwiftUI
import SwiftData
import WidgetKit
import CoreSpotlight
import os

@main
struct FoodMomentApp: App {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "FoodMomentApp")

    // MARK: - State

    @State private var appState = AppState()

    // MARK: - Environment

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Properties

    /// 检查是否处于 UI 测试模式
    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    /// 检查是否使用模拟数据
    private static var isUsingMockData: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-data")
    }

    /// 检查是否使用模拟相机
    private static var isUsingMockCamera: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-camera")
    }

    /// 检查是否需要重置状态
    private static var shouldResetState: Bool {
        ProcessInfo.processInfo.arguments.contains("--reset-state")
    }

    // MARK: - Initialization

    init() {
        if Self.isUITesting {
            _appState = State(initialValue: AppState.forUITesting())
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    handleSpotlightActivity(activity)
                }
                .task {
                    await setupApp()
                }
        }
        .modelContainer(for: [
            UserProfile.self,
            MealRecord.self,
            DetectedFood.self,
            WeightLog.self,
            WaterLog.self,
            Achievement.self
        ])
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
}

// MARK: - App Setup

extension FoodMomentApp {

    @MainActor
    private func setupApp() async {
        // UI 测试模式下跳过大部分初始化
        if Self.isUITesting {
            Self.logger.debug("Running in UI testing mode")
            appState.isAuthenticated = true
            appState.isUITesting = true
            return
        }

        // 1. 注册通知分类
        NotificationManager.shared.registerNotificationCategories()

        // 2. 请求通知权限并设置默认提醒
        do {
            let isGranted = try await NotificationManager.shared.requestAuthorization()
            if isGranted {
                await NotificationManager.shared.setupDefaultReminders()
            }
        } catch {
            Self.logger.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
        }

        // 3. 请求 HealthKit 权限
        do {
            try await HealthKitManager.shared.requestAuthorization()
        } catch {
            Self.logger.error("HealthKit authorization failed: \(error.localizedDescription, privacy: .public)")
        }

        // 4. 启动网络监控和同步
        SyncManager.shared.startMonitoring()
        CloudSyncManager.shared.startNetworkMonitoring()

        // 5. 检查 iCloud 状态
        CloudSyncManager.shared.checkiCloudStatus()

        // 6. 监听通知 Deep Link
        NotificationCenter.default.addObserver(
            forName: .notificationDeepLinkReceived,
            object: nil,
            queue: .main
        ) { notification in
            if let url = notification.userInfo?["url"] as? URL {
                handleDeepLink(url)
            }
        }
    }
}

// MARK: - Scene Phase Handling

extension FoodMomentApp {

    @MainActor
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            NotificationManager.shared.clearBadge()
            refreshWidgetData()

        case .background:
            WidgetCenter.shared.reloadAllTimelines()

        case .inactive:
            break

        @unknown default:
            break
        }
    }
}

// MARK: - Deep Link Handling

extension FoodMomentApp {

    @MainActor
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == SharedDataManager.urlScheme else { return }

        let action = url.host ?? ""
        Self.logger.debug("Handling deep link: \(action, privacy: .public)")

        switch action {
        case "camera":
            appState.selectedTab = .camera
            appState.shouldOpenCamera = true

        case "log-breakfast":
            appState.selectedTab = .camera
            appState.pendingMealType = .breakfast
            appState.shouldOpenCamera = true

        case "log-lunch":
            appState.selectedTab = .camera
            appState.pendingMealType = .lunch
            appState.shouldOpenCamera = true

        case "log-dinner":
            appState.selectedTab = .camera
            appState.pendingMealType = .dinner
            appState.shouldOpenCamera = true

        case "log-water":
            appState.selectedTab = .home
            appState.shouldShowWaterSheet = true

        case "stats":
            appState.selectedTab = .statistics

        case "diary":
            appState.selectedTab = .diary

        case "checkin":
            appState.selectedTab = .profile

        default:
            break
        }
    }
}

// MARK: - Spotlight Handling

extension FoodMomentApp {

    @MainActor
    private func handleSpotlightActivity(_ activity: NSUserActivity) {
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return
        }

        Self.logger.debug("Spotlight activity: \(identifier, privacy: .public)")

        if let mealID = SpotlightIndexer.parseMealId(from: identifier) {
            appState.selectedTab = .diary
            appState.highlightedMealID = mealID
        }
    }
}

// MARK: - Widget Data

extension FoodMomentApp {

    @MainActor
    private func refreshWidgetData() {
        let widgetData = SharedDataManager.WidgetData(
            caloriesConsumed: appState.todayCalories,
            caloriesGoal: appState.calorieGoal,
            proteinGrams: appState.todayProtein,
            proteinGoal: appState.proteinGoal,
            carbsGrams: appState.todayCarbs,
            carbsGoal: appState.carbsGoal,
            fatGrams: appState.todayFat,
            fatGoal: appState.fatGoal,
            waterML: appState.todayWater,
            waterGoal: appState.waterGoal,
            mealCount: appState.todayMealCount,
            lastUpdated: Date()
        )

        SharedDataManager.shared.saveWidgetData(widgetData)
    }
}
