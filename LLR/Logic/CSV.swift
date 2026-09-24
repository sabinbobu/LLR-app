import Foundation

/// RFC 4180 reading and writing. Both Hevy and Strong quote fields that contain the delimiter
/// (Hevy's dates look like "28 Mar 2025, 17:29"), so splitting lines on commas corrupts rows.
enum CSV {
    static func parse(_ text: String, delimiter: Character = ",") -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        let chars = Array(text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if inQuotes {
                if ch == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" {
                        field.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(ch)
                }
            } else if ch == "\"" {
                inQuotes = true
            } else if ch == delimiter {
                row.append(field)
                field = ""
            } else if ch.isNewline {
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else {
                field.append(ch)
            }
            i += 1
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows.filter { $0.contains { !$0.isEmpty } }
    }

    /// Comma-decimal locales export with semicolons; the header line says which one this file uses.
    static func delimiter(of text: String) -> Character {
        let header = text.prefix { !$0.isNewline }
        return header.filter { $0 == ";" }.count > header.filter { $0 == "," }.count ? ";" : ","
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    static func line(_ fields: [String]) -> String {
        fields.map(escape).joined(separator: ",")
    }
}
