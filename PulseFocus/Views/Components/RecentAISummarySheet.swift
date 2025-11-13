import SwiftUI
import SwiftData

struct RecentAISummarySheet: View {
    @ObservedObject var app: AppState
    let sessions: [Session]
    @Environment(\.dismiss) private var dismiss
    @State private var summaryText: String = ""
    @State private var tips: [String] = []
    @State private var loading: Bool = true
    @State private var showError: Bool = false
    @State private var errorText: String = ""
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.green.opacity(0.2), Color.purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("近期总结报告").font(.system(size: 28, weight: .bold))
                        Text(rangeText()).font(.callout).foregroundStyle(.secondary)
                    }
                    if showError {
                        SectionCard(title: "连接状态") { Text(errorText).font(.system(size: 17)).foregroundStyle(.red) }
                    }
                    if loading { ProgressView().progressViewStyle(.circular) } else {
                        SectionCard(title: "总结") {
                            Text(summaryText.isEmpty ? "暂无 AI 文本，请检查连接" : SummaryParser.summary(from: summaryText)).font(.system(size: 17)).multilineTextAlignment(.leading).lineSpacing(4)
                        }
                        SectionCard(title: "改进建议") {
                            let list = tips.isEmpty ? SummaryParser.suggestions(from: summaryText, fallback: []) : tips
                            VStack(alignment: .leading, spacing: 8) { ForEach(list, id: \.self) { t in Text("• " + t).fixedSize(horizontal: false, vertical: true) } }
                        }
                    }
                    Button("关闭") { dismiss() }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                }.padding()
            }
        }
        .task { await requestSummary(); loading = false }
        .alert("AI 连接失败", isPresented: $showError) { Button("好的", role: .cancel) {} } message: { Text(errorText) }
        .presentationDetents([.medium, .large])
    }
    private func requestSummary() async {
        let agg = aggregateJSON()
        let spark = aggregateSparkline()
        let result = await AISummaryGenerator.reviewAggregate(sessions, app: app)
        summaryText = result.0
        tips = result.1
        if let err = result.2 { showError = true; errorText = "AI连接失败或未配置：\(err)" }
    }
    private func aggregateJSON() -> String {
        let arr = sessions.map { s in
            [
                "start": ISO8601DateFormatter().string(from: s.startedAt),
                "focus": s.focusMinutes,
                "rest": s.restMinutes,
                "hrAvg": Int(s.heartRateAvg),
                "hrv": Int(s.hrvAvg)
            ]
        }
        if let data = try? JSONSerialization.data(withJSONObject: arr), let str = String(data: data, encoding: .utf8) { return str }
        return "[]"
    }
    private func aggregateSparkline() -> String {
        var series: [Double] = []
        for s in sessions { if !s.hrSeries.isEmpty { series.append(contentsOf: s.hrSeries) } else { series.append(s.heartRateAvg) } }
        return Sparkline.from(series: series)
    }
    private func rangeText() -> String {
        guard let minD = sessions.map({ $0.startedAt }).min(), let maxD = sessions.map({ $0.startedAt }).max() else { return "" }
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "yyyy年M月d日"
        return "范围：\(f.string(from: minD)) – \(f.string(from: maxD))"
    }
}
