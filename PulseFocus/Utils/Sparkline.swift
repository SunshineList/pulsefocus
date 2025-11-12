import Foundation

struct Sparkline {
    static func from(series: [Double], buckets: Int = 16) -> String {
        guard !series.isEmpty else { return "" }
        let size = max(1, series.count / buckets)
        var values: [Double] = []
        var i = 0
        while i < series.count {
            let end = min(series.count, i + size)
            let slice = series[i..<end]
            values.append(slice.reduce(0, +) / Double(slice.count))
            i += size
        }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let shades = "▁▂▃▄▅▆▇█"
        let mapped = values.map { v -> Character in
            let t = (v - minV) / max(0.0001, maxV - minV)
            let idx = Int(t * Double(shades.count - 1))
            return shades[shades.index(shades.startIndex, offsetBy: idx)]
        }
        return String(mapped)
    }
}

