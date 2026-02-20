import SwiftUI
import SwiftData
import os

// MARK: - Scroll Offset Tracking

private struct DiaryScrollOffsetKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct DiaryView: View {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "DiaryView")

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var viewModel = DiaryViewModel()
    @State private var isShowingSearchBar = false
    @State private var scrollOffset: CGFloat = 0

    // MARK: - Constants

    /// WeekDatePicker 展开态完整高度
    private let calendarExpandedHeight: CGFloat = 120
    /// 开始折叠的滚动阈值
    private let collapseStartOffset: CGFloat = -10
    /// 完全折叠的滚动阈值
    private let collapseEndOffset: CGFloat = -80

    // MARK: - Computed

    /// 0 = 完全折叠, 1 = 完全展开
    private var calendarProgress: CGFloat {
        if scrollOffset >= collapseStartOffset {
            return 1
        }
        if scrollOffset <= collapseEndOffset {
            return 0
        }
        return (scrollOffset - collapseEndOffset) / (collapseStartOffset - collapseEndOffset)
    }

    private var calendarHeight: CGFloat {
        calendarExpandedHeight * calendarProgress
    }

    private var progressValue: CGFloat {
        guard viewModel.dailyCalorieGoal > 0 else { return 0 }
        return min(CGFloat(viewModel.dailyCalories) / CGFloat(viewModel.dailyCalorieGoal), 1)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            mainContent
                .premiumBackground()
                .navigationBarHidden(true)
                .navigationDestination(item: $viewModel.selectedMeal) { meal in
                    MealDetailView(meal: meal)
                }
        }
        .searchable(
            text: $viewModel.searchText,
            isPresented: $isShowingSearchBar,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "搜索食物、标签..."
        )
        .onChange(of: viewModel.selectedDate) { _, _ in
            scrollOffset = 0
            viewModel.loadMeals(modelContext: modelContext)
            Task {
                await viewModel.refreshFromAPI(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel.selectedMeal) { _, newValue in
            appState.isTabBarHidden = (newValue != nil)
        }
        .onAppear {
            viewModel.loadMeals(modelContext: modelContext)
        }
        .task {
            await viewModel.refreshFromAPI(modelContext: modelContext)
        }
        .accessibilityIdentifier("DiaryView")
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection

            ScrollView {
                VStack(spacing: 0) {
                    // Scroll offset tracking anchor
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: DiaryScrollOffsetKey.self,
                            value: proxy.frame(in: .named("diaryScroll")).minY
                        )
                    }
                    .frame(height: 0)

                    contentSection
                }
            }
            .coordinateSpace(name: "diaryScroll")
            .scrollIndicators(.hidden)
            .onPreferenceChange(DiaryScrollOffsetKey.self) { value in
                scrollOffset = value
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.top, 6)

            summaryBar
                .padding(.top, 2)
                .padding(.bottom, 8)

            WeekDatePicker(
                selectedDate: $viewModel.selectedDate,
                weekDates: viewModel.weekDates,
                dateHasMeals: { date in
                    viewModel.dateHasMealsFromCache(date)
                },
                onPreviousWeek: {
                    viewModel.previousWeek()
                },
                onNextWeek: {
                    viewModel.nextWeek()
                }
            )
            .padding(.top, 2)
            .padding(.bottom, 6)
            .frame(height: calendarHeight)
            .clipped()
            .opacity(calendarProgress)
            .animation(AppTheme.Animation.fastSpring, value: calendarProgress)

            // 底部渐变分隔线
            LinearGradient(
                colors: [
                    AppTheme.Colors.primary.opacity(0.2),
                    AppTheme.Colors.primary.opacity(0.05),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
        .background(.ultraThinMaterial)
        .accessibilityIdentifier("DiaryView.Header")
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.filteredMeals.isEmpty {
            emptyView
        } else {
            mealListContent
        }
    }

    // MARK: - Formatters

    private static let calorieFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()

    private func formattedCalories(_ value: Int) -> String {
        Self.calorieFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // 月份标题
            Text(viewModel.monthTitle)
                .font(.Jakarta.bold(24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .accessibilityIdentifier("DiaryView.MonthTitle")

            Spacer()

            // 操作按钮
            HStack(spacing: 16) {
                searchButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var summaryBar: some View {
        VStack(spacing: 8) {
            summaryInfoRow
            summaryProgressBar
        }
        .padding(.horizontal, 20)
        .accessibilityIdentifier("DiaryView.SummaryBar")
    }

    private var summaryInfoRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(viewModel.selectedDate.formatted(as: "M月d日"))
                .font(.Jakarta.medium(13))
                .foregroundColor(.secondary)

            Spacer()

            Text("今日已摄入")
                .font(.Jakarta.regular(12))
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formattedCalories(viewModel.dailyCalories))
                    .font(.Jakarta.bold(16))
                    .foregroundColor(.primary)

                Text("/ \(formattedCalories(viewModel.dailyCalorieGoal)) kcal")
                    .font(.Jakarta.medium(12))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var summaryProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progressValue, height: 6)
                    .shadow(color: AppTheme.Colors.primary.opacity(0.35), radius: 6, y: 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progressValue)
            }
        }
        .frame(height: 6)
        .accessibilityIdentifier("DiaryView.SummaryProgressBar")
    }

    private var searchButton: some View {
        Button {
            isShowingSearchBar.toggle()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.Jakarta.medium(16))
                .foregroundColor(.secondary)
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
        .accessibilityIdentifier("DiaryView.SearchButton")
        .accessibilityLabel("搜索")
    }

    // MARK: - Meal List Content

    private var mealListContent: some View {
        let meals = viewModel.filteredMeals
        let count = meals.count

        return VStack(spacing: 0) {
            ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                TimelineEntry(
                    meal: meal,
                    isFirst: index == 0,
                    isLast: index == count - 1,
                    onDelete: {
                        Task {
                            withAnimation {
                                // 先做乐观 UI 更新
                            }
                            await viewModel.deleteMeal(meal, modelContext: modelContext)
                        }
                    }
                )
                .onTapGesture {
                    viewModel.selectedMeal = meal
                }
                .padding(.bottom, index == count - 1 ? AppTheme.Layout.tabBarClearance + 32 : 8)
            }
        }
        .padding(.top, 16)
        .accessibilityIdentifier("DiaryView.MealList")
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack {
            Spacer()

            EmptyStateView(
                icon: "camera.fill",
                title: viewModel.searchText.isEmpty ? "还没有记录" : "未找到结果",
                subtitle: viewModel.searchText.isEmpty
                    ? "拍张食物照片，AI 会自动识别营养成分"
                    : "换个关键词试试吧",
                buttonTitle: viewModel.searchText.isEmpty ? "拍照记录" : nil,
                action: viewModel.searchText.isEmpty ? {
                    // 导航到相机 - 由父级 Tab 处理
                } : nil
            )

            Spacer()
        }
        .accessibilityIdentifier("DiaryView.EmptyState")
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
                .frame(height: 200)

            ProgressView()
                .tint(AppTheme.Colors.primary)

            Spacer()
                .frame(height: 200)
        }
        .accessibilityIdentifier("DiaryView.LoadingView")
    }
}

// MARK: - Preview

#Preview {
    DiaryView()
        .modelContainer(for: [MealRecord.self, UserProfile.self], inMemory: true)
}
