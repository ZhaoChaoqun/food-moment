import Foundation
import SwiftData

/// 用户档案模型
///
/// 存储用户的基本信息和每日营养目标设置。
/// 支持 Pro 会员功能标识和目标体重追踪。
@Model
final class UserProfile {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 显示名称
    var displayName: String

    /// 邮箱地址
    var email: String?

    /// 头像 Asset 名称（本地图片）
    var avatarAssetName: String?

    /// 是否为 Pro 会员
    var isPro: Bool = false

    // MARK: - Daily Goals

    /// 每日卡路里目标
    var dailyCalorieGoal: Int = 2000

    /// 每日蛋白质目标（克）
    var dailyProteinGoal: Int = 50

    /// 每日碳水目标（克）
    var dailyCarbsGoal: Int = 250

    /// 每日脂肪目标（克）
    var dailyFatGoal: Int = 65

    /// 目标体重（公斤）
    var targetWeight: Double?

    // MARK: - Personal Info

    /// 性别（male/female/other）
    var gender: String?

    /// 出生年份
    var birthYear: Int?

    /// 身高（厘米）
    var heightCm: Double?

    /// 活动水平（sedentary/light/moderate/active/veryActive）
    var activityLevel: String?

    /// 头像远程 URL
    var avatarUrl: String?

    /// 头像本地缓存数据（外部存储）
    @Attribute(.externalStorage) var localAvatarData: Data?

    // MARK: - Lifestyle Goals

    /// 每日饮水目标（毫升）
    var dailyWaterGoal: Int = 2500

    /// 每日步数目标
    var dailyStepGoal: Int = 10000

    // MARK: - Metadata

    /// 创建时间
    var createdAt: Date = Date()

    /// 更新时间
    var updatedAt: Date = Date()

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        displayName: String,
        email: String? = nil,
        avatarAssetName: String? = nil,
        isPro: Bool = false,
        dailyCalorieGoal: Int = 2000,
        dailyProteinGoal: Int = 50,
        dailyCarbsGoal: Int = 250,
        dailyFatGoal: Int = 65,
        targetWeight: Double? = nil,
        gender: String? = nil,
        birthYear: Int? = nil,
        heightCm: Double? = nil,
        activityLevel: String? = nil,
        avatarUrl: String? = nil,
        localAvatarData: Data? = nil,
        dailyWaterGoal: Int = 2500,
        dailyStepGoal: Int = 10000
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.avatarAssetName = avatarAssetName
        self.isPro = isPro
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbsGoal = dailyCarbsGoal
        self.dailyFatGoal = dailyFatGoal
        self.targetWeight = targetWeight
        self.gender = gender
        self.birthYear = birthYear
        self.heightCm = heightCm
        self.activityLevel = activityLevel
        self.avatarUrl = avatarUrl
        self.localAvatarData = localAvatarData
        self.dailyWaterGoal = dailyWaterGoal
        self.dailyStepGoal = dailyStepGoal
    }
}

// MARK: - Computed Properties

extension UserProfile {

    /// 是否已设置目标体重
    var hasTargetWeight: Bool {
        targetWeight != nil
    }

    /// 总每日宏量营养素目标（克）
    var totalDailyMacrosGoal: Int {
        dailyProteinGoal + dailyCarbsGoal + dailyFatGoal
    }
}
