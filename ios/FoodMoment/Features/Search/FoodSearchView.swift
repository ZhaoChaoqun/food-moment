import SwiftUI

struct FoodSearchView: View {
    @State private var viewModel = FoodSearchViewModel()
    @Environment(\.dismiss) private var dismiss

    /// 选中食物后的回调
    var onFoodSelected: ((FoodSearchResultDTO) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                // 主内容
                Group {
                    switch viewModel.viewState {
                    case .loading:
                        loadingView
                    case .error(let message):
                        errorView(message: message)
                    case .emptyResult:
                        emptyResultView
                    case .initial:
                        initialStateView
                    case .results:
                        resultsList
                    }
                }

                // 自动补全建议覆盖层
                if !viewModel.suggestions.isEmpty && viewModel.searchResults.isEmpty {
                    suggestionsOverlay
                }
            }
            .navigationTitle("搜索食物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(FoodSearchViewModel.SearchSource.allCases, id: \.self) { source in
                            Button {
                                viewModel.searchSource = source
                                viewModel.search()
                            } label: {
                                HStack {
                                    Text(source.rawValue)
                                    if viewModel.searchSource == source {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "搜索食物名称..."
        )
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.search()
        }
    }

    // MARK: - Initial State (Recent Searches + Quick Access)

    private var initialStateView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // 最近搜索
                if !viewModel.recentSearches.isEmpty {
                    recentSearchesSection
                }

                // 常见食物快捷入口
                quickAccessSection
            }
            .padding(16)
        }
    }

    // MARK: - Recent Searches Section

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近搜索")
                    .font(.Jakarta.semiBold(15))
                    .foregroundStyle(.primary)

                Spacer()

                Button("清空") {
                    viewModel.clearRecentSearches()
                }
                .font(.Jakarta.regular(13))
                .foregroundStyle(.secondary)
            }

            FlowLayout(spacing: 8) {
                ForEach(viewModel.recentSearches, id: \.self) { search in
                    Button {
                        viewModel.searchText = search
                        viewModel.search()
                    } label: {
                        Text(search)
                            .font(.Jakarta.medium(14))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Quick Access Section

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("常见食物")
                .font(.Jakarta.semiBold(15))
                .foregroundStyle(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                ForEach(quickAccessFoods, id: \.id) { food in
                    quickAccessButton(food)
                }
            }
        }
    }

    private var quickAccessFoods: [FoodSearchResultDTO] {
        // 从本地数据库中选取常见食物
        Array(ChineseFoodDatabase.foods.prefix(12).map { $0.toDTO() })
    }

    private func quickAccessButton(_ food: FoodSearchResultDTO) -> some View {
        Button {
            onFoodSelected?(food)
            dismiss()
        } label: {
            VStack(spacing: 8) {
                Text(food.emoji)
                    .font(.Jakarta.regular(32))

                Text(food.nameZh)
                    .font(.Jakarta.medium(13))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(food.calories) kcal")
                    .font(.Jakarta.regular(11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(food.nameZh)，\(food.calories)千卡")
    }

    // MARK: - Suggestions Overlay

    private var suggestionsOverlay: some View {
        VStack(spacing: 0) {
            // 搜索框下方的建议列表
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.suggestions) { suggestion in
                    Button {
                        viewModel.selectSuggestion(suggestion)
                        onFoodSelected?(suggestion)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text(suggestion.emoji)
                                .font(.Jakarta.regular(24))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.nameZh)
                                    .font(.Jakarta.medium(15))
                                    .foregroundStyle(.primary)

                                Text("\(suggestion.calories) kcal / \(suggestion.servingSize ?? "100g")")
                                    .font(.Jakarta.regular(12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.left")
                                .font(.Jakarta.regular(14))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                    }
                    .buttonStyle(.plain)

                    if suggestion.id != viewModel.suggestions.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Placeholder (Initial State)

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.Jakarta.regular(48))
                .foregroundStyle(.tertiary)

            Text("输入食物名称开始搜索")
                .font(.Jakarta.medium(16))
                .foregroundStyle(.secondary)

            Text("例如：鸡胸肉、番茄炒蛋、牛油果")
                .font(.Jakarta.regular(14))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("正在搜索...")
                .font(.Jakarta.medium(14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.Jakarta.regular(40))
                .foregroundStyle(.orange)

            Text("搜索失败")
                .font(.Jakarta.semiBold(16))

            Text(message)
                .font(.Jakarta.regular(14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("重试") {
                viewModel.search()
            }
            .font(.Jakarta.semiBold(14))
            .foregroundStyle(AppTheme.Colors.primary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty Results

    private var emptyResultView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.Jakarta.regular(40))
                .foregroundStyle(.tertiary)

            Text("未找到相关食物")
                .font(.Jakarta.semiBold(16))

            Text("试试其他关键词吧")
                .font(.Jakarta.regular(14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            ForEach(viewModel.searchResults) { food in
                foodRow(food)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    private func foodRow(_ food: FoodSearchResultDTO) -> some View {
        Button {
            onFoodSelected?(food)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                // Emoji 图标
                Text(food.emoji)
                    .font(.Jakarta.regular(36))
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground))
                    )

                // 食物信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(food.nameZh)
                            .font(.Jakarta.semiBold(16))
                            .foregroundStyle(.primary)

                        // 数据来源标签
                        if let source = food.source {
                            Text(sourceLabel(source))
                                .font(.Jakarta.regular(10))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(sourceColor(source))
                                )
                        }
                    }

                    if food.nameZh != food.name {
                        Text(food.name)
                            .font(.Jakarta.regular(13))
                            .foregroundStyle(.tertiary)
                    }

                    if let serving = food.servingSize {
                        Text(serving)
                            .font(.Jakarta.regular(12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // 卡路里
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(food.calories)")
                        .font(.Jakarta.bold(20))
                        .foregroundStyle(AppTheme.Colors.primary)
                    Text("kcal")
                        .font(.Jakarta.regular(12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color(.systemBackground))
            )
            .modifier(CardShadow())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(food.nameZh)，\(food.calories)千卡")
        .accessibilityHint("点击选择此食物")
    }

    private func sourceLabel(_ source: String) -> String {
        switch source {
        case "local": return "本地"
        case "usda": return "USDA"
        default: return "API"
        }
    }

    private func sourceColor(_ source: String) -> Color {
        switch source {
        case "local": return AppTheme.Colors.primary
        case "usda": return .blue
        default: return .orange
        }
    }
}

// MARK: - Flow Layout for Recent Searches

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}

#Preview {
    FoodSearchView()
}
