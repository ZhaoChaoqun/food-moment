import SwiftUI
import SwiftData

struct HomeView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel = HomeViewModel()

    // MARK: - Properties

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    calorieRingCard
                    healthMetricsGrid
                    foodMomentSection
                }
                .padding(.bottom, 100)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .refreshable {
                viewModel.loadTodayData(modelContext: modelContext)
                viewModel.refresh()
            }
            .onAppear {
                viewModel.loadMockData()
            }
            .navigationBarHidden(true)
            .accessibilityIdentifier("HomeScrollView")
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
                    .foregroundStyle(.primary)
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
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.primary)
            )
    }

    private var proBadge: some View {
        Text("PRO")
            .font(.Jakarta.extraBold(7))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(AppTheme.Colors.primary)
            .clipShape(Capsule())
            .offset(x: 2, y: 2)
    }

    // MARK: - Calorie Ring Card

    private var calorieRingCard: some View {
        VStack(spacing: 16) {
            ZStack {
                CalorieRingChart(
                    calorieProgress: viewModel.calorieProgress,
                    proteinProgress: viewModel.proteinProgress,
                    carbsProgress: viewModel.carbsProgress
                )
                .frame(width: 200, height: 200)
                .accessibilityIdentifier("CalorieRingChart")

                caloriesCenterContent
            }

            Text("每日目标: \(formattedNumber(viewModel.dailyCalorieGoal))")
                .font(.Jakarta.medium(12))
                .foregroundStyle(.tertiary)

            MacroIndicatorRow(
                calories: viewModel.consumedCalories,
                proteinGrams: viewModel.proteinGrams,
                carbsGrams: viewModel.carbsGrams
            )
            .accessibilityIdentifier("MacroIndicators")
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
        .padding(.horizontal, 20)
    }

    private var caloriesCenterContent: some View {
        VStack(spacing: 4) {
            Text(formattedNumber(viewModel.caloriesLeft))
                .font(.Jakarta.extraBold(48))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .accessibilityIdentifier("CaloriesRemainingText")

            Text("KCAL LEFT")
                .font(.Jakarta.semiBold(11))
                .foregroundStyle(.secondary)
                .tracking(1.5)
        }
    }

    // MARK: - Health Metrics Grid

    private var healthMetricsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            WaterCard(
                waterAmount: viewModel.waterAmount,
                dailyGoal: viewModel.dailyWaterGoal,
                progress: viewModel.waterProgress,
                onAddWater: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        viewModel.addWater(modelContext: modelContext)
                    }
                }
            )
            .accessibilityIdentifier("WaterCard")

            StepsCard(
                stepCount: viewModel.stepCount,
                dailyGoal: viewModel.dailyStepGoal,
                progress: viewModel.stepProgress,
                caloriesBurned: viewModel.caloriesBurned
            )
            .accessibilityIdentifier("StepsCard")
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Food Moment Section

    private var foodMomentSection: some View {
        FoodMomentCarousel(meals: viewModel.todayMeals)
            .accessibilityIdentifier("FoodMomentCarousel")
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
