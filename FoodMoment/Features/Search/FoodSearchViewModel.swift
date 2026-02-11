import Foundation
import Observation
import os

/// 食物搜索结果 DTO
struct FoodSearchResultDTO: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let nameZh: String
    let emoji: String
    let calories: Int
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    let servingSize: String?
    let source: String?  // "local" | "usda" | "api"

    init(
        id: String,
        name: String,
        nameZh: String,
        emoji: String,
        calories: Int,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double,
        servingSize: String?,
        source: String? = nil
    ) {
        self.id = id
        self.name = name
        self.nameZh = nameZh
        self.emoji = emoji
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.servingSize = servingSize
        self.source = source
    }
}

/// 搜索响应包装
struct FoodSearchResponse: Codable, Sendable {
    let results: [FoodSearchResultDTO]
}

@MainActor
@Observable
final class FoodSearchViewModel {
    private static let logger = Logger(subsystem: "com.foodmoment", category: "FoodSearchViewModel")

    var searchText = ""
    var searchResults: [FoodSearchResultDTO] = []
    var suggestions: [FoodSearchResultDTO] = []  // 自动补全建议
    var recentSearches: [String] = []
    var isSearching = false
    var errorMessage: String?
    var searchSource: SearchSource = .all

    private var searchTask: Task<Void, Never>?

    /// 搜索来源
    enum SearchSource: String, CaseIterable {
        case all = "全部"
        case local = "本地库"
        case usda = "USDA"
    }

    // MARK: - Computed Properties

    /// 是否需要搜索本地数据库
    private var shouldSearchLocal: Bool {
        searchSource == .all || searchSource == .local
    }

    /// 是否需要搜索 USDA API
    private var shouldSearchUSDA: Bool {
        searchSource == .all || searchSource == .usda
    }

    init() {
        loadRecentSearches()
    }

    // MARK: - Search with Debounce

    /// 触发搜索（带 0.3s 防抖）
    func search() {
        // 取消上一次搜索任务
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = []
            suggestions = []
            isSearching = false
            errorMessage = nil
            return
        }

        // 立即显示本地自动补全建议
        suggestions = getLocalSuggestions(for: query)

