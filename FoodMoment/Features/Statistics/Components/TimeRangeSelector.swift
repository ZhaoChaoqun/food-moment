import SwiftUI

struct TimeRangeSelector: View {

    // MARK: - Properties

    @Bindable var viewModel: StatisticsViewModel

    // MARK: - Body

    var body: some View {
        Picker("Time Range", selection: $viewModel.selectedRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.rawValue)
                    .tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .accessibilityIdentifier("TimeRangeSelector")
    }
}
