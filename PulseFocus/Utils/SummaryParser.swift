import Foundation

struct SummaryParser {
    static func summary(from text: String) -> String {
        let trimmed = text.replacingOccurrences(of: "\r", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        let lines = trimmed.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        var out: [String] = []
        for l in lines {
            if l.isEmpty { if !out.isEmpty { break } else { continue } }
            if l.hasPrefix("标题：") { let c = l.replacingOccurrences(of: "标题：", with: "").trimmingCharacters(in: .whitespaces); if !c.isEmpty { out.append(c) }; continue }
            if l == "总体表现摘要" || l == "近期总体表现摘要" || l == "总结" { continue }
            if l.hasPrefix("列表") || l.localizedCaseInsensitiveContains("建议 #") || l.hasPrefix("-") || l.hasPrefix("•") { break }
            out.append(l)
            if out.joined().count >= 220 { break }
        }
        let joined = out.joined(separator: " ")
        return joined.isEmpty ? trimmed : joined
    }
    static func suggestions(from text: String, fallback: [String]) -> [String] {
        let lines = text.replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n")
        var out: [String] = []
        var current: String = ""
        func commit() {
            let t = current.trimmingCharacters(in: .whitespaces)
            if !t.isEmpty { out.append(t) }
            current = ""
        }
        for raw in lines {
            var t = raw.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { if !current.isEmpty { commit() }; continue }
            if t.hasPrefix("标题：") || t == "总体表现摘要" || t == "近期总体表现摘要" { continue }
            if t.hasPrefix("列表") || t == "列表：" || t == "• 列表：" { continue }
            if t.hasPrefix("•") { t = String(t.dropFirst()).trimmingCharacters(in: .whitespaces) }
            if t.hasPrefix("-") { t = String(t.dropFirst()).trimmingCharacters(in: .whitespaces) }
            if t.localizedCaseInsensitiveContains("建议 #") {
                if !current.isEmpty { commit() }
                current = t
            } else {
                if !current.isEmpty { current += " " + t }
                else { out.append(t) }
            }
        }
        if !current.isEmpty { commit() }
        return out.isEmpty ? fallback : out
    }
}
