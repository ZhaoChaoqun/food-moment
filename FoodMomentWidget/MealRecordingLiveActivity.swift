@preconcurrency import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Attributes

@available(iOS 16.1, *)
struct MealRecordingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// 当前阶段：analyzing / saving / completed
        var phase: String
        /// 进度百分比 (0.0 - 1.0)
        var progress: Double
        /// 检测到的食物名称
        var foodName: String
        /// 预估卡路里
        var estimatedCalories: Int
        /// 开始时间
        var startTime: Date
    }

    /// 餐次类型
    var mealType: String
    /// 餐次名称
    var mealTypeName: String
}

// MARK: - Live Activity Widget

@available(iOS 16.1, *)
struct MealRecordingLiveActivity: Widget {
    let kind: String = "MealRecordingLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MealRecordingAttributes.self) { context in
            // 锁屏/横幅视图
            LockScreenMealRecordingView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开状态 - Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(hex: "#13EC5B"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.mealTypeName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

                            Text(phaseText(context.state.phase))
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }

                // 展开状态 - Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.estimatedCalories)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#13EC5B"))

                        Text("kcal")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                // 展开状态 - Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // 食物名称
                        Text(context.state.foodName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)

                        // 进度条
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: "#13EC5B"))
                                    .frame(width: geometry.size.width * context.state.progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.horizontal, 4)
                }

                // 展开状态 - Center
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                // 紧凑模式 - 左侧
                Image(systemName: "fork.knife")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "#13EC5B"))
            } compactTrailing: {
                // 紧凑模式 - 右侧
                Text("\(context.state.estimatedCalories)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#13EC5B"))
            } minimal: {
                // 最小模式
                Image(systemName: "fork.knife")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#13EC5B"))
            }
        }
    }

    private func phaseText(_ phase: String) -> String {
        switch phase {
        case "analyzing":
            return "AI 分析中..."
        case "saving":
            return "保存中..."
        case "completed":
            return "记录完成"
        default:
            return "处理中..."
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.1, *)
struct LockScreenMealRecordingView: View {
    let context: ActivityViewContext<MealRecordingAttributes>

    private let primaryColor = Color(hex: "#13EC5B")

    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(primaryColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: phaseIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(primaryColor)
            }

            // 中间内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(context.attributes.mealTypeName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text(phaseText)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Text(context.state.foodName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.8))

                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(primaryColor)
                            .frame(width: geometry.size.width * context.state.progress, height: 4)
                    }
                }
                .frame(height: 4)
            }

            Spacer()

            // 右侧卡路里
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(context.state.estimatedCalories)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryColor)

                Text("kcal")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .activityBackgroundTint(Color(.systemBackground))
    }

    private var phaseIcon: String {
        switch context.state.phase {
        case "analyzing":
            return "sparkles"
        case "saving":
            return "arrow.up.circle"
        case "completed":
            return "checkmark.circle.fill"
        default:
            return "fork.knife"
        }
    }

    private var phaseText: String {
        switch context.state.phase {
        case "analyzing":
            return "AI 分析中"
        case "saving":
            return "保存中"
        case "completed":
            return "完成"
        default:
            return "处理中"
        }
    }
}

// MARK: - Live Activity Manager

@available(iOS 16.1, *)
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<MealRecordingAttributes>?

    private init() {}

    /// 开始记录餐食的 Live Activity
    func startMealRecording(
        mealType: String,
        mealTypeName: String,
        foodName: String = "识别中..."
    ) async {
        // 确保设备支持 Live Activity
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivityManager] Live Activities not enabled")
            return
        }

        // 结束之前的活动
        await endCurrentActivity()

        let attributes = MealRecordingAttributes(
            mealType: mealType,
            mealTypeName: mealTypeName
        )

        let initialState = MealRecordingAttributes.ContentState(
            phase: "analyzing",
            progress: 0.1,
            foodName: foodName,
            estimatedCalories: 0,
            startTime: Date()
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("[LiveActivityManager] Started meal recording activity: \(activity.id)")
        } catch {
            print("[LiveActivityManager] Failed to start activity: \(error.localizedDescription)")
        }
    }

    /// 更新分析进度
    func updateProgress(
        phase: String,
        progress: Double,
        foodName: String,
        estimatedCalories: Int
    ) async {
        guard let activity = currentActivity else { return }

        let newState = MealRecordingAttributes.ContentState(
            phase: phase,
            progress: progress,
            foodName: foodName,
            estimatedCalories: estimatedCalories,
            startTime: activity.content.state.startTime
        )

        await activity.update(
            ActivityContent(state: newState, staleDate: nil)
        )
    }

    /// 完成记录
    func completeRecording(
        foodName: String,
        finalCalories: Int
    ) async {
        guard let activity = currentActivity else { return }

        let finalState = MealRecordingAttributes.ContentState(
            phase: "completed",
            progress: 1.0,
            foodName: foodName,
            estimatedCalories: finalCalories,
            startTime: activity.content.state.startTime
        )

        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .after(.now + 5)
        )

        currentActivity = nil
    }

    /// 取消当前活动
    func endCurrentActivity() async {
        guard let activity = currentActivity else { return }

        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
    }
}
