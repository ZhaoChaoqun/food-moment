import SwiftUI

struct WeightCard: View {

    // MARK: - Properties

    let currentWeight: Double
    let targetWeight: Double
    let trend: String
    var onTap: (() -> Void)? = nil

    // MARK: - Computed Properties

    private var progress: Double {
        guard targetWeight > 0, currentWeight > targetWeight else { return 1.0 }
        let startWeight = currentWeight + 5.0
        let totalToLose = startWeight - targetWeight
        let lost = startWeight - currentWeight
        return min(max(lost / totalToLose, 0), 1.0)
    }

    private var isDownTrend: Bool {
        trend.contains("\u{2193}")
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow
            weightDisplay
            targetDisplay
            progressBar
        }
        .padding(16)
        .glassCard()
        .onTapGesture {
            onTap?()
        }
        .accessibilityIdentifier("WeightCard")
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            Image(systemName: "scalemass.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.Colors.primary)

            Text("Weight Tracking")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            trendBadge
        }
    }

    // MARK: - Trend Badge

    private var trendBadge: some View {
        Text(trend)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isDownTrend ? AppTheme.Colors.primary : Color(hex: "#F87171"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        isDownTrend
                            ? AppTheme.Colors.primary.opacity(0.15)
                            : Color(hex: "#F87171").opacity(0.15)
                    )
            )
    }

    // MARK: - Weight Display

    private var weightDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(String(format: "%.1f", currentWeight))
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("kg")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Target Display

    private var targetDisplay: some View {
        Text(String(format: "Goal: %.1f kg", targetWeight))
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)

            progressLabels
        }
    }

    private var progressLabels: some View {
        HStack {
            Text(String(format: "%.1f kg", currentWeight))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Text(String(format: "%.1f kg", targetWeight))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
