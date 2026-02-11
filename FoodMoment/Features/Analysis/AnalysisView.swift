import SwiftUI
import SwiftData
import UIKit

// MARK: - Scroll Offset Tracking

private struct ScrollOffsetKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// The main analysis result screen presented after capturing a food photo.
/// Uses a single ScrollView with parallax photo and inline nutrition content.
/// When the photo scrolls off-screen, a sticky thumbnail bar appears at the top.
struct AnalysisView: View {

    let image: UIImage

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var viewModel: AnalysisViewModel
    @State private var shareImage: UIImage?

    // MARK: - Scroll State

    @State private var scrollOffset: CGFloat = 0

    // MARK: - Layout Constants

    private enum Layout {
        static let collapsedBarHeight: CGFloat = 60
        static let contentCornerRadius: CGFloat = AppTheme.CornerRadius.medium
    }

    // MARK: - Image Display Geometry (供 FoodTagOverlay 使用)

    @State private var imageDisplayFrame: CGRect = .zero

    init(image: UIImage) {
        self.image = image
        self._viewModel = State(initialValue: AnalysisViewModel(capturedImage: image))
    }

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
            let safeTop = geometry.safeAreaInsets.top
            let imageHeight = computeImageHeight(screenWidth: screenWidth, screenHeight: screenHeight)

