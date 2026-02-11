import SwiftUI
import SwiftData

struct DiaryView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel = DiaryViewModel()
    @State private var isShowingMonthPicker = false
    @State private var isShowingSearchBar = false
    @State private var isShowingCalendarPicker = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mainContent
                floatingProgressBar
            }
            .premiumBackground()
            .navigationBarHidden(true)
        }
        .searchable(
            text: $viewModel.searchText,
            isPresented: $isShowingSearchBar,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "搜索食物、标签..."
        )
        .onChange(of: viewModel.selectedDate) { _, _ in
            viewModel.loadMeals(modelContext: modelContext)
        }
        .onAppear {
            viewModel.loadMeals(modelContext: modelContext)
        }
        .accessibilityIdentifier("DiaryView")
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                contentSection
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.top, 8)

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
            .padding(.top, 4)
            .padding(.bottom, 8)

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

    // MARK: - Floating Progress Bar

    @ViewBuilder
    private var floatingProgressBar: some View {
        if !viewModel.meals.isEmpty {
            DailyProgressFloat(
                consumed: viewModel.dailyCalories,
                goal: viewModel.dailyCalorieGoal
            )
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityIdentifier("DiaryView.FloatingProgressBar")
        }
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
                calendarButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var searchButton: some View {
        Button {
            isShowingSearchBar.toggle()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
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

    private var calendarButton: some View {
        Button {
            isShowingCalendarPicker.toggle()
        } label: {
            Image(systemName: "calendar")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.Colors.primary)
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
        .accessibilityIdentifier("DiaryView.CalendarButton")
        .accessibilityLabel("日历")
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
                        withAnimation {
                            viewModel.deleteMeal(meal, modelContext: modelContext)
                        }
                    }
                )
                .padding(.bottom, index == count - 1 ? 120 : 8)
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
