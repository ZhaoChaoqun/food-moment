import SwiftUI
import SwiftData

/// 体重记录 Sheet 的独立宿主视图
///
/// 将 sheet 展示逻辑与 ProfileView 的 body 完全隔离：
/// - 当 `isShowing` 切换时，只有本视图会被重新评估
/// - ProfileView 的其他子组件（头像、成就、日历等）不会被触发重绘
/// - 解决 sheet 弹出时整个 ProfileView body 重新求值导致的严重卡顿
struct WeightSheetHost: View {

    let modelContext: ModelContext
    var onWeightSaved: (() -> Void)?

    @State private var isShowing = false

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                isShowing = true
            }
            .sheet(isPresented: $isShowing) {
                WeightInputSheet { weightKg in
                    await saveWeight(weightKg)
                }
            }
    }

    private func saveWeight(_ weightKg: Double) async {
        let now = Date()

        let weightLog = WeightLog(weightKg: weightKg, recordedAt: now)
        modelContext.insert(weightLog)
        try? modelContext.save()

        do {
            let _ = try await UserService.shared.logWeight(
                WeightLogCreateDTO(weightKg: weightKg, recordedAt: now)
            )
            weightLog.isSynced = true
            try? modelContext.save()
        } catch {}

        do {
            try await HealthKitManager.shared.saveWeight(
                kilograms: weightKg,
                date: now
            )
        } catch {}

        onWeightSaved?()
    }
}
