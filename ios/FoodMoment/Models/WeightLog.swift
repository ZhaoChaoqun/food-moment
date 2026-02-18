import Foundation
import SwiftData

/// 体重记录模型
///
/// 存储用户的体重测量记录，支持历史数据追踪和趋势分析。
@Model
final class WeightLog {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 体重（公斤）
    var weightKg: Double

    /// 记录时间
    var recordedAt: Date

    // MARK: - Metadata

    /// 创建时间
    var createdAt: Date = Date()

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        weightKg: Double,
        recordedAt: Date
    ) {
        self.id = id
        self.weightKg = weightKg
        self.recordedAt = recordedAt
    }
}

// MARK: - Computed Properties

extension WeightLog {

    /// 体重（磅）
    var weightLbs: Double {
        weightKg * 2.20462
    }

    /// 格式化的体重字符串（公斤）
    var formattedWeightKg: String {
        String(format: "%.1f kg", weightKg)
    }

    /// 格式化的记录日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: recordedAt)
    }
}
