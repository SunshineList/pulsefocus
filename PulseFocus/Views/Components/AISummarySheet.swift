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
                        Text(DateFmt.cn(session.startedAt)).font(.callout).foregroundStyle(.secondary)
                    }
                    if showError {
                        SectionCard(title: "连接状态") { Text(errorText).font(.system(size: 17)).foregroundStyle(.red) }
                    }
                    if loading {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        SectionCard(title: "总结") {
                            Text(summaryText.isEmpty ? "暂无 AI 文本，请检查连接" : SummaryParser.summary(from: summaryText))
                                .font(.system(size: 17))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(4)
                        }
                        SectionCard(title: "改进建议") {
                    VStack(alignment: .leading, spacing: 8) {
                                let list = tips.isEmpty ? SummaryParser.suggestions(from: summaryText, fallback: []) : tips
                                ForEach(list, id: \.self) { t in Text("• " + t).fixedSize(horizontal: false, vertical: true) }
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
        let result = await AISummaryGenerator.reviewSession(session, app: app)
        summaryText = result.0
        tips = result.1
        if let err = result.2 { showError = true; errorText = "AI连接失败或未配置：\(err)" }
    }
    
}
