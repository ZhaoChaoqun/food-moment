import SwiftUI
import SwiftData
import os

struct DiaryView: View {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "DiaryView")

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var viewModel = DiaryViewModel()
    @State private var isShowingSearch = false
    @State private var isCalendarExpanded = false
    @FocusState private var isSearchFieldFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            mainContent
                .premiumBackground()
                .navigationBarHidden(true)
                .navigationDestination(item: $viewModel.selectedMeal) { meal in
                    MealDetailView(meal: meal, onDelete: {
                        Task {
                            await viewModel.deleteMeal(meal, modelContext: modelContext)
                        }
                        viewModel.selectedMeal = nil
                    })
                }
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            Task {
                await viewModel.refreshFromAPI(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel.selectedMeal) { _, newValue in
            appState.isTabBarHidden = (newValue != nil)
        }
        .onChange(of: isShowingSearch) { _, newValue in
            if !newValue {
                viewModel.searchText = ""
                isSearchFieldFocused = false
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFieldFocused = true
                }
            }
        }
        .task {
            await viewModel.refreshFromAPI(modelContext: modelContext)
        }
        .accessibilityIdentifier("DiaryView")
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                if isShowingSearch {
                    SearchResultsView(
                        searchText: viewModel.searchText,
                        onSelectMeal: { meal in
                            viewModel.selectedMeal = meal
                        }
                    )
                } else {
                    DiaryContentView(
                        startOfDay: viewModel.selectedDate.startOfDay,
                        endOfDay: viewModel.selectedDate.endOfDay,
                        selectedDate: viewModel.selectedDate,
                        searchText: viewModel.searchText,
                        isRefreshing: viewModel.isRefreshing,
                        onSelectMeal: { meal in
                            viewModel.selectedMeal = meal
                        },
                        onDeleteMeal: { meal in
                            viewModel.softDeleteMeal(meal, modelContext: modelContext)
                        }
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top) {
            if isShowingSearch {
                searchBarSection
            } else {
                fixedHeader
            }
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.undoToastMessage {
                UndoToast(message: message) {
                    viewModel.undoDelete(modelContext: modelContext)
                }
                .padding(.bottom, AppTheme.Layout.tabBarClearance + 8)
            }
        }
        .animation(AppTheme.Animation.fastSpring, value: viewModel.undoToastMessage)
    }

    // MARK: - Fixed Header

    private var fixedHeader: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.top, 6)

            DiarySummaryBar(
                startOfDay: viewModel.selectedDate.startOfDay,
                endOfDay: viewModel.selectedDate.endOfDay,
                selectedDate: viewModel.selectedDate,
                isCalendarExpanded: isCalendarExpanded,
                onToggleCalendar: {
                    withAnimation(AppTheme.Animation.defaultSpring) {
                        isCalendarExpanded.toggle()
                    }
                }
            )
            .padding(.top, 2)
            .padding(.bottom, 8)

            // WeekDatePicker — 展开/收起
            if isCalendarExpanded {
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
                .transition(.move(edge: .top).combined(with: .opacity))
            }

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

    private var searchButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isShowingSearch = true
            }
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

    // MARK: - Search Bar Section

    private var searchBarSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                TextField("搜索食物、标签、AI 分析...", text: $viewModel.searchText)
                    .font(.Jakarta.regular(15))
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .focused($isSearchFieldFocused)
                    .accessibilityIdentifier("DiaryView.SearchField")

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )

            Button("取消") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.searchText = ""
                    isShowingSearch = false
                }
            }
            .font(.Jakarta.medium(15))
            .foregroundStyle(AppTheme.Colors.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Summary Bar (uses @Query)

/// 独立子视图：使用 @Query 自动驱动摘要栏数据
private struct DiarySummaryBar: View {
    @Query private var meals: [MealRecord]
    @Query private var profiles: [UserProfile]

    let selectedDate: Date
    let isCalendarExpanded: Bool
    let onToggleCalendar: () -> Void

    init(startOfDay: Date, endOfDay: Date, selectedDate: Date, isCalendarExpanded: Bool, onToggleCalendar: @escaping () -> Void) {
        self.selectedDate = selectedDate
        self.isCalendarExpanded = isCalendarExpanded
        self.onToggleCalendar = onToggleCalendar
        _meals = Query(
            filter: #Predicate<MealRecord> { meal in
                meal.mealTime >= startOfDay && meal.mealTime <= endOfDay
                && meal.pendingDeletion == false
            },
            sort: \.mealTime
        )
        _profiles = Query()
    }

    private var dailyCalories: Int {
        meals.reduce(0) { $0 + $1.totalCalories }
    }

    private var dailyCalorieGoal: Int {
        profiles.first?.dailyCalorieGoal ?? 2000
    }

    private var progressValue: CGFloat {
        guard dailyCalorieGoal > 0 else { return 0 }
        return min(CGFloat(dailyCalories) / CGFloat(dailyCalorieGoal), 1)
    }

    private static let calorieFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()

    private func formattedCalories(_ value: Int) -> String {
        Self.calorieFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    var body: some View {
        VStack(spacing: 8) {
            // Info row
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                // 可点击的日期 + 展开/收起指示器
                Button(action: onToggleCalendar) {
                    HStack(spacing: 6) {
                        Text(selectedDate.formatted(as: "M月d日"))
                            .font(.Jakarta.medium(13))
                            .foregroundColor(.secondary)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isCalendarExpanded ? 180 : 0))
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text("今日已摄入")
                    .font(.Jakarta.regular(12))
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedCalories(dailyCalories))
                        .font(.Jakarta.bold(16))
                        .foregroundColor(.primary)

                    Text("/ \(formattedCalories(dailyCalorieGoal)) kcal")
                        .font(.Jakarta.medium(12))
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#34C759"), Color(hex: "#30B350")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressValue, height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progressValue)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
        .accessibilityIdentifier("DiaryView.SummaryBar")
    }
}

// MARK: - Content View (uses @Query)

/// 独立子视图：使用 @Query 自动驱动餐食列表数据
private struct DiaryContentView: View {
    @Query private var meals: [MealRecord]
    @Environment(AppState.self) private var appState

    let searchText: String
    let isRefreshing: Bool
    let onSelectMeal: (MealRecord) -> Void
    let onDeleteMeal: (MealRecord) -> Void

    init(
        startOfDay: Date,
        endOfDay: Date,
        selectedDate: Date,
        searchText: String,
        isRefreshing: Bool,
        onSelectMeal: @escaping (MealRecord) -> Void,
        onDeleteMeal: @escaping (MealRecord) -> Void
    ) {
        self.searchText = searchText
        self.isRefreshing = isRefreshing
        self.onSelectMeal = onSelectMeal
        self.onDeleteMeal = onDeleteMeal
        _meals = Query(
            filter: #Predicate<MealRecord> { meal in
                meal.mealTime >= startOfDay && meal.mealTime <= endOfDay
                && meal.pendingDeletion == false
            },
            sort: \.mealTime
        )
    }

    private var filteredMeals: [MealRecord] {
        guard !searchText.isEmpty else { return meals }
        return meals.filter { meal in
            meal.title.localizedCaseInsensitiveContains(searchText)
                || (meal.descriptionText?.localizedCaseInsensitiveContains(searchText) ?? false)
                || meal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        if isRefreshing && filteredMeals.isEmpty {
            VStack {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                    .tint(.secondary)
                Spacer()
                Spacer()
            }
            .frame(minHeight: 300)
        } else if filteredMeals.isEmpty {
            emptyView
        } else {
            mealListContent
        }
    }

    // MARK: - Meal List Content

    private var mealListContent: some View {
        let meals = filteredMeals
        let count = meals.count

        return VStack(spacing: 0) {
            ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                TimelineEntry(
                    meal: meal,
                    isFirst: index == 0,
                    isLast: index == count - 1,
                    onDelete: {
                        onDeleteMeal(meal)
                    }
                )
                .onTapGesture {
                    onSelectMeal(meal)
                }
                .padding(.bottom, index == count - 1 ? AppTheme.Layout.tabBarClearance + 8 : 8)
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
                title: searchText.isEmpty ? "还没有记录" : "未找到结果",
                subtitle: searchText.isEmpty
                    ? "拍张食物照片，AI 会自动识别营养成分"
                    : "换个关键词试试吧",
                buttonTitle: searchText.isEmpty ? "拍照记录" : nil,
                action: searchText.isEmpty ? {
                    appState.activeFullScreen = .camera
                } : nil
            )

            Spacer()
            Spacer()
        }
        .frame(minHeight: UIScreen.main.bounds.height * 0.55)
        .accessibilityIdentifier("DiaryView.EmptyState")
    }
}