            // Scroll-derived values
            let scrollUp = max(-scrollOffset, 0)
            let threshold = imageHeight - Layout.collapsedBarHeight
            let showCollapsedBar = scrollUp >= threshold
            let tagOpacity = max(1.0 - scrollUp / max(threshold * 0.3, 1), 0)
            let parallaxOffset = min(scrollUp * 0.3, imageHeight * 0.3)

            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Scroll offset anchor
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: proxy.frame(in: .named("scroll")).minY
                            )
                        }
                        .frame(height: 0)

                        // MARK: - Photo Section
                        photoSection(
                            screenWidth: screenWidth,
                            imageHeight: imageHeight,
                            parallaxOffset: parallaxOffset,
                            tagOpacity: tagOpacity
                        )

                        // MARK: - Nutrition Content Section
                        nutritionContentSection(screenHeight: screenHeight, imageHeight: imageHeight)
                            .padding(.top, -Layout.contentCornerRadius)
                    }
                }
                .ignoresSafeArea()
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    scrollOffset = value
                }

                // MARK: - Floating Top Control Bar
                topControlBar(safeTop: safeTop)

                // MARK: - Sticky Collapsed Photo Bar
                if showCollapsedBar {
                    collapsedPhotoBar(safeTop: safeTop)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: showCollapsedBar)
                }
            }
            .onAppear {
                updateImageDisplayFrame(screenWidth: screenWidth, imageHeight: imageHeight)
            }
            .onChange(of: geometry.size) { _, newSize in
                let newImageHeight = computeImageHeight(screenWidth: newSize.width, screenHeight: newSize.height)
                updateImageDisplayFrame(screenWidth: newSize.width, imageHeight: newImageHeight)
            }
        }
        // MARK: - Food edit sheet
        .sheet(isPresented: $viewModel.isEditingFood) {
            foodEditSheet
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppTheme.CornerRadius.medium)
        }
        .onAppear {
            Task {
                await viewModel.analyzeFood()
            }
        }
        .onChange(of: viewModel.isMealSaved) { _, saved in
            if saved {
                dismiss()
            }
        }
    }

    // MARK: - Photo Section

    private func photoSection(
        screenWidth: CGFloat,
        imageHeight: CGFloat,
        parallaxOffset: CGFloat,
        tagOpacity: Double
    ) -> some View {
        ZStack {
            // Food photo with parallax
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: screenWidth, height: imageHeight)
                .offset(y: parallaxOffset)
                .clipped()

            // Gradient overlay
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.5), location: 0),
                    .init(color: .clear, location: 0.2),
                    .init(color: .clear, location: 0.75),
                    .init(color: .black.opacity(0.35), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Food tag overlay
            if let result = viewModel.analysisResult {
                FoodTagOverlay(
                    detectedFoods: result.detectedFoods,
                    imageDisplayFrame: imageDisplayFrame,
                    onFoodTapped: { index in
                        viewModel.startEditingFood(at: index)
                    }
                )
                .opacity(tagOpacity)
                .allowsHitTesting(tagOpacity > 0.5)
            }
        }
        .frame(width: screenWidth, height: imageHeight)
        .clipped()
        .background(Color.black)
    }

    // MARK: - Nutrition Content Section

    private func nutritionContentSection(screenHeight: CGFloat, imageHeight: CGFloat) -> some View {
        let minContentHeight = screenHeight - imageHeight + Layout.contentCornerRadius
        return VStack(spacing: 0) {
            // Decorative drag indicator
            Capsule()
                .fill(AppTheme.Colors.dragIndicator)
                .frame(width: 48, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            FloatingNutritionPanel(
                analysisResult: viewModel.analysisResult,
                isAnalyzing: viewModel.isAnalyzing,
                errorMessage: viewModel.errorMessage,
                onLogMeal: {
                    viewModel.saveMeal(modelContext: modelContext, appState: appState)
                },
                onRetry: {
                    Task {
                        await viewModel.analyzeFood()
                    }
                }
            )

            Spacer(minLength: 0)
        }
        .frame(minHeight: minContentHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: Layout.contentCornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: Layout.contentCornerRadius
            )
        )
    }

    // MARK: - Compute Image Height

    /// 根据图片宽高比和屏幕宽度，计算图片显示高度
    /// 竖版图片最多占屏幕 45%，横版图片按比例自然缩放
    private func computeImageHeight(screenWidth: CGFloat, screenHeight: CGFloat) -> CGFloat {
        guard image.size.width > 0, image.size.height > 0 else { return 300 }

        let imageAspect = image.size.width / image.size.height
        let naturalHeight = screenWidth / imageAspect

        let maxHeight = screenHeight * 0.45
        let minHeight = screenHeight * 0.35

        return min(max(naturalHeight, minHeight), maxHeight)
    }

    // MARK: - Top Control Bar

    private func topControlBar(safeTop: CGFloat) -> some View {
        VStack {
            HStack {
                // Close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.Jakarta.semiBold(20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                }
                .accessibilityLabel("关闭")

                Spacer()

                // Share button with ShareLink
                if let result = viewModel.analysisResult {
                    ShareLink(
                        item: shareableImage,
                        preview: SharePreview(
                            "My Meal - \(result.totalCalories) kcal",
                            image: shareableImage
                        )
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.Jakarta.semiBold(20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                    .accessibilityLabel("分享")
                } else {
                    Button {
                        // Disabled state
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.Jakarta.semiBold(20))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .disabled(true)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, safeTop + 16)

            Spacer()
        }
        .ignoresSafeArea()
    }

    // MARK: - Collapsed Photo Bar

    private func collapsedPhotoBar(safeTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                if let result = viewModel.analysisResult {
                    Text("\(result.totalCalories) kcal")
                        .font(.Jakarta.bold(16))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 72)
            .frame(height: Layout.collapsedBarHeight)
            .background(.ultraThinMaterial)

            Spacer()
        }
        .padding(.top, safeTop)
        .ignoresSafeArea()
    }

    private var shareableImage: Image {
        if let generated = viewModel.generateShareImage() {
            return Image(uiImage: generated)
        }
        return Image(uiImage: image)
    }

    // MARK: - Food Edit Sheet

    private var foodEditSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Food name
                VStack(alignment: .leading, spacing: 8) {
                    Text("食物名称")
                        .font(.Jakarta.medium(13))
                        .foregroundColor(.secondary)

                    TextField("输入食物名称", text: $viewModel.editedFoodName)
                        .font(.Jakarta.regular(16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Calories
                VStack(alignment: .leading, spacing: 8) {
                    Text("热量")
                        .font(.Jakarta.medium(13))
                        .foregroundColor(.secondary)

                    HStack {
                        TextField("0", text: $viewModel.editedFoodCalories)
                            .font(.Jakarta.regular(16))
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("kcal")
                            .font(.Jakarta.medium(14))
                            .foregroundColor(.secondary)
                    }
                }

                // Portion
                VStack(alignment: .leading, spacing: 8) {
                    Text("份量")
                        .font(.Jakarta.medium(13))
                        .foregroundColor(.secondary)

                    HStack {
                        TextField("1", text: $viewModel.editedFoodPortion)
                            .font(.Jakarta.regular(16))
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("份")
                            .font(.Jakarta.medium(14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("编辑食物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        viewModel.cancelEditingFood()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.saveEditedFood()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
    }

    // MARK: - Image Display Frame Calculation

    /// 计算图片在 `.fill` 模式下的实际显示区域（供 FoodTagOverlay 使用）
    ///
    /// `.fill` 模式下图片填满整个 frame，超出部分被 clipped。
    /// FoodTagOverlay 需要知道图片的可见区域来正确映射食物标签坐标。
    private func updateImageDisplayFrame(screenWidth: CGFloat, imageHeight: CGFloat) {
        guard image.size.width > 0, image.size.height > 0 else { return }

        let imageAspect = image.size.width / image.size.height
        let frameAspect = screenWidth / imageHeight

        let filledWidth: CGFloat
        let filledHeight: CGFloat

        if imageAspect > frameAspect {
            // 图片更宽：高度填满 frame，宽度溢出被裁切
            filledHeight = imageHeight
            filledWidth = imageHeight * imageAspect
        } else {
            // 图片更高：宽度填满 frame，高度溢出被裁切
            filledWidth = screenWidth
            filledHeight = screenWidth / imageAspect
        }

        // 图片居中显示，计算可见区域的偏移（负值表示超出 frame 的部分）
        let offsetX = (screenWidth - filledWidth) / 2
        let offsetY = (imageHeight - filledHeight) / 2

        imageDisplayFrame = CGRect(
            x: offsetX,
            y: offsetY,
            width: filledWidth,
            height: filledHeight
        )
    }
}

#Preview {
    AnalysisView(image: UIImage(systemName: "photo")!)
        .environment(AppState())
        .modelContainer(for: [MealRecord.self], inMemory: true)
}
