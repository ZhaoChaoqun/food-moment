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
            .premiumBackground()
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
        .background(
            ZStack {
                // 品牌色径向光晕
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
            Text(formattedNumber(viewModel.caloriesLeft))
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
