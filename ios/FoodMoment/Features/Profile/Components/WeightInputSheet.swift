import SwiftUI
import SwiftData
import Charts
import os

struct WeightInputSheet: View {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "WeightInputSheet")

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Types

    private enum SaveState {
        case idle, saving, success
    }

    // MARK: - State

    @State private var weightValue: Double = 65.0
    @State private var saveState: SaveState = .idle
    @Query(sort: \WeightLog.recordedAt, order: .reverse) private var allWeights: [WeightLog]

    private var recentWeights: [WeightLog] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return allWeights.filter { $0.recordedAt >= sevenDaysAgo }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                weightDisplay
                weightSlider

                if !recentWeights.isEmpty {
                    trendChart
                }

                Spacer()

                recordButton
            }
            .padding(24)
            .navigationTitle("记录体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    cancelButton
                }
            }
            .task {
                await loadInitialData()
            }
            .accessibilityIdentifier("WeightInputSheet")
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Cancel Button

    private var cancelButton: some View {
        Button("取消") {
            dismiss()
        }
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("CancelButton")
    }

    // MARK: - Weight Display

    private var weightDisplay: some View {
        VStack(spacing: 8) {
            weightIcon
            weightValueText
            weightComparisonText
        }
    }

    private var weightIcon: some View {
        Image(systemName: "scalemass.fill")
            .font(.Jakarta.regular(40))
            .foregroundStyle(AppTheme.Colors.primary)
            .padding(.bottom, 8)
    }

    private var weightValueText: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(String(format: "%.1f", weightValue))
                .font(.Jakarta.extraBold(56))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Text("kg")
                .font(.Jakarta.medium(20))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var weightComparisonText: some View {
        if let lastWeight = recentWeights.first {
            let diff = weightValue - lastWeight.weightKg
            let diffSign = diff >= 0 ? "+" : ""
            HStack(spacing: 4) {
                Image(systemName: diff >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.Jakarta.semiBold(12))
                Text("\(diffSign)\(String(format: "%.1f", diff)) kg")
                    .font(.Jakarta.medium(14))
            }
            .foregroundStyle(diff > 0 ? .orange : AppTheme.Colors.primary)
        }
    }

    // MARK: - Weight Slider

    private var weightSlider: some View {
        VStack(spacing: 12) {
            Slider(
                value: $weightValue,
                in: 30...200,
                step: 0.1
            ) {
                Text("体重")
            } minimumValueLabel: {
                Text("30")
                    .font(.Jakarta.regular(12))
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("200")
                    .font(.Jakarta.regular(12))
                    .foregroundStyle(.secondary)
            }
            .tint(AppTheme.Colors.primary)

            quickAdjustButtons
        }
    }

    private var quickAdjustButtons: some View {
        HStack(spacing: 16) {
            adjustButton(delta: -1.0, label: "-1.0")
            adjustButton(delta: -0.1, label: "-0.1")
            adjustButton(delta: +0.1, label: "+0.1")
            adjustButton(delta: +1.0, label: "+1.0")
        }
    }

    private func adjustButton(delta: Double, label: String) -> some View {
        Button {
            withAnimation(AppTheme.Animation.defaultSpring) {
                weightValue = max(30, min(200, weightValue + delta))
            }
        } label: {
            Text(label)
                .font(.Jakarta.semiBold(14))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
        }
        .foregroundStyle(.primary)
        .accessibilityIdentifier("AdjustButton_\(label)")
    }

    // MARK: - Trend Chart

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近 7 天趋势")
                .font(.Jakarta.semiBold(16))
                .foregroundStyle(.primary)

            trendChartContent
        }
        .padding(16)
        .glassCard(cornerRadius: AppTheme.CornerRadius.small)
    }

    private var trendChartContent: some View {
        Group {
            let data = chartData
            if data.count >= 2 {
                Chart(data, id: \.date) { entry in
                    LineMark(
                        x: .value("日期", entry.date),
                        y: .value("体重", entry.weight)
                    )
                    .foregroundStyle(AppTheme.Colors.primary)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日期", entry.date),
                        y: .value("体重", entry.weight)
                    )
                    .foregroundStyle(AppTheme.Colors.primary)
                    .symbolSize(30)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(as: "M/d"))
                                    .font(.Jakarta.regular(10))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(.separator).opacity(0.3))
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text(String(format: "%.1f", weight))
                                    .font(.Jakarta.regular(10))
                            }
                        }
                    }
                }
            } else {
                noDataPlaceholder
            }
        }
        .frame(height: 140)
        .padding(.horizontal, 4)
    }

    private var noDataPlaceholder: some View {
        Text("数据不足，暂无趋势图")
            .font(.Jakarta.regular(14))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button {
            Task {
                await saveWeight()
            }
        } label: {
            HStack(spacing: 8) {
                switch saveState {
                case .saving:
                    ProgressView()
                        .tint(.white)
                case .success:
                    Image(systemName: "checkmark")
                        .font(.Jakarta.bold(18))
                case .idle:
                    Image(systemName: "scalemass.fill")
                    Text("记录")
                        .font(.Jakarta.bold(18))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primary)
            )
            .foregroundStyle(.white)
        }
        .disabled(saveState != .idle)
        .accessibilityIdentifier("RecordWeightButton")
    }

    // MARK: - Chart Data

    private struct ChartEntry {
        let date: Date
        let weight: Double
        let dateLabel: String
    }

    private var chartData: [ChartEntry] {
        recentWeights.reversed().map { log in
            ChartEntry(
                date: log.recordedAt,
                weight: log.weightKg,
                dateLabel: log.recordedAt.formatted(as: "M/d")
            )
        }
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        // 从 HealthKit 获取最新体重作为默认值
        do {
            if let latestWeight = try await HealthKitManager.shared.fetchLatestWeight() {
                weightValue = latestWeight
            } else if let lastLog = recentWeights.first {
                weightValue = lastLog.weightKg
            }
        } catch {
            if let lastLog = recentWeights.first {
                weightValue = lastLog.weightKg
            }
        }
    }

    // MARK: - Save Weight

    private func saveWeight() async {
        saveState = .saving

        let now = Date()

        // 写入 SwiftData（离线优先，isSynced 默认 false）
        let weightLog = WeightLog(weightKg: weightValue, recordedAt: now)
        modelContext.insert(weightLog)
        try? modelContext.save()

        // 尝试同步到后端
        do {
            let _ = try await UserService.shared.logWeight(
                WeightLogCreateDTO(weightKg: weightValue, recordedAt: now)
            )
            weightLog.isSynced = true
            try? modelContext.save()
        } catch {
            // API 失败，保留未同步记录，SyncManager 会重试
            Self.logger.warning("[Weight] API sync failed, will retry: \(error.localizedDescription, privacy: .public)")
        }

        // 写入 HealthKit
        do {
            try await HealthKitManager.shared.saveWeight(
                kilograms: weightValue,
                date: now
            )
        } catch {
            Self.logger.error("[Weight] HealthKit save failed: \(error.localizedDescription, privacy: .public)")
        }

        saveState = .success

        try? await Task.sleep(for: .milliseconds(600))
        dismiss()
    }
}

#Preview {
    WeightInputSheet()
        .modelContainer(for: [WeightLog.self], inMemory: true)
}
