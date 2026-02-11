import SwiftUI

struct CalorieRingChart: View {

    // MARK: - Properties

    let calorieProgress: Double
    let proteinProgress: Double
    let carbsProgress: Double

    // MARK: - State

    @State private var animatedCalorieProgress: Double = 0
    @State private var animatedProteinProgress: Double = 0
    @State private var animatedCarbsProgress: Double = 0

    // MARK: - Design Constants

    private let lineWidth: CGFloat = 14
    private let ringGap: CGFloat = 22
    private let trackColor: Color = .gray.opacity(0.1)

    // MARK: - Gradient Colors

    /// 外环渐变 - 卡路里：深绿到墨绿（森林渐变）
    private var calorieGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#076653"),
                Color(hex: "#102216")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 中环渐变 - 蛋白质：黄绿色（青柠-鼠尾草渐变）
    private var proteinGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#E3EF26"),
                Color(hex: "#076653")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 内环渐变 - 碳水：奶油到薄荷（奶油-薄荷渐变）
    private var carbsGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#FFFDEE"),
                Color(hex: "#E2FBCE")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                outerRing(diameter: size)
                middleRing(diameter: size - ringGap * 2)
                innerRing(diameter: size - ringGap * 4)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            animateProgressOnAppear()
        }
        .onChange(of: calorieProgress) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedCalorieProgress = newValue
            }
        }
        .onChange(of: proteinProgress) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProteinProgress = newValue
            }
        }
        .onChange(of: carbsProgress) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedCarbsProgress = newValue
            }
        }
    }

    // MARK: - Ring Layers

    private func outerRing(diameter: CGFloat) -> some View {
        ringLayer(
            progress: animatedCalorieProgress,
            gradient: calorieGradient,
            diameter: diameter
        )
    }

    private func middleRing(diameter: CGFloat) -> some View {
        ringLayer(
            progress: animatedProteinProgress,
            gradient: proteinGradient,
            diameter: diameter
        )
    }

    private func innerRing(diameter: CGFloat) -> some View {
        ringLayer(
            progress: animatedCarbsProgress,
            gradient: carbsGradient,
            diameter: diameter
        )
    }

    @ViewBuilder
    private func ringLayer(
        progress: Double,
        gradient: LinearGradient,
        diameter: CGFloat
    ) -> some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
                .frame(width: diameter - lineWidth, height: diameter - lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter - lineWidth, height: diameter - lineWidth)
                .rotationEffect(.degrees(-90))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        }
    }

    // MARK: - Private Methods

    private func animateProgressOnAppear() {
        withAnimation(.easeOut(duration: 1.2)) {
            animatedCalorieProgress = calorieProgress
            animatedProteinProgress = proteinProgress
            animatedCarbsProgress = carbsProgress
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        CalorieRingChart(
            calorieProgress: 0.72,
            proteinProgress: 0.75,
            carbsProgress: 0.48
        )
        .frame(width: 200, height: 200)

        CalorieRingChart(
            calorieProgress: 0.5,
            proteinProgress: 0.6,
            carbsProgress: 0.4
        )
        .frame(width: 150, height: 150)
    }
    .padding()
}
