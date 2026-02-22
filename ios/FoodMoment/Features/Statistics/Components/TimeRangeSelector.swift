import SwiftUI

struct TimeRangeSelector: View {

    // MARK: - Properties

    @Bindable var viewModel: StatisticsViewModel

    @Namespace private var animation

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases) { range in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        viewModel.selectedRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.Jakarta.semiBold(14))
                        .foregroundStyle(
                            viewModel.selectedRange == range
                                ? .white
                                : .secondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if viewModel.selectedRange == range {
                                Capsule()
                                    .fill(AppTheme.Colors.primary)
                                    .matchedGeometryEffect(id: "selector", in: animation)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(.systemGray6).opacity(0.6))
        )
        .padding(.horizontal, 20)
        .accessibilityIdentifier("TimeRangeSelector")
    }
}
