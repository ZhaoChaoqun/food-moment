import Foundation
import SwiftData

/// 饮水记录模型
///
/// 存储用户的饮水记录，支持每日饮水量追踪。
@Model
final class WaterLog {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 饮水量（毫升）
    var amountML: Int

    /// 记录时间
    var recordedAt: Date = Date()

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        amountML: Int,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.amountML = amountML
        self.recordedAt = recordedAt
    }
}

// MARK: - Computed Properties

extension WaterLog {

    /// 饮水量（升）
    var amountLiters: Double {
        Double(amountML) / 1000.0
    }

    /// 格式化的饮水量字符串
    var formattedAmount: String {
        if amountML >= 1000 {
            return String(format: "%.1f L", amountLiters)
        } else {
            return "\(amountML) ml"
        }
    }

    /// 格式化的记录时间
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: recordedAt)
    }
}
