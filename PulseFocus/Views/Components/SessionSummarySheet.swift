import SwiftUI
import SwiftData

struct SessionSummarySheet: View {
    @ObservedObject var app: AppState
    @Environment(\.modelContext) private var model
    @State private var summaryText: String = ""
    @State private var tips: [String] = []
    @State private var coachAdvice: AIAdvice? = nil
    @State private var loadingReview: Bool = true
    @State private var loadingCoach: Bool = true
    var body: some View {
        VStack(spacing: 16) {
            Text("复盘总结").font(.system(size: 28, weight: .bold))
            SectionCard(title: "AI 总结") {
                if loadingReview { ProgressView().progressViewStyle(.circular) } else { Text(SummaryParser.summary(from: summaryText)).font(.system(size: 17)).multilineTextAlignment(.leading).lineSpacing(4) }
            }
            SectionCard(title: "改进建议") {
                if loadingReview { ProgressView().progressViewStyle(.circular) } else {
                    let list = tips.isEmpty ? SummaryParser.suggestions(from: summaryText, fallback: []) : tips
                    VStack(alignment: .leading, spacing: 8) { ForEach(list, id: \.self) { t in Text("• " + t).fixedSize(horizontal: false, vertical: true) } }
                }
            }
            if let c = coachAdvice {
                SectionCard(title: "下一段建议") {
                    HStack(spacing: 16) {
                        Label("专注 \(c.focusMinutes) 分钟", systemImage: "hourglass")
                        Label("休息 \(c.restMinutes) 分钟", systemImage: "cup.and.saucer")
                    }.font(.system(size: 17))
                    Text(c.phrase).font(.system(size: 17)).foregroundStyle(.secondary)
                }
            } else if loadingCoach {
                SectionCard(title: "下一段建议") { ProgressView().progressViewStyle(.circular) }
            }
            Button("保存并关闭") {
                let s = Session(startedAt: Date(), endedAt: Date(), mode: app.mode, phase: .idle, focusMinutes: app.focusMinutes, restMinutes: app.restMinutes, heartRateAvg: HealthManager.shared.heartRate, hrvAvg: HealthManager.shared.hrv, restingHeartRate: HealthManager.shared.restingHeartRate, score: 80, pauseCount: 0, hrSeries: [])
                model.insert(s)
                app.showSummary = false
            }.buttonStyle(.borderedProminent).disabled(loadingReview || loadingCoach)
        }.padding()
        .task { await requestReview(); await requestCoach() }
    }
    private func requestReview() async {
        let result = await AISummaryGenerator.reviewSession(Session(focusMinutes: app.focusMinutes, restMinutes: app.restMinutes, heartRateAvg: HealthManager.shared.heartRate, hrvAvg: HealthManager.shared.hrv, restingHeartRate: HealthManager.shared.restingHeartRate), app: app)
        summaryText = result.0
        tips = result.1
        loadingReview = false
    }
    private func requestCoach() async {
        if AIFactory.available(app: app) {
            let ai = AIFactory.make(app: app)
            coachAdvice = await ai.coach(task: "当前任务", rhr: HealthManager.shared.restingHeartRate, hrv: HealthManager.shared.hrv, hrAvg: HealthManager.shared.heartRate)
        }
        loadingCoach = false
    }
}