// MARK: - Search Results View (uses @Query)

/// 全局搜索结果视图：查询所有餐食记录，在内存中过滤后按日期分组展示
private struct SearchResultsView: View {
    @Query(
        filter: #Predicate<MealRecord> { meal in
            meal.pendingDeletion == false
        },
        sort: \MealRecord.mealTime,
        order: .reverse
    ) private var allMeals: [MealRecord]

    let searchText: String
    let onSelectMeal: (MealRecord) -> Void

    private var groupedResults: [(date: Date, meals: [MealRecord])] {
        guard !searchText.isEmpty else { return [] }

        let filtered = allMeals.filter { meal in
            meal.title.localizedCaseInsensitiveContains(searchText)
                || (meal.descriptionText?.localizedCaseInsensitiveContains(searchText) ?? false)
                || meal.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
                || (meal.aiAnalysis?.localizedCaseInsensitiveContains(searchText) ?? false)
                || meal.detectedFoods.contains {
                    $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.nameZh.localizedCaseInsensitiveContains(searchText)
                }
        }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filtered) { meal in
            calendar.startOfDay(for: meal.mealTime)
        }

        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, meals: $0.value) }
    }

    private var totalResultCount: Int {
        groupedResults.reduce(0) { $0 + $1.meals.count }
    }

    var body: some View {
        if groupedResults.isEmpty {
            emptySearchView
        } else {
            searchResultsList
        }
    }

    private var searchResultsList: some View {
        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
            HStack {
                Text("找到 \(totalResultCount) 条结果")
                    .font(.Jakarta.medium(13))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            ForEach(groupedResults, id: \.date) { group in
                Section {
                    ForEach(group.meals) { meal in
                        SearchResultRow(meal: meal)
                            .onTapGesture { onSelectMeal(meal) }
                    }
                } header: {
                    searchSectionHeader(for: group.date, count: group.meals.count)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, AppTheme.Layout.tabBarClearance)
    }

    private func searchSectionHeader(for date: Date, count: Int) -> some View {
        HStack {
            Text(date.formatted(as: "M月d日 EEEE"))
                .font(.Jakarta.semiBold(13))
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(count)条记录")
                .font(.Jakarta.regular(12))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var emptySearchView: some View {
        VStack {
            Spacer()

            EmptyStateView(
                icon: "magnifyingglass",
                title: "未找到结果",
                subtitle: "换个关键词试试吧",
                buttonTitle: nil,
                action: nil
            )

            Spacer()
            Spacer()
        }
        .frame(minHeight: UIScreen.main.bounds.height * 0.55)
        .accessibilityIdentifier("SearchResultsView.EmptyState")
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let meal: MealRecord

    var body: some View {
        HStack(spacing: 12) {
            mealThumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.title)
                    .font(.Jakarta.semiBold(15))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(MealRecord.MealType(rawValue: meal.mealType)?.displayName ?? meal.mealType)
                        .font(.Jakarta.medium(11))
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.quaternary)

                    Text("\(meal.totalCalories) kcal")
                        .font(.Jakarta.medium(11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(meal.mealTime.formatted(as: "HH:mm"))
                .font(.Jakarta.regular(12))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var mealThumbnail: some View {
        if let imageData = meal.localImageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if let urlString = meal.imageURL, let url = APIEndpoint.resolveMediaURL(urlString) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    defaultThumbnail
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            defaultThumbnail
        }
    }

    private var defaultThumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray6))
            .frame(width: 44, height: 44)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: 16))
                    .foregroundStyle(.quaternary)
            }
    }
}

// MARK: - Preview

#Preview {
    DiaryView()
        .modelContainer(for: [MealRecord.self, UserProfile.self], inMemory: true)
}
