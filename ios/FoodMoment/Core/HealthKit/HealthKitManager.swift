import Foundation
import HealthKit

actor HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    // MARK: - Availability

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    /// 请求 HealthKit 读写权限
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.bodyMass),
        ]

        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryWater),
            HKQuantityType(.bodyMass),
        ]

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    // MARK: - Read: Steps

    /// 读取今日步数
    func fetchTodaySteps() async throws -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let steps = try await fetchSteps(from: startOfDay, to: endOfDay)
        return steps[startOfDay] ?? 0
    }

    /// 读取步数（指定日期范围，按天聚合）
    func fetchSteps(from startDate: Date, to endDate: Date) async throws -> [Date: Int] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let stepType = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let calendar = Calendar.current
        var interval = DateComponents()
        interval.day = 1

        let anchorDate = calendar.startOfDay(for: startDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                guard let results else {
                    continuation.resume(returning: [:])
                    return
                }

                var stepsByDate: [Date: Int] = [:]
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let date = calendar.startOfDay(for: statistics.startDate)
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    stepsByDate[date] = Int(steps)
                }

                continuation.resume(returning: stepsByDate)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Read: Weight

    /// 读取最新体重（单位：kg）
    func fetchLatestWeight() async throws -> Double? {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let weightType = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: weight)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Write: Nutrition

    /// 写入营养数据（餐食记录后调用）
    func saveNutrition(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        date: Date
    ) async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let samples: [(HKQuantityTypeIdentifier, Double, HKUnit)] = [
            (.dietaryEnergyConsumed, calories, .kilocalorie()),
            (.dietaryProtein, protein, .gramUnit(with: .none)),
            (.dietaryCarbohydrates, carbs, .gramUnit(with: .none)),
            (.dietaryFatTotal, fat, .gramUnit(with: .none)),
        ]

        for (identifier, value, unit) in samples {
            guard value > 0 else { continue }
            let quantityType = HKQuantityType(identifier)
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            let sample = HKQuantitySample(
                type: quantityType,
                quantity: quantity,
                start: date,
                end: date
            )

            try await healthStore.save(sample)
        }
    }

    // MARK: - Write: Water

    /// 写入饮水量（单位：mL）
    func saveWaterIntake(milliliters: Double, date: Date) async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let waterType = HKQuantityType(.dietaryWater)
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: milliliters)
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: date,
            end: date
        )

        try await healthStore.save(sample)
    }

    // MARK: - Write: Weight

    /// 写入体重（单位：kg）
    func saveWeight(kilograms: Double, date: Date) async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let weightType = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kilograms)
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: date,
            end: date
        )

        try await healthStore.save(sample)
    }
}

// MARK: - HealthKit Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case authorizationFailed(Error)
    case queryFailed(Error)
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "此设备不支持 HealthKit"
        case .authorizationDenied:
            return "HealthKit 权限被拒绝，请在设置中开启"
        case .authorizationFailed(let error):
            return "HealthKit 授权失败: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "HealthKit 数据查询失败: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "HealthKit 数据写入失败: \(error.localizedDescription)"
        }
    }
}
