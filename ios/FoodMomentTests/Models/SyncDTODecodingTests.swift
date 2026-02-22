import XCTest
@testable import FoodMoment

/// 新增同步字段的 DTO 解码测试
/// 覆盖：MealResponseDTO.updatedAt、WaterLogResponseDTO 时间戳、WeightLogResponseDTO.updatedAt
final class SyncDTODecodingTests: XCTestCase {

    private lazy var decoder: JSONDecoder = .appSnakeCase

    // MARK: - MealResponseDTO with updatedAt

    func test_mealResponseDTO_decodesUpdatedAt() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "image_url": null,
            "meal_type": "lunch",
            "meal_time": "2025-01-15T12:30:00Z",
            "total_calories": 500,
            "protein_grams": 20.0,
            "carbs_grams": 50.0,
            "fat_grams": 15.0,
            "fiber_grams": 5.0,
            "title": "Test Lunch",
            "description_text": null,
            "ai_analysis": null,
            "tags": ["healthy"],
            "detected_foods": [],
            "created_at": "2025-01-15T12:00:00Z",
            "updated_at": "2025-01-15T13:00:00Z"
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(MealResponseDTO.self, from: json)

        XCTAssertEqual(dto.title, "Test Lunch")
        XCTAssertEqual(dto.totalCalories, 500)
        XCTAssertNotNil(dto.updatedAt, "updatedAt 应成功解码")

        // 验证 updatedAt 的值
        let expectedDate = ISO8601DateFormatter().date(from: "2025-01-15T13:00:00Z")!
        XCTAssertEqual(dto.updatedAt, expectedDate)
    }

    // MARK: - MealCreateDTO with id

    func test_mealCreateDTO_encodesClientID() throws {
        let id = UUID()
        let dto = MealCreateDTO(
            id: id,
            imageUrl: nil,
            mealType: "lunch",
            mealTime: Date(),
            totalCalories: 500,
            proteinGrams: 20,
            carbsGrams: 50,
            fatGrams: 15,
            fiberGrams: 5,
            title: "Test",
            descriptionText: nil,
            aiAnalysis: nil,
            tags: [],
            detectedFoods: []
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(dto)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(dict?["id"], "MealCreateDTO 应编码 id 字段")
        XCTAssertEqual(dict?["id"] as? String, id.uuidString.uppercased())
    }

    func test_mealCreateDTO_nilID_encodesNull() throws {
        let dto = MealCreateDTO(
            id: nil,
            imageUrl: nil,
            mealType: "lunch",
            mealTime: Date(),
            totalCalories: 500,
            proteinGrams: 20,
            carbsGrams: 50,
            fatGrams: 15,
            fiberGrams: 5,
            title: "Test",
            descriptionText: nil,
            aiAnalysis: nil,
            tags: [],
            detectedFoods: []
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(dto)
        let jsonString = String(data: data, encoding: .utf8) ?? ""

        // nil id 编码后应有 id 字段（null）
        XCTAssertTrue(jsonString.contains("\"id\""), "nil id 也应被编码")
    }

    // MARK: - WaterLogResponseDTO with timestamps

    func test_waterLogResponseDTO_decodesTimestamps() throws {
        let json = """
        {
            "id": "660e8400-e29b-41d4-a716-446655440001",
            "amount_ml": 250,
            "recorded_at": "2025-01-15T10:00:00Z",
            "created_at": "2025-01-15T10:00:00Z",
            "updated_at": "2025-01-15T10:05:00Z"
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(WaterLogResponseDTO.self, from: json)

        XCTAssertEqual(dto.amountMl, 250)
        XCTAssertNotNil(dto.createdAt, "createdAt 应成功解码")
        XCTAssertNotNil(dto.updatedAt, "updatedAt 应成功解码")
    }

    // MARK: - WeightLogResponseDTO with updatedAt

    func test_weightLogResponseDTO_decodesUpdatedAt() throws {
        let json = """
        {
            "id": "770e8400-e29b-41d4-a716-446655440002",
            "weight_kg": 68.5,
            "recorded_at": "2025-01-15T08:00:00Z",
            "created_at": "2025-01-15T08:00:00Z",
            "updated_at": "2025-01-15T08:10:00Z"
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(WeightLogResponseDTO.self, from: json)

        XCTAssertEqual(dto.weightKg, 68.5)
        XCTAssertNotNil(dto.updatedAt, "updatedAt 应成功解码")
    }

    // MARK: - DailyWaterResponseDTO

    func test_dailyWaterResponseDTO_decodesWithLogs() throws {
        let json = """
        {
            "date": "2025-01-15",
            "total_ml": 1500,
            "goal_ml": 2000,
            "logs": [
                {
                    "id": "880e8400-e29b-41d4-a716-446655440003",
                    "amount_ml": 500,
                    "recorded_at": "2025-01-15T09:00:00Z",
                    "created_at": "2025-01-15T09:00:00Z",
                    "updated_at": "2025-01-15T09:00:00Z"
                },
                {
                    "id": "990e8400-e29b-41d4-a716-446655440004",
                    "amount_ml": 1000,
                    "recorded_at": "2025-01-15T14:00:00Z",
                    "created_at": "2025-01-15T14:00:00Z",
                    "updated_at": "2025-01-15T14:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(DailyWaterResponseDTO.self, from: json)

        XCTAssertEqual(dto.totalMl, 1500)
        XCTAssertEqual(dto.goalMl, 2000)
        XCTAssertEqual(dto.logs.count, 2)
        XCTAssertEqual(dto.logs[0].amountMl, 500)
        XCTAssertEqual(dto.logs[1].amountMl, 1000)
    }
}
