import SwiftData
import Foundation

enum PersistenceController {
    /// 创建 ModelContainer，配置所有数据模型
    static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            MealRecord.self,
            DetectedFood.self,
            WeightLog.self,
            WaterLog.self,
            Achievement.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// 用于预览和测试的内存数据库
    static func createPreviewContainer() -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            MealRecord.self,
            DetectedFood.self,
            WeightLog.self,
            WaterLog.self,
            Achievement.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }
}
