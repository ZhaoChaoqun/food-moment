import SwiftUI

struct WeightInputSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Callback

    /// 保存回调，由父视图提供，处理 SwiftData/API/HealthKit 写入
    var onSave: ((Double) async -> Void)?

    // MARK: - State

    @State private var weightValue: Double = 65.0
    @State private var isSaving = false
    @State private var showCheck = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                weightDisplay
                weightSlider

                Spacer()

                recordButton
            }
            .padding(24)
            .navigationTitle("记录体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    cancelButton
                }
            }
            .task {
                // 延迟加载 HealthKit 体重，避免阻塞 sheet 弹出动画
                try? await Task.sleep(for: .milliseconds(400))
                await loadFromHealthKit()
            }
            .accessibilityIdentifier("WeightInputSheet")
        }
        .tint(AppTheme.Colors.primary)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Cancel Button

    private var cancelButton: some View {
        Button("取消") {
            dismiss()
        }
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("CancelButton")
    }

    // MARK: - Weight Display

    private var weightDisplay: some View {
        VStack(spacing: 8) {
            Image(systemName: "scalemass.fill")
                .font(.Jakarta.regular(40))
                .foregroundStyle(AppTheme.Colors.primary)
                .padding(.bottom, 8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", weightValue))
                    .font(.Jakarta.extraBold(56))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text("kg")
                    .font(.Jakarta.medium(20))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Weight Slider

    private var weightSlider: some View {
        VStack(spacing: 4) {
            Slider(
                value: $weightValue,
                in: 30...200,
                step: 0.1
            )
            .tint(AppTheme.Colors.primary)

            HStack {
                Text("30")
                    .font(.Jakarta.regular(12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("200")
                    .font(.Jakarta.regular(12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button {
            Task {
                await performSave()
            }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else if showCheck {
                    Image(systemName: "checkmark")
                        .font(.Jakarta.bold(18))
                } else {
                    Image(systemName: "scalemass.fill")
                    Text("记录")
                        .font(.Jakarta.bold(18))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(AppTheme.Colors.primary)
            )
            .foregroundStyle(.white)
        }
        .disabled(isSaving || showCheck)
        .accessibilityIdentifier("RecordWeightButton")
    }

    // MARK: - Data Loading

    private func loadFromHealthKit() async {
        do {
            if let latestWeight = try await HealthKitManager.shared.fetchLatestWeight() {
                weightValue = latestWeight
            }
        } catch {
            // HealthKit 不可用时静默忽略
        }
    }

    // MARK: - Save

    private func performSave() async {
        isSaving = true
        await onSave?(weightValue)
        isSaving = false
        showCheck = true

        try? await Task.sleep(for: .milliseconds(600))
        dismiss()
    }
}

#Preview {
    WeightInputSheet()
}
