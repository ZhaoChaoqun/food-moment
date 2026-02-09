import SwiftUI

/// Overlays food tag pins on the analyzed photo at positions
/// derived from each food item's bounding box coordinates.
/// Tags appear sequentially with scale + opacity transitions.
struct FoodTagOverlay: View {

    let detectedFoods: [DetectedFoodDTO]
    var onFoodTapped: ((Int) -> Void)?

    @State private var visibleIndices: Set<Int> = []

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ForEach(Array(detectedFoods.enumerated()), id: \.offset) { index, food in
                let position = tagPosition(for: food, in: size)

                if visibleIndices.contains(index) {
                    FoodTagPin(food: food) {
                        onFoodTapped?(index)
                    }
                    .position(position)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            animateTagsSequentially()
        }
    }

    // MARK: - Helpers

    /// Computes the center position for a food tag based on its bounding box.
    /// The bounding box uses normalized coordinates (0...1).
    private func tagPosition(for food: DetectedFoodDTO, in size: CGSize) -> CGPoint {
        let box = food.boundingBox
        let centerX = (box.x + box.w / 2) * size.width
        let centerY = box.y * size.height
        return CGPoint(x: centerX, y: centerY)
    }

    /// Reveals tags one by one with staggered delays.
    private func animateTagsSequentially() {
        for index in detectedFoods.indices {
            let delay = Double(index) * 0.25 + 0.3
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.7)
                .delay(delay)
            ) {
                visibleIndices.insert(index)
            }
        }
    }
}
