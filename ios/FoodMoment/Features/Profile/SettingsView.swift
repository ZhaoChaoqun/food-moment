import SwiftUI

struct SettingsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    // MARK: - State

    @State private var isMealReminderEnabled: Bool = true
    @State private var selectedCalorieUnit: CalorieUnit = .kcal
    @State private var selectedWeightUnit: WeightUnit = .kg
    @State private var selectedAppearanceMode: AppearanceMode = .system
    @State private var selectedLanguage: AppLanguage = .chinese
    @State private var isShowingDeleteAccountAlert: Bool = false

    // MARK: - Properties

    let viewModel: ProfileViewModel

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                notificationsSection
                unitsSection
                appearanceSection
                aboutSection
                accountSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, AppTheme.Layout.tabBarClearance)
        }
        .premiumBackground()
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .alert("删除账户", isPresented: $isShowingDeleteAccountAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                viewModel.deleteAccount(appState: appState)
                dismiss()
            }
        } message: {
            Text("此操作不可撤销。您的所有数据，包括饮食记录、成就和个人信息，都将被永久删除。确定要继续吗？")
        }
        .accessibilityIdentifier("SettingsView")
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("通知")

            VStack(spacing: 0) {
                Toggle(isOn: $isMealReminderEnabled) {
                    Label("用餐提醒", systemImage: "bell.fill")
                }
                .tint(AppTheme.Colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .glassSection()
            .accessibilityIdentifier("MealReminderToggle")
        }
    }

    // MARK: - Units Section

    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("单位")

            VStack(spacing: 0) {
                Picker(selection: $selectedCalorieUnit) {
                    ForEach(CalorieUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                } label: {
                    Label("热量单位", systemImage: "flame.fill")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityIdentifier("CalorieUnitPicker")

                Divider().padding(.leading, 16)

                Picker(selection: $selectedWeightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                } label: {
                    Label("体重单位", systemImage: "scalemass.fill")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityIdentifier("WeightUnitPicker")
            }
            .glassSection()
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("外观")

            VStack(spacing: 0) {
                Picker(selection: $selectedAppearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                } label: {
                    Label("外观", systemImage: "circle.lefthalf.filled")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityIdentifier("AppearanceModePicker")

                Divider().padding(.leading, 16)

                Picker(selection: $selectedLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                } label: {
                    Label("语言", systemImage: "globe")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityIdentifier("LanguagePicker")
            }
            .glassSection()
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("关于")

            VStack(spacing: 0) {
                Link(destination: URL(string: "https://foodmoment.app/privacy")!) {
                    HStack {
                        Label("隐私政策", systemImage: "hand.raised.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.Jakarta.regular(12))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityIdentifier("PrivacyPolicyLink")

                Divider().padding(.leading, 16)

                NavigationLink {
                    aboutView
                } label: {
                    Label("关于食刻", systemImage: "info.circle.fill")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityIdentifier("AboutLink")
            }
            .glassSection()
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("账户")

            VStack(spacing: 0) {
                Button {
                    isShowingDeleteAccountAlert = true
                } label: {
                    HStack {
                        Label("删除账户", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityIdentifier("DeleteAccountButton")
            }
            .glassSection()
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.Jakarta.medium(12))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 4)
    }

    // MARK: - About View

    private var aboutView: some View {
        VStack(spacing: 24) {
            Spacer()

            appIcon

            appInfo

            appDescription

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .premiumBackground()
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("AboutView")
    }

    private var appIcon: some View {
        Image(systemName: "fork.knife.circle.fill")
            .font(.Jakarta.regular(80))
            .foregroundStyle(
                LinearGradient(
                    colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var appInfo: some View {
        VStack(spacing: 8) {
            Text("食刻")
                .font(.Jakarta.bold(28))

            Text("版本 1.0.0")
                .font(.Jakarta.regular(15))
                .foregroundStyle(.secondary)
        }
    }

    private var appDescription: some View {
        Text("AI 驱动的食物追踪，助你更健康。")
            .font(.Jakarta.regular(17))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }
}

// MARK: - Enums

extension SettingsView {

    enum CalorieUnit: String, CaseIterable, Identifiable {
        case kcal = "kcal"
        case kj = "kJ"

        var id: String { rawValue }
    }

    enum WeightUnit: String, CaseIterable, Identifiable {
        case kg = "kg"
        case lbs = "lbs"

        var id: String { rawValue }
    }

    enum AppearanceMode: String, CaseIterable, Identifiable {
        case system = "跟随系统"
        case light = "浅色"
        case dark = "深色"

        var id: String { rawValue }
    }

    enum AppLanguage: String, CaseIterable, Identifiable {
        case chinese = "中文"
        case english = "English"

        var id: String { rawValue }
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: ProfileViewModel())
    }
    .environment(AppState())
    .modelContainer(for: [MealRecord.self, UserProfile.self], inMemory: true)
}
