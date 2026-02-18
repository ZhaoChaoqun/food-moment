import SwiftUI

/// 圆环形状 - 用于进度指示器
struct RingShape: Shape {

    // MARK: - Properties

    var progress: Double
    var lineWidth: CGFloat

    // MARK: - Animatable Data

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    // MARK: - Path

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress),
            clockwise: false
        )

        return path.strokedPath(
            StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
    }
}

// MARK: - Ring View

/// 圆环视图组件 - 带有轨道和进度显示
struct RingView: View {

    // MARK: - Properties

    let progress: Double
    let lineWidth: CGFloat
    let gradient: LinearGradient
    let trackColor: Color

    // MARK: - Initialization

    init(
        progress: Double,
        lineWidth: CGFloat = 14,
        gradient: LinearGradient = LinearGradient(
            colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        trackColor: Color = .gray.opacity(0.1)
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.trackColor = trackColor
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            trackCircle
            progressCircle
        }
        .accessibilityIdentifier("RingView")
    }

    // MARK: - Track Circle

    private var trackCircle: some View {
        Circle()
            .stroke(trackColor, lineWidth: lineWidth)
    }

    // MARK: - Progress Circle

    private var progressCircle: some View {
        Circle()
            .trim(from: 0, to: CGFloat(min(progress, 1.0)))
            .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        RingView(progress: 0.75)
            .frame(width: 100, height: 100)

        RingShape(progress: 0.5, lineWidth: 10)
            .fill(AppTheme.Colors.primary)
            .frame(width: 80, height: 80)
    }
    .padding()
}
