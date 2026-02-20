import Foundation

/// 类型安全的 CSV 构建器
///
/// 自动处理引号转义和特殊字符，替代手动字符串拼接。
///
/// ## 使用示例
/// ```swift
/// var csv = CSVBuilder(headers: ["Date", "Calories", "Protein(g)"])
/// csv.addRow(["2026-01-01", "500", "25.0"])
/// let output = csv.build()
/// ```
struct CSVBuilder {

    private let headers: [String]
    private var rows: [[String]] = []

    init(headers: [String]) {
        self.headers = headers
    }

    /// 添加一行数据
    mutating func addRow(_ values: [String]) {
        rows.append(values)
    }

    /// 生成 CSV 字符串
    func build() -> String {
        var lines: [String] = []
        lines.append(headers.map { escapeField($0) }.joined(separator: ","))

        for row in rows {
            lines.append(row.map { escapeField($0) }.joined(separator: ","))
        }

        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - Private

    /// 对包含逗号、引号或换行的字段添加引号转义
    private func escapeField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
