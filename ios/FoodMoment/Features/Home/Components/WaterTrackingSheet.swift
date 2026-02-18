import SwiftUI
import SwiftData

struct WaterTrackingSheet: View {
    let onConfirm: (Int) -> Void

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Types

    private enum SelectionMode: Equatable {
        case preset(Int)
        case custom
    }

    // MARK: - State

    @State private var selectionMode: SelectionMode = .preset(250)
    @State private var customAmount: String = ""
    @State private var isSaving = false
    @State private var isShowingSuccess = false
    @State private var dropletScale: CGFloat = 1.0
    @State private var dropletOffset: CGFloat = 0

    // MARK: - Properties

    private let presetAmounts = [250, 500, 750]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                waterDropletIcon
                amountSelector
                customInputSection
                currentAmountDisplay
                recordButton
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .navigationTitle("记录饮水")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    cancelButton
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Cancel Button

    private var cancelButton: some View {
        Button("取消") {
            dismiss()
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Water Droplet Icon

    private var waterDropletIcon: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.primary.opacity(0.1))
                .frame(width: 100, height: 100)

            Image(systemName: "drop.fill")
                .font(.Jakarta.regular(44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "#4FC3F7"),
                            Color(hex: "#0288D1")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(dropletScale)
                .offset(y: dropletOffset)
        }
        .onAppear {
            startDropletAnimation()
        }
    }

    // MARK: - Amount Selector

    private var amountSelector: some View {
        VStack(spacing: 12) {
            Text("选择饮水量")
                .font(.Jakarta.medium(14))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(presetAmounts, id: \.self) { amount in
                    presetButton(amount: amount)
                }
                customToggleButton
            }
        }
    }

    private func presetButton(amount: Int) -> some View {
        let isSelected = selectionMode == .preset(amount)
        return Button {
            withAnimation(AppTheme.Animation.defaultSpring) {
                selectionMode = .preset(amount)
            }
        } label: {
            VStack(spacing: 4) {
                Text("\(amount)")
                    .font(.Jakarta.bold(18))

                Text("mL")
                    .font(.Jakarta.regular(12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(presetButtonBackground(isSelected: isSelected))
            .overlay(presetButtonBorder(isSelected: isSelected))
        }
        .foregroundStyle(isSelected ? AppTheme.Colors.primary : .primary)
    }

    private func presetButtonBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
            .fill(isSelected ? AppTheme.Colors.primary.opacity(0.15) : Color(.secondarySystemBackground))
    }

    private func presetButtonBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
            .stroke(isSelected ? AppTheme.Colors.primary : .clear, lineWidth: 2)
    }

    private var customToggleButton: some View {
        let isSelected = selectionMode == .custom
        return Button {
            withAnimation(AppTheme.Animation.defaultSpring) {
                selectionMode = .custom
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                    .font(.Jakarta.semiBold(18))

                Text("自定义")
                    .font(.Jakarta.regular(12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(presetButtonBackground(isSelected: isSelected))
            .overlay(presetButtonBorder(isSelected: isSelected))
        }
        .foregroundStyle(isSelected ? AppTheme.Colors.primary : .primary)
    }

    // MARK: - Custom Input Section

    @ViewBuilder
    private var customInputSection: some View {
        if selectionMode == .custom {
            customInputField
        }
    }

    private var customInputField: some View {
        HStack(spacing: 8) {
            TextField("输入毫升数", text: $customAmount)
                .keyboardType(.numberPad)
                .font(.Jakarta.semiBold(20))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(Color(.secondarySystemBackground))
                )

            Text("mL")
                .font(.Jakarta.medium(16))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 40)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Current Amount Display

    private var currentAmountDisplay: some View {
        VStack(spacing: 4) {
            Text("\(effectiveAmount)")
                .font(.Jakarta.extraBold(40))
                .foregroundStyle(AppTheme.Colors.primary)
                .contentTransition(.numericText())

            Text("毫升")
                .font(.Jakarta.medium(14))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button {
            Task {
                await saveWaterLog()
            }
        } label: {
            HStack(spacing: 8) {
                recordButtonContent
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.primary)
            )
            .foregroundStyle(.white)
        }
        .disabled(!canRecord)
        .opacity(canRecord ? 1.0 : 0.5)
    }

    @ViewBuilder
    private var recordButtonContent: some View {
        if isSaving {
            ProgressView()
                .tint(.white)
        } else if isShowingSuccess {
            Image(systemName: "checkmark")
                .font(.Jakarta.bold(18))
        } else {
            Image(systemName: "drop.fill")
            Text("记录")
                .font(.Jakarta.bold(18))
        }
    }

    // MARK: - Computed Properties

    private var effectiveAmount: Int {
        switch selectionMode {
        case .preset(let amount):
            return amount
        case .custom:
            guard let value = Int(customAmount), value > 0 else { return 0 }
            return min(value, 5000)
        }
    }

    private var canRecord: Bool {
        !isSaving && effectiveAmount > 0
    }

    // MARK: - Private Methods

    private func startDropletAnimation() {
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            dropletScale = 1.1
            dropletOffset = -6
        }
    }

    private func saveWaterLog() async {
        let amount = effectiveAmount
        guard amount > 0 else { return }

        isSaving = true
        onConfirm(amount)

        isSaving = false
        isShowingSuccess = true

        try? await Task.sleep(for: .milliseconds(600))
        dismiss()
    }
}

#Preview {
    WaterTrackingSheet { _ in }
}
