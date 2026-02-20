import SwiftUI
import SwiftData

struct HomeView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var viewModel = HomeViewModel()
    @State private var isShowingWaterSheet = false
    @State private var selectedMeal: MealRecord?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection

                    HomeDataContent(
                        startOfDay: Date().startOfDay,
                        endOfDay: Date().endOfDay,
                        stepCount: viewModel.stepCount,
                        caloriesBurned: viewModel.caloriesBurned,
                        dailyStepGoal: 10000,
                        onAddWater: {
                            Task {
                                await viewModel.addWater(
                                    modelContext: modelContext,
                                    writeToHealthKit: true
                                )
                            }
                        },
                        onShowWaterOptions: {
                            isShowingWaterSheet = true
                        },
                        onMoreMealsTapped: {
                            appState.selectedTab = .diary
                        },
                        onMealTapped: { meal in
                            selectedMeal = meal
                        }
                    )
                }
                .padding(.bottom, AppTheme.Layout.tabBarClearance)
            }
            .premiumBackground()
            .refreshable {
                await viewModel.refresh(modelContext: modelContext)
            }
            .task {
                await viewModel.refreshFromAPI(modelContext: modelContext)
            }
            .navigationBarHidden(true)
            .accessibilityIdentifier("HomeScrollView")
            .navigationDestination(item: $selectedMeal) { meal in
                MealDetailView(meal: meal)
            }
        }
        .sheet(isPresented: $isShowingWaterSheet) {
            WaterTrackingSheet { amount in
                Task {
                    await viewModel.addWater(
                        amount: amount,
                        modelContext: modelContext,
                        writeToHealthKit: true
                    )
                }
            }
        }
        .accessibilityIdentifier("HomeView")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.Jakarta.semiBold(12))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .accessibilityIdentifier("DateLabel")

                Text("\(viewModel.greeting),")
                    .font(.Jakarta.medium(20))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("GreetingText")

                Text(viewModel.userName)
                    .font(.Jakarta.bold(28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .accessibilityIdentifier("UserNameText")
            }

            Spacer()

            userAvatarView
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - User Avatar

    private var userAvatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            if let assetName = viewModel.userAvatarAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            } else {
                defaultAvatarView
            }

            proBadge
        }
        .accessibilityIdentifier("UserAvatar")
    }

    private var defaultAvatarView: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.primary.opacity(0.3),
                        AppTheme.Colors.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.Jakarta.regular(20))
                    .foregroundStyle(AppTheme.Colors.primary)
            )
    }

    private var proBadge: some View {
        Text("PRO")
            .font(.Jakarta.extraBold(10))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 4, y: 1)
            .offset(x: 2, y: 2)
    }

    // MARK: - Helper Methods

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }

    private func formattedNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Home Data Content (uses @Query)

/// 独立子视图：使用 @Query 自动驱动首页数据
private struct HomeDataContent: View {
    @Query private var todayMeals: [MealRecord]
    @Query private var todayWaterLogs: [WaterLog]
    @Query private var profiles: [UserProfile]

    let stepCount: Int
    let caloriesBurned: Int
    let dailyStepGoal: Int
    let onAddWater: () -> Void
    let onShowWaterOptions: () -> Void
    let onMoreMealsTapped: () -> Void
    let onMealTapped: (MealRecord) -> Void

