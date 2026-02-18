import Foundation
import SwiftData
import SwiftUI

/// 成就记录模型
///
/// 存储用户获得的成就徽章，包括成就类型和等级。
/// 支持多种成就类型如连续打卡、特定目标达成等。
@Model
final class Achievement {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 成就类型（first_glimpse, weekly_streak 等）
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

    /// 成就维度分类
    enum AchievementCategory: String, CaseIterable, Codable, Sendable {
        case habit = "habit"
        case nutritionExplorer = "nutrition_explorer"
        case aesthetic = "aesthetic"
        case easterEgg = "easter_egg"

        var displayName: String {
            switch self {
            case .habit: return "习惯养成"
            case .nutritionExplorer: return "营养探索"
            case .aesthetic: return "摄影美学"
            case .easterEgg: return "隐藏彩蛋"
            }
        }

        var icon: String {
            switch self {
            case .habit: return "flame.fill"
            case .nutritionExplorer: return "magnifyingglass"
            case .aesthetic: return "camera.fill"
            case .easterEgg: return "sparkles"
            }
        }
    }

    /// 成就类型枚举
    enum AchievementType: String, CaseIterable, Codable, Sendable {
        // 维度一: 习惯养成
        case firstGlimpse = "first_glimpse"
        case weeklyStreak = "streak_7day"
        case perfectLoop = "perfect_loop"

        // 维度二: 营养探索
        case proteinHunter = "protein_hunter"
        case forestWalker = "forest_walker"
        case rainbowDiet = "rainbow_diet"
        case sugarController = "sugar_controller"

        // 维度三: 摄影美学
        case midnightDiner = "midnight_diner"
        case earlyBird = "early_bird"
        case foodEncyclopedia = "food_encyclopedia"

        // 维度四: 隐藏彩蛋
        case cheatDay = "cheat_day"
        case caffeineFix = "caffeine_fix"

        var displayName: String {
            switch self {
            case .firstGlimpse: return "初见食刻"
            case .weeklyStreak: return "七日连珠"
            case .perfectLoop: return "完美闭环"
            case .proteinHunter: return "蛋白质猎人"
            case .forestWalker: return "绿野仙踪"
            case .rainbowDiet: return "彩虹饮食"
            case .sugarController: return "控糖大师"
            case .midnightDiner: return "夜食记录者"
            case .earlyBird: return "晨光熹微"
            case .foodEncyclopedia: return "百科全书"
            case .cheatDay: return "欺骗餐日"
            case .caffeineFix: return "咖啡星人"
            }
        }

        var subtitle: String {
            switch self {
            case .firstGlimpse: return "First Glimpse"
            case .weeklyStreak: return "Weekly Streak"
            case .perfectLoop: return "Perfect Loop"
            case .proteinHunter: return "Protein Hunter"
            case .forestWalker: return "Forest Walker"
            case .rainbowDiet: return "Rainbow Diet"
            case .sugarController: return "Sugar Controller"
            case .midnightDiner: return "Midnight Diner"
            case .earlyBird: return "Early Bird"
            case .foodEncyclopedia: return "Food Encyclopedia"
            case .cheatDay: return "Cheat Day"
            case .caffeineFix: return "Caffeine Fix"
            }
        }

        var icon: String {
            switch self {
            case .firstGlimpse: return "camera.fill"
            case .weeklyStreak: return "flame.fill"
            case .perfectLoop: return "infinity"
            case .proteinHunter: return "shield.fill"
            case .forestWalker: return "leaf.fill"
            case .rainbowDiet: return "rainbow"
            case .sugarController: return "lock.fill"
            case .midnightDiner: return "moon.stars.fill"
            case .earlyBird: return "sunrise.fill"
            case .foodEncyclopedia: return "book.fill"
            case .cheatDay: return "circle.dotted"
            case .caffeineFix: return "cup.and.saucer.fill"
            }
        }

        var description: String {
            switch self {
            case .firstGlimpse: return "完成第1次拍照记录"
            case .weeklyStreak: return "连续7天每天记录至少3餐"
            case .perfectLoop: return "三大营养素误差在±5%以内"
            case .proteinHunter: return "累计摄入1000g优质蛋白"
            case .forestWalker: return "一周内记录10种绿色蔬菜"
            case .rainbowDiet: return "一天内记录5种颜色的食物"
            case .sugarController: return "连续7天碳水在目标范围内"
            case .midnightDiner: return "晚10点后记录低卡夜宵"
            case .earlyBird: return "连续5天8点前记录早餐"
            case .foodEncyclopedia: return "累计识别100种不同食材"
            case .cheatDay: return "健康6天后第7天超标20%"
            case .caffeineFix: return "累计识别50杯咖啡"
            }
        }

