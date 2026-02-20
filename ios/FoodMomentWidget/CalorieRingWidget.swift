import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct CalorieRingProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieRingEntry {
        CalorieRingEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieRingEntry) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData() ?? .placeholder
        let entry = CalorieRingEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieRingEntry>) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData() ?? .placeholder
        let currentDate = Date()
        let entry = CalorieRingEntry(date: currentDate, data: data)

        // 每 15 分钟刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct CalorieRingEntry: TimelineEntry {
    let date: Date
    let data: SharedDataManager.WidgetData
}

// MARK: - Widget Views

struct CalorieRingWidgetEntryView: View {
    var entry: CalorieRingProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallCalorieRingView(data: entry.data)
        case .systemMedium:
            MediumCalorieRingView(data: entry.data)
        default:
            SmallCalorieRingView(data: entry.data)
        }
    }
}

// MARK: - Small Widget (155x155)

struct SmallCalorieRingView: View {
    let data: SharedDataManager.WidgetData

    private let primaryColor = Color(hex: "#13EC5B")
    private let proteinColor = Color(hex: "#FF6B6B")
    private let carbsColor = Color(hex: "#4DA8FF")

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

            VStack(spacing: 8) {
                // 三环进度
                ZStack {
                    // 外环 - 卡路里
                    Circle()
                        .stroke(primaryColor.opacity(0.2), lineWidth: 10)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: data.caloriesProgress)
                        .stroke(
                            primaryColor,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    // 中环 - 蛋白质
                    Circle()
                        .stroke(proteinColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 58, height: 58)

                    Circle()
                        .trim(from: 0, to: data.proteinProgress)
                        .stroke(
                            proteinColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 58, height: 58)
                        .rotationEffect(.degrees(-90))

                    // 内环 - 碳水
                    Circle()
                        .stroke(carbsColor.opacity(0.2), lineWidth: 6)
                        .frame(width: 38, height: 38)

                    Circle()
                        .trim(from: 0, to: data.carbsProgress)
                        .stroke(
                            carbsColor,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 38, height: 38)
                        .rotationEffect(.degrees(-90))
                }

                // 剩余卡路里
                VStack(spacing: 2) {
                    Text("\(data.caloriesRemaining)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("剩余 kcal")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(12)
        }
        .widgetBackground()
    }
}

// MARK: - Medium Widget (329x155)

struct MediumCalorieRingView: View {
    let data: SharedDataManager.WidgetData

    private let primaryColor = Color(hex: "#13EC5B")
    private let proteinColor = Color(hex: "#FF6B6B")
    private let carbsColor = Color(hex: "#4DA8FF")
    private let fatColor = Color(hex: "#FFD43B")

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

            HStack(spacing: 20) {
                // 左侧 - 环形图
                ZStack {
                    // 外环 - 卡路里
                    Circle()
                        .stroke(primaryColor.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: data.caloriesProgress)
                        .stroke(
                            LinearGradient(
                                colors: [primaryColor, Color(hex: "#0A8F35")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    // 中心文字
                    VStack(spacing: 0) {
                        Text("\(data.caloriesConsumed)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("/ \(data.caloriesGoal)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // 右侧 - 营养素详情
                VStack(alignment: .leading, spacing: 10) {
                    // 剩余卡路里
                    HStack {
                        Text("剩余")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text("\(data.caloriesRemaining) kcal")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(primaryColor)
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // 营养素进度条
                    NutrientProgressRow(
                        label: "蛋白质",
                        current: data.proteinGrams,
                        goal: data.proteinGoal,
                        unit: "g",
                        color: proteinColor
                    )

                    NutrientProgressRow(
                        label: "碳水",
                        current: data.carbsGrams,
                        goal: data.carbsGoal,
                        unit: "g",
                        color: carbsColor
                    )

                    NutrientProgressRow(
                        label: "脂肪",
                        current: data.fatGrams,
                        goal: data.fatGoal,
                        unit: "g",
                        color: fatColor
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .widgetBackground()
    }
}

// MARK: - Nutrient Progress Row

struct NutrientProgressRow: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, current / goal)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 40, alignment: .leading)

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)

            Text("\(Int(current))\(unit)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 35, alignment: .trailing)
        }
    }
}

// MARK: - Widget Configuration

struct CalorieRingWidget: Widget {
    let kind: String = "CalorieRingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieRingProvider()) { entry in
            CalorieRingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("今日卡路里")
        .description("查看今日卡路里摄入进度和营养素分布")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Widget Background Modifier

extension View {
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            return containerBackground(for: .widget) {
                Color.clear
            }
        } else {
            return self
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    CalorieRingWidget()
} timeline: {
    CalorieRingEntry(date: .now, data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    CalorieRingWidget()
} timeline: {
    CalorieRingEntry(date: .now, data: .placeholder)
}
