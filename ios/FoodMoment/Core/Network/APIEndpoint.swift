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

    #if DEBUG
    // 开发环境：通过 ngrok 代理连接后端服务（真机测试用）
    private static let baseURL = "https://sparkle-regardant-mirella.ngrok-free.dev"
    #else
    // 生产环境
    private static let baseURL = "https://api.foodmoment.app"
    #endif
    private static let apiVersion = "/api/v1"

    // MARK: - Auth Endpoints

    case deviceAuth
    case appleSignIn
    case refreshToken
    case deleteAccount

    // MARK: - Demo Endpoints

    case seedDemo

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
        case .deviceAuth:
            return "/auth/device"
        case .appleSignIn:
            return "/auth/apple"
        case .refreshToken:
            return "/auth/refresh"
        case .deleteAccount:
            return "/auth/account"

        // Demo
        case .seedDemo:
            return "/demo/seed"

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
        case .deviceAuth, .appleSignIn, .refreshToken, .analyzeFood, .createMeal, .logWeight, .logWater, .seedDemo:
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
        case .deviceAuth, .appleSignIn, .refreshToken, .analyzeFood:
            return false
        default:
            return true
        }
    }

    /// 日志用短标签（固定 4 字中文）
    var label: String {
        switch self {
        case .deviceAuth:       return "设备认证"
        case .appleSignIn:      return "Apple登录"
        case .refreshToken:     return "刷新令牌"
        case .deleteAccount:    return "注销账户"
        case .seedDemo:         return "播种演示"
        case .analyzeFood:      return "食物识别"
        case .barcodeLookup:    return "条码查询"
        case .foodSearch:       return "食物搜索"
        case .createMeal:       return "创建记录"
        case .getMeals:         return "查询记录"
        case .updateMeal:       return "更新记录"
        case .deleteMeal:       return "删除记录"
        case .dailyStats:       return "日统计量"
        case .weeklyStats:      return "周统计量"
        case .monthlyStats:     return "月统计量"
        case .insights:         return "数据洞察"
        case .getProfile:       return "获取档案"
        case .updateProfile:    return "更新档案"
        case .achievements:     return "成就列表"
        case .updateGoals:      return "更新目标"
        case .logWeight:        return "记录体重"
        case .streaks:          return "连续打卡"
        case .logWater:         return "记录饮水"
        case .getWater:         return "查询饮水"
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