        var category: AchievementCategory {
            switch self {
            case .firstGlimpse, .weeklyStreak, .perfectLoop:
                return .habit
            case .proteinHunter, .forestWalker, .rainbowDiet, .sugarController:
                return .nutritionExplorer
            case .midnightDiner, .earlyBird, .foodEncyclopedia:
                return .aesthetic
            case .cheatDay, .caffeineFix:
                return .easterEgg
            }
        }

        var isHidden: Bool {
            category == .easterEgg
        }

        /// 对应 Assets.xcassets 中的图片名称
        var badgeAssetName: String {
            switch self {
            case .weeklyStreak:
                return "Badges/badge_weekly_streak"
            default:
                return "Badges/badge_\(rawValue)"
            }
        }

        /// 独有的视觉主题（3色渐变）
        var theme: BadgeTheme {
            switch self {
            case .firstGlimpse:
                return BadgeTheme(
                    primaryHex: "#13EC5B",
                    highlightHex: "#B8FFD0",
                    shadowHex: "#0A7A2E"
                )
            case .weeklyStreak:
                return BadgeTheme(
                    primaryHex: "#FF6B35",
                    highlightHex: "#FFD49A",
                    shadowHex: "#C23616"
                )
            case .perfectLoop:
                return BadgeTheme(
                    primaryHex: "#E8E8E8",
                    highlightHex: "#FFFFFF",
                    shadowHex: "#A0A0A0"
                )
            case .proteinHunter:
                return BadgeTheme(
                    primaryHex: "#4A90D9",
                    highlightHex: "#B8D4F0",
                    shadowHex: "#1C3D6E"
                )
            case .forestWalker:
                return BadgeTheme(
                    primaryHex: "#2ECC71",
                    highlightHex: "#A8FFD2",
                    shadowHex: "#1A7A42"
                )
            case .rainbowDiet:
                return BadgeTheme(
                    primaryHex: "#FF6B6B",
                    highlightHex: "#FFEAA7",
                    shadowHex: "#6C5CE7"
                )
            case .sugarController:
                return BadgeTheme(
                    primaryHex: "#74B9FF",
                    highlightHex: "#DFE6E9",
                    shadowHex: "#2D3436"
                )
            case .midnightDiner:
                return BadgeTheme(
                    primaryHex: "#A855F7",
                    highlightHex: "#E0C3FC",
                    shadowHex: "#581C87"
                )
            case .earlyBird:
                return BadgeTheme(
                    primaryHex: "#FBBF24",
                    highlightHex: "#FEF3C7",
                    shadowHex: "#D97706"
                )
            case .foodEncyclopedia:
                return BadgeTheme(
                    primaryHex: "#F59E0B",
                    highlightHex: "#FDE68A",
                    shadowHex: "#92400E"
                )
            case .cheatDay:
                return BadgeTheme(
                    primaryHex: "#FFD700",
                    highlightHex: "#FBF5B7",
                    shadowHex: "#D4AF37"
                )
            case .caffeineFix:
                return BadgeTheme(
                    primaryHex: "#8B6914",
                    highlightHex: "#D4A76A",
                    shadowHex: "#5C3D0E"
                )
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

// MARK: - Badge Theme

/// 徽章视觉主题配置
///
/// 每个徽章独有的3色渐变主题，模拟原型HTML中的金属/玻璃质感。
struct BadgeTheme: Sendable {
    /// 主色（对应 CSS from 色）
    let primaryHex: String
    /// 高光色（对应 CSS via 色，模拟金属反光）
    let highlightHex: String
    /// 阴影色（对应 CSS to 色，增加深度）
    let shadowHex: String

    var primaryColor: Color { Color(hex: primaryHex) }
    var highlightColor: Color { Color(hex: highlightHex) }
    var shadowColor: Color { Color(hex: shadowHex) }

    /// 三色线性渐变（模拟金属质感）
    var metalGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, highlightColor, shadowColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 外层背景淡色渐变
    var outerGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor.opacity(0.3), shadowColor.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 内层径向渐变（三色模拟金属球面反光）
    var innerRadialGradient: RadialGradient {
        RadialGradient(
            colors: [highlightColor, primaryColor, shadowColor],
            center: .center,
            startRadius: 2,
            endRadius: 34
        )
    }

    /// 边框渐变
    var borderGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, highlightColor, shadowColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
