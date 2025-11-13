import Foundation

struct AISummaryGenerator {
    static func reviewSession(_ s: Session, app: AppState) async -> (String, [String], String?) {
        let series = s.hrSeries.isEmpty ? Array(repeating: s.heartRateAvg, count: 16) : s.hrSeries
        let spark = Sparkline.from(series: series)
        let json = "{\"focusMinutes\":\(s.focusMinutes),\"restMinutes\":\(s.restMinutes),\"hrAvg\":\(Int(s.heartRateAvg)),\"hrv\":\(Int(s.hrvAvg))}"
        let prompt = PromptFactory().review(sessionJSON: json, sparkline: spark)
        guard AIFactory.available(app: app) else { return ("", [], "未配置或不可用") }
        let ai = AIFactory.make(app: app)
        let result = await ai.review(summaryInput: prompt)
        let summary = result.0
        let tips = result.1
        return (summary, tips, summary.isEmpty ? "连接失败" : nil)
    }
    static func reviewAggregate(_ sessions: [Session], app: AppState) async -> (String, [String], String?) {
        let arr = sessions.map { s in
            [
                "start": ISO8601DateFormatter().string(from: s.startedAt),
                "focus": s.focusMinutes,
                "rest": s.restMinutes,
                "hrAvg": Int(s.heartRateAvg),
                "hrv": Int(s.hrvAvg)
            ] as [String : Any]
        }
        let data = try? JSONSerialization.data(withJSONObject: arr)
        let agg = String(data: data ?? Data("[]".utf8), encoding: .utf8) ?? "[]"
        var series: [Double] = []
        for s in sessions { if !s.hrSeries.isEmpty { series.append(contentsOf: s.hrSeries) } else { series.append(s.heartRateAvg) } }
        let spark = Sparkline.from(series: series)
        let prompt = PromptFactory().reviewAggregate(sessionsJSON: agg, sparkline: spark)
        guard AIFactory.available(app: app) else { return ("", [], "未配置或不可用") }
        let ai = AIFactory.make(app: app)
        let result = await ai.review(summaryInput: prompt)
        let summary = result.0
        let tips = result.1
        return (summary, tips, summary.isEmpty ? "连接失败" : nil)
    }
}

