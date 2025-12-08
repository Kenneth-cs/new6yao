import SwiftUI
import Foundation

// 表格数据结构
struct TableData {
    let headers: [String]
    let rows: [[String]]
}

// 格式化文本段落结构
struct FormattedTextSegment {
    let text: String
    let isTitle: Bool
    let isBullet: Bool
    let isNormal: Bool
    let isDivider: Bool
    let isTable: Bool
    let titleLevel: Int  // 2, 3, 4 for ##, ###, ####
    let tableData: TableData?
    
    init(text: String, isTitle: Bool = false, isBullet: Bool = false, 
         isNormal: Bool = false, isDivider: Bool = false, isTable: Bool = false,
         titleLevel: Int = 3, tableData: TableData? = nil) {
        self.text = text
        self.isTitle = isTitle
        self.isBullet = isBullet
        self.isNormal = isNormal
        self.isDivider = isDivider
        self.isTable = isTable
        self.titleLevel = titleLevel
        self.tableData = tableData
    }
}

// 格式化文本视图 - 支持Markdown格式显示
struct FormattedTextView: View {
    let segments: [FormattedTextSegment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                renderSegment(segment)
            }
        }
    }
    
    @ViewBuilder
    private func renderSegment(_ segment: FormattedTextSegment) -> some View {
        if segment.isTable, let tableData = segment.tableData {
            renderTable(tableData)
                .padding(.vertical, 8)
        } else {
            HStack(alignment: .top, spacing: 0) {
                if segment.isTitle {
                    formatInlineText(segment.text)
                        .font(segment.titleLevel == 2 ? .title2 : 
                              segment.titleLevel == 3 ? .title3 : .headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                } else if segment.isBullet {
                    Text("• ")
                        .font(.body)
                        .foregroundColor(.blue)
                    formatInlineText(segment.text)
                        .font(.body)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 4)
                } else if segment.isDivider {
                    Divider()
                        .frame(height: 1)
                        .background(Color.gray.opacity(0.3))
                } else {
                    formatInlineText(segment.text)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.vertical, segment.isTitle ? 6 : segment.isDivider ? 4 : 2)
            .padding(.leading, segment.isBullet ? 12 : 0)
        }
    }
    
    // 渲染表格
    @ViewBuilder
    private func renderTable(_ tableData: TableData) -> some View {
        VStack(spacing: 0) {
            // 表头
            HStack(spacing: 0) {
                ForEach(Array(tableData.headers.enumerated()), id: \.offset) { index, header in
                    Text(header)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
            }
            
            // 表格行
            ForEach(Array(tableData.rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
                        Text(cell)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .frame(maxWidth: .infinity)
                            .background(rowIndex % 2 == 0 ? Color.gray.opacity(0.05) : Color(.systemBackground))
                            .overlay(
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // 处理内联格式（加粗）
    private func formatInlineText(_ text: String) -> Text {
        var result = Text("")
        var currentText = ""
        var inBold = false
        var i = text.startIndex
        
        while i < text.endIndex {
            let char = text[i]
            
            // 检查 ** 加粗标记
            if char == "*" && i < text.index(before: text.endIndex) {
                let nextIndex = text.index(after: i)
                if nextIndex < text.endIndex && text[nextIndex] == "*" {
                    // 遇到 ** 标记
                    if !currentText.isEmpty {
                        if inBold {
                            result = result + Text(currentText).fontWeight(.bold).foregroundColor(.blue)
                        } else {
                            result = result + Text(currentText)
                        }
                        currentText = ""
                    }
                    inBold.toggle()
                    i = text.index(after: nextIndex)
                    continue
                }
            }
            
            currentText.append(char)
            i = text.index(after: i)
        }
        
        // 添加剩余文本
        if !currentText.isEmpty {
            if inBold {
                result = result + Text(currentText).fontWeight(.bold).foregroundColor(.blue)
            } else {
                result = result + Text(currentText)
            }
        }
        
        return result
    }
}

// 格式化AI解读文本函数 - 支持Markdown和表格
func formatAIText(_ text: String) -> [FormattedTextSegment] {
    var segments: [FormattedTextSegment] = []
    let lines = text.components(separatedBy: "\n")
    
    var i = 0
    while i < lines.count {
        let trimmedLine = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 跳过空行
        if trimmedLine.isEmpty {
            i += 1
            continue
        }
        
        // 检测表格（| 开头）
        if trimmedLine.hasPrefix("|") && trimmedLine.hasSuffix("|") {
            // 解析表格
            var tableLines: [String] = []
            var j = i
            while j < lines.count {
                let tableLine = lines[j].trimmingCharacters(in: .whitespacesAndNewlines)
                if tableLine.hasPrefix("|") && tableLine.hasSuffix("|") {
                    tableLines.append(tableLine)
                    j += 1
                } else {
                    break
                }
            }
            
            if let tableData = parseTable(tableLines) {
                segments.append(FormattedTextSegment(text: "", isTable: true, tableData: tableData))
            }
            i = j
            continue
        }
        
        // 检测分隔线 ---
        if trimmedLine.hasPrefix("---") || trimmedLine.hasPrefix("***") {
            segments.append(FormattedTextSegment(text: "", isDivider: true))
            i += 1
            continue
        }
        
        // 检测 Markdown 标题 ####
        if trimmedLine.hasPrefix("####") {
            let title = trimmedLine.replacingOccurrences(of: "####", with: "")
                .trimmingCharacters(in: .whitespaces)
            segments.append(FormattedTextSegment(text: title, isTitle: true, titleLevel: 4))
        }
        // 检测 Markdown 标题 ###
        else if trimmedLine.hasPrefix("###") {
            let title = trimmedLine.replacingOccurrences(of: "###", with: "")
                .trimmingCharacters(in: .whitespaces)
            segments.append(FormattedTextSegment(text: title, isTitle: true, titleLevel: 3))
        }
        // 检测 Markdown 标题 ##
        else if trimmedLine.hasPrefix("##") {
            let title = trimmedLine.replacingOccurrences(of: "##", with: "")
                .trimmingCharacters(in: .whitespaces)
            segments.append(FormattedTextSegment(text: title, isTitle: true, titleLevel: 2))
        }
        // 检测包含：的标题行（中文标题）
        else if trimmedLine.contains("：") && trimmedLine.count < 50 {
            segments.append(FormattedTextSegment(text: trimmedLine, isTitle: true, titleLevel: 3))
        }
        // 检测 Markdown 列表项（- 或 * 开头）
        else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
            let bulletText = trimmedLine.replacingOccurrences(of: "^[\\-\\*]\\s+", with: "", options: .regularExpression)
            segments.append(FormattedTextSegment(text: bulletText, isBullet: true))
        }
        // 检测数字列表 1. 2. 3.
        else if trimmedLine.range(of: "^\\d+\\.\\s+", options: .regularExpression) != nil {
            let bulletText = trimmedLine.replacingOccurrences(of: "^\\d+\\.\\s+", with: "", options: .regularExpression)
            segments.append(FormattedTextSegment(text: bulletText, isBullet: true))
        }
        // 普通段落
        else {
            segments.append(FormattedTextSegment(text: trimmedLine, isNormal: true))
        }
        
        i += 1
    }
    
    return segments
}

// 解析Markdown表格
private func parseTable(_ lines: [String]) -> TableData? {
    guard lines.count >= 2 else { return nil }
    
    // 解析表头
    let headerLine = lines[0]
    let headers = headerLine
        .components(separatedBy: "|")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
    
    guard !headers.isEmpty else { return nil }
    
    // 解析数据行（跳过分隔行）
    var rows: [[String]] = []
    for i in 1..<lines.count {
        let line = lines[i]
        // 跳过分隔行（包含 --- 或 :---: 等）
        if line.contains("---") || line.contains(":--") {
            continue
        }
        
        let cells = line
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        if !cells.isEmpty {
            rows.append(cells)
        }
    }
    
    return TableData(headers: headers, rows: rows)
}
