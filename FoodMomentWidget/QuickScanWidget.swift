import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct QuickScanProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickScanEntry {
        QuickScanEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickScanEntry) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData() ?? .placeholder
        let entry = QuickScanEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickScanEntry>) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData() ?? .placeholder
        let currentDate = Date()
        let entry = QuickScanEntry(date: currentDate, data: data)

        // 每 15 分钟刷新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct QuickScanEntry: TimelineEntry {
    let date: Date
    let data: SharedDataManager.WidgetData
}

// MARK: - Widget View

struct QuickScanWidgetEntryView: View {
    var entry: QuickScanProvider.Entry
    @Environment(\.widgetFamily) var family

    private let primaryColor = Color(hex: "#13EC5B")

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(hex: "#102216"),
                    Color(hex: "#0A1610")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // 左侧 - 今日摘要
                VStack(alignment: .leading, spacing: 12) {
                    // 标题
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(primaryColor)

                        Text("今日进度")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // 卡路里进度
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(entry.data.caloriesConsumed)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("/ \(entry.data.caloriesGoal)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Text("kcal")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // 餐次统计
                    HStack(spacing: 4) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))

                        Text("已记录 \(entry.data.mealCount) 餐")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 右侧 - 快捷扫描按钮
                Link(destination: URL(string: "foodmoment://camera")!) {
                    VStack(spacing: 8) {
                        ZStack {
                            // 外层光晕
                            Circle()
                                .fill(primaryColor.opacity(0.15))
                                .frame(width: 80, height: 80)

                            // 中层圆环
                            Circle()
                                .stroke(primaryColor.opacity(0.3), lineWidth: 2)
                                .frame(width: 65, height: 65)

                            // 内层按钮
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [primaryColor, Color(hex: "#0A8F35")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 55, height: 55)
                                .shadow(color: primaryColor.opacity(0.4), radius: 8, y: 4)

                            // 相机图标
                            Image(systemName: "camera.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Text("Scan")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(primaryColor)
                    }
                }
            }
            .padding(16)
        }
        .widgetBackground()
    }
}

// MARK: - Widget Configuration

struct QuickScanWidget: Widget {
    let kind: String = "QuickScanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickScanProvider()) { entry in
            QuickScanWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("快捷扫描")
        .description("一键打开相机，快速记录餐食")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview

#Preview("Quick Scan", as: .systemMedium) {
    QuickScanWidget()
} timeline: {
    QuickScanEntry(date: .now, data: .placeholder)
}
