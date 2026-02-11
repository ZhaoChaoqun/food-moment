import SwiftUI
import SwiftData
import UIKit
import os

@MainActor
@Observable
final class AnalysisViewModel {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "AnalysisViewModel")

    // MARK: - Input

    let capturedImage: UIImage
    var analysisResponse: AnalysisResponseDTO?

    // MARK: - State

    var isAnalyzing: Bool = false
    var analysisResult: AnalysisResponseDTO?
    var errorMessage: String?
    var showNutritionDetail: Bool = false
    var isMealSaved: Bool = false
    var isSavingToHealthKit: Bool = false
    var healthKitSaveError: String?

    // MARK: - Edit State

    var selectedFoodIndex: Int?
    var isEditingFood: Bool = false
    var editedFoodName: String = ""
    var editedFoodCalories: String = ""
    var editedFoodPortion: String = "1"

    // MARK: - Init

    init(capturedImage: UIImage, analysisResponse: AnalysisResponseDTO? = nil) {
        self.capturedImage = capturedImage
        self.analysisResponse = analysisResponse
    }

    // MARK: - Computed

    /// Total calories computed from detected foods
    var computedTotalCalories: Int {
        guard let result = analysisResult else { return 0 }
        return result.detectedFoods.reduce(0) { $0 + $1.calories }
    }

    /// Total nutrition computed from detected foods
    var computedNutrition: NutritionDataDTO {
        guard let result = analysisResult else {
            return NutritionDataDTO(proteinG: 0, carbsG: 0, fatG: 0, fiberG: 0)
        }
        let protein = result.detectedFoods.reduce(0.0) { $0 + $1.proteinGrams }
        let carbs = result.detectedFoods.reduce(0.0) { $0 + $1.carbsGrams }
        let fat = result.detectedFoods.reduce(0.0) { $0 + $1.fatGrams }
        return NutritionDataDTO(proteinG: protein, carbsG: carbs, fatG: fat, fiberG: result.totalNutrition.fiberG)
    }

    // MARK: - Analyze Food

    /// Calls APIClient to upload image for analysis.
    func analyzeFood() async {
        guard !isAnalyzing else { return }  // 防止重复调用

        isAnalyzing = true
        errorMessage = nil

        Self.logger.debug("========== 开始食物分析 ==========")
        Self.logger.debug("API URL: \(APIEndpoint.analyzeFood.url, privacy: .public)")
        Self.logger.debug("原始图片尺寸: \(self.capturedImage.size.width, privacy: .public) x \(self.capturedImage.size.height, privacy: .public)")
        Self.logger.debug("原始图片方向: \(self.capturedImage.imageOrientation.rawValue, privacy: .public)")
        Self.logger.debug("原始图片 scale: \(self.capturedImage.scale, privacy: .public)")

        do {
            guard let imageData = capturedImage.jpegData(compressionQuality: 0.8) else {
                Self.logger.error("ERROR: jpegData 返回 nil，无法转换图片")
                errorMessage = "无法处理图片"
                isAnalyzing = false
                return
            }

            let imageSizeKB = Double(imageData.count) / 1024.0
            Self.logger.debug("JPEG 数据大小: \(String(format: "%.1f", imageSizeKB), privacy: .public) KB (\(imageData.count, privacy: .public) bytes)")
            Self.logger.debug("压缩质量: 0.8")

            // 验证 JPEG 数据头部（JPEG magic bytes: FF D8 FF）
            if imageData.count >= 3 {
                let header = imageData.prefix(3).map { String(format: "%02X", $0) }.joined(separator: " ")
                Self.logger.debug("JPEG 文件头: \(header, privacy: .public) (期望: FF D8 FF)")
            }

            Self.logger.debug("正在调用 API 上传图片...")
            let startTime = CFAbsoluteTimeGetCurrent()

            let response: AnalysisResponseDTO = try await APIClient.shared.upload(
                .analyzeFood,
                imageData: imageData
            )

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            Self.logger.debug("========== API 响应成功 ==========")
            Self.logger.debug("耗时: \(String(format: "%.2f", elapsed), privacy: .public)s")
            Self.logger.debug("总热量: \(response.totalCalories, privacy: .public) kcal")
            Self.logger.debug("识别到 \(response.detectedFoods.count, privacy: .public) 种食物:")
            for (i, food) in response.detectedFoods.enumerated() {
                Self.logger.debug("  [\(i, privacy: .public)] \(food.emoji, privacy: .public) \(food.name, privacy: .public) (\(food.nameZh, privacy: .public))")
                Self.logger.debug("      置信度: \(String(format: "%.2f", food.confidence), privacy: .public)")
                Self.logger.debug("      热量: \(food.calories, privacy: .public) kcal")
                Self.logger.debug("      蛋白质: \(String(format: "%.1f", food.proteinGrams), privacy: .public)g, 碳水: \(String(format: "%.1f", food.carbsGrams), privacy: .public)g, 脂肪: \(String(format: "%.1f", food.fatGrams), privacy: .public)g")
                Self.logger.debug("      边界框: x=\(String(format: "%.3f", food.boundingBox.x), privacy: .public) y=\(String(format: "%.3f", food.boundingBox.y), privacy: .public) w=\(String(format: "%.3f", food.boundingBox.w), privacy: .public) h=\(String(format: "%.3f", food.boundingBox.h), privacy: .public)")
                Self.logger.debug("      颜色: \(food.color, privacy: .public)")
            }
            Self.logger.debug("总营养: 蛋白质=\(String(format: "%.1f", response.totalNutrition.proteinG), privacy: .public)g 碳水=\(String(format: "%.1f", response.totalNutrition.carbsG), privacy: .public)g 脂肪=\(String(format: "%.1f", response.totalNutrition.fatG), privacy: .public)g 纤维=\(String(format: "%.1f", response.totalNutrition.fiberG), privacy: .public)g")
            Self.logger.debug("AI分析: \(response.aiAnalysis, privacy: .public)")
            Self.logger.debug("标签: \(response.tags, privacy: .public)")
            Self.logger.debug("====================================")

            if !Task.isCancelled {
                analysisResult = response
                isAnalyzing = false
            }
        } catch {
            Self.logger.error("========== API 请求失败 ==========")
            Self.logger.error("错误类型: \(String(describing: type(of: error)), privacy: .public)")
            Self.logger.error("错误描述: \(String(describing: error), privacy: .public)")
            Self.logger.error("本地化描述: \(error.localizedDescription, privacy: .public)")
            Self.logger.error("====================================")
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
                isAnalyzing = false
            }
        }
    }

    // MARK: - Edit Food

    /// Opens the edit sheet for a specific food item
    func startEditingFood(at index: Int) {
        guard let result = analysisResult, index < result.detectedFoods.count else { return }
        let food = result.detectedFoods[index]
        selectedFoodIndex = index
        editedFoodName = food.name
        editedFoodCalories = "\(food.calories)"
        editedFoodPortion = "1"
        isEditingFood = true
    }

    /// Saves the edited food item
    func saveEditedFood() {
        guard let index = selectedFoodIndex,
              let result = analysisResult,
              index < result.detectedFoods.count else {
            isEditingFood = false
            return
        }

        let newCalories = Int(editedFoodCalories) ?? result.detectedFoods[index].calories
        let portionMultiplier = Double(editedFoodPortion) ?? 1.0
        let originalFood = result.detectedFoods[index]

        // Create updated food with new values
        let updatedFood = DetectedFoodDTO(
            name: editedFoodName,
            nameZh: originalFood.nameZh,
            emoji: originalFood.emoji,
            confidence: originalFood.confidence,
            boundingBox: originalFood.boundingBox,
            calories: Int(Double(newCalories) * portionMultiplier),
            proteinGrams: originalFood.proteinGrams * portionMultiplier,
            carbsGrams: originalFood.carbsGrams * portionMultiplier,
            fatGrams: originalFood.fatGrams * portionMultiplier,
            color: originalFood.color
        )

        // Update the foods array
        var updatedFoods = result.detectedFoods
        updatedFoods[index] = updatedFood

        // Recalculate totals
        let totalCal = updatedFoods.reduce(0) { $0 + $1.calories }
        let totalProtein = updatedFoods.reduce(0.0) { $0 + $1.proteinGrams }
        let totalCarbs = updatedFoods.reduce(0.0) { $0 + $1.carbsGrams }
        let totalFat = updatedFoods.reduce(0.0) { $0 + $1.fatGrams }

        // Create updated result
        analysisResult = AnalysisResponseDTO(
            imageUrl: result.imageUrl,
            totalCalories: totalCal,
            totalNutrition: NutritionDataDTO(
                proteinG: totalProtein,
                carbsG: totalCarbs,
                fatG: totalFat,
                fiberG: result.totalNutrition.fiberG
            ),
            detectedFoods: updatedFoods,
            aiAnalysis: result.aiAnalysis,
            tags: result.tags
        )

        isEditingFood = false
        selectedFoodIndex = nil
    }

    /// Cancels the edit operation
    func cancelEditingFood() {
        isEditingFood = false
        selectedFoodIndex = nil
        editedFoodName = ""
        editedFoodCalories = ""
        editedFoodPortion = "1"
    }

    // MARK: - Save Meal

    /// Creates a MealRecord via API first, then saves to SwiftData cache.
    /// Falls back to local-only save if API is unavailable.
    func saveMeal(modelContext: ModelContext, appState: AppState) {
        guard let result = analysisResult else { return }

        let imageData = capturedImage.jpegData(compressionQuality: 0.8)
        let mealType = Self.inferMealType(from: Date())

        // Build API DTO
        let createDTO = MealCreateDTO(
            imageUrl: result.imageUrl,
            mealType: mealType.rawValue,
            mealTime: Date(),
            totalCalories: result.totalCalories,
            proteinGrams: result.totalNutrition.proteinG,
            carbsGrams: result.totalNutrition.carbsG,
            fatGrams: result.totalNutrition.fatG,
            fiberGrams: result.totalNutrition.fiberG,
            title: Self.generateMealTitle(from: result.detectedFoods),
            descriptionText: nil,
            aiAnalysis: result.aiAnalysis,
            tags: result.tags,
            detectedFoods: result.detectedFoods.map { food in
                DetectedFoodCreateDTO(
                    name: food.name,
                    nameZh: food.nameZh,
                    emoji: food.emoji,
                    confidence: food.confidence,
                    boundingBoxX: food.boundingBox.x,
                    boundingBoxY: food.boundingBox.y,
                    boundingBoxW: food.boundingBox.w,
                    boundingBoxH: food.boundingBox.h,
                    calories: food.calories,
                    proteinGrams: food.proteinGrams,
                    carbsGrams: food.carbsGrams,
                    fatGrams: food.fatGrams
                )
            }
        )

        Task {
            var isSynced = false
            var mealId: UUID? = nil

            // 尝试 API 优先
            do {
                let response = try await MealService.shared.createMeal(createDTO)
                isSynced = true
                mealId = response.id
            } catch {
                Self.logger.warning("API save failed, saving locally: \(error.localizedDescription, privacy: .public)")
            }

            // 写入 SwiftData 缓存
            let meal = MealRecord(
                mealType: mealType.rawValue,
                mealTime: Date(),
                title: Self.generateMealTitle(from: result.detectedFoods),
                totalCalories: result.totalCalories,
                proteinGrams: result.totalNutrition.proteinG,
                carbsGrams: result.totalNutrition.carbsG,
                fatGrams: result.totalNutrition.fatG,
                fiberGrams: result.totalNutrition.fiberG,
                aiAnalysis: result.aiAnalysis,
                tags: result.tags,
                imageURL: result.imageUrl,
                localImageData: imageData
            )
            if let mealId {
                meal.id = mealId
            }
            meal.isSynced = isSynced

            modelContext.insert(meal)

            for foodDTO in result.detectedFoods {
                let detectedFood = DetectedFood(
                    name: foodDTO.name,
                    nameZh: foodDTO.nameZh,
                    emoji: foodDTO.emoji,
                    confidence: foodDTO.confidence,
                    boundingBoxX: foodDTO.boundingBox.x,
                    boundingBoxY: foodDTO.boundingBox.y,
                    boundingBoxW: foodDTO.boundingBox.w,
                    boundingBoxH: foodDTO.boundingBox.h,
                    calories: foodDTO.calories,
                    proteinGrams: foodDTO.proteinGrams,
                    carbsGrams: foodDTO.carbsGrams,
                    fatGrams: foodDTO.fatGrams
                )
                detectedFood.mealRecord = meal
                modelContext.insert(detectedFood)
            }

            do {
                try modelContext.save()

                AchievementManager.shared.checkAndUnlock(
                    modelContext: modelContext,
                    appState: appState
                )

                Task {
                    await writeToHealthKit(result: result)
                }

                if !isSynced {
                    Task {
                        await SyncManager.shared.syncPendingRecords(modelContext: modelContext)
                    }
                }

                isMealSaved = true
            } catch {
                errorMessage = "Failed to save meal: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - HealthKit Integration

    /// Writes nutrition data to HealthKit
    private func writeToHealthKit(result: AnalysisResponseDTO) async {
        isSavingToHealthKit = true
        defer { isSavingToHealthKit = false }

        do {
            try await HealthKitManager.shared.saveNutrition(
                calories: Double(result.totalCalories),
                protein: result.totalNutrition.proteinG,
                carbs: result.totalNutrition.carbsG,
                fat: result.totalNutrition.fatG,
                date: Date()
            )
        } catch {
            healthKitSaveError = error.localizedDescription
            Self.logger.error("HealthKit write failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Share Image Generation

    /// Generates a shareable image of the analysis result
    @MainActor
    func generateShareImage() -> UIImage? {
        guard let result = analysisResult else { return nil }

        let renderer = ImageRenderer(content: ShareableAnalysisView(
            image: capturedImage,
            totalCalories: result.totalCalories,
            nutrition: result.totalNutrition,
            foods: result.detectedFoods
        ))

        renderer.scale = UIScreen.main.scale

        return renderer.uiImage
    }

    // MARK: - Mock Data (Preview only)

    /// Returns a simulated analysis result for UI development.
    static func mockAnalysis() -> AnalysisResponseDTO {
        AnalysisResponseDTO(
            imageUrl: "",
            totalCalories: 485,
            totalNutrition: NutritionDataDTO(
                proteinG: 22,
                carbsG: 45,
                fatG: 18,
                fiberG: 6
            ),
            detectedFoods: [
                DetectedFoodDTO(
                    name: "Poached Egg",
                    nameZh: "水煮蛋",
                    emoji: "\u{1F95A}",
                    confidence: 0.95,
                    boundingBox: BoundingBoxDTO(x: 0.15, y: 0.25, w: 0.25, h: 0.2),
                    calories: 140,
                    proteinGrams: 12,
                    carbsGrams: 1,
                    fatGrams: 10,
                    color: "#4ADE80"
                ),
                DetectedFoodDTO(
                    name: "Avocado",
                    nameZh: "牛油果",
                    emoji: "\u{1F951}",
                    confidence: 0.92,
                    boundingBox: BoundingBoxDTO(x: 0.55, y: 0.20, w: 0.3, h: 0.25),
                    calories: 160,
                    proteinGrams: 2,
                    carbsGrams: 9,
                    fatGrams: 15,
                    color: "#FACC15"
                ),
                DetectedFoodDTO(
                    name: "Toast",
                    nameZh: "吐司",
                    emoji: "\u{1F35E}",
                    confidence: 0.88,
                    boundingBox: BoundingBoxDTO(x: 0.30, y: 0.55, w: 0.35, h: 0.2),
                    calories: 185,
                    proteinGrams: 8,
                    carbsGrams: 35,
                    fatGrams: 2,
                    color: "#FB923C"
                )
            ],
            aiAnalysis: "A well-balanced breakfast with good protein from the poached egg and healthy fats from avocado. The toast provides sustained energy through complex carbohydrates. Consider adding leafy greens for extra vitamins and fiber.",
            tags: ["High Protein", "Healthy Fats", "Balanced"]
        )
    }

    // MARK: - Meal Time Configuration

    /// 餐次时间范围配置
    private enum MealTimeRange {
        static let breakfastStart = 5
        static let breakfastEnd = 11
        static let lunchEnd = 14
        static let snackEnd = 17
    }

    // MARK: - Helpers

    /// Infers the meal type based on the current time of day.
    private static func inferMealType(from date: Date) -> MealRecord.MealType {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case MealTimeRange.breakfastStart..<MealTimeRange.breakfastEnd:
            return .breakfast
        case MealTimeRange.breakfastEnd..<MealTimeRange.lunchEnd:
            return .lunch
        case MealTimeRange.lunchEnd..<MealTimeRange.snackEnd:
            return .snack
        default:
            return .dinner
        }
    }

    /// Generates a readable title from the list of detected foods.
    private static func generateMealTitle(from foods: [DetectedFoodDTO]) -> String {
        let names = foods.map { $0.name }
        switch names.count {
        case 0:
            return "Meal"
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) & \(names[1])"
        default:
            return "\(names[0]), \(names[1]) & more"
        }
    }
}

// MARK: - Shareable Analysis View

/// A view designed for ImageRenderer to generate a shareable image
struct ShareableAnalysisView: View {
    let image: UIImage
    let totalCalories: Int
    let nutrition: NutritionDataDTO
    let foods: [DetectedFoodDTO]

    var body: some View {
        VStack(spacing: 0) {
            // Food image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 390, height: 300)
                .clipped()

            // Stats section
            VStack(spacing: 16) {
                // Total calories
                VStack(spacing: 4) {
                    Text("TOTAL ENERGY")
                        .font(.Jakarta.medium(11))
                        .foregroundColor(.gray)
                        .tracking(1.5)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(totalCalories)")
                            .font(.Jakarta.bold(42))
                            .foregroundColor(.black)

                        Text("kcal")
                            .font(.Jakarta.medium(16))
                            .foregroundColor(.gray)
                    }
                }

                // Macros row
                HStack(spacing: 32) {
                    macroItem(value: nutrition.proteinG, label: "蛋白质", color: Color(hex: "#4ADE80"))
                    macroItem(value: nutrition.carbsG, label: "碳水", color: Color(hex: "#FACC15"))
                    macroItem(value: nutrition.fatG, label: "脂肪", color: Color(hex: "#FB923C"))
                }

                // Foods list
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(foods, id: \.name) { food in
                        HStack(spacing: 8) {
                            Text(food.emoji)
                                .font(.Jakarta.regular(16))
                            Text(food.name)
                                .font(.Jakarta.medium(14))
                                .foregroundColor(.black)
                            Spacer()
                            Text("\(food.calories) kcal")
                                .font(.Jakarta.medium(14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Branding
                HStack(spacing: 6) {
                    Text("由")
                        .font(.Jakarta.regular(12))
                        .foregroundColor(.gray)
                    Text("食刻")
                        .font(.Jakarta.bold(12))
                        .foregroundColor(AppTheme.Colors.primary)
                    Text("记录")
                        .font(.Jakarta.regular(12))
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(Color.white)
        }
        .frame(width: 390)
        .background(Color.white)
    }

    private func macroItem(value: Double, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(Int(value))g")
                .font(.Jakarta.bold(16))
                .foregroundColor(.black)
            Text(label)
                .font(.Jakarta.medium(11))
                .foregroundColor(.gray)
        }
    }
}
