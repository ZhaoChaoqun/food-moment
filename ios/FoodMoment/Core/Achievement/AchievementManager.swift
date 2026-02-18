import Foundation
import SwiftData

/// 成就管理器
///
/// 负责检测成就解锁条件、写入 SwiftData、触发弹窗队列。
@MainActor
@Observable
final class AchievementManager {

    // MARK: - Singleton

    static let shared = AchievementManager()

    // MARK: - Properties

    /// 已注册的成就检测器列表
    private let checkers: [AchievementChecker]

    /// 是否正在检测中（防止并发重入）
    private var isChecking = false

    // MARK: - Initialization

    private init() {
        self.checkers = [
            FirstGlimpseChecker(),
        ]
    }

    // MARK: - Public Methods

    /// 检测并解锁成就
    ///
    /// 遍历所有注册的检测器，对比已有记录，
    /// 将新解锁的成就写入 SwiftData 并加入弹窗队列。
    func checkAndUnlock(modelContext: ModelContext, appState: AppState) {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        let earnedTypes = fetchEarnedTypes(modelContext: modelContext)

        var newlyUnlocked: [AchievementItem] = []

        for checker in checkers {
            let typeRawValue = checker.achievementType.rawValue

            guard !earnedTypes.contains(typeRawValue) else { continue }

            guard let tier = checker.check(context: modelContext) else { continue }

            let achievement = Achievement(
                type: typeRawValue,
                tier: tier.rawValue,
                earnedAt: Date()
            )
            modelContext.insert(achievement)

            let achievementType = checker.achievementType
            let item = AchievementItem(
                type: typeRawValue,
                title: achievementType.displayName,
                subtitle: achievementType.subtitle,
                icon: achievementType.icon,
                tier: Self.mapTier(tier),
                isEarned: true,
                earnedDate: Date(),
                theme: achievementType.theme,
                category: achievementType.category,
                isHidden: achievementType.isHidden,
                description: achievementType.description,
                badgeAssetName: achievementType.badgeAssetName
            )

            newlyUnlocked.append(item)
        }

        if !newlyUnlocked.isEmpty {
            try? modelContext.save()

            for item in newlyUnlocked {
                appState.achievementUnlockQueue.append(item)
            }

            if appState.currentUnlockAchievement == nil {
                appState.showNextUnlockAchievement()
            }
        }
    }

    // MARK: - Private Methods

    private func fetchEarnedTypes(modelContext: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<Achievement>()
        let earned = (try? modelContext.fetch(descriptor)) ?? []
        return Set(earned.map { $0.type })
    }

    private static func mapTier(_ tier: Achievement.Tier) -> AchievementItem.AchievementTier {
        switch tier {
        case .gold: return .gold
        case .silver: return .silver
        case .bronze: return .bronze
        }
    }
}
