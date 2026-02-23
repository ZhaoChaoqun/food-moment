import Foundation
import SwiftData
import UIKit
import os

// MARK: - Edit Profile View Model

@MainActor
@Observable
final class EditProfileViewModel {

    // MARK: - Logger

    private static let logger = Logger(subsystem: "com.foodmoment", category: "EditProfileViewModel")

    // MARK: - Constants

    static let maxNicknameLength = 16

    // MARK: - Enums

    enum Gender: String, CaseIterable, Identifiable {
        case male, female, other

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .male: return "男"
            case .female: return "女"
            case .other: return "其他"
            }
        }
    }

    enum ActivityLevel: String, CaseIterable, Identifiable {
        case sedentary, light, moderate, active, veryActive

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .sedentary: return "久坐"
            case .light: return "轻度活动"
            case .moderate: return "中度活动"
            case .active: return "高强度"
            case .veryActive: return "专业运动员"
            }
        }

        var description: String {
            switch self {
            case .sedentary: return "办公室工作，很少运动"
            case .light: return "每周运动 1-3 天"
            case .moderate: return "每周运动 3-5 天"
            case .active: return "每周运动 6-7 天"
            case .veryActive: return "每日高强度训练"
            }
        }

        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .light: return 1.375
            case .moderate: return 1.55
            case .active: return 1.725
            case .veryActive: return 1.9
            }
        }
    }

    private enum SaveState {
        case idle, saving, success
    }

    // MARK: - Editable State

    var displayName: String = ""
    var gender: Gender?
    var birthDate: Date?
    var heightCm: Double?
    var activityLevel: ActivityLevel?
    var targetWeight: Double?
    var dailyCalorieGoal: Int = 2000
    var dailyProteinGoal: Int = 50
    var dailyCarbsGoal: Int = 250
    var dailyFatGoal: Int = 65
    var dailyWaterGoal: Int = 2500
    var dailyStepGoal: Int = 10000

    // MARK: - Avatar State

    var selectedImage: UIImage?
    var avatarUrl: String?
    var localAvatarData: Data?
    var isShowingImagePicker: Bool = false

    // MARK: - UI State

    private var saveState: SaveState = .idle
    var autoDistributeMacros: Bool = true

    var isSaving: Bool { saveState == .saving }
    var isSaveSuccess: Bool { saveState == .success }
    var canSave: Bool { saveState == .idle && !displayName.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Picker Expansion State

    var isBirthDateExpanded: Bool = false
    var isHeightExpanded: Bool = false
    var isTargetWeightExpanded: Bool = false
    var isActivityLevelExpanded: Bool = false

    /// 收起除 `except` 以外的所有 Picker
    func collapseAllPickers(except: String? = nil) {
        if except != "birthDate" { isBirthDateExpanded = false }
        if except != "height" { isHeightExpanded = false }
        if except != "targetWeight" { isTargetWeightExpanded = false }
        if except != "activityLevel" { isActivityLevelExpanded = false }
    }

    // MARK: - Wheel Picker Bindings (Height)

    var heightInteger: Int {
        get { Int(heightCm ?? 170) }
        set {
            let dec = heightCm.map { Int(($0 * 10).truncatingRemainder(dividingBy: 10)) } ?? 0
            heightCm = Double(newValue) + Double(dec) * 0.1
        }
    }

    var heightDecimal: Int {
        get {
            guard let h = heightCm else { return 0 }
            return Int((h * 10).rounded(.down).truncatingRemainder(dividingBy: 10))
        }
        set { heightCm = Double(heightInteger) + Double(newValue) * 0.1 }
    }

    // MARK: - Wheel Picker Bindings (Target Weight)

    var targetWeightInteger: Int {
        get { Int(targetWeight ?? 65) }
        set {
            let dec = targetWeight.map { Int(($0 * 10).truncatingRemainder(dividingBy: 10)) } ?? 0
            targetWeight = Double(newValue) + Double(dec) * 0.1
        }
    }

    var targetWeightDecimal: Int {
        get {
            guard let w = targetWeight else { return 0 }
            return Int((w * 10).rounded(.down).truncatingRemainder(dividingBy: 10))
        }
        set { targetWeight = Double(targetWeightInteger) + Double(newValue) * 0.1 }
    }

    // MARK: - TDEE

    var currentWeight: Double?

    // MARK: - Private

    private let userService: UserServiceProtocol
    private let profileId: UUID?

    // MARK: - Initialization

    init(userProfile: UserProfile?, userService: UserServiceProtocol = UserService.shared) {
        self.userService = userService
        self.profileId = userProfile?.id

        if let profile = userProfile {
            displayName = profile.displayName
            avatarUrl = profile.avatarUrl
            localAvatarData = profile.localAvatarData
            dailyCalorieGoal = profile.dailyCalorieGoal
            dailyProteinGoal = profile.dailyProteinGoal
            dailyCarbsGoal = profile.dailyCarbsGoal
            dailyFatGoal = profile.dailyFatGoal
            targetWeight = profile.targetWeight
            dailyWaterGoal = profile.dailyWaterGoal
            dailyStepGoal = profile.dailyStepGoal

            if let g = profile.gender {
                gender = Gender(rawValue: g)
            }
            // 优先使用 birthDate，兼容旧 birthYear
            if let bd = profile.birthDate {
                birthDate = bd
            } else if let by = profile.birthYear {
                birthDate = Calendar.current.date(from: DateComponents(year: by, month: 7, day: 1))
            }
            heightCm = profile.heightCm
            if let al = profile.activityLevel {
                activityLevel = ActivityLevel(rawValue: al)
            }
        }
    }

    // MARK: - TDEE Calculation (Mifflin-St Jeor)

    var recommendedCalories: Int? {
        guard let gender,
              let birthDate,
              let heightCm,
              let weight = currentWeight, weight > 0,
              let activityLevel else { return nil }

        let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: Date())
        let age = Double(ageComponents.year ?? 0)
        guard age > 0 && age < 120 else { return nil }

        let bmr: Double
        switch gender {
        case .male:
            bmr = 10.0 * weight + 6.25 * heightCm - 5.0 * age + 5.0
        case .female:
            bmr = 10.0 * weight + 6.25 * heightCm - 5.0 * age - 161.0
        case .other:
            bmr = 10.0 * weight + 6.25 * heightCm - 5.0 * age - 78.0
        }

        return Int(round(bmr * activityLevel.multiplier))
    }

    // MARK: - Macro Distribution

    func applyRecommendedCalories() {
        guard let recommended = recommendedCalories else { return }
        dailyCalorieGoal = recommended
        if autoDistributeMacros {
            distributeMacros()
        }
    }

    func distributeMacros() {
        dailyProteinGoal = Int(round(Double(dailyCalorieGoal) * 0.30 / 4.0))
        dailyCarbsGoal = Int(round(Double(dailyCalorieGoal) * 0.50 / 4.0))
        dailyFatGoal = Int(round(Double(dailyCalorieGoal) * 0.20 / 9.0))
    }

    func onCalorieGoalChanged() {
        if autoDistributeMacros {
            distributeMacros()
        }
    }

    // MARK: - Load Current Weight

    func loadCurrentWeight() async {
        do {
            if let weight = try await HealthKitManager.shared.fetchLatestWeight() {
                currentWeight = weight
            }
        } catch {
            Self.logger.debug("[EditProfile] HealthKit weight unavailable: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Save

    func save(modelContext: ModelContext) async -> Bool {
        saveState = .saving

        // 1. Upload avatar if selected
        var newAvatarUrl = avatarUrl
        var newLocalAvatarData: Data?
        if let image = selectedImage {
            let resized = Self.resizeForUpload(image, maxDimension: 512)
            if let data = resized.jpegData(compressionQuality: 0.7) {
                newLocalAvatarData = data
                do {
                    let response = try await userService.uploadAvatar(imageData: data)
                    newAvatarUrl = response.avatarUrl
                } catch {
                    Self.logger.error("[EditProfile] Avatar upload failed: \(error.localizedDescription, privacy: .public)")
                    saveState = .idle
                    return false
                }
            }
        }

        // 2. Update profile via API
        let update = UserProfileUpdateDTO(
            displayName: displayName,
            avatarUrl: newAvatarUrl,
            dailyCalorieGoal: dailyCalorieGoal,
            dailyProteinGoal: dailyProteinGoal,
            dailyCarbsGoal: dailyCarbsGoal,
            dailyFatGoal: dailyFatGoal,
            targetWeight: targetWeight,
            gender: gender?.rawValue,
            birthYear: birthDate.map { Calendar.current.component(.year, from: $0) },
            birthDate: birthDate,
            heightCm: heightCm,
            activityLevel: activityLevel?.rawValue,
            dailyWaterGoal: dailyWaterGoal,
            dailyStepGoal: dailyStepGoal
        )

        do {
            let _ = try await userService.updateProfile(update)
        } catch {
            Self.logger.error("[EditProfile] Profile update failed: \(error.localizedDescription, privacy: .public)")
            saveState = .idle
            return false
        }

        // 3. Update local SwiftData
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = (try? modelContext.fetch(descriptor))?.first {
            profile.displayName = displayName
            profile.avatarUrl = newAvatarUrl
            if let avatarData = newLocalAvatarData {
                profile.localAvatarData = avatarData
            }
            profile.dailyCalorieGoal = dailyCalorieGoal
            profile.dailyProteinGoal = dailyProteinGoal
            profile.dailyCarbsGoal = dailyCarbsGoal
            profile.dailyFatGoal = dailyFatGoal
            profile.targetWeight = targetWeight
            profile.gender = gender?.rawValue
            profile.birthDate = birthDate
            profile.birthYear = birthDate.map { Calendar.current.component(.year, from: $0) }
            profile.heightCm = heightCm
            profile.activityLevel = activityLevel?.rawValue
            profile.dailyWaterGoal = dailyWaterGoal
            profile.dailyStepGoal = dailyStepGoal
            profile.updatedAt = Date()
            try? modelContext.save()
        }

        saveState = .success
        HapticManager.success()
        return true
    }

    // MARK: - Private Helpers

    /// 缩小图片到指定最大边长，保持比例
    private static func resizeForUpload(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }

        let scale: CGFloat
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