    init(
        startOfDay: Date,
        endOfDay: Date,
        stepCount: Int,
        caloriesBurned: Int,
        dailyStepGoal: Int,
        onAddWater: @escaping () -> Void,
        onShowWaterOptions: @escaping () -> Void,
        onMoreMealsTapped: @escaping () -> Void,
        onMealTapped: @escaping (MealRecord) -> Void
    ) {
        self.stepCount = stepCount
        self.caloriesBurned = caloriesBurned
        self.dailyStepGoal = dailyStepGoal
        self.onAddWater = onAddWater
        self.onShowWaterOptions = onShowWaterOptions
        self.onMoreMealsTapped = onMoreMealsTapped
        self.onMealTapped = onMealTapped

        _todayMeals = Query(
            filter: #Predicate<MealRecord> { record in
                record.mealTime >= startOfDay && record.mealTime < endOfDay
            },
            sort: \.mealTime
        )
        _todayWaterLogs = Query(
            filter: #Predicate<WaterLog> { log in
                log.recordedAt >= startOfDay && log.recordedAt < endOfDay
            }
        )
        _profiles = Query()
    }

    // MARK: - Computed from @Query

    private var consumedCalories: Int {
        todayMeals.reduce(0) { $0 + $1.totalCalories }
    }

    private var proteinGrams: Double {
        todayMeals.reduce(0) { $0 + $1.proteinGrams }
    }

    private var carbsGrams: Double {
        todayMeals.reduce(0) { $0 + $1.carbsGrams }
    }

    private var fatGrams: Double {
        todayMeals.reduce(0) { $0 + $1.fatGrams }
    }

    private var waterAmount: Int {
        todayWaterLogs.reduce(0) { $0 + $1.amountML }
    }

    private var dailyCalorieGoal: Int {
        profiles.first?.dailyCalorieGoal ?? 2500
    }

    private var dailyProteinGoal: Int {
        profiles.first?.dailyProteinGoal ?? 50
    }

    private var dailyCarbsGoal: Int {
        profiles.first?.dailyCarbsGoal ?? 250
    }

    private var dailyFatGoal: Int {
        profiles.first?.dailyFatGoal ?? 65
    }

    private var dailyWaterGoal: Int { 2500 }

    private var caloriesLeft: Int {
        max(dailyCalorieGoal - consumedCalories, 0)
    }

    private var calorieProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0 }
        return min(Double(consumedCalories) / Double(dailyCalorieGoal), 1.0)
    }

    private var proteinProgress: Double {
        guard dailyProteinGoal > 0 else { return 0 }
        return min(proteinGrams / Double(dailyProteinGoal), 1.0)
    }

    private var carbsProgress: Double {
        guard dailyCarbsGoal > 0 else { return 0 }
        return min(carbsGrams / Double(dailyCarbsGoal), 1.0)
    }

    private var waterProgress: Double {
        guard dailyWaterGoal > 0 else { return 0 }
        return min(Double(waterAmount) / Double(dailyWaterGoal), 1.0)
    }

    private var stepProgress: Double {
        guard dailyStepGoal > 0 else { return 0 }
        return min(Double(stepCount) / Double(dailyStepGoal), 1.0)
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Body

    var body: some View {
        calorieRingCard
        healthMetricsGrid
        foodMomentSection
    }

    // MARK: - Calorie Ring Card

    private var calorieRingCard: some View {
        VStack(spacing: 16) {
            ZStack {
                CalorieRingChart(
                    calorieProgress: calorieProgress,
                    proteinProgress: proteinProgress,
                    carbsProgress: carbsProgress
                )
                .frame(width: 200, height: 200)
                .accessibilityIdentifier("CalorieRingChart")

                caloriesCenterContent
            }

            Text("每日目标: \(formattedNumber(dailyCalorieGoal))")
                .font(.Jakarta.medium(12))
                .foregroundStyle(.tertiary)

            MacroIndicatorRow(
                calories: consumedCalories,
                proteinGrams: proteinGrams,
                carbsGrams: carbsGrams
            )
            .accessibilityIdentifier("MacroIndicators")
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RadialGradient(
                    colors: [
                        AppTheme.Colors.primary.opacity(0.06),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 200
                )
            }
        )
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
        .padding(.horizontal, 20)
    }

    private var caloriesCenterContent: some View {
        VStack(spacing: 4) {
            Text(formattedNumber(caloriesLeft))
                .font(.Jakarta.extraBold(48))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .accessibilityIdentifier("CaloriesRemainingText")

            Text("剩余千卡")
                .font(.Jakarta.semiBold(11))
                .foregroundStyle(.secondary)
                .tracking(1.5)
        }
    }

    // MARK: - Health Metrics Grid

    private var healthMetricsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            WaterCard(
                waterAmount: waterAmount,
                dailyGoal: dailyWaterGoal,
                progress: waterProgress,
                onAddWater: onAddWater,
                onShowOptions: onShowWaterOptions
            )
            .accessibilityIdentifier("WaterCard")

            StepsCard(
                stepCount: stepCount,
                dailyGoal: dailyStepGoal,
                progress: stepProgress,
                caloriesBurned: caloriesBurned
            )
            .accessibilityIdentifier("StepsCard")
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Food Moment Section

    private var foodMomentSection: some View {
        FoodMomentCarousel(
            meals: Array(todayMeals),
            onMealTapped: onMealTapped,
            onMoreTapped: onMoreMealsTapped
        )
        .accessibilityIdentifier("FoodMomentCarousel")
    }

    // MARK: - Helpers

    private func formattedNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
