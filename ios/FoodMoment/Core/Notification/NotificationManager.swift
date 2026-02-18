import Foundation
import UserNotifications
import os

@MainActor
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private nonisolated static let logger = Logger(subsystem: "com.foodmoment", category: "NotificationManager")

    private let center = UNUserNotificationCenter.current()

    /// 通知设置状态
    var isAuthorized = false

    /// 用餐提醒开关
    var mealRemindersEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "mealRemindersEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "mealRemindersEnabled") }
    }

    /// 打卡提醒开关
    var checkinReminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "checkinReminderEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "checkinReminderEnabled") }
    }

    /// 饮水提醒开关
    var waterReminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "waterReminderEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "waterReminderEnabled") }
    }

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Authorization

    /// 请求通知权限
    func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
        isAuthorized = granted
        return granted
    }

    /// 检查权限状态
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
        return settings.authorizationStatus
    }

    // MARK: - Setup All Reminders

    /// 设置所有默认提醒
    func setupDefaultReminders() async {
        let status = await checkAuthorizationStatus()

        guard status == .authorized || status == .provisional else {
            Self.logger.warning("[Notification] Not authorized for notifications")
            return
        }

        // 用餐提醒
        if mealRemindersEnabled {
            scheduleMealReminders()
        }

        // 打卡提醒
        if checkinReminderEnabled {
            scheduleCheckinReminder()
        }

        // 饮水提醒
        if waterReminderEnabled {
            scheduleWaterReminders()
        }
    }

    // MARK: - Meal Reminders

    /// 设置用餐提醒（默认：早餐 8:00，午餐 12:00，晚餐 18:00）
    func scheduleMealReminders(
        breakfast: Date? = nil,
        lunch: Date? = nil,
        dinner: Date? = nil
    ) {
        // 先移除已有的用餐提醒
        cancelMealReminders()

        let calendar = Calendar.current

        // 早餐提醒 - 8:00
        let breakfastComponents: DateComponents
        if let breakfast {
            breakfastComponents = calendar.dateComponents([.hour, .minute], from: breakfast)
        } else {
            breakfastComponents = DateComponents(hour: 8, minute: 0)
        }
        scheduleDaily(
            identifier: "meal.breakfast",
            title: "早餐时间到",
            body: "美好的一天从早餐开始，记得拍照记录哦",
            dateComponents: breakfastComponents,
            categoryIdentifier: "MEAL_REMINDER",
            userInfo: ["mealType": "breakfast", "action": "log-breakfast"]
        )

        // 午餐提醒 - 12:00
        let lunchComponents: DateComponents
        if let lunch {
            lunchComponents = calendar.dateComponents([.hour, .minute], from: lunch)
        } else {
            lunchComponents = DateComponents(hour: 12, minute: 0)
        }
        scheduleDaily(
            identifier: "meal.lunch",
            title: "午餐时间到",
            body: "中午好！该享用午餐了，记得拍照记录",
            dateComponents: lunchComponents,
            categoryIdentifier: "MEAL_REMINDER",
            userInfo: ["mealType": "lunch", "action": "log-lunch"]
        )

        // 晚餐提醒 - 18:00
        let dinnerComponents: DateComponents
        if let dinner {
            dinnerComponents = calendar.dateComponents([.hour, .minute], from: dinner)
        } else {
            dinnerComponents = DateComponents(hour: 18, minute: 0)
        }
        scheduleDaily(
            identifier: "meal.dinner",
            title: "晚餐时间到",
            body: "结束忙碌的一天，享受健康晚餐吧",
            dateComponents: dinnerComponents,
            categoryIdentifier: "MEAL_REMINDER",
            userInfo: ["mealType": "dinner", "action": "log-dinner"]
        )

        mealRemindersEnabled = true
        Self.logger.debug("[Notification] Meal reminders scheduled")
    }

    // MARK: - Checkin Reminder

    /// 设置打卡提醒（默认 21:00）
    func scheduleCheckinReminder(at hour: Int = 21) {
        // 移除已有的打卡提醒
        center.removePendingNotificationRequests(withIdentifiers: ["checkin.daily"])

        let dateComponents = DateComponents(hour: hour, minute: 0)
        scheduleDaily(
            identifier: "checkin.daily",
            title: "每日打卡",
            body: "今天记录了 \(todayMealCount()) 餐，来完成今日打卡吧",
            dateComponents: dateComponents,
            categoryIdentifier: "CHECKIN_REMINDER",
            userInfo: ["action": "checkin"]
        )

        checkinReminderEnabled = true
        Self.logger.debug("[Notification] Checkin reminder scheduled at \(hour, privacy: .public):00")
    }

    // MARK: - Water Reminders

    /// 设置饮水提醒（每 2 小时，9:00-21:00）
    func scheduleWaterReminders() {
        // 移除已有的饮水提醒
        cancelWaterReminders()

        let waterHours = [9, 11, 13, 15, 17, 19, 21]

        for hour in waterHours {
            let dateComponents = DateComponents(hour: hour, minute: 0)
            scheduleDaily(
                identifier: "water.\(hour)",
                title: "喝水时间",
                body: "别忘了补充水分，保持身体水分充足",
                dateComponents: dateComponents,
                categoryIdentifier: "WATER_REMINDER",
                userInfo: ["action": "log-water", "amount": 250]
            )
        }

        waterReminderEnabled = true
        Self.logger.debug("[Notification] Water reminders scheduled")
    }

    // MARK: - Cancel

    /// 取消所有提醒
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    /// 取消用餐提醒
    func cancelMealReminders() {
        let identifiers = ["meal.breakfast", "meal.lunch", "meal.dinner"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        mealRemindersEnabled = false
    }

    /// 取消饮水提醒
    func cancelWaterReminders() {
        let identifiers = [9, 11, 13, 15, 17, 19, 21].map { "water.\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        waterReminderEnabled = false
    }

    /// 取消打卡提醒
    func cancelCheckinReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["checkin.daily"])
        checkinReminderEnabled = false
    }

    // MARK: - Notification Categories

    /// 注册通知分类和操作按钮
    func registerNotificationCategories() {
        // 用餐提醒分类 - 带快捷操作
        let logAction = UNNotificationAction(
            identifier: "LOG_MEAL",
            title: "立即记录",
            options: [.foreground]
        )
        let skipAction = UNNotificationAction(
            identifier: "SKIP_MEAL",
            title: "跳过",
            options: [.destructive]
        )
        let mealCategory = UNNotificationCategory(
            identifier: "MEAL_REMINDER",
            actions: [logAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // 饮水提醒分类
        let logWaterAction = UNNotificationAction(
            identifier: "LOG_WATER",
            title: "记录 250mL",
            options: []
        )
        let waterCategory = UNNotificationCategory(
            identifier: "WATER_REMINDER",
            actions: [logWaterAction],
            intentIdentifiers: [],
            options: []
        )

        // 打卡提醒分类
        let checkinAction = UNNotificationAction(
            identifier: "CHECKIN",
            title: "去打卡",
            options: [.foreground]
        )
        let checkinCategory = UNNotificationCategory(
            identifier: "CHECKIN_REMINDER",
            actions: [checkinAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([mealCategory, waterCategory, checkinCategory])
    }

    // MARK: - Badge Management

    /// 更新应用角标
    func updateBadge(count: Int) {
        center.setBadgeCount(count)
    }

    /// 清除角标
    func clearBadge() {
        center.setBadgeCount(0)
    }

    // MARK: - Get Pending Notifications

    /// 获取所有待发送的通知
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    // MARK: - Private Helpers

    /// 安排每日重复通知
    private func scheduleDaily(
        identifier: String,
        title: String,
        body: String,
        dateComponents: DateComponents,
        categoryIdentifier: String? = nil,
        userInfo: [String: Any]? = nil
    ) {
        let logger = Self.logger
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }

        if let userInfo {
            content.userInfo = userInfo
        }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                logger.error("[Notification] Failed to schedule \(identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// 发送即时通知
    func sendImmediateNotification(
        title: String,
        body: String,
        identifier: String = UUID().uuidString
    ) {
        let logger = Self.logger
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // 立即发送
        )

        center.add(request) { error in
            if let error {
                logger.error("[Notification] Failed to send notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// 获取今日餐食记录数（用于打卡提醒文案）
    private func todayMealCount() -> Int {
        // 从 SharedDataManager 获取
        SharedDataManager.shared.loadWidgetData()?.mealCount ?? 0
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// 前台收到通知时的处理
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // 前台也显示通知
        [.banner, .sound, .badge]
    }

    /// 用户点击通知时的处理
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        switch actionIdentifier {
        case "LOG_MEAL":
            // 打开记录餐食页面
            if let action = userInfo["action"] as? String {
                await handleDeepLink(action: action)
            }

        case "LOG_WATER":
            // 快速记录饮水
            await quickLogWater()

        case "CHECKIN":
            // 打开打卡页面
            await handleDeepLink(action: "checkin")

        case UNNotificationDefaultActionIdentifier:
            // 用户点击了通知本身
            if let action = userInfo["action"] as? String {
                await handleDeepLink(action: action)
            }

        case UNNotificationDismissActionIdentifier:
            // 用户滑动取消了通知
            break

        default:
            break
        }
    }

    /// 处理 Deep Link
    private func handleDeepLink(action: String) async {
        let urlString = "foodmoment://\(action)"
        if let url = URL(string: urlString) {
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .notificationDeepLinkReceived,
                    object: nil,
                    userInfo: ["url": url]
                )
            }
        }
    }

    /// 快速记录饮水
    private func quickLogWater() async {
        do {
            try await HealthKitManager.shared.saveWaterIntake(
                milliliters: 250,
                date: Date()
            )
            await MainActor.run {
                NotificationManager.shared.sendImmediateNotification(
                    title: "饮水已记录",
                    body: "已记录 250mL 饮水"
                )
            }
        } catch {
            NotificationManager.logger.error("[Notification] Failed to log water: \(String(describing: error), privacy: .public)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let notificationDeepLinkReceived = Notification.Name("notificationDeepLinkReceived")
}
