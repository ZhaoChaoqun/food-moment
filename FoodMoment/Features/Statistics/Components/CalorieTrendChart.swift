import SwiftUI
import Charts

struct CalorieTrendChart: View {

    // MARK: - Properties

    let data: [DailyCalorie]
    @Binding var selectedDataPoint: DailyCalorie?

    // MARK: - State

    @State private var plotWidth: CGFloat = 0

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            chartSection
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.2), value: selectedDataPoint?.id)
        .accessibilityIdentifier("CalorieTrendChart")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Calorie Trend")
                    .font(.Jakarta.semiBold(18))
                    .foregroundStyle(.primary)

                Text("Daily intake overview")
                    .font(.Jakarta.regular(13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let selected = selectedDataPoint {
                selectedDataPointView(selected)
            }
        }
    }

    // MARK: - Selected Data Point View

    private func selectedDataPointView(_ selected: DailyCalorie) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(selected.calories) kcal")
                .font(.Jakarta.bold(16))
                .foregroundStyle(AppTheme.Colors.primary)

            Text(selected.date, format: .dateTime.month(.abbreviated).day())
                .font(.Jakarta.regular(12))
                .foregroundStyle(.secondary)
        }
        .transition(.opacity.combined(with: .scale))
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
        .chartOverlay { proxy in
            chartOverlayContent(proxy: proxy)
        }
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
        .foregroundStyle(
            isSelected(item) ? AppTheme.Colors.primary : AppTheme.Colors.primary.opacity(0.6)
        )
        .symbolSize(isSelected(item) ? 80 : 30)
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

    // MARK: - Chart Overlay

    private func chartOverlayContent(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleChartInteraction(
                                at: value.location,
                                proxy: proxy,
                                geometry: geometry
                            )
                        }
                )
                .onTapGesture { location in
                    handleChartInteraction(
                        at: location,
                        proxy: proxy,
                        geometry: geometry
                    )
                }
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

    // MARK: - Helper Methods

    private func isSelected(_ item: DailyCalorie) -> Bool {
        selectedDataPoint?.id == item.id
    }

    private func handleChartInteraction(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        let plotFrame = geometry[proxy.plotFrame!]
        let xPosition = location.x - plotFrame.origin.x

        guard xPosition >= 0, xPosition <= plotFrame.width else { return }
        guard let date: Date = proxy.value(atX: xPosition) else { return }

        let calendar = Calendar.current
        if let closest = data.min(by: {
            abs(calendar.dateComponents([.hour], from: $0.date, to: date).hour ?? 999) <
            abs(calendar.dateComponents([.hour], from: $1.date, to: date).hour ?? 999)
        }) {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDataPoint = closest
            }
        }
    }
}
