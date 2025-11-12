import SwiftUI
import SwiftData

struct HomeView: View {
    @ObservedObject var app: AppState
    @ObservedObject var timer: SessionTimer
    private let adaptive = AdaptiveController()
    @Environment(\.modelContext) private var model
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.green.opacity(0.3), Color.purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    Circle().strokeBorder(.linearGradient(colors: [.green, .blue], startPoint: .top, endPoint: .bottom), lineWidth: 16).frame(width: 220, height: 220).background(.ultraThinMaterial, in: Circle())
                    VStack {
                        Text(timeString(timer.remaining)).font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("心率 \(Int(HealthManager.shared.heartRate))").font(.system(size: 22, weight: .semibold))
                    }
                }
                TomatoProgressBar(progress: currentProgress())
                TipCard(text: "圆环显示剩余时间，下方为当前心率。点击“开始”进入专注，结束后自动弹出复盘总结。")
                TipCard(text: "AI 建议与复盘会在结束弹窗展示，帮助你调整下一段专注与休息。")
                HStack(spacing: 16) {
                    Button(action: startFocus) { Label("开始", systemImage: "play.fill") }.buttonStyle(.borderedProminent)
                    Button(action: pauseOrResume) { Label(timer.isRunning ? "暂停" : "继续", systemImage: timer.isRunning ? "pause.fill" : "play.fill") }.buttonStyle(.bordered)
                    Button(action: reset) { Label("重置", systemImage: "stop.fill") }.buttonStyle(.bordered)
                }
                Button(action: saveNow) { Label("结束并保存", systemImage: "checkmark.circle") }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }.padding()
        }
        .animation(.spring(dampingFraction: 0.8), value: timer.remaining)
    }
    private func startFocus() {
        HealthManager.shared.simulated = app.isSimulatedHR
        HealthManager.shared.start()
        let advised = adaptive.advise(focusBase: app.focusMinutes, restBase: app.restMinutes, rhr: HealthManager.shared.restingHeartRate, hrv: HealthManager.shared.hrv, hrAvg: HealthManager.shared.heartRate)
        app.focusMinutes = advised.focus
        app.restMinutes = advised.rest
        Haptics.play(.phaseChange)
        timer.start(minutes: app.focusMinutes) {
            app.phase = .rest
            Haptics.play(.complete)
            NotificationManager().schedule(title: "休息开始", seconds: 1)
            timer.start(minutes: app.restMinutes) {
                app.phase = .idle
                app.showSummary = true
            }
        }
        app.phase = .focus
        if #available(iOS 16.1, *) { LiveActivityManager.shared.start(phase: app.phase, remaining: Int(timer.remaining), heartRate: Int(HealthManager.shared.heartRate)) }
    }
    private func pauseOrResume() { timer.isRunning ? timer.pause() : timer.resume() }
    private func reset() { timer.reset(); app.phase = .idle; HealthManager.shared.stop(); if #available(iOS 16.1, *) { LiveActivityManager.shared.end() } }
    private func timeString(_ t: TimeInterval) -> String { let m = Int(t) / 60; let s = Int(t) % 60; return String(format: "%02d:%02d", m, s) }
    private func currentProgress() -> Double {
        switch app.phase {
        case .focus:
            let total = Double(max(1, app.focusMinutes * 60))
            return max(0, min(1, 1 - timer.remaining / total))
        case .rest:
            let total = Double(max(1, app.restMinutes * 60))
            return max(0, min(1, 1 - timer.remaining / total))
        case .idle:
            return 0
        }
    }
    private func saveNow() {
        if timer.isRunning { timer.pause() }
        let isFocus = app.phase == .focus
        let totalSec = app.focusMinutes * 60
        let remainingSec = Int(timer.remaining)
        let elapsedSec = isFocus ? max(0, totalSec - remainingSec) : 0
        let savedMinutes = max(1, elapsedSec / 60)
        let startTime = Date().addingTimeInterval(-TimeInterval(elapsedSec))
        let s = Session(startedAt: startTime, endedAt: Date(), mode: app.mode, phase: .idle, focusMinutes: savedMinutes, restMinutes: app.restMinutes, heartRateAvg: HealthManager.shared.heartRate, hrvAvg: HealthManager.shared.hrv, restingHeartRate: HealthManager.shared.restingHeartRate, score: 80, pauseCount: 0, hrSeries: [])
        model.insert(s)
        timer.reset()
        app.phase = .idle
        HealthManager.shared.stop()
        Haptics.play(.complete)
    }
}

struct TipCard: View {
    let text: String
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "info.circle")
            Text(text).font(.system(size: 17)).foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.linearGradient(colors: [.green.opacity(0.6), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 8, x: 0, y: 4)
    }
}
