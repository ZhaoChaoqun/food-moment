import SwiftUI
import Charts

struct CalorieTrendChart: View {

    // MARK: - Properties

    let data: [DailyCalorie]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            if data.isEmpty {
                chartEmptyState
            } else {
                chartSection
                chartLegend
            }
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, 20)
        .accessibilityIdentifier("CalorieTrendChart")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("热量趋势")
                .font(.Jakarta.semiBold(18))
                .foregroundStyle(.primary)

            Text("每日摄入概览")
                .font(.Jakarta.regular(13))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Chart Empty State

    private var chartEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.Colors.primary.opacity(0.4))

            Text("暂无数据")
                .font(.Jakarta.semiBold(15))
                .foregroundStyle(.secondary)

            Text("记录餐食后，热量趋势将在这里展示")
                .font(.Jakarta.regular(13))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("CalorieTrendChart.EmptyState")
    }

    // MARK: - Chart Legend

    private var chartLegend: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.Colors.primary)
                .frame(width: 8, height: 8)

            Text("热量 (kcal)")
                .font(.Jakarta.regular(12))
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("CalorieTrendChart.Legend")
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        Chart(data) { item in
            areaMarkContent(for: item)
            lineMarkContent(for: item)
            pointMarkContent(for: item)
        }
        .chartYScale(domain: yAxisDomain)
        .chartXAxis { xAxisContent }
        .chartYAxis { yAxisContent }
        .frame(height: 200)
    }

    // MARK: - Chart Marks

    private func areaMarkContent(for item: DailyCalorie) -> some ChartContent {
        AreaMark(
            x: .value("Date", item.date, unit: .day),
            y: .value("Calories", item.calories)
        )
        .foregroundStyle(
            LinearGradient(
                colors: [
                    AppTheme.Colors.primary.opacity(0.3),
                    AppTheme.Colors.primary.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .interpolationMethod(.catmullRom)
    }

    private func lineMarkContent(for item: DailyCalorie) -> some ChartContent {
        LineMark(
            x: .value("Date", item.date, unit: .day),
            y: .value("Calories", item.calories)
        )
        .foregroundStyle(AppTheme.Colors.primary)
        .lineStyle(StrokeStyle(lineWidth: 2.5))
        .interpolationMethod(.catmullRom)
    }

    private func pointMarkContent(for item: DailyCalorie) -> some ChartContent {
        PointMark(
            x: .value("Date", item.date, unit: .day),
            y: .value("Calories", item.calories)
        )
        .foregroundStyle(AppTheme.Colors.primary.opacity(0.6))
        .symbolSize(30)
    }

    // MARK: - Axis Content

    @AxisContentBuilder
    private var xAxisContent: some AxisContent {
        AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(date, format: .dateTime.day())
                        .font(.Jakarta.regular(10))
                        .foregroundStyle(.secondary)
                }
            }
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                .foregroundStyle(.secondary.opacity(0.3))
        }
    }

    @AxisContentBuilder
    private var yAxisContent: some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisValueLabel {
                if let cal = value.as(Int.self) {
                    Text("\(cal)")
                        .font(.Jakarta.regular(10))
                        .foregroundStyle(.secondary)
                }
            }
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                .foregroundStyle(.secondary.opacity(0.3))
        }
    }

    // MARK: - Computed Properties

    private var yAxisDomain: ClosedRange<Int> {
        let minCal = (data.map(\.calories).min() ?? 1500) - 200
        let maxCal = (data.map(\.calories).max() ?? 2500) + 200
        return minCal...maxCal
    }

    private var xAxisStride: Int {
        let count = data.count
        if count <= 7 { return 1 }
        if count <= 14 { return 2 }
        if count <= 30 { return 5 }
        return 30
    }
}
