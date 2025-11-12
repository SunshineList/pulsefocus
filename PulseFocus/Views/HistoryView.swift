import SwiftUI
import Charts
import SwiftData

struct HistoryView: View {
    @ObservedObject var app: AppState
    @Query(sort: \Session.startedAt) private var sessions: [Session]
    @Environment(\.modelContext) private var model
    @State private var selected: Session? = nil
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("历史记录").font(.system(size: 28, weight: .bold))
                if sessions.isEmpty {
                    EmptyHistoryCard()
                    SampleChart()
                } else {
                    WeeklySummary(sessions: sessions)
                    Chart(sessions) { s in
                        LineMark(x: .value("开始时间", s.startedAt), y: .value("心率", s.heartRateAvg)).foregroundStyle(.blue)
                        LineMark(x: .value("开始时间", s.startedAt), y: .value("HRV", s.hrvAvg)).foregroundStyle(.green)
                    }
                    .frame(height: 220)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    VStack(spacing: 12) {
                        ForEach(sessions) { s in
                            SectionCard(title: dateString(s.startedAt)) {
                                HStack {
                                    Label("专注 \(s.focusMinutes) 分钟", systemImage: "clock")
                                    Spacer()
                                    Label("平均心率 \(Int(s.heartRateAvg))", systemImage: "heart.fill")
                                }.font(.system(size: 17))
                                HStack {
                                    Button("AI 总结报告") { selected = s }.buttonStyle(.borderedProminent)
                                    Spacer()
                                    Button(role: .destructive) { deleteSession(s) } label: { Label("删除", systemImage: "trash") }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { deleteSession(s) } label: { Label("删除", systemImage: "trash") }
                            }
                        }
                    }
                }
            }.padding()
        }
        .background(LinearGradient(colors: [Color.green.opacity(0.15), Color.purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
        .sheet(item: $selected) { s in AISummarySheet(app: app, session: s) }
    }
}

private struct WeeklySummary: View {
    let sessions: [Session]
    var body: some View {
        let weekSessions = sessions.filter { Calendar.current.isDateInThisWeek($0.startedAt) }
        let totalMinutes = weekSessions.reduce(0) { $0 + $1.focusMinutes }
        let avgHR = weekSessions.map { $0.heartRateAvg }.average()
        SectionCard(title: "周专注报告") {
            HStack {
                Label("总专注时长 \(totalMinutes) 分钟", systemImage: "clock")
                Spacer()
                Label("平均心率 \(Int(avgHR))", systemImage: "heart.fill")
            }
            .font(.system(size: 17))
        }
    }
}

private func dateString(_ d: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "zh_CN")
    f.dateFormat = "yyyy年M月d日 HH:mm"
    return f.string(from: d)
}

private extension HistoryView {
    func deleteSession(_ s: Session) {
        withAnimation {
            model.delete(s)
        }
    }
}

private struct EmptyHistoryCard: View {
    var body: some View {
        SectionCard(title: "暂无记录") {
            Text("完成一段专注后点击复盘弹窗中的“保存并关闭”，即可在此查看历史与趋势图。")
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
        }
    }
}

private struct SampleChart: View {
    var body: some View {
        let sample = SampleData.generate()
        SectionCard(title: "示例趋势图") {
            Chart(sample) { p in
                LineMark(x: .value("时间", p.t), y: .value("心率", p.hr)).foregroundStyle(.blue)
                LineMark(x: .value("时间", p.t), y: .value("HRV", p.hrv)).foregroundStyle(.green)
            }.frame(height: 220)
        }
    }
}

private struct SamplePoint: Identifiable { let id = UUID(); let t: Int; let hr: Double; let hrv: Double }
private enum SampleData {
    static func generate() -> [SamplePoint] {
        (0..<12).map { i in SamplePoint(t: i, hr: 65 + Double(Int.random(in: -5...10)), hrv: 60 + Double(Int.random(in: -10...15))) }
    }
}

private extension Collection where Element == Double {
    func average() -> Double { isEmpty ? 0 : reduce(0, +) / Double(count) }
}

private extension Calendar {
    func isDateInThisWeek(_ date: Date) -> Bool {
        isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
}
