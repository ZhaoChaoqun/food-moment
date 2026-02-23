import SwiftUI

struct WeightCard: View {

    // MARK: - Properties

    let currentWeight: Double
    let targetWeight: Double
    let trend: String
    /// 体重历史数据（按时间升序），用于 sparkline
    let weightHistory: [(date: Date, weight: Double)]
    /// 体重记录总数
    let recordCount: Int

    // MARK: - Computed Properties

    private var hasRecords: Bool {
        recordCount > 0
    }

    private var hasTrend: Bool {
        recordCount >= 2 && !trend.isEmpty
    }

    private var isDownTrend: Bool {
        trend.contains("▾")
    }

    private var hasTarget: Bool {
        targetWeight > 0
    }

    private var remainingWeight: Double {
        guard hasTarget, currentWeight > targetWeight else { return 0 }
        return currentWeight - targetWeight
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            if hasRecords {
                weightDisplay
                sparklineView
                goalLabel
            } else {
                emptyState
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassCard()
        .accessibilityIdentifier("WeightCard")
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            Image(systemName: "scalemass.fill")
                .font(.Jakarta.regular(14))
                .foregroundStyle(AppTheme.Colors.primary)

            Text("体重")
                .font(.Jakarta.semiBold(17))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(.primary)

            Spacer(minLength: 4)

            trendBadge
        }
    }

    // MARK: - Trend Badge

    @ViewBuilder
    private var trendBadge: some View {
        if hasTrend {
            Text("较上次 \(trend)")
                .font(.Jakarta.semiBold(11))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(isDownTrend ? AppTheme.Colors.primary : Color(hex: "#F87171"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(
                            isDownTrend
                                ? AppTheme.Colors.primary.opacity(0.15)
                                : Color(hex: "#F87171").opacity(0.15)
                        )
                )
        } else if hasRecords {
            Text("首次记录")
                .font(.Jakarta.semiBold(11))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                )
        }
    }

    // MARK: - Weight Display

    private var weightDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(String(format: "%.1f", currentWeight))
                .font(.Jakarta.bold(28))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Text("kg")
                .font(.Jakarta.regular(13))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Sparkline

    @ViewBuilder
    private var sparklineView: some View {
        if weightHistory.count >= 2 {
            MiniSparkline(data: weightHistory.map { $0.weight })
                .frame(height: 32)
        } else {
            // 只有 1 个数据点：显示单点标记
            singlePointLine
                .frame(height: 32)
        }
    }

    private var singlePointLine: some View {
        GeometryReader { geometry in
            ZStack {
                // 虚线基准线
                Path { path in
                    let y = geometry.size.height / 2
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .foregroundStyle(Color.gray.opacity(0.2))

                // 单点
                Circle()
                    .fill(AppTheme.Colors.primary)
                    .frame(width: 6, height: 6)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }

    // MARK: - Goal Label

    @ViewBuilder
    private var goalLabel: some View {
        if hasTarget && remainingWeight > 0 {
            Text("目标 \(String(format: "%.1f", targetWeight)) kg · 还差 \(String(format: "%.1f", remainingWeight))")
                .font(.Jakarta.regular(11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        } else if hasTarget && currentWeight <= targetWeight {
            Text("已达成目标 \(String(format: "%.1f", targetWeight)) kg")
                .font(.Jakarta.regular(11))
                .foregroundStyle(AppTheme.Colors.primary)
                .lineLimit(1)
        } else {
            Text("点击记录体重")
                .font(.Jakarta.regular(11))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(AppTheme.Colors.primary.opacity(0.5))

            Text("点击记录第一笔体重")
                .font(.Jakarta.regular(13))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mini Sparkline

private struct MiniSparkline: View {

    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            let points = calculatePoints(in: geometry.size)
            ZStack {
                // 渐变填充区域
                gradientFill(points: points, size: geometry.size)
                // 线条
                sparklinePath(points: points)
                // 最后一个点高亮
                if let last = points.last {
                    Circle()
                        .fill(AppTheme.Colors.primary)
                        .frame(width: 5, height: 5)
                        .position(last)
                }
            }
        }
    }

    private func calculatePoints(in size: CGSize) -> [CGPoint] {
        guard data.count >= 2 else { return [] }
        let minVal = (data.min() ?? 0) - 0.5
        let maxVal = (data.max() ?? 0) + 0.5
        let range = maxVal - minVal
        guard range > 0 else {
            // 所有值相同，画一条水平线
            return data.enumerated().map { index, _ in
                let x = size.width * CGFloat(index) / CGFloat(data.count - 1)
                return CGPoint(x: x, y: size.height / 2)
            }
        }

        return data.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(data.count - 1)
            let y = size.height * (1 - CGFloat((value - minVal) / range))
            return CGPoint(x: x, y: y)
        }
    }

    private func sparklinePath(points: [CGPoint]) -> some View {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(
            AppTheme.Colors.primary,
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
        )
    }

    private func gradientFill(points: [CGPoint], size: CGSize) -> some View {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: first.x, y: size.height))
            path.addLine(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            if let last = points.last {
                path.addLine(to: CGPoint(x: last.x, y: size.height))
            }
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    AppTheme.Colors.primary.opacity(0.15),
                    AppTheme.Colors.primary.opacity(0.02)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
