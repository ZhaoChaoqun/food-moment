import SwiftUI

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

// MARK: - View Performance Modifiers

extension View {

    /// 添加绘图组以优化复杂视图渲染
    func optimizedRendering() -> some View {
        self.drawingGroup()
    }

    /// 懒加载视图内容
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
    func optimizedForList(id: some Hashable) -> some View {
        self.id(id)
    }
}
