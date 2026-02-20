import SwiftUI
import Charts

struct StatisticsView: View {

    // MARK: - State

    @State private var viewModel = StatisticsViewModel()
    @State private var isShowingDatePicker = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    timeRangeSelectorSection
                    checkinGridSection
                    if viewModel.selectedRange != .day {
                        calorieTrendSection
                    }
                    macroDonutSection
                    aiInsightSection
                    tabBarSpacerSection
                }
                .padding(.top, 8)
            }
            .premiumBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $isShowingDatePicker) {
                DatePickerSheet(selectedDate: $viewModel.selectedDate) {
                    isShowingDatePicker = false
                    Task { await viewModel.loadStatistics() }
                }
                .presentationDetents([.medium])
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.selectedRange)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedDataPoint?.id)
            .accessibilityIdentifier("StatisticsView")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("统计")
                .font(.Jakarta.extraBold(32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("概览与趋势")
                .font(.Jakarta.regular(15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .accessibilityIdentifier("StatisticsView.Header")
    }

    // MARK: - Time Range Selector Section

    private var timeRangeSelectorSection: some View {
        TimeRangeSelector(viewModel: viewModel)
            .padding(.horizontal, 20)
            .accessibilityIdentifier("StatisticsView.TimeRangeSelector")
    }

    // MARK: - Calorie Trend Section

    private var calorieTrendSection: some View {
        VStack(spacing: 16) {
            weeklyAverageCard
            CalorieTrendChart(
                data: viewModel.calorieData,
                selectedDataPoint: $viewModel.selectedDataPoint
            )
        }
        .accessibilityIdentifier("StatisticsView.CalorieTrend")
    }

    // MARK: - Weekly Average Card

    private var weeklyAverageCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.averageLabelCN)
                    .font(.Jakarta.medium(13))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedAverage)
                        .font(.Jakarta.bold(28))
                        .foregroundStyle(.primary)

                    Text("kcal")
                        .font(.Jakarta.medium(14))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(viewModel.weeklyChangeText)
                .font(.Jakarta.semiBold(14))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(viewModel.isPositiveChange
                            ? AppTheme.Colors.primary
                            : Color(hex: "#F87171")
                        )
                )
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, 20)
        .accessibilityIdentifier("StatisticsView.WeeklyAverageCard")
    }

    // MARK: - Macro Donut Section

    private var macroDonutSection: some View {
        MacroDonutChart(
            proteinTotal: viewModel.proteinTotal,
            carbsTotal: viewModel.carbsTotal,
            fatTotal: viewModel.fatTotal
        )
        .accessibilityIdentifier("StatisticsView.MacroDonut")
    }

    // MARK: - Checkin Grid Section

    private var checkinGridSection: some View {
        CheckinGrid(
            checkinDays: viewModel.checkinDays,
            isCheckedIn: viewModel.isCheckedIn
        )
        .accessibilityIdentifier("StatisticsView.CheckinGrid")
    }

    // MARK: - AI Insight Section

    private var aiInsightSection: some View {
        AIInsightDarkCard(insight: viewModel.aiInsight)
            .accessibilityIdentifier("StatisticsView.AIInsight")
    }

    // MARK: - Tab Bar Spacer Section

    private var tabBarSpacerSection: some View {
        Spacer()
            .frame(height: AppTheme.Layout.tabBarClearance)
    }

    // MARK: - Toolbar Content

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isShowingDatePicker = true
            } label: {
                Image(systemName: "calendar")
                    .font(.Jakarta.medium(16))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.7))
                            .background(Circle().fill(.ultraThinMaterial))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            }
            .accessibilityIdentifier("StatisticsView.Toolbar.CalendarButton")
        }
    }

    // MARK: - Helper Properties

    private var formattedAverage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: viewModel.weeklyAverage)) ?? "\(viewModel.weeklyAverage)"
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {

    // MARK: - Properties

    @Binding var selectedDate: Date
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            titleSection
            datePickerSection
            doneButtonSection
        }
        .padding(20)
        .accessibilityIdentifier("DatePickerSheet")
    }

    // MARK: - Title Section

    private var titleSection: some View {
        Text("选择日期")
            .font(.Jakarta.semiBold(18))
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        DatePicker(
            "Date",
            selection: $selectedDate,
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .labelsHidden()
    }

    // MARK: - Done Button Section

    private var doneButtonSection: some View {
        Button {
            onDismiss()
        } label: {
            Text("完成")
                .font(.Jakarta.semiBold(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.primary)
                )
        }
        .padding(.horizontal, 20)
        .accessibilityIdentifier("DatePickerSheet.DoneButton")
    }
}
