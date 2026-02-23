import SwiftUI

struct CalorieRingChart: View {

    // MARK: - Properties

    let progress: Double

    // MARK: - State

    @State private var animatedProgress: Double = 0

    // MARK: - Design Constants

    private let lineWidth: CGFloat = 20

    /// 亮黄绿色（进度弧线）
    private var progressColor: Color { AppTheme.Colors.calorieRingProgress }
    /// 深绿色（底部轨道）
    private var trackColor: Color { AppTheme.Colors.calorieRingTrack }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                singleRing(diameter: size)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newValue
            }
        }
    }

    // MARK: - Single Ring

    private func singleRing(diameter: CGFloat) -> some View {
        let ringDiameter = diameter - lineWidth
        let radius = ringDiameter / 2
        let clampedProgress = max(animatedProgress, 0)

        return ZStack {
            // 底部轨道
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
                .frame(width: ringDiameter, height: ringDiameter)

            if clampedProgress <= 1.0 {
                normalArc(
                    progress: clampedProgress,
                    ringDiameter: ringDiameter,
                    radius: radius
                )
            } else {
                overflowArc(
                    progress: clampedProgress,
                    ringDiameter: ringDiameter,
                    radius: radius
                )
            }
        }
    }

    // MARK: - Normal Arc (≤ 100%)

    @ViewBuilder
    private func normalArc(
        progress: Double,
        ringDiameter: CGFloat,
        radius: CGFloat
    ) -> some View {
        Circle()
            .trim(from: 0, to: CGFloat(progress))
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        progressColor.opacity(0.8),
                        progressColor,
                        progressColor.opacity(0.9)
                    ]),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360 * progress)
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: ringDiameter, height: ringDiameter)
            .rotationEffect(.degrees(-90))
            .shadow(color: progressColor.opacity(0.4), radius: 8, x: 0, y: 0)

        if progress > 0.05 {
            endCapCircle(
                progress: progress,
                radius: radius,
                shadowRadius: 6,
                shadowOpacity: 0.4
            )
        }
    }

    // MARK: - Overflow Arc (> 100%)

    @ViewBuilder
    private func overflowArc(
        progress: Double,
        ringDiameter: CGFloat,
        radius: CGFloat
    ) -> some View {
        let overProgress = progress - 1.0

        // 底层：完整一圈
        Circle()
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        progressColor.opacity(0.6),
                        progressColor.opacity(0.7),
                        progressColor.opacity(0.6)
                    ]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: ringDiameter, height: ringDiameter)
            .rotationEffect(.degrees(-90))

        // 叠加层：超出弧线（更亮 + 发光）
        Circle()
            .trim(from: 0, to: CGFloat(min(overProgress, 1.0)))
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        progressColor,
                        AppTheme.Colors.calorieRingOverflow,
                        progressColor
                    ]),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360 * min(overProgress, 1.0))
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: ringDiameter, height: ringDiameter)
            .rotationEffect(.degrees(-90))
            .shadow(color: progressColor.opacity(0.6), radius: 8, x: 0, y: 0)

        // 末端阴影圆
        endCapCircle(
            progress: min(overProgress, 1.0),
            radius: radius,
            shadowRadius: 8,
            shadowOpacity: 0.6
        )
    }

    // MARK: - End Cap Circle

    private func endCapCircle(
        progress: Double,
        radius: CGFloat,
        shadowRadius: CGFloat,
        shadowOpacity: Double
    ) -> some View {
        let angle = Angle(degrees: 360 * progress - 90)
        let x = radius * cos(CGFloat(angle.radians))
        let y = radius * sin(CGFloat(angle.radians))

        return Circle()
            .fill(progressColor)
            .frame(width: lineWidth, height: lineWidth)
            .shadow(color: progressColor.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 0)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .offset(x: x, y: y)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // 正常进度
        CalorieRingChart(progress: 0.72)
            .frame(width: 220, height: 220)

        // 超标情况
        CalorieRingChart(progress: 1.15)
            .frame(width: 220, height: 220)
    }
    .padding()
}
