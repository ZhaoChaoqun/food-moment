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
                        },
                        onCameraTapped: {
                            appState.activeFullScreen = .camera
                        }
                    )
                }
                .padding(.bottom, AppTheme.Layout.tabBarClearance)
            }
            .premiumBackground()
            .refreshable {
                await viewModel.refresh(modelContext: modelContext)
            }
            .overlay(alignment: .top) {
                if let error = viewModel.refreshError {
                    RefreshErrorToast(message: error)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            Task {
                                try? await Task.sleep(for: .seconds(3))
                                withAnimation {
                                    viewModel.refreshError = nil
                                }
                            }
                        }
                        .padding(.top, 8)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.refreshError != nil)
            .task {
                await viewModel.refreshFromAPI(modelContext: modelContext)
            }
            .navigationBarHidden(true)
            .accessibilityIdentifier("HomeScrollView")
            .navigationDestination(item: $selectedMeal) { meal in
                MealDetailView(meal: meal, onDelete: {
                    Task {
                        do {
                            try await MealService.shared.deleteMeal(id: meal.id.uuidString)
                            modelContext.delete(meal)
                            try? modelContext.save()
                            HapticManager.success()
                        } catch {
                            HapticManager.error()
                        }
                    }
                    selectedMeal = nil
                })
            }
        }
        .onChange(of: selectedMeal) { _, newValue in
            appState.isTabBarHidden = (newValue != nil)
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
                    .font(.Jakarta.semiBold(14))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .accessibilityIdentifier("DateLabel")

                Text("\(viewModel.greeting), \(viewModel.userName)")
                    .font(.Jakarta.bold(28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("GreetingText")
            }

            Spacer()

            userAvatarView
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - User Avatar

    private var userAvatarView: some View {
        Button {
            appState.selectedTab = .profile
            HapticManager.impact(.light)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                if let imageData = viewModel.localAvatarData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                } else if let urlString = viewModel.userAvatarUrl, let url = APIEndpoint.resolveMediaURL(urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                        default:
                            defaultAvatarView
                        }
                    }
                } else if let assetName = viewModel.userAvatarAssetName {
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
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
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
        Date().homeHeaderString
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
    let onAddWater: () -> Void
    let onShowWaterOptions: () -> Void
    let onMoreMealsTapped: () -> Void
    let onMealTapped: (MealRecord) -> Void
    let onCameraTapped: () -> Void

    init(
        startOfDay: Date,
        endOfDay: Date,
        stepCount: Int,
        caloriesBurned: Int,
        onAddWater: @escaping () -> Void,
        onShowWaterOptions: @escaping () -> Void,
        onMoreMealsTapped: @escaping () -> Void,
        onMealTapped: @escaping (MealRecord) -> Void,
        onCameraTapped: @escaping () -> Void
    ) {
        self.stepCount = stepCount
        self.caloriesBurned = caloriesBurned
        self.onAddWater = onAddWater
        self.onShowWaterOptions = onShowWaterOptions
        self.onMoreMealsTapped = onMoreMealsTapped
        self.onMealTapped = onMealTapped
        self.onCameraTapped = onCameraTapped

        _todayMeals = Query(
            filter: #Predicate<MealRecord> { record in
                record.mealTime >= startOfDay && record.mealTime < endOfDay
                && record.pendingDeletion == false
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

    private var dailyWaterGoal: Int { profiles.first?.dailyWaterGoal ?? 2500 }

    private var dailyStepGoal: Int { profiles.first?.dailyStepGoal ?? 10000 }

    private var isOverGoal: Bool {
        consumedCalories > dailyCalorieGoal
    }

    private var calorieProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0 }
        return Double(consumedCalories) / Double(dailyCalorieGoal)
    }

    private var proteinProgress: Double {
        guard dailyProteinGoal > 0 else { return 0 }
        return proteinGrams / Double(dailyProteinGoal)
    }

    private var carbsProgress: Double {
        guard dailyCarbsGoal > 0 else { return 0 }
        return carbsGrams / Double(dailyCarbsGoal)
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
        if todayMeals.isEmpty {
            emptyCalorieCard
        } else {
            calorieRingCard
        }
        healthMetricsGrid
        foodMomentSection
    }

    // MARK: - Empty Calorie Card

    private var emptyCalorieCard: some View {
        Button {
            onCameraTapped()
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    CalorieRingChart(progress: 0)
                        .frame(width: 220, height: 220)
                        .opacity(0.3)

                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.Jakarta.regular(32))
                            .foregroundStyle(AppTheme.Colors.primary)

                        Text("记录第一餐")
                            .font(.Jakarta.bold(18))
                            .foregroundStyle(.primary)

                        Text("拍照开始追踪今日营养")
                            .font(.Jakarta.medium(13))
                            .foregroundStyle(.secondary)
                    }
                }

                MacroIndicatorRow(
                    proteinGrams: 0,
                    carbsGrams: 0,
                    fatGrams: 0
                )
                .opacity(0.3)
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
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: - Calorie Ring Card

    private var calorieRingCard: some View {
        VStack(spacing: 16) {
            ZStack {
                CalorieRingChart(progress: calorieProgress)
                    .frame(width: 220, height: 220)
                    .accessibilityIdentifier("CalorieRingChart")

                caloriesCenterContent
            }

            caloriesSummaryText

            MacroIndicatorRow(
                proteinGrams: proteinGrams,
                carbsGrams: carbsGrams,
                fatGrams: fatGrams
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
        VStack(spacing: 6) {
            Text("\(percentageText)%")
                .font(.Jakarta.extraBold(44))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .accessibilityIdentifier("CaloriePercentageText")

            Text("目标完成度")
                .font(.Jakarta.semiBold(11))
                .foregroundStyle(.secondary)
                .tracking(1.5)
                .textCase(.uppercase)

            if isOverGoal {
                Text("已超出目标")
                    .font(.Jakarta.bold(10))
                    .foregroundStyle(AppTheme.Colors.calorieRingProgress)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.calorieRingProgress.opacity(0.15))
                    )
                    .padding(.top, 2)
            }
        }
    }

    private var caloriesSummaryText: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(formattedCalories(consumedCalories))
                .font(.Jakarta.bold(20))
                .foregroundStyle(.primary)

            Text("/ \(formattedCalories(dailyCalorieGoal)) kcal")
                .font(.Jakarta.medium(13))
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("CalorieSummaryText")
    }

    private var percentageText: Int {
        guard dailyCalorieGoal > 0 else { return 0 }
        return Int(Double(consumedCalories) / Double(dailyCalorieGoal) * 100)
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
            onMoreTapped: onMoreMealsTapped,
            onCameraTapped: onCameraTapped
        )
        .accessibilityIdentifier("FoodMomentCarousel")
    }

    // MARK: - Helpers

    private static let calorieFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()

    private func formattedCalories(_ value: Int) -> String {
        Self.calorieFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Refresh Error Toast

struct RefreshErrorToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.Jakarta.medium(14))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.Jakarta.medium(13))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThickMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}
