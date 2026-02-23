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
        Form {
            Section("通知") {
                Toggle(isOn: $isMealReminderEnabled) {
                    settingsLabel("用餐提醒", icon: "bell.fill", color: .red)
                }
                .accessibilityIdentifier("MealReminderToggle")
            }

            Section("单位") {
                Picker(selection: $selectedCalorieUnit) {
                    ForEach(CalorieUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                } label: {
                    settingsLabel("热量单位", icon: "flame.fill", color: .orange)
                }
                .accessibilityIdentifier("CalorieUnitPicker")

                Picker(selection: $selectedWeightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                } label: {
                    settingsLabel("体重单位", icon: "scalemass.fill", color: .purple)
                }
                .accessibilityIdentifier("WeightUnitPicker")
            }

            Section("外观") {
                Picker(selection: $selectedAppearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                } label: {
                    settingsLabel("外观", icon: "circle.lefthalf.filled", color: .indigo)
                }
                .accessibilityIdentifier("AppearanceModePicker")

                Picker(selection: $selectedLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                } label: {
                    settingsLabel("语言", icon: "globe", color: .blue)
                }
                .accessibilityIdentifier("LanguagePicker")
            }

            Section("关于") {
                Link(destination: URL(string: "https://foodmoment.app/privacy")!) {
                    HStack {
                        settingsLabel("隐私政策", icon: "hand.raised.fill", color: .gray)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .accessibilityIdentifier("PrivacyPolicyLink")

                NavigationLink {
                    aboutView
                } label: {
                    settingsLabel("关于食刻", icon: "info.circle.fill", color: .blue)
                }
                .accessibilityIdentifier("AboutLink")
            }

            Section {
                Button(role: .destructive) {
                    isShowingDeleteAccountAlert = true
                } label: {
                    Label("删除账户", systemImage: "trash.fill")
                }
                .accessibilityIdentifier("DeleteAccountButton")
            }
        }
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

    // MARK: - Settings Label

    private func settingsLabel(_ title: String, icon: String, color: Color) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    // MARK: - About View

    private var aboutView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("食刻")
                    .font(.title)
                    .fontWeight(.bold)

                Text("版本 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("AI 驱动的食物追踪，助你更健康。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("AboutView")
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
