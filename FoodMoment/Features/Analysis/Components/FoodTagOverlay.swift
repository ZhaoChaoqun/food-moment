import SwiftUI

/// Overlays food tag pins on the analyzed photo at positions
/// derived from each food item's bounding box coordinates.
/// Tags appear sequentially with scale + opacity transitions.
/// Includes anti-overlap logic to prevent labels from colliding.
struct FoodTagOverlay: View {

    let detectedFoods: [DetectedFoodDTO]
    /// The actual display frame of the fitted image within the screen
    let imageDisplayFrame: CGRect
    var onFoodTapped: ((Int) -> Void)?

    @State private var visibleIndices: Set<Int> = []
    @State private var resolvedPositions: [CGPoint] = []

    // Estimated tag dimensions for overlap detection
    private enum TagSize {
        static let estimatedWidth: CGFloat = 140
        static let estimatedHeight: CGFloat = 36
        // Total pin height: capsule + connector (24) + anchor dot (8)
        static let totalPinHeight: CGFloat = 68
        static let minSpacing: CGFloat = 8
    }

    var body: some View {
        ZStack {
            ForEach(Array(detectedFoods.enumerated()), id: \.element.id) { index, food in
                if visibleIndices.contains(index), index < resolvedPositions.count {
                    FoodTagPin(food: food) {
                        onFoodTapped?(index)
                    }
                    .position(resolvedPositions[index])
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            resolvedPositions = computeResolvedPositions()
            animateTagsSequentially()
        }
        .onChange(of: detectedFoods.map(\.id)) { _, _ in
            resolvedPositions = computeResolvedPositions()
        }
        .onChange(of: imageDisplayFrame) { _, _ in
            resolvedPositions = computeResolvedPositions()
        }
    }

    // MARK: - Overlap Resolution

    /// Computes adjusted positions for all tags so they don't overlap.
    /// Uses a simple iterative push-apart algorithm on the Y axis.
    private func computeResolvedPositions() -> [CGPoint] {
        guard !detectedFoods.isEmpty else { return [] }

        // Start with raw positions
        var positions = detectedFoods.map { tagPosition(for: $0) }

        let requiredVerticalGap = TagSize.estimatedHeight + TagSize.minSpacing

        // Sort indices by Y to process top-to-bottom
        let sortedIndices = positions.indices.sorted { positions[$0].y < positions[$1].y }

        // Multiple passes to resolve cascading overlaps
        for _ in 0..<5 {
            var didAdjust = false

            for i in 0..<sortedIndices.count {
                for j in (i + 1)..<sortedIndices.count {
                    let idxA = sortedIndices[i]
                    let idxB = sortedIndices[j]

                    let dx = abs(positions[idxA].x - positions[idxB].x)
                    let dy = abs(positions[idxA].y - positions[idxB].y)

                    // Check if tags overlap horizontally (within estimated width)
                    if dx < TagSize.estimatedWidth && dy < requiredVerticalGap {
                        // Push them apart vertically, centered around their midpoint
                        let midY = (positions[idxA].y + positions[idxB].y) / 2
                        let halfGap = requiredVerticalGap / 2

                        if positions[idxA].y <= positions[idxB].y {
                            positions[idxA].y = midY - halfGap
                            positions[idxB].y = midY + halfGap
                        } else {
                            positions[idxB].y = midY - halfGap
                            positions[idxA].y = midY + halfGap
                        }
                        didAdjust = true
                    }
                }
            }

            if !didAdjust { break }
        }

        // Horizontal staggering: alternate left/right offsets for vertically-sorted tags
        // to avoid them forming a straight column
        let staggerAmount: CGFloat = 40
        for (rank, idx) in sortedIndices.enumerated() {
            let direction: CGFloat = rank.isMultiple(of: 2) ? -1 : 1
            positions[idx].x += staggerAmount * direction
        }

        // Clamp positions to stay within image bounds
        let minY = imageDisplayFrame.origin.y + TagSize.totalPinHeight / 2
        let maxY = imageDisplayFrame.origin.y + imageDisplayFrame.height - TagSize.totalPinHeight / 2
        let minX = imageDisplayFrame.origin.x + TagSize.estimatedWidth / 2
        let maxX = imageDisplayFrame.origin.x + imageDisplayFrame.width - TagSize.estimatedWidth / 2

        for i in positions.indices {
            positions[i].y = min(max(positions[i].y, minY), maxY)
            positions[i].x = min(max(positions[i].x, minX), maxX)
        }

        return positions
    }

    // MARK: - Helpers

    /// Computes the center position for a food tag based on its bounding box.
    /// Maps normalized coordinates (0...1) to the actual displayed image area.
    private func tagPosition(for food: DetectedFoodDTO) -> CGPoint {
        let box = food.boundingBox
        let centerX = imageDisplayFrame.origin.x + (box.x + box.w / 2) * imageDisplayFrame.width
        let centerY = imageDisplayFrame.origin.y + (box.y + box.h / 2) * imageDisplayFrame.height
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
