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
                    bodyDataSection
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

            VStack(spacing: 4) {
                TextField("昵称", text: $viewModel.displayName)
                    .font(.Jakarta.bold(20))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .onChange(of: viewModel.displayName) { _, newValue in
                        if newValue.count > EditProfileViewModel.maxNicknameLength {
                            viewModel.displayName = String(newValue.prefix(EditProfileViewModel.maxNicknameLength))
                        }
                    }

                nicknameCounter
            }
        }
        .padding(.vertical, 8)
    }

    private var nicknameCounter: some View {
        let count = viewModel.displayName.count
        let max = EditProfileViewModel.maxNicknameLength
        let remaining = max - count
        let color: Color = remaining <= 0 ? .red : remaining <= 3 ? .orange : .tertiary

        return Text("\(count)/\(max)")
            .font(.Jakarta.regular(11))
            .foregroundStyle(color)
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

    // MARK: - Body Data Section (原"基本信息")

    private var bodyDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("身体数据", description: "用于计算你的每日推荐热量")

            // Gender - 3段 Segmented + 清除按钮
            genderRow

            // Birth Date - 展开式 DatePicker
            birthDateRow

            // Height - 展开式 WheelValuePicker
            heightRow
        }
        .padding(16)
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium)
    }

    // MARK: - Gender Row

    private var genderRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                fieldLabel("生理性别")
                Spacer()
                if viewModel.gender != nil {
                    Button {
                        withAnimation(AppTheme.Animation.defaultSpring) {
                            viewModel.gender = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Picker("性别", selection: Binding(
                get: { viewModel.gender ?? .male },
                set: { viewModel.gender = $0 }
            )) {
                ForEach(EditProfileViewModel.Gender.allCases) { g in
                    Text(g.displayName).tag(g)
                }
            }
            .pickerStyle(.segmented)

            Text("用于基础代谢率计算")
                .font(.Jakarta.regular(11))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Birth Date Row

    private var birthDateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(AppTheme.Animation.defaultSpring) {
                    viewModel.collapseAllPickers(except: "birthDate")
                    viewModel.isBirthDateExpanded.toggle()
                }
            } label: {
                HStack {
                    fieldLabel("出生日期")
                    Spacer()
                    Text(birthDateDisplayText)
                        .font(.Jakarta.medium(16))
                        .foregroundStyle(viewModel.birthDate == nil ? .tertiary : .primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(viewModel.isBirthDateExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if viewModel.isBirthDateExpanded {
                VStack(spacing: 8) {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { viewModel.birthDate ?? defaultBirthDate },
                            set: { viewModel.birthDate = $0 }
                        ),
                        in: birthDateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                    .frame(height: 150)
                    .clipped()

                    Text("填写完整日期，生日当天会有惊喜")
                        .font(.Jakarta.regular(11))
                        .foregroundStyle(.tertiary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var birthDateDisplayText: String {
        guard let date = viewModel.birthDate else { return "未设置" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    private var defaultBirthDate: Date {
        Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
    }

    private var birthDateRange: ClosedRange<Date> {
        let min = Calendar.current.date(from: DateComponents(year: 1920, month: 1, day: 1)) ?? Date()
        return min...Date()
    }

    // MARK: - Height Row

    private var heightRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(AppTheme.Animation.defaultSpring) {
                    viewModel.collapseAllPickers(except: "height")
                    viewModel.isHeightExpanded.toggle()
                }
            } label: {
                HStack {
                    fieldLabel("身高")
                    Spacer()
                    Text(viewModel.heightCm.map { String(format: "%.1f cm", $0) } ?? "未设置")
                        .font(.Jakarta.medium(16))
                        .foregroundStyle(viewModel.heightCm == nil ? .tertiary : .primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(viewModel.isHeightExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if viewModel.isHeightExpanded {
                WheelValuePicker(
                    integerPart: Binding(
                        get: { viewModel.heightInteger },
                        set: { viewModel.heightInteger = $0 }
                    ),
                    decimalPart: Binding(
                        get: { viewModel.heightDecimal },
                        set: { viewModel.heightDecimal = $0 }
                    ),
                    integerRange: 100...250,
                    unit: "cm"
                )
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onChange(of: viewModel.heightInteger) { _, _ in
                    if viewModel.heightCm == nil { viewModel.heightCm = 170.0 }
                }
            }
        }
    }

    // MARK: - Body Goals Section (原"身体目标")

    private var bodyGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("我的目标", description: "设定你想达到的身体状态")

            // Target Weight - 展开式 WheelValuePicker
            targetWeightRow

            // Activity Level - 展开式单选列表
            activityLevelRow
        }
        .padding(16)
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium)
    }

    // MARK: - Target Weight Row

    private var targetWeightRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(AppTheme.Animation.defaultSpring) {
                    viewModel.collapseAllPickers(except: "targetWeight")
                    viewModel.isTargetWeightExpanded.toggle()
                }
            } label: {
                HStack {
                    fieldLabel("目标体重")
                    Spacer()
                    Text(viewModel.targetWeight.map { String(format: "%.1f kg", $0) } ?? "未设置")
                        .font(.Jakarta.medium(16))
                        .foregroundStyle(viewModel.targetWeight == nil ? .tertiary : .primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(viewModel.isTargetWeightExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if viewModel.isTargetWeightExpanded {
                WheelValuePicker(
                    integerPart: Binding(
                        get: { viewModel.targetWeightInteger },
                        set: { viewModel.targetWeightInteger = $0 }
                    ),
                    decimalPart: Binding(
                        get: { viewModel.targetWeightDecimal },
                        set: { viewModel.targetWeightDecimal = $0 }
                    ),
                    integerRange: 30...200,
                    unit: "kg"
                )
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onChange(of: viewModel.targetWeightInteger) { _, _ in
                    if viewModel.targetWeight == nil { viewModel.targetWeight = 65.0 }
                }
            }
        }
    }

    // MARK: - Activity Level Row

    private var activityLevelRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(AppTheme.Animation.defaultSpring) {
                    viewModel.collapseAllPickers(except: "activityLevel")
                    viewModel.isActivityLevelExpanded.toggle()
                }
            } label: {
                HStack {
                    fieldLabel("活动水平")
                    Spacer()
                    Text(viewModel.activityLevel?.displayName ?? "未设置")
                        .font(.Jakarta.medium(16))
                        .foregroundStyle(viewModel.activityLevel == nil ? .tertiary : .primary)

                    if viewModel.activityLevel != nil {
                        Button {
                            withAnimation(AppTheme.Animation.defaultSpring) {
                                viewModel.activityLevel = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(viewModel.isActivityLevelExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if viewModel.isActivityLevelExpanded {
                VStack(spacing: 0) {
                    ForEach(EditProfileViewModel.ActivityLevel.allCases) { level in
                        activityLevelOption(level)
                        if level != EditProfileViewModel.ActivityLevel.allCases.last {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func activityLevelOption(_ level: EditProfileViewModel.ActivityLevel) -> some View {
        Button {
            withAnimation(AppTheme.Animation.defaultSpring) {
                viewModel.activityLevel = level
                viewModel.isActivityLevelExpanded = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: viewModel.activityLevel == level ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(viewModel.activityLevel == level ? AppTheme.Colors.primary : .tertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.Jakarta.medium(15))
                        .foregroundStyle(.primary)
                    Text(level.description)
                        .font(.Jakarta.regular(12))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
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

    // MARK: - Nutrition Goals Section (原"营养目标")

    private var nutritionGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("营养计划", description: "每日摄入的热量与宏量素分配")

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

    // MARK: - Lifestyle Goals Section (原"生活目标")

    private var lifestyleGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("生活习惯", description: "保持健康的日常习惯")

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

    private func sectionHeader(_ title: String, description: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.Jakarta.bold(16))
                .foregroundStyle(.primary)
            if let description {
                Text(description)
                    .font(.Jakarta.regular(12))
                    .foregroundStyle(.tertiary)
            }
        }
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
