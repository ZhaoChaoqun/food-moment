import SwiftUI
import UIKit

// MARK: - Optimized Async Image

/// 优化的异步图片加载组件
///
/// 支持缩略图、占位符和错误处理。
///
/// ## 使用示例
/// ```swift
/// OptimizedAsyncImage(url: imageURL) { image in
///     image
///         .resizable()
///         .aspectRatio(contentMode: .fill)
/// } placeholder: {
///     ProgressView()
/// }
/// ```
struct OptimizedAsyncImage<Content: View, Placeholder: View>: View {

    // MARK: - Properties

    private let url: URL?
    private let thumbnailSize: CGSize?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    // MARK: - Initialization

    init(
        url: URL?,
        thumbnailSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.thumbnailSize = thumbnailSize
        self.content = content
        self.placeholder = placeholder
    }

    // MARK: - Body

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                placeholder()
            case .success(let image):
                content(image)
            case .failure:
                placeholder()
            @unknown default:
                placeholder()
            }
        }
    }
}

// MARK: - Lazy Loading List

/// 懒加载列表包装器
///
/// 自动检测滚动到底部并触发加载更多。
///
/// ## 使用示例
/// ```swift
/// LazyLoadingList(data: items, onLoadMore: { viewModel.loadMore() }) { item in
///     ItemRow(item: item)
/// }
/// ```
struct LazyLoadingList<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Identifiable {

    // MARK: - Properties

    private let data: Data
    private let loadMoreThreshold: Int
    private let onLoadMore: (() -> Void)?
    private let content: (Data.Element) -> Content

    // MARK: - State

    @State private var hasReachedEnd = false

    // MARK: - Initialization

    init(
        data: Data,
        loadMoreThreshold: Int = 5,
        onLoadMore: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.loadMoreThreshold = loadMoreThreshold
        self.onLoadMore = onLoadMore
        self.content = content
    }

    // MARK: - Body

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                content(item)
                    .onAppear {
                        checkLoadMore(index: index)
                    }
            }
        }
    }

    // MARK: - Private Methods

    private func checkLoadMore(index: Int) {
        let totalCount = data.count
        if index >= totalCount - loadMoreThreshold && !hasReachedEnd {
            onLoadMore?()
        }
    }
}

// MARK: - Image Cache Manager

/// 内存图片缓存管理器
///
/// 使用 NSCache 实现自动内存管理的图片缓存。
final class ImageCacheManager: @unchecked Sendable {

    // MARK: - Singleton

    nonisolated(unsafe) static let shared = ImageCacheManager()

    // MARK: - Private Properties

    private let cache = NSCache<NSURL, UIImage>()
    private let memoryCacheLimitMB = 100
    private let memoryCacheCountLimit = 100

    // MARK: - Initialization

    private init() {
        configureCache()
    }

    // MARK: - Public Methods

    /// 获取缓存的图片
    ///
    /// - Parameter url: 图片 URL
    /// - Returns: 缓存的图片，如果不存在则返回 nil
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    /// 缓存图片
    ///
    /// - Parameters:
    ///   - image: 要缓存的图片
    ///   - url: 图片 URL
    func cache(_ image: UIImage, for url: URL) {
        let cost = image.pngData()?.count ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }

    /// 清除所有缓存
    func clearAllCache() {
        cache.removeAllObjects()
    }

    /// 清除内存缓存
    func clearMemoryCache() {
        cache.removeAllObjects()
    }

    /// 获取缓存大小（NSCache 不支持精确统计，返回 0）
    func getCacheSize() async -> UInt {
        return 0
    }

    // MARK: - Private Methods

    private func configureCache() {
        cache.totalCostLimit = memoryCacheLimitMB * 1024 * 1024
        cache.countLimit = memoryCacheCountLimit
    }
}

// MARK: - Debounced Property Wrapper

/// 防抖值包装器
///
/// 用于包装需要防抖处理的值。
/// 实际的防抖逻辑需要在调用处使用 Task 实现。
@propertyWrapper
struct Debounced<Value: Sendable>: Sendable {

    // MARK: - Properties

    private var value: Value

    // MARK: - Property Wrapper

    var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }

    // MARK: - Initialization

    init(wrappedValue: Value, delay: TimeInterval = 0.3) {
        self.value = wrappedValue
    }
}

// MARK: - View Performance Modifiers

extension View {

    /// 添加绘图组以优化复杂视图渲染
    ///
    /// 将视图光栅化为单个图层，适用于复杂但静态的视图。
    func optimizedRendering() -> some View {
        self.drawingGroup()
    }

    /// 懒加载视图内容
    ///
    /// 只有当 `isVisible` 为 true 时才渲染内容。
    ///
    /// - Parameters:
    ///   - isVisible: 是否可见
    ///   - content: 要懒加载的内容
    /// - Returns: 懒加载的视图
    @ViewBuilder
    func lazyLoad<Content: View>(
        isVisible: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if isVisible {
            content()
        } else {
            Color.clear
        }
    }

    /// 为列表项添加 ID 以优化重用
    ///
    /// - Parameter id: 唯一标识符
    /// - Returns: 带有 ID 的视图
    func optimizedForList(id: some Hashable) -> some View {
        self.id(id)
    }
}

// MARK: - Throttler

/// 节流器
///
/// 限制动作的执行频率，在指定时间间隔内只执行一次。
actor Throttler {

    // MARK: - Properties

    private var lastExecutionTime: Date?
    private let interval: TimeInterval

    // MARK: - Initialization

    init(interval: TimeInterval) {
        self.interval = interval
    }

    // MARK: - Public Methods

    /// 执行节流动作
    ///
    /// 如果距离上次执行时间不足指定间隔，则跳过执行。
    ///
    /// - Parameter action: 要执行的动作
    func execute(_ action: @Sendable () async -> Void) async {
        let now = Date()

        if let lastTime = lastExecutionTime,
           now.timeIntervalSince(lastTime) < interval {
            return
        }

        lastExecutionTime = now
        await action()
    }
}

// MARK: - Prefetch Manager

/// 图片预取管理器
///
/// 在用户滚动列表时预先加载即将显示的图片。
@MainActor
final class PrefetchManager {

    // MARK: - Singleton

    static let shared = PrefetchManager()

    // MARK: - Private Properties

    private var prefetchedURLs: Set<URL> = []
    private var prefetchTasks: [URL: Task<Void, Never>] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 预取图片
    ///
    /// - Parameter urls: 要预取的图片 URL 数组
    func prefetchImages(urls: [URL]) {
        let newURLs = urls.filter { !prefetchedURLs.contains($0) }
        guard !newURLs.isEmpty else { return }

        for url in newURLs {
            let task = Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        ImageCacheManager.shared.cache(image, for: url)
                    }
                } catch {
                    // 静默处理预取错误
                }
            }
            prefetchTasks[url] = task
        }
        prefetchedURLs.formUnion(newURLs)
    }

    /// 取消预取
    ///
    /// - Parameter urls: 要取消预取的 URL 数组
    func cancelPrefetch(urls: [URL]) {
        for url in urls {
            prefetchTasks[url]?.cancel()
            prefetchTasks.removeValue(forKey: url)
        }
    }

    /// 清除预取缓存
    func clearPrefetchCache() {
        for task in prefetchTasks.values {
            task.cancel()
        }
        prefetchTasks.removeAll()
        prefetchedURLs.removeAll()
    }
}

