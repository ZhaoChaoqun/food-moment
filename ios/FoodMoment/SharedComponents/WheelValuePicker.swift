import SwiftUI

/// 可复用的双列数值滚轮选择器（整数 + 小数），用于身高和体重等场景。
struct WheelValuePicker: View {

    @Binding var integerPart: Int
    @Binding var decimalPart: Int
    let integerRange: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack(spacing: 0) {
            Picker("", selection: $integerPart) {
                ForEach(Array(integerRange), id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100, height: 150)
            .clipped()

            Text(".")
                .font(Font.Jakarta.bold(20))
                .foregroundStyle(.primary)

            Picker("", selection: $decimalPart) {
                ForEach(0...9, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60, height: 150)
            .clipped()

            Text(unit)
                .font(Font.Jakarta.medium(16))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        }
    }
}
