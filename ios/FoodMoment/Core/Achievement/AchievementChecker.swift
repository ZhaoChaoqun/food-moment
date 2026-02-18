import Foundation
import SwiftData

/// 成就检测协议
///
/// 每种成就类型实现此协议，封装具体的解锁条件判断逻辑。
protocol AchievementChecker: Sendable {

    /// 该检测器对应的成就类型
    var achievementType: Achievement.AchievementType { get }

    /// 检测是否满足解锁条件
    /// - Parameter context: SwiftData 模型上下文
    /// - Returns: 满足条件时返回成就等级，否则返回 nil
    @MainActor
    func check(context: ModelContext) -> Achievement.Tier?
}

// MARK: - FirstGlimpseChecker

/// "初见食刻" 成就检测器
///
/// 条件：完成第 1 次拍照记录（MealRecord 表中至少有 1 条记录）
struct FirstGlimpseChecker: AchievementChecker {

    let achievementType = Achievement.AchievementType.firstGlimpse

    @MainActor
    func check(context: ModelContext) -> Achievement.Tier? {
        let descriptor = FetchDescriptor<MealRecord>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count >= 1 ? .gold : nil
    }
}
