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
    @State private var isShowingSignOutAlert: Bool = false

    // MARK: - Properties

    let viewModel: ProfileViewModel

    // MARK: - Body

    var body: some View {
        Form {
            notificationsSection
            unitsSection
            appearanceSection
            aboutSection
            accountSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Out", isPresented: $isShowingSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                viewModel.signOut(appState: appState)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $isShowingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.signOut(appState: appState)
                dismiss()
            }
        } message: {
            Text("This action is irreversible. All your data, including meal records, achievements, and personal information, will be permanently deleted. Are you sure?")
        }
        .accessibilityIdentifier("SettingsView")
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $isMealReminderEnabled) {
                Label("Meal Reminder", systemImage: "bell.fill")
            }
            .tint(AppTheme.Colors.primary)
            .accessibilityIdentifier("MealReminderToggle")
        } header: {
            Text("Notifications")
        }
    }

    // MARK: - Units Section

    private var unitsSection: some View {
        Section {
            Picker(selection: $selectedCalorieUnit) {
                ForEach(CalorieUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            } label: {
                Label("Calorie Unit", systemImage: "flame.fill")
            }
            .accessibilityIdentifier("CalorieUnitPicker")

            Picker(selection: $selectedWeightUnit) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            } label: {
                Label("Weight Unit", systemImage: "scalemass.fill")
            }
            .accessibilityIdentifier("WeightUnitPicker")
        } header: {
            Text("Units")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            Picker(selection: $selectedAppearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }
            .accessibilityIdentifier("AppearanceModePicker")

            Picker(selection: $selectedLanguage) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.rawValue).tag(lang)
                }
            } label: {
                Label("Language", systemImage: "globe")
            }
            .accessibilityIdentifier("LanguagePicker")
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            Link(destination: URL(string: "https://foodmoment.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
                    .foregroundStyle(.primary)
            }
            .accessibilityIdentifier("PrivacyPolicyLink")

            NavigationLink {
                aboutView
            } label: {
                Label("About FoodMoment", systemImage: "info.circle.fill")
            }
            .accessibilityIdentifier("AboutLink")
        } header: {
            Text("About")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                isShowingSignOutAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.red)
                    Spacer()
                }
            }
            .accessibilityIdentifier("SignOutButton")

            Button(role: .destructive) {
                isShowingDeleteAccountAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label("Delete Account", systemImage: "trash.fill")
                        .foregroundStyle(.red)
                    Spacer()
                }
            }
            .accessibilityIdentifier("DeleteAccountButton")
        } header: {
            Text("Account")
        }
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
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("AboutView")
    }

    private var appIcon: some View {
        Image(systemName: "fork.knife.circle.fill")
            .font(.system(size: 80))
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
            Text("FoodMoment")
                .font(.title.weight(.bold))

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var appDescription: some View {
        Text("AI-powered food tracking for a healthier you.")
            .font(.body)
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
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var id: String { rawValue }
    }

    enum AppLanguage: String, CaseIterable, Identifiable {
        case chinese = "Chinese"
        case english = "English"

        var id: String { rawValue }
    }
}
