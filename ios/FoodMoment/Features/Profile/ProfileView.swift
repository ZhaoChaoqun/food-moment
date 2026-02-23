import SwiftUI
import SwiftData

struct ProfileView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var viewModel = ProfileViewModel()
    @State private var isShowingEditProfile = false

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
            .premiumBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("我的")
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                HStack {
                    Spacer()
                    Text("我的")
                        .font(.Jakarta.semiBold(17))
                    Spacer()
                }
                .overlay(alignment: .trailing) {
                    Button {
                        viewModel.isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundStyle(.primary)
                    }
                    .padding(.trailing, 16)
                    .accessibilityIdentifier("ProfileSettingsButton")
                }
                .padding(.vertical, 8)
                .background(.clear)
            }
            .navigationDestination(isPresented: $viewModel.isShowingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $viewModel.isShowingAchievements) {
                AchievementsGalleryView(viewModel: viewModel)
            }
            .onChange(of: viewModel.isShowingSettings) { _, newValue in
                appState.isTabBarHidden = newValue
            }
            .onChange(of: viewModel.isShowingAchievements) { _, newValue in
                appState.isTabBarHidden = newValue
            }
            .sheet(isPresented: $isShowingEditProfile, onDismiss: {
                viewModel.loadProfile(modelContext: modelContext)
            }) {
                EditProfileView(userProfile: viewModel.userProfile)
            }
            .onAppear {
                viewModel.loadProfile(modelContext: modelContext)
            }
            .task {
                await viewModel.refreshFromAPI(modelContext: modelContext)
            }
            .accessibilityIdentifier("ProfileView")
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Button {
            isShowingEditProfile = true
        } label: {
            VStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    avatarWithBadge

                    // 编辑指示器
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 28, height: 28)
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 1)
                    .offset(x: 4, y: 4)
                }

                VStack(spacing: 8) {
                    userNameText

                    Text("编辑资料")
                        .font(.Jakarta.medium(13))
                        .foregroundStyle(AppTheme.Colors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
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
        if let imageData = viewModel.userProfile?.localAvatarData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 112, height: 112)
        } else if let urlString = viewModel.avatarUrl, let url = APIEndpoint.resolveMediaURL(urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                        .frame(width: 112, height: 112)
                case .failure:
                    defaultAvatar
                        .frame(width: 112, height: 112)
                default:
                    ProgressView()
                        .frame(width: 112, height: 112)
                }
            }
        } else if let assetName = viewModel.avatarAssetName {
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
            .font(.Jakarta.extraBold(10))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .stroke(Color(.systemBackground), lineWidth: 2)
            )
            .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 4, y: 1)
            .offset(x: 0, y: 4)
    }

    private var userNameText: some View {
        Text(viewModel.userName)
            .font(.Jakarta.bold(28))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityIdentifier("ProfileUserName")
    }

    // MARK: - Weight and Streak Section

    private var weightAndStreakSection: some View {
        HStack(alignment: .top, spacing: 12) {
            WeightCard(
                currentWeight: viewModel.currentWeight,
                targetWeight: viewModel.targetWeight,
                trend: viewModel.weightTrend,
                weightHistory: viewModel.weightHistory,
                recordCount: viewModel.weightRecordCount
            )
            .overlay {
                // 将 sheet 隔离在一个独立的轻量级视图中
                // 避免 sheet 展示/消失触发 ProfileView 整体 body 重新评估
                WeightSheetHost(modelContext: modelContext, onWeightSaved: {
                    viewModel.loadProfile(modelContext: modelContext)
                })
            }

            StreakCard(streakDays: viewModel.streakDays)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("WeightAndStreakSection")
    }

    // MARK: - Activity Calendar Section

    private var activityCalendarSection: some View {
        ActivityCalendar()
            .accessibilityIdentifier("ActivityCalendarSection")
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            achievementsSectionHeader
            achievementsRow
        }
        .accessibilityIdentifier("AchievementsSection")
    }

    private var achievementsSectionHeader: some View {
        HStack {
            Text("成就")
                .font(.Jakarta.semiBold(20))
                .foregroundStyle(.primary)

            if viewModel.unlockedCount > 0 {
                Text("\(viewModel.unlockedCount)/\(viewModel.totalVisibleCount)")
                    .font(.Jakarta.medium(13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                viewModel.isShowingAchievements = true
            } label: {
                HStack(spacing: 4) {
                    Text("更多")
                        .font(.Jakarta.semiBold(12))
                    Image(systemName: "chevron.right")
                        .font(.Jakarta.semiBold(9))
                }
                .foregroundStyle(AppTheme.Colors.primary)
            }
            .accessibilityIdentifier("ViewAllAchievementsButton")
        }
        .padding(.horizontal, 4)
    }

    private var achievementsRow: some View {
        Group {
            let items = viewModel.highlightedAchievements
            if items.isEmpty {
                // 引导卡片
                achievementsEmptyCard
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { achievement in
                            AchievementBadge(item: achievement, renderMode: .swiftUI)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var achievementsEmptyCard: some View {
        Button {
            viewModel.isShowingAchievements = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trophy")
                    .font(.Jakarta.medium(24))
                    .foregroundStyle(AppTheme.Colors.primary.opacity(0.6))

                VStack(alignment: .leading, spacing: 4) {
                    Text("开始收集徽章吧")
                        .font(.Jakarta.semiBold(14))
                        .foregroundStyle(.primary)
                    Text("记录饮食解锁专属成就")
                        .font(.Jakarta.regular(12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.Jakarta.medium(12))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6).opacity(0.7))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("AchievementsEmptyCard")
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
        Color.clear.frame(height: AppTheme.Layout.tabBarClearance)
    }

}

// MARK: - Preview

#Preview {
    ProfileView()
        .environment(AppState())
        .modelContainer(for: [UserProfile.self, MealRecord.self, WeightLog.self, Achievement.self])
}
