import SwiftUI
import SwiftData
import os

struct WeightInputSheet: View {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "WeightInputSheet")

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var weightValue: Double = 65.0
    @State private var isSaving = false
    @State private var isShowingSuccess = false
    @State private var recentWeights: [WeightLog] = []

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
        GeometryReader { geometry in
            let data = chartData
            let width = geometry.size.width
            let height = geometry.size.height

            if data.count >= 2,
               let minW = data.map(\.weight).min(),
               let maxW = data.map(\.weight).max() {
                let range = max(maxW - minW, 0.5)
                let padding: CGFloat = 16

                ZStack {
                    gridLines(width: width, height: height, padding: padding)
                    trendLine(data: data, width: width, height: height, padding: padding, minW: minW, range: range)
                    dataPoints(data: data, width: width, height: height, padding: padding, minW: minW, range: range)
                    dateLabels(data: data, width: width, height: height)
                }
            } else {
                noDataPlaceholder
            }
        }
        .frame(height: 140)
        .padding(.horizontal, 4)
    }

    private func gridLines(width: CGFloat, height: CGFloat, padding: CGFloat) -> some View {
        Path { path in
            for i in 0...3 {
                let y = padding + (height - 2 * padding) * CGFloat(i) / 3.0
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
        }
        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
    }

    private func trendLine(
        data: [ChartEntry],
        width: CGFloat,
        height: CGFloat,
        padding: CGFloat,
        minW: Double,
        range: Double
    ) -> some View {
        Path { path in
            for (index, entry) in data.enumerated() {
                let x = width * CGFloat(index) / CGFloat(data.count - 1)
                let normalizedY = (entry.weight - minW) / range
                let y = (height - 2 * padding) * (1 - CGFloat(normalizedY)) + padding

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(
            AppTheme.Colors.primary,
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }

    private func dataPoints(
        data: [ChartEntry],
        width: CGFloat,
        height: CGFloat,
        padding: CGFloat,
        minW: Double,
        range: Double
    ) -> some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, entry in
            let x = width * CGFloat(index) / CGFloat(data.count - 1)
            let normalizedY = (entry.weight - minW) / range
            let y = (height - 2 * padding) * (1 - CGFloat(normalizedY)) + padding

            Circle()
                .fill(AppTheme.Colors.primary)
                .frame(width: 8, height: 8)
                .position(x: x, y: y)
        }
    }

    private func dateLabels(data: [ChartEntry], width: CGFloat, height: CGFloat) -> some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, entry in
            let x = width * CGFloat(index) / CGFloat(data.count - 1)

            Text(entry.dateLabel)
                .font(.Jakarta.regular(10))
                .foregroundStyle(.secondary)
                .position(x: x, y: height - 2)
        }
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
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else if isShowingSuccess {
                    Image(systemName: "checkmark")
                        .font(.Jakarta.bold(18))
                } else {
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
        .disabled(isSaving)
        .accessibilityIdentifier("RecordWeightButton")
    }

    // MARK: - Chart Data

    private struct ChartEntry {
        let date: Date
        let weight: Double
        let dateLabel: String
    }

    private var chartData: [ChartEntry] {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "zh_CN")

        return recentWeights.reversed().map { log in
            ChartEntry(
                date: log.recordedAt,
                weight: log.weightKg,
                dateLabel: formatter.string(from: log.recordedAt)
            )
        }
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        // 加载最近 7 天体重记录
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let predicate = #Predicate<WeightLog> { log in
            log.recordedAt >= sevenDaysAgo
        }
        let descriptor = FetchDescriptor<WeightLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )

        do {
            recentWeights = try modelContext.fetch(descriptor)
        } catch {
            Self.logger.error("[Weight] Failed to load weight logs: \(error.localizedDescription, privacy: .public)")
        }

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
        isSaving = true

        let now = Date()

        // 写入 SwiftData
        let weightLog = WeightLog(weightKg: weightValue, recordedAt: now)
        modelContext.insert(weightLog)

        // 写入 HealthKit
        do {
            try await HealthKitManager.shared.saveWeight(
                kilograms: weightValue,
                date: now
            )
        } catch {
            Self.logger.error("[Weight] HealthKit save failed: \(error.localizedDescription, privacy: .public)")
        }

        isSaving = false
        isShowingSuccess = true

        try? await Task.sleep(for: .milliseconds(600))
        dismiss()
    }
}

#Preview {
    WeightInputSheet()
        .modelContainer(for: [WeightLog.self], inMemory: true)
}
