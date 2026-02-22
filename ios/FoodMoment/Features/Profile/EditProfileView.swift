import SwiftUI
import SwiftData

struct EditProfileView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel: EditProfileViewModel

    // MARK: - Init

    init(userProfile: UserProfile?) {
        _viewModel = State(initialValue: EditProfileViewModel(userProfile: userProfile))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    avatarSection
                    basicInfoSection
                    bodyGoalsSection
                    tdeeRecommendationCard
                    nutritionGoalsSection
                    lifestyleGoalsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .premiumBackground()
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    saveButton
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $viewModel.isShowingImagePicker) {
            ImagePicker(image: $viewModel.selectedImage)
        }
        .task {
            await viewModel.loadCurrentWeight()
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.isShowingImagePicker = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    avatarImage
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 2))
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)

                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.Colors.primary)
                        .background(Circle().fill(.white).frame(width: 24, height: 24))
                }
            }
            .buttonStyle(.plain)

            TextField("昵称", text: $viewModel.displayName)
                .font(.Jakarta.bold(20))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let image = viewModel.selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let imageData = viewModel.localAvatarData,
                  let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let urlString = viewModel.avatarUrl, let url = APIEndpoint.resolveMediaURL(urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    defaultAvatar
                }
            }
        } else {
            defaultAvatar
        }
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [AppTheme.Colors.primary.opacity(0.3), AppTheme.Colors.primary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "person.fill")
                    .font(.Jakarta.regular(36))
                    .foregroundStyle(AppTheme.Colors.primary)
            )
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("基本信息")

            // Gender
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("性别")
                Picker("性别", selection: $viewModel.gender) {
                    Text("未设置").tag(EditProfileViewModel.Gender?.none)
                    ForEach(EditProfileViewModel.Gender.allCases) { g in
                        Text(g.displayName).tag(EditProfileViewModel.Gender?.some(g))
                    }
                }
                .pickerStyle(.segmented)
            }

            // Birth Year
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("出生年份")
                HStack {
                    Text(viewModel.birthYear.map { "\($0) 年" } ?? "未设置")
                        .font(.Jakarta.medium(16))
                        .foregroundStyle(viewModel.birthYear == nil ? .tertiary : .primary)

                    Spacer()

                    Picker("", selection: Binding(
                        get: { viewModel.birthYear ?? 1990 },
                        set: { viewModel.birthYear = $0 }
                    )) {
                        ForEach((1920...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.Colors.primary)
                }
            }

            // Height
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("身高")
                HStack {
                    TextField("170.0", value: $viewModel.heightCm, format: .number)
                        .font(.Jakarta.medium(16))
                        .keyboardType(.decimalPad)
                        .frame(width: 80)

                    Text("cm")
                        .font(.Jakarta.regular(14))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Stepper("", value: Binding(
                        get: { viewModel.heightCm ?? 170.0 },
                        set: { viewModel.heightCm = $0 }
                    ), in: 100...250, step: 0.5)
                    .labelsHidden()
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium)
    }

    // MARK: - Body Goals Section

    private var bodyGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("身体目标")

            // Target Weight
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("目标体重")
                HStack {
                    TextField("60.0", value: $viewModel.targetWeight, format: .number)
                        .font(.Jakarta.medium(16))
                        .keyboardType(.decimalPad)
                        .frame(width: 80)

                    Text("kg")
                        .font(.Jakarta.regular(14))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Stepper("", value: Binding(
                        get: { viewModel.targetWeight ?? 65.0 },
                        set: { viewModel.targetWeight = $0 }
                    ), in: 30...200, step: 0.5)
                    .labelsHidden()
                }
            }

            // Activity Level
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("活动水平")
                Picker("活动水平", selection: $viewModel.activityLevel) {
                    Text("未设置").tag(EditProfileViewModel.ActivityLevel?.none)
                    ForEach(EditProfileViewModel.ActivityLevel.allCases) { level in
                        VStack(alignment: .leading) {
                            Text(level.displayName)
                        }
                        .tag(EditProfileViewModel.ActivityLevel?.some(level))
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.Colors.primary)

                if let level = viewModel.activityLevel {
                    Text(level.description)
                        .font(.Jakarta.regular(12))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium)
    }

    // MARK: - TDEE Recommendation

    @ViewBuilder
    private var tdeeRecommendationCard: some View {
        if let recommended = viewModel.recommendedCalories {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(AppTheme.Colors.primary)
                    Text("推荐每日摄入")
                        .font(.Jakarta.medium(14))
                        .foregroundStyle(.secondary)
                }

                Text("\(recommended)")
                    .font(.Jakarta.extraBold(36))
                    .foregroundStyle(.primary)
                +
                Text(" kcal")
                    .font(.Jakarta.medium(16))
                    .foregroundStyle(.secondary)

                if let weight = viewModel.currentWeight {
                    Text("基于当前体重 \(String(format: "%.1f", weight))kg 计算")
                        .font(.Jakarta.regular(11))
                        .foregroundStyle(.tertiary)
                }

                Button {
                    withAnimation(AppTheme.Animation.defaultSpring) {
                        viewModel.applyRecommendedCalories()
                    }
                } label: {
                    Text("使用推荐值")
                        .font(.Jakarta.semiBold(14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .fill(AppTheme.Colors.primary)
                        )
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RadialGradient(
                    colors: [AppTheme.Colors.primary.opacity(0.08), Color.clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 150
                )
            )
            .glassCard(cornerRadius: AppTheme.CornerRadius.medium)
        }
    }

    // MARK: - Nutrition Goals Section

    private var nutritionGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("营养目标")

            // Calorie Goal
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("每日热量")
                HStack {
                    TextField("2000", value: $viewModel.dailyCalorieGoal, format: .number)
                        .font(.Jakarta.medium(16))
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                        .onChange(of: viewModel.dailyCalorieGoal) { _, _ in
                            viewModel.onCalorieGoalChanged()
                        }

                    Text("kcal")
                        .font(.Jakarta.regular(14))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Stepper("", value: $viewModel.dailyCalorieGoal, in: 800...5000, step: 50)
                        .labelsHidden()
                }
            }

            // Auto distribute toggle
            Toggle(isOn: $viewModel.autoDistributeMacros) {
                Text("自动分配宏量素")
                    .font(.Jakarta.medium(14))
            }
            .tint(AppTheme.Colors.primary)
            .onChange(of: viewModel.autoDistributeMacros) { _, newValue in
                if newValue { viewModel.distributeMacros() }
            }

            // Macro Goals
            macroRow(label: "蛋白质", value: $viewModel.dailyProteinGoal, unit: "g", range: 10...500, step: 5, color: AppTheme.Colors.protein)
            macroRow(label: "碳水", value: $viewModel.dailyCarbsGoal, unit: "g", range: 10...800, step: 5, color: AppTheme.Colors.carbs)
            macroRow(label: "脂肪", value: $viewModel.dailyFatGoal, unit: "g", range: 10...300, step: 5, color: AppTheme.Colors.fat)
        }
        .padding(16)
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium)
    }

    private func macroRow(label: String, value: Binding<Int>, unit: String, range: ClosedRange<Int>, step: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.Jakarta.medium(14))
                .frame(width: 50, alignment: .leading)

            TextField("", value: value, format: .number)
                .font(.Jakarta.medium(16))
                .keyboardType(.numberPad)
                .frame(width: 60)
                .disabled(viewModel.autoDistributeMacros)
                .opacity(viewModel.autoDistributeMacros ? 0.6 : 1.0)

            Text(unit)
                .font(.Jakarta.regular(12))
                .foregroundStyle(.secondary)

            Spacer()

            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
                .disabled(viewModel.autoDistributeMacros)
        }
    }

    // MARK: - Lifestyle Goals Section

    private var lifestyleGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("生活目标")

            // Water Goal
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    fieldLabel("饮水目标")
                    Spacer()
                    Text("\(viewModel.dailyWaterGoal) ml")
                        .font(.Jakarta.semiBold(16))
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                Slider(
                    value: Binding(
                        get: { Double(viewModel.dailyWaterGoal) },
                        set: { viewModel.dailyWaterGoal = Int($0) }
                    ),
                    in: 500...5000,
                    step: 100
                )
                .tint(AppTheme.Colors.primary)
            }

            // Step Goal
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    fieldLabel("步数目标")
                    Spacer()
                    Text(formattedNumber(viewModel.dailyStepGoal) + " 步")
                        .font(.Jakarta.semiBold(16))
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                Slider(
                    value: Binding(
                        get: { Double(viewModel.dailyStepGoal) },
                        set: { viewModel.dailyStepGoal = Int($0) }
                    ),
                    in: 1000...30000,
                    step: 1000
                )
                .tint(AppTheme.Colors.primary)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task {
                let success = await viewModel.save(modelContext: modelContext)
                if success {
                    try? await Task.sleep(for: .milliseconds(500))
                    dismiss()
                }
            }
        } label: {
            Group {
                switch (viewModel.isSaving, viewModel.isSaveSuccess) {
                case (true, _):
                    ProgressView()
                        .tint(AppTheme.Colors.primary)
                case (_, true):
                    Image(systemName: "checkmark")
                        .font(.Jakarta.bold(14))
                        .foregroundStyle(AppTheme.Colors.primary)
                default:
                    Text("保存")
                        .font(.Jakarta.semiBold(14))
                        .foregroundStyle(AppTheme.Colors.primary)
                }
            }
        }
        .disabled(!viewModel.canSave)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.Jakarta.bold(16))
            .foregroundStyle(.primary)
    }

    private func fieldLabel(_ label: String) -> some View {
        Text(label)
            .font(.Jakarta.medium(13))
            .foregroundStyle(.secondary)
    }

    private func formattedNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
