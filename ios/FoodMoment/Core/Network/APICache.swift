import Foundation

/// Thread-safe in-memory cache for GET API responses.
///
/// Keyed by URL path string. Each entry has a configurable TTL.
/// Integrated into APIClient for transparent caching of GET requests.
actor APICache {

    // MARK: - Singleton

    static let shared = APICache()

    // MARK: - Types

    private struct CacheEntry {
        let data: Data
        let timestamp: Date
        let ttl: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }

    /// Per-endpoint TTL configuration
    enum CacheTTL {
        static let profile: TimeInterval = 300    // 5 min
        static let meals: TimeInterval = 120      // 2 min
        static let weekDates: TimeInterval = 120  // 2 min
        static let stats: TimeInterval = 180      // 3 min
        static let `default`: TimeInterval = 60   // 1 min
    }

    // MARK: - Storage

    private var cache: [String: CacheEntry] = [:]

    private init() {}

    // MARK: - Public Methods

    func get(for key: String) -> Data? {
        guard let entry = cache[key], !entry.isExpired else {
            cache[key] = nil
            return nil
        }
        return entry.data
    }

    func set(_ data: Data, for key: String, ttl: TimeInterval) {
        cache[key] = CacheEntry(data: data, timestamp: Date(), ttl: ttl)
    }

    /// Invalidate all entries whose keys contain the given substring.
    func invalidate(matching pattern: String) {
        cache = cache.filter { !$0.key.contains(pattern) }
    }

    func invalidate(key: String) {
        cache[key] = nil
    }

    func clearAll() {
        cache.removeAll()
    }
}
