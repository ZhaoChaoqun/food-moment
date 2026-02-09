import Foundation
import SwiftData

/// 成就记录模型
///
/// 存储用户获得的成就徽章，包括成就类型和等级。
/// 支持多种成就类型如连续打卡、特定目标达成等。
@Model
final class Achievement {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 成就类型（streak_7day, veggie_king, early_bird 等）
    var type: String

    /// 成就等级（gold, silver, bronze）
    var tier: String

    /// 获得时间
    var earnedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        type: String,
        tier: String,
        earnedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.tier = tier
        self.earnedAt = earnedAt
    }

    // MARK: - Nested Types

    /// 成就类型枚举
    enum AchievementType: String, CaseIterable, Codable, Sendable {
        case streak7Day = "streak_7day"
        case streak30Day = "streak_30day"
        case earlyBird = "early_bird"
        case nightOwl = "night_owl"
        case veggieKing = "veggie_king"
        case proteinChamp = "protein_champ"
        case waterHero = "water_hero"
        case firstMeal = "first_meal"
        case century = "century_meals"

        var displayName: String {
            switch self {
            case .streak7Day: return "连续7天"
            case .streak30Day: return "连续30天"
            case .earlyBird: return "早起打卡"
            case .nightOwl: return "夜猫子"
            case .veggieKing: return "蔬菜达人"
            case .proteinChamp: return "蛋白质冠军"
            case .waterHero: return "饮水英雄"
            case .firstMeal: return "第一餐"
            case .century: return "百餐成就"
            }
        }

        var icon: String {
            switch self {
            case .streak7Day: return "flame.fill"
            case .streak30Day: return "flame.circle.fill"
            case .earlyBird: return "sunrise.fill"
            case .nightOwl: return "moon.stars.fill"
            case .veggieKing: return "leaf.fill"
            case .proteinChamp: return "dumbbell.fill"
            case .waterHero: return "drop.fill"
            case .firstMeal: return "fork.knife"
            case .century: return "star.fill"
            }
        }
    }

    /// 等级枚举
    enum Tier: String, CaseIterable, Codable, Sendable {
        case bronze
        case silver
        case gold

        var displayName: String {
            switch self {
            case .bronze: return "铜牌"
            case .silver: return "银牌"
            case .gold: return "金牌"
            }
        }

        /// 等级对应的颜色十六进制值
        var colorHex: String {
            switch self {
            case .bronze: return "#CD7F32"
            case .silver: return "#C0C0C0"
            case .gold: return "#FFD700"
            }
        }
    }
}

// MARK: - Computed Properties

extension Achievement {

    /// 获取成就类型枚举值
    var achievementTypeEnum: AchievementType? {
        AchievementType(rawValue: type)
    }

    /// 获取等级枚举值
    var tierEnum: Tier? {
        Tier(rawValue: tier)
    }

    /// 成就显示名称
    var displayName: String {
        achievementTypeEnum?.displayName ?? type
    }

    /// 成就图标
    var icon: String {
        achievementTypeEnum?.icon ?? "star.fill"
    }

    /// 等级显示名称
    var tierDisplayName: String {
        tierEnum?.displayName ?? tier
    }

    /// 格式化的获得日期
    var formattedEarnedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: earnedAt)
    }
}
