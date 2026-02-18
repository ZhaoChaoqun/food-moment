import XCTest
@testable import FoodMoment

/// Tests for DTO decoding
final class DTODecodingTests: XCTestCase {

    // MARK: - AnalysisResponseDTO Tests

    func test_AnalysisResponseDTO_decodesSuccessfully() throws {
        // Given
        let data = MockData.analysisResponseData
        let decoder = JSONDecoder()

        // When
        let result = try decoder.decode(AnalysisResponseDTO.self, from: data)

        // Then
        XCTAssertEqual(result.totalCalories, 485)
        XCTAssertEqual(result.imageUrl, "https://example.com/food.jpg")
    }

    func test_AnalysisResponseDTO_nutritionDecodesCorrectly() throws {
        // Given
        let data = MockData.analysisResponseData
        let decoder = JSONDecoder()

        // When
        let result = try decoder.decode(AnalysisResponseDTO.self, from: data)

        // Then
        XCTAssertEqual(result.totalNutrition.proteinG, 22)
        XCTAssertEqual(result.totalNutrition.carbsG, 45)
        XCTAssertEqual(result.totalNutrition.fatG, 18)
        XCTAssertEqual(result.totalNutrition.fiberG, 6)
    }

    func test_AnalysisResponseDTO_detectedFoodsCountCorrect() throws {
        // Given
        let data = MockData.analysisResponseData
        let decoder = JSONDecoder()

        // When
        let result = try decoder.decode(AnalysisResponseDTO.self, from: data)

        // Then
        XCTAssertEqual(result.detectedFoods.count, 2)
    }

    func test_AnalysisResponseDTO_firstFoodDetailsCorrect() throws {
        // Given
        let data = MockData.analysisResponseData
        let decoder = JSONDecoder()

        // When
        let result = try decoder.decode(AnalysisResponseDTO.self, from: data)
        let firstFood = result.detectedFoods[0]

        // Then
        XCTAssertEqual(firstFood.name, "Poached Egg")
        XCTAssertEqual(firstFood.nameZh, "水波蛋")
        XCTAssertEqual(firstFood.emoji, "🥚")
        XCTAssertEqual(firstFood.confidence, 0.95, accuracy: 0.01)
        XCTAssertEqual(firstFood.calories, 140)
    }

    func test_AnalysisResponseDTO_aiAnalysisPresent() throws {
        // Given
        let data = MockData.analysisResponseData
        let decoder = JSONDecoder()

        // When
        let result = try decoder.decode(AnalysisResponseDTO.self, from: data)

        // Then - aiAnalysis is non-optional in DTO
        XCTAssertTrue(result.aiAnalysis.contains("营养均衡"))
    }

    // MARK: - Invalid JSON Tests

    func test_AnalysisResponseDTO_invalidJSON_throwsError() {
        // Given
        let data = MockData.invalidJSONData
        let decoder = JSONDecoder()

        // When/Then
        XCTAssertThrowsError(try decoder.decode(AnalysisResponseDTO.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - BoundingBox Tests

    func test_BoundingBox_decodesCorrectly() throws {
        // Given
        let data = MockData.analysisResponseData
        let decoder = JSONDecoder()

        // When
        let result = try decoder.decode(AnalysisResponseDTO.self, from: data)
        let boundingBox = result.detectedFoods[0].boundingBox

        // Then
        XCTAssertEqual(boundingBox.x, 0.55, accuracy: 0.01)
        XCTAssertEqual(boundingBox.y, 0.15, accuracy: 0.01)
        XCTAssertEqual(boundingBox.w, 0.2, accuracy: 0.01)
        XCTAssertEqual(boundingBox.h, 0.15, accuracy: 0.01)
    }

    // MARK: - NutritionData Tests

    func test_NutritionDataDTO_allFieldsPresent() throws {
        // Given
        let json = """
        {
            "protein_g": 25.5,
            "carbs_g": 50.0,
            "fat_g": 15.5,
            "fiber_g": 8.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()

        // When
        let result = try decoder.decode(NutritionDataDTO.self, from: json)

        // Then
        XCTAssertEqual(result.proteinG, 25.5, accuracy: 0.01)
        XCTAssertEqual(result.carbsG, 50.0, accuracy: 0.01)
        XCTAssertEqual(result.fatG, 15.5, accuracy: 0.01)
        XCTAssertEqual(result.fiberG, 8.0, accuracy: 0.01)
    }

    // MARK: - Tags Tests

    func test_AnalysisResponseDTO_tagsDecodeCorrectly() throws {
        // Given
        let data = MockData.analysisResponseData
        let decoder = JSONDecoder()

        // When
        let result = try decoder.decode(AnalysisResponseDTO.self, from: data)

        // Then
        XCTAssertEqual(result.tags.count, 2)
        XCTAssertTrue(result.tags.contains("高蛋白"))
        XCTAssertTrue(result.tags.contains("优质脂肪"))
    }
}
