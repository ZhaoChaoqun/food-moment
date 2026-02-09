import SwiftUI
import SwiftData
import UIKit

/// The main analysis result screen presented after capturing a food photo.
/// Displays the photo with food tag overlays and a bottom sheet containing
/// calorie totals, nutrition rings, AI insights, and a log button.
struct AnalysisView: View {

    let image: UIImage

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: AnalysisViewModel
    @State private var showSheet: Bool = true
    @State private var shareImage: UIImage?

    init(image: UIImage) {
        self.image = image
        self._viewModel = State(initialValue: AnalysisViewModel(capturedImage: image))
    }

    var body: some View {
        ZStack {
            // MARK: - Background: Full-screen food photo with gradient overlay
            photoBackground

            // MARK: - Food tag overlay
            if let result = viewModel.analysisResult {
                FoodTagOverlay(
                    detectedFoods: result.detectedFoods,
                    onFoodTapped: { index in
                        viewModel.startEditingFood(at: index)
                    }
                )
            }

            // MARK: - Top control bar
            topControlBar

            // MARK: - Loading indicator
            if viewModel.isAnalyzing {
                loadingOverlay
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showSheet) {
            bottomSheetContent
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationCornerRadius(AppTheme.CornerRadius.extraLarge)
                .presentationBackground(.thickMaterial)
                .interactiveDismissDisabled()
        }
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

    // MARK: - Photo Background

    private var photoBackground: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.5), location: 0),
                            .init(color: .clear, location: 0.25),
                            .init(color: .clear, location: 0.55),
                            .init(color: .black.opacity(0.3), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    // MARK: - Top Control Bar

    private var topControlBar: some View {
        VStack {
            HStack {
                // Close button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                }

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
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    }
                } else {
                    Button {
                        // Disabled state
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .disabled(true)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)

            Spacer()
        }
    }

    // MARK: - Shareable Image

    private var shareableImage: Image {
        if let generated = viewModel.generateShareImage() {
            return Image(uiImage: generated)
        }
        return Image(uiImage: image)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
                    .scaleEffect(1.2)

                Text("Analyzing your food...")
                    .font(.Jakarta.medium(15))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
    }

    // MARK: - Bottom Sheet Content

    private var bottomSheetContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Drag indicator
                dragIndicator

                if let result = viewModel.analysisResult {
                    // Total energy header
                    totalEnergySection(result)

                    // Nutrition rings
                    NutritionRingsRow(nutrition: result.totalNutrition)
                        .padding(.horizontal, 20)

                    // Tags row
                    if !result.tags.isEmpty {
                        tagsRow(result.tags)
                    }

                    // AI insight card
                    AIInsightCard(analysisText: result.aiAnalysis)
                        .padding(.horizontal, 20)

                    // Log meal button
                    LogMealButton {
                        viewModel.saveMeal(modelContext: modelContext)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                } else if viewModel.isAnalyzing {
                    analysingPlaceholder
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                }
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Food Edit Sheet

    private var foodEditSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Food name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Food Name")
                        .font(.Jakarta.medium(13))
                        .foregroundColor(.secondary)

                    TextField("Enter food name", text: $viewModel.editedFoodName)
                        .font(.Jakarta.regular(16))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Calories
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calories")
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
                    Text("Portion")
                        .font(.Jakarta.medium(13))
                        .foregroundColor(.secondary)

                    HStack {
                        TextField("1", text: $viewModel.editedFoodPortion)
                            .font(.Jakarta.regular(16))
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("serving")
                            .font(.Jakarta.medium(14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditingFood()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveEditedFood()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
    }

    // MARK: - Subviews

    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.white.opacity(0.3))
            .frame(width: 48, height: 6)
    }

    private func totalEnergySection(_ result: AnalysisResponseDTO) -> some View {
        VStack(spacing: 4) {
            Text("TOTAL ENERGY")
                .font(.Jakarta.semiBold(14))
                .foregroundColor(.white.opacity(0.5))
                .tracking(2)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(result.totalCalories)")
                    .font(.Jakarta.extraBold(48))
                    .foregroundColor(.white)

                Text("kcal")
                    .font(.Jakarta.bold(20))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
    }

    private func tagsRow(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.Jakarta.medium(12))
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.primary.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var analysingPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))

            Text("Analyzing nutrients...")
                .font(.Jakarta.medium(14))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)

            Text(message)
                .font(.Jakarta.medium(14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.analyzeFood()
                }
            } label: {
                Text("Retry")
                    .font(.Jakarta.semiBold(15))
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .stroke(AppTheme.Colors.primary, lineWidth: 1.5)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
}
