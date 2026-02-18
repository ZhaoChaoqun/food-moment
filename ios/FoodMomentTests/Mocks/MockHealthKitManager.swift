import Foundation
import HealthKit
@testable import FoodMoment

/// Mock HealthKit Manager for testing
final class MockHealthKitManager: @unchecked Sendable {
    var isAuthorized = true
    var savedNutrition: [(calories: Double, protein: Double, carbs: Double, fat: Double, date: Date)] = []
    var savedWater: [(amount: Double, date: Date)] = []
    var savedWeight: [(weight: Double, date: Date)] = []
    var mockSteps: Double = 5000
    var mockWeight: Double = 70.0

    func reset() {
        isAuthorized = true
        savedNutrition.removeAll()
        savedWater.removeAll()
        savedWeight.removeAll()
        mockSteps = 5000
        mockWeight = 70.0
    }

    func requestAuthorization() async throws -> Bool {
        return isAuthorized
    }

    func saveNutrition(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        date: Date
    ) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        savedNutrition.append((calories, protein, carbs, fat, date))
    }

    func saveWater(amount: Double, date: Date) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        savedWater.append((amount, date))
    }

    func saveWeight(weight: Double, date: Date) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        savedWeight.append((weight, date))
    }

    func readSteps(for date: Date) async throws -> Double {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        return mockSteps
    }

    func readLatestWeight() async throws -> Double? {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        return mockWeight
    }
}

enum HealthKitError: Error {
    case notAuthorized
    case dataNotAvailable
}
