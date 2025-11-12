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
                if loadingReview { ProgressView().progressViewStyle(.circular) } else { Text(summaryText).font(.system(size: 17)).multilineTextAlignment(.leading) }
            }
            SectionCard(title: "改进建议") {
                if loadingReview { ProgressView().progressViewStyle(.circular) } else {
                    VStack(alignment: .leading, spacing: 8) { ForEach(tips, id: \.self) { t in Text("• " + t) } }
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
        let spark = Sparkline.from(series: [])
        let prompt = PromptFactory().review(sessionJSON: "{}", sparkline: spark)
        if app.aiEnabled, let key = SecureStore.get("aiKey"), !key.isEmpty {
            var endpoint = AIEndpoint(baseURL: app.aiBaseURL)
            endpoint.apiKeyHeaderName = app.aiKeyHeaderName
            endpoint.apiKeyPrefix = app.aiKeyPrefix
            let ai = AIService(provider: .remote, endpoint: endpoint, model: app.aiModel, apiKey: key)
            let result = await ai.review(summaryInput: prompt)
            summaryText = result.0
            tips = result.1
            loadingReview = false
        } else {
            summaryText = "AI未配置或连接失败，请在设置中填写 API Key 并测试连接"
            tips = []
            loadingReview = false
        }
    }
    private func requestCoach() async {
        if app.aiEnabled, let key = SecureStore.get("aiKey"), !key.isEmpty {
            var endpoint = AIEndpoint(baseURL: app.aiBaseURL)
            endpoint.apiKeyHeaderName = app.aiKeyHeaderName
            endpoint.apiKeyPrefix = app.aiKeyPrefix
            let ai = AIService(provider: .remote, endpoint: endpoint, model: app.aiModel, apiKey: key)
            coachAdvice = await ai.coach(task: "当前任务", rhr: HealthManager.shared.restingHeartRate, hrv: HealthManager.shared.hrv, hrAvg: HealthManager.shared.heartRate)
            loadingCoach = false
        } else {
            loadingCoach = false
        }
    }
}
