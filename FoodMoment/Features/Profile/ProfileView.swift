import SwiftUI
import SwiftData

struct ProfileView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var viewModel = ProfileViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    profileSection
                    weightAndStreakSection
                    activityCalendarSection
                    achievementsSection
                    intakeChartSection
                    bottomPadding
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    settingsButton
                }
            }
            .navigationDestination(isPresented: $viewModel.isShowingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShowingWeightInput) {
                WeightInputSheet()
            }
            .onAppear {
                viewModel.loadProfile(modelContext: modelContext)
            }
            .accessibilityIdentifier("ProfileView")
        }
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button {
            viewModel.isShowingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.body)
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                )
        }
        .accessibilityIdentifier("ProfileSettingsButton")
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(spacing: 16) {
            avatarWithBadge
            userNameText
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .accessibilityIdentifier("ProfileSection")
    }

    private var avatarWithBadge: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarView
                .frame(width: 112, height: 112)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.primary,
                                    Color(hex: "#60A5FA")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                )
                .padding(4)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                )
                .shadow(color: AppTheme.Colors.primary.opacity(0.2), radius: 12, y: 4)

            if viewModel.isPro {
                proBadge
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let assetName = viewModel.avatarAssetName {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            defaultAvatar
        }
    }

    private var defaultAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(
                LinearGradient(
                    colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(Color.gray.opacity(0.1))
    }

    private var proBadge: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.primary)
            )
            .overlay(
                Capsule()
                    .stroke(Color(.systemBackground), lineWidth: 2)
            )
            .offset(x: 0, y: 4)
    }

    private var userNameText: some View {
        Text(viewModel.userName)
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .foregroundStyle(.primary)
            .accessibilityIdentifier("ProfileUserName")
    }

    // MARK: - Weight and Streak Section

    private var weightAndStreakSection: some View {
        HStack(spacing: 12) {
            WeightCard(
                currentWeight: viewModel.currentWeight,
                targetWeight: viewModel.targetWeight,
                trend: viewModel.weightTrend,
                onTap: {
                    viewModel.isShowingWeightInput = true
                }
            )

            StreakCard(streakDays: viewModel.streakDays)
        }
        .accessibilityIdentifier("WeightAndStreakSection")
    }

    // MARK: - Activity Calendar Section

    private var activityCalendarSection: some View {
        ActivityCalendar(
            activeDays: Set(
                viewModel.dailyActivities.filter { $0.hasActivity }.map { $0.day }
            )
        )
        .accessibilityIdentifier("ActivityCalendarSection")
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            achievementsSectionHeader
            achievementsBadgeList
        }
        .accessibilityIdentifier("AchievementsSection")
    }

    private var achievementsSectionHeader: some View {
        HStack {
            Text("Achievements")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                // View all achievements
            } label: {
                Text("View All")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            .accessibilityIdentifier("ViewAllAchievementsButton")
        }
        .padding(.horizontal, 4)
    }

    private var achievementsBadgeList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.achievements) { achievement in
                    AchievementBadge(item: achievement)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Intake Chart Section

    private var intakeChartSection: some View {
        IntakeChartCard(
            averageCalories: viewModel.averageCalories,
            calorieChange: viewModel.calorieChange,
            dailyData: viewModel.dailyCalories
        )
        .accessibilityIdentifier("IntakeChartSection")
    }

    // MARK: - Bottom Padding

    private var bottomPadding: some View {
        Color.clear.frame(height: 100)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environment(AppState())
        .modelContainer(for: [UserProfile.self, MealRecord.self, WeightLog.self, Achievement.self])
}