        searchTask = Task {
            // Debounce: 等待 0.3 秒
            try? await Task.sleep(for: .milliseconds(300))

            // 检查是否被取消
            guard !Task.isCancelled else { return }

            await performSearch(query: query)
        }
    }

    /// 选择搜索建议
    func selectSuggestion(_ suggestion: FoodSearchResultDTO) {
        searchText = suggestion.nameZh
        searchResults = [suggestion]
        suggestions = []
        saveRecentSearch(suggestion.nameZh)
    }

    /// 清空搜索
    func clearSearch() {
        searchTask?.cancel()
        searchText = ""
        searchResults = []
        suggestions = []
        isSearching = false
        errorMessage = nil
    }

    // MARK: - Recent Searches

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentFoodSearches") ?? []
    }

    func saveRecentSearch(_ query: String) {
        var searches = recentSearches
        searches.removeAll { $0 == query }
        searches.insert(query, at: 0)
        if searches.count > 10 {
            searches = Array(searches.prefix(10))
        }
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "recentFoodSearches")
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentFoodSearches")
    }

    // MARK: - Local Suggestions (Auto-complete)

    /// 获取本地自动补全建议
    private func getLocalSuggestions(for query: String) -> [FoodSearchResultDTO] {
        let lowercasedQuery = query.lowercased()

        return ChineseFoodDatabase.foods
            .filter { food in
                food.nameZh.contains(query) ||
                food.name.lowercased().contains(lowercasedQuery) ||
                food.aliases.contains { $0.contains(query) }
            }
            .prefix(5)
            .map { $0.toDTO() }
    }

    // MARK: - Private Search Implementation

    private func performSearch(query: String) async {
        isSearching = true
        errorMessage = nil

        do {
            var results: [FoodSearchResultDTO] = []

            // 1. 本地中文库搜索
            if shouldSearchLocal {
                let localResults = searchLocalDatabase(query: query)
                results.append(contentsOf: localResults)
            }

            // 2. API 搜索 (USDA + 后端)
            if shouldSearchUSDA {
                let apiResults = await performAPISearch(query: query, excludingIds: Set(results.map { $0.id }))
                results.append(contentsOf: apiResults)
            }

            // 确认搜索词未发生变化
            guard !Task.isCancelled else { return }

            searchResults = results
            suggestions = []  // 清空建议，显示完整结果

            // 保存搜索记录
            if !results.isEmpty {
                saveRecentSearch(query)
            }
        } catch is CancellationError {
            // 搜索被取消，忽略
        } catch {
            guard !Task.isCancelled else { return }
            searchResults = []
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    /// 执行 API 搜索
    ///
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - excludingIds: 需要排除的 ID 集合（用于去重）
    /// - Returns: 搜索结果列表
    private func performAPISearch(query: String, excludingIds: Set<String>) async -> [FoodSearchResultDTO] {
        let encodedQuery = query.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? query

        do {
            let response: FoodSearchResponse = try await APIClient.shared.request(
                .foodSearch(query: encodedQuery)
            )

            // 去重：避免本地和 API 返回相同食物
            return response.results.filter { !excludingIds.contains($0.id) }
        } catch {
            // API 搜索失败，返回空数组
            Self.logger.error("API search failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// 搜索本地中文食物数据库
    private func searchLocalDatabase(query: String) -> [FoodSearchResultDTO] {
        let lowercasedQuery = query.lowercased()

        return ChineseFoodDatabase.foods
            .filter { food in
                food.nameZh.contains(query) ||
                food.name.lowercased().contains(lowercasedQuery) ||
                food.aliases.contains { $0.contains(query) }
            }
            .map { $0.toDTO() }
    }
}

// MARK: - Chinese Food Database

/// 本地中文食物数据库
struct ChineseFoodDatabase {
    struct FoodItem {
        let id: String
        let name: String
        let nameZh: String
        let aliases: [String]
        let emoji: String
        let calories: Int  // per 100g
        let protein: Double
        let carbs: Double
        let fat: Double
        let servingSize: String

        func toDTO() -> FoodSearchResultDTO {
            FoodSearchResultDTO(
                id: id,
                name: name,
                nameZh: nameZh,
                emoji: emoji,
                calories: calories,
                proteinGrams: protein,
                carbsGrams: carbs,
                fatGrams: fat,
                servingSize: servingSize,
                source: "local"
            )
        }
    }

    /// 常见中文食物数据库
    static let foods: [FoodItem] = [
        // === 主食 ===
        FoodItem(id: "cn-rice", name: "Rice", nameZh: "米饭", aliases: ["白米饭", "白饭", "大米饭"], emoji: "🍚", calories: 116, protein: 2.6, carbs: 25.6, fat: 0.3, servingSize: "100g"),
        FoodItem(id: "cn-noodles", name: "Noodles", nameZh: "面条", aliases: ["挂面", "拉面", "阳春面"], emoji: "🍜", calories: 138, protein: 4.5, carbs: 28, fat: 0.8, servingSize: "100g"),
        FoodItem(id: "cn-mantou", name: "Steamed Bun", nameZh: "馒头", aliases: ["白馒头", "花卷"], emoji: "🥖", calories: 221, protein: 7, carbs: 45, fat: 1.1, servingSize: "100g"),
        FoodItem(id: "cn-congee", name: "Congee", nameZh: "粥", aliases: ["白粥", "稀饭", "米粥"], emoji: "🥣", calories: 46, protein: 1.1, carbs: 9.9, fat: 0.1, servingSize: "100g"),
        FoodItem(id: "cn-baozi", name: "Steamed Stuffed Bun", nameZh: "包子", aliases: ["肉包", "菜包", "小笼包"], emoji: "🥟", calories: 180, protein: 6.5, carbs: 25, fat: 6, servingSize: "100g"),
        FoodItem(id: "cn-dumpling", name: "Dumpling", nameZh: "饺子", aliases: ["水饺", "蒸饺", "煎饺"], emoji: "🥟", calories: 195, protein: 8, carbs: 24, fat: 7.5, servingSize: "100g"),

        // === 肉类 ===
        FoodItem(id: "cn-chicken-breast", name: "Chicken Breast", nameZh: "鸡胸肉", aliases: ["鸡胸", "鸡脯肉"], emoji: "🍗", calories: 165, protein: 31, carbs: 0, fat: 3.6, servingSize: "100g"),
        FoodItem(id: "cn-pork", name: "Pork", nameZh: "猪肉", aliases: ["瘦肉", "猪瘦肉", "里脊肉"], emoji: "🥩", calories: 143, protein: 21, carbs: 0, fat: 6, servingSize: "100g"),
        FoodItem(id: "cn-beef", name: "Beef", nameZh: "牛肉", aliases: ["牛腩", "牛腱", "肥牛"], emoji: "🥩", calories: 250, protein: 26, carbs: 0, fat: 15, servingSize: "100g"),
        FoodItem(id: "cn-lamb", name: "Lamb", nameZh: "羊肉", aliases: ["羊肉片", "羊腿肉"], emoji: "🍖", calories: 294, protein: 25, carbs: 0, fat: 21, servingSize: "100g"),
        FoodItem(id: "cn-duck", name: "Duck", nameZh: "鸭肉", aliases: ["烤鸭", "鸭腿"], emoji: "🦆", calories: 337, protein: 19, carbs: 0, fat: 28, servingSize: "100g"),

        // === 海鲜 ===
        FoodItem(id: "cn-shrimp", name: "Shrimp", nameZh: "虾", aliases: ["大虾", "基围虾", "明虾"], emoji: "🦐", calories: 99, protein: 24, carbs: 0.2, fat: 0.3, servingSize: "100g"),
        FoodItem(id: "cn-fish", name: "Fish", nameZh: "鱼", aliases: ["鲈鱼", "鳕鱼", "三文鱼"], emoji: "🐟", calories: 206, protein: 22, carbs: 0, fat: 13, servingSize: "100g"),
        FoodItem(id: "cn-crab", name: "Crab", nameZh: "螃蟹", aliases: ["大闸蟹", "梭子蟹"], emoji: "🦀", calories: 97, protein: 19, carbs: 0, fat: 1.5, servingSize: "100g"),

        // === 蔬菜 ===
        FoodItem(id: "cn-qingcai", name: "Bok Choy", nameZh: "青菜", aliases: ["小白菜", "上海青"], emoji: "🥬", calories: 13, protein: 1.5, carbs: 1.2, fat: 0.2, servingSize: "100g"),
        FoodItem(id: "cn-spinach", name: "Spinach", nameZh: "菠菜", aliases: ["波菜"], emoji: "🥬", calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, servingSize: "100g"),
        FoodItem(id: "cn-tomato", name: "Tomato", nameZh: "番茄", aliases: ["西红柿"], emoji: "🍅", calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, servingSize: "100g"),
        FoodItem(id: "cn-cucumber", name: "Cucumber", nameZh: "黄瓜", aliases: ["青瓜"], emoji: "🥒", calories: 16, protein: 0.7, carbs: 3.6, fat: 0.1, servingSize: "100g"),
        FoodItem(id: "cn-broccoli", name: "Broccoli", nameZh: "西兰花", aliases: ["花椰菜"], emoji: "🥦", calories: 34, protein: 2.8, carbs: 7, fat: 0.4, servingSize: "100g"),
        FoodItem(id: "cn-carrot", name: "Carrot", nameZh: "胡萝卜", aliases: ["红萝卜"], emoji: "🥕", calories: 41, protein: 0.9, carbs: 10, fat: 0.2, servingSize: "100g"),
        FoodItem(id: "cn-potato", name: "Potato", nameZh: "土豆", aliases: ["马铃薯", "洋芋"], emoji: "🥔", calories: 77, protein: 2, carbs: 17, fat: 0.1, servingSize: "100g"),
        FoodItem(id: "cn-eggplant", name: "Eggplant", nameZh: "茄子", aliases: ["紫茄"], emoji: "🍆", calories: 25, protein: 1, carbs: 6, fat: 0.2, servingSize: "100g"),

        // === 蛋奶 ===
        FoodItem(id: "cn-egg", name: "Egg", nameZh: "鸡蛋", aliases: ["煮蛋", "煎蛋", "荷包蛋"], emoji: "🥚", calories: 155, protein: 13, carbs: 1.1, fat: 11, servingSize: "100g (约2个)"),
        FoodItem(id: "cn-milk", name: "Milk", nameZh: "牛奶", aliases: ["纯牛奶", "鲜牛奶"], emoji: "🥛", calories: 42, protein: 3.4, carbs: 5, fat: 1, servingSize: "100ml"),
        FoodItem(id: "cn-yogurt", name: "Yogurt", nameZh: "酸奶", aliases: ["原味酸奶"], emoji: "🥛", calories: 72, protein: 3.5, carbs: 12, fat: 1.5, servingSize: "100g"),

        // === 豆制品 ===
        FoodItem(id: "cn-tofu", name: "Tofu", nameZh: "豆腐", aliases: ["嫩豆腐", "老豆腐", "北豆腐"], emoji: "🧊", calories: 76, protein: 8.1, carbs: 1.9, fat: 4.2, servingSize: "100g"),
        FoodItem(id: "cn-doujiang", name: "Soy Milk", nameZh: "豆浆", aliases: ["原味豆浆"], emoji: "🥛", calories: 33, protein: 3, carbs: 1.8, fat: 1.6, servingSize: "100ml"),

        // === 水果 ===
        FoodItem(id: "cn-apple", name: "Apple", nameZh: "苹果", aliases: ["红富士", "青苹果"], emoji: "🍎", calories: 52, protein: 0.3, carbs: 14, fat: 0.2, servingSize: "100g"),
        FoodItem(id: "cn-banana", name: "Banana", nameZh: "香蕉", aliases: [], emoji: "🍌", calories: 89, protein: 1.1, carbs: 23, fat: 0.3, servingSize: "100g"),
        FoodItem(id: "cn-orange", name: "Orange", nameZh: "橙子", aliases: ["脐橙", "甜橙"], emoji: "🍊", calories: 47, protein: 0.9, carbs: 12, fat: 0.1, servingSize: "100g"),
        FoodItem(id: "cn-grape", name: "Grape", nameZh: "葡萄", aliases: ["提子"], emoji: "🍇", calories: 69, protein: 0.7, carbs: 18, fat: 0.2, servingSize: "100g"),
        FoodItem(id: "cn-watermelon", name: "Watermelon", nameZh: "西瓜", aliases: [], emoji: "🍉", calories: 30, protein: 0.6, carbs: 7.6, fat: 0.2, servingSize: "100g"),
        FoodItem(id: "cn-strawberry", name: "Strawberry", nameZh: "草莓", aliases: [], emoji: "🍓", calories: 33, protein: 0.7, carbs: 8, fat: 0.3, servingSize: "100g"),

        // === 常见菜品 ===
        FoodItem(id: "cn-chaodan", name: "Scrambled Eggs", nameZh: "炒蛋", aliases: ["炒鸡蛋", "番茄炒蛋"], emoji: "🍳", calories: 212, protein: 14, carbs: 2, fat: 16, servingSize: "100g"),
        FoodItem(id: "cn-hongshaorou", name: "Braised Pork", nameZh: "红烧肉", aliases: ["东坡肉"], emoji: "🍖", calories: 350, protein: 18, carbs: 5, fat: 28, servingSize: "100g"),
        FoodItem(id: "cn-gongbaojiding", name: "Kung Pao Chicken", nameZh: "宫保鸡丁", aliases: [], emoji: "🍗", calories: 180, protein: 20, carbs: 8, fat: 8, servingSize: "100g"),
        FoodItem(id: "cn-yuxiangrousi", name: "Shredded Pork", nameZh: "鱼香肉丝", aliases: [], emoji: "🥢", calories: 165, protein: 15, carbs: 10, fat: 8, servingSize: "100g"),
        FoodItem(id: "cn-mapo-tofu", name: "Mapo Tofu", nameZh: "麻婆豆腐", aliases: [], emoji: "🥘", calories: 120, protein: 8, carbs: 6, fat: 7, servingSize: "100g"),
        FoodItem(id: "cn-huiguorou", name: "Twice-Cooked Pork", nameZh: "回锅肉", aliases: [], emoji: "🥓", calories: 280, protein: 16, carbs: 6, fat: 22, servingSize: "100g"),
        FoodItem(id: "cn-chaofan", name: "Fried Rice", nameZh: "炒饭", aliases: ["蛋炒饭", "扬州炒饭"], emoji: "🍚", calories: 180, protein: 5, carbs: 28, fat: 6, servingSize: "100g"),

        // === 饮品 ===
        FoodItem(id: "cn-tea", name: "Tea", nameZh: "茶", aliases: ["绿茶", "红茶", "乌龙茶"], emoji: "🍵", calories: 1, protein: 0, carbs: 0.2, fat: 0, servingSize: "100ml"),
        FoodItem(id: "cn-coffee", name: "Coffee", nameZh: "咖啡", aliases: ["美式咖啡", "黑咖啡"], emoji: "☕", calories: 2, protein: 0.1, carbs: 0, fat: 0, servingSize: "100ml"),
        FoodItem(id: "cn-latte", name: "Latte", nameZh: "拿铁", aliases: ["拿铁咖啡"], emoji: "☕", calories: 56, protein: 2.5, carbs: 5, fat: 2.5, servingSize: "100ml"),
        FoodItem(id: "cn-milktea", name: "Milk Tea", nameZh: "奶茶", aliases: ["珍珠奶茶"], emoji: "🧋", calories: 120, protein: 1.5, carbs: 22, fat: 3, servingSize: "100ml"),
        FoodItem(id: "cn-juice", name: "Orange Juice", nameZh: "果汁", aliases: ["橙汁", "苹果汁"], emoji: "🧃", calories: 45, protein: 0.5, carbs: 10, fat: 0.2, servingSize: "100ml"),

        // === 坚果零食 ===
        FoodItem(id: "cn-peanut", name: "Peanut", nameZh: "花生", aliases: ["花生米"], emoji: "🥜", calories: 567, protein: 25.8, carbs: 16, fat: 49, servingSize: "100g"),
        FoodItem(id: "cn-almond", name: "Almond", nameZh: "杏仁", aliases: ["巴旦木"], emoji: "🌰", calories: 579, protein: 21, carbs: 22, fat: 50, servingSize: "100g"),
        FoodItem(id: "cn-walnut", name: "Walnut", nameZh: "核桃", aliases: [], emoji: "🌰", calories: 654, protein: 15, carbs: 14, fat: 65, servingSize: "100g"),
    ]
}
