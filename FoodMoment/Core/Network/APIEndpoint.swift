import Foundation

// MARK: - API Endpoint

/// API 端点定义
///
/// 定义所有 API 请求的路径、方法和认证要求。
/// 使用枚举关联值传递动态参数。
///
/// ## 使用示例
/// ```swift
/// let url = APIEndpoint.getMeals(date: "2024-01-01").url
/// let method = APIEndpoint.createMeal.method
/// ```
enum APIEndpoint {

    // MARK: - Configuration

    private static let baseURL = "https://api.foodmoment.app"
    private static let apiVersion = "/api/v1"

    // MARK: - Auth Endpoints

    case appleSignIn
    case refreshToken
    case deleteAccount

    // MARK: - Food Recognition Endpoints

    case analyzeFood
    case barcodeLookup(code: String)
    case foodSearch(query: String)

    // MARK: - Meal Endpoints

    case createMeal
    case getMeals(date: String)
    case updateMeal(id: String)
    case deleteMeal(id: String)

    // MARK: - Statistics Endpoints

    case dailyStats(date: String)
    case weeklyStats(week: String)
    case monthlyStats(month: String)
    case insights

    // MARK: - User Endpoints

    case getProfile
    case updateProfile
    case achievements
    case updateGoals
    case logWeight
    case streaks

    // MARK: - Water Endpoints

    case logWater
    case getWater(date: String)

    // MARK: - Computed Properties

    /// API 请求路径
    var path: String {
        switch self {
        // Auth
        case .appleSignIn:
            return "/auth/apple"
        case .refreshToken:
            return "/auth/refresh"
        case .deleteAccount:
            return "/auth/account"

        // Food
        case .analyzeFood:
            return "/food/analyze"
        case .barcodeLookup(let code):
            return "/food/barcode/\(code)"
        case .foodSearch(let query):
            return "/food/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"

        // Meals
        case .createMeal:
            return "/meals"
        case .getMeals(let date):
            return "/meals?date=\(date)"
        case .updateMeal(let id):
            return "/meals/\(id)"
        case .deleteMeal(let id):
            return "/meals/\(id)"

        // Stats
        case .dailyStats(let date):
            return "/stats/daily?date=\(date)"
        case .weeklyStats(let week):
            return "/stats/weekly?week=\(week)"
        case .monthlyStats(let month):
            return "/stats/monthly?month=\(month)"
        case .insights:
            return "/stats/insights"

        // User
        case .getProfile:
            return "/user/profile"
        case .updateProfile:
            return "/user/profile"
        case .achievements:
            return "/user/achievements"
        case .updateGoals:
            return "/user/goals"
        case .logWeight:
            return "/user/weight"
        case .streaks:
            return "/user/streaks"

        // Water
        case .logWater:
            return "/water"
        case .getWater(let date):
            return "/water?date=\(date)"
        }
    }

    /// HTTP 请求方法
    var method: HTTPMethod {
        switch self {
        case .appleSignIn, .refreshToken, .analyzeFood, .createMeal, .logWeight, .logWater:
            return .post
        case .updateProfile, .updateMeal, .updateGoals:
            return .put
        case .deleteAccount, .deleteMeal:
            return .delete
        default:
            return .get
        }
    }

    /// 完整请求 URL
    var url: URL {
        guard let url = URL(string: Self.baseURL + Self.apiVersion + path) else {
            fatalError("Invalid URL: \(Self.baseURL + Self.apiVersion + path)")
        }
        return url
    }

    /// 是否需要认证
    var requiresAuth: Bool {
        switch self {
        case .appleSignIn, .refreshToken:
            return false
        default:
            return true
        }
    }
}

// MARK: - HTTP Method

/// HTTP 请求方法
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
