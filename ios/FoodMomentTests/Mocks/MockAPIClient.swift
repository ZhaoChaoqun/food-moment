import Foundation
@testable import FoodMoment

/// Mock API Client for testing
final class MockAPIClient: @unchecked Sendable {
    var shouldSucceed = true
    var mockResponse: Any?
    var mockError: Error?
    var requestCallCount = 0
    var lastEndpoint: APIEndpoint?

    func reset() {
        shouldSucceed = true
        mockResponse = nil
        mockError = nil
        requestCallCount = 0
        lastEndpoint = nil
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        requestCallCount += 1
        lastEndpoint = endpoint

        if let error = mockError {
            throw error
        }

        if !shouldSucceed {
            throw APIError.networkError(NSError(domain: "MockError", code: -1))
        }

        guard let response = mockResponse as? T else {
            throw APIError.decodingError(NSError(domain: "MockError", code: -1))
        }

        return response
    }
}

/// Mock URL Session for testing network layer
final class MockURLSession: @unchecked Sendable {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    var refreshTokenCalled = false

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }

        guard let data = data, let response = response else {
            throw URLError(.badServerResponse)
        }

        return (data, response)
    }
}
