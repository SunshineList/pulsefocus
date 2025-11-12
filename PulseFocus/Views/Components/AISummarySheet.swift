import SwiftUI
import SwiftData

struct AISummarySheet: View {
    @ObservedObject var app: AppState
    let session: Session
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
                        Text("AI 总结报告").font(.system(size: 28, weight: .bold))
                        Text(cnDate(session.startedAt)).font(.callout).foregroundStyle(.secondary)
                    }
                    if showError {
                        SectionCard(title: "连接状态") { Text(errorText).font(.system(size: 17)).foregroundStyle(.red) }
                    }
                    if loading {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        SectionCard(title: "总结") {
                            Text(summaryText.isEmpty ? "暂无 AI 文本，请检查连接" : summaryText)
                                .font(.system(size: 17))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(4)
                        }
                        SectionCard(title: "改进建议") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(tips.isEmpty ? ["暂无建议"] : tips, id: \.self) { t in Text("• " + t) }
                            }
                        }
                    }
                    Button("关闭") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                }.padding()
            }
        }
        .task { await requestSummary(); loading = false }
        .alert("AI 连接失败", isPresented: $showError) { Button("好的", role: .cancel) {} } message: { Text(errorText) }
        .presentationDetents([.medium, .large])
    }
    private func requestSummary() async {
        let series = session.hrSeries.isEmpty ? Array(repeating: session.heartRateAvg, count: 16) : session.hrSeries
        let spark = Sparkline.from(series: series)
        let json = "{\"focusMinutes\":\(session.focusMinutes),\"restMinutes\":\(session.restMinutes),\"hrAvg\":\(Int(session.heartRateAvg)),\"hrv\":\(Int(session.hrvAvg))}"
        let prompt = PromptFactory().review(sessionJSON: json, sparkline: spark)
        if app.aiEnabled, let key = SecureStore.get("aiKey"), !key.isEmpty {
            var endpoint = AIEndpoint(baseURL: app.aiBaseURL)
            endpoint.apiKeyHeaderName = app.aiKeyHeaderName
            endpoint.apiKeyPrefix = app.aiKeyPrefix
            let ai = AIService(provider: .remote, endpoint: endpoint, model: app.aiModel, apiKey: key)
            let result = await ai.review(summaryInput: prompt)
            summaryText = result.0
            tips = result.1
            if summaryText.isEmpty || summaryText.contains("AI连接失败") {
                showError = true
                errorText = summaryText.isEmpty ? "AI连接失败，请检查设置" : summaryText
            }
        } else {
            showError = true
            errorText = "AI未配置或连接失败，请在设置中填写 API Key 并测试连接"
        }
    }
    private func cnDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日 HH:mm"
        return f.string(from: d)
    }
}
