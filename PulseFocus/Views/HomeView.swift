import SwiftUI
import SwiftData

struct HomeView: View {
    @ObservedObject var app: AppState
    @ObservedObject var timer: SessionTimer
    @ObservedObject private var health = HealthManager.shared
    private let adaptive = AdaptiveController()
    @Environment(\.modelContext) private var model
    @State private var focusTotal: Int = 0
    @State private var lastReward: Int = 0
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.green.opacity(0.3), Color.purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    Circle().strokeBorder(.linearGradient(colors: [.green, .blue], startPoint: .top, endPoint: .bottom), lineWidth: 16).frame(width: 220, height: 220).background(.ultraThinMaterial, in: Circle())
                    VStack {
                        Text(timeString(timer.remaining)).font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("心率 \(Int(health.heartRate))").font(.system(size: 22, weight: .semibold))
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
        .onReceive(ConnectivityManager.shared.$received) { msg in
            if let f = msg["focus"] as? Int { app.focusMinutes = f }
            if let r = msg["rest"] as? Int { app.restMinutes = r }
            if let state = msg["state"] as? String {
                switch state {
                case "start":
                    HealthManager.shared.start()
                    app.phase = .focus
                    focusTotal = app.focusMinutes * 60
                    lastReward = 0
                    timer.start(minutes: app.focusMinutes) {
                        app.phase = .rest
                        NotificationManager().schedule(title: "休息开始", seconds: 1)
                        timer.start(minutes: app.restMinutes) {
                            app.phase = .idle
                            app.showSummary = true
                        }
                    }
                    NotificationManager().schedule(title: "专注开始", seconds: 1)
                    broadcastContext()
                case "pause":
                    timer.pause()
                    broadcastContext()
                case "resume":
                    timer.resume()
                    broadcastContext()
                case "reset":
                    timer.reset(); app.phase = .idle
                    broadcastContext()
                case "complete":
                    app.phase = .idle; app.showSummary = true
                    broadcastContext()
                default:
                    break
                }
            }
        }
        .onReceive(timer.$remaining) { _ in
            let sec = Int(timer.remaining)
            if sec % 5 == 0 { broadcastContext() }
            if app.phase == .focus {
                let total = max(1, focusTotal)
                let elapsed = max(0, total - Int(timer.remaining))
                if elapsed > 0 && elapsed % 300 == 0 && elapsed != lastReward {
                    lastReward = elapsed
                    let mins = max(1, elapsed / 60)
                    NotificationManager().schedule(title: "您已坚持\(mins)分钟😁", body: "继续保持，加油！", seconds: 0.1)
                }
            }
        }
    }
    private func startFocus() {
        HealthManager.shared.simulated = app.isSimulatedHR
        HealthManager.shared.start()
        let advised = adaptive.advise(focusBase: app.focusMinutes, restBase: app.restMinutes, rhr: HealthManager.shared.restingHeartRate, hrv: HealthManager.shared.hrv, hrAvg: HealthManager.shared.heartRate)
        app.focusMinutes = advised.focus
        app.restMinutes = advised.rest
        ConnectivityManager.shared.send(["state": "start", "focus": app.focusMinutes, "rest": app.restMinutes, "remaining": Int(timer.remaining), "epochStart": Int(Date().timeIntervalSince1970)])
        Haptics.play(.phaseChange)
        timer.start(minutes: app.focusMinutes) {
            app.phase = .rest
            Haptics.play(.complete)
            NotificationManager().schedule(title: "休息开始", seconds: 1)
            
            timer.start(minutes: app.restMinutes) {
                app.phase = .idle
                app.showSummary = true
                NotificationManager().schedule(title: "本段完成", body: "共坚持 \(app.focusMinutes) 分钟，干得漂亮！", seconds: 0.1)
                ConnectivityManager.shared.send(["state": "complete"]) 
            }
        }
        app.phase = .focus
        focusTotal = app.focusMinutes * 60
        lastReward = 0
        broadcastContext()
        
    }
    private func pauseOrResume() {
        if timer.isRunning {
            timer.pause()
            ConnectivityManager.shared.send(["state": "pause", "remaining": Int(timer.remaining)])
        } else {
            timer.resume()
            let total = app.phase == .focus ? app.focusMinutes * 60 : app.restMinutes * 60
            let elapsed = max(0, total - Int(timer.remaining))
            let epochStart = Int(Date().timeIntervalSince1970) - elapsed
            ConnectivityManager.shared.send(["state": "resume", "remaining": Int(timer.remaining), "epochStart": epochStart])
        }
    }
    private func reset() { timer.reset(); app.phase = .idle; HealthManager.shared.stop(); ConnectivityManager.shared.send(["state": "reset", "remaining": 0]) }
    private func broadcastContext() {
        let total = app.phase == .focus ? app.focusMinutes * 60 : app.phase == .rest ? app.restMinutes * 60 : 0
        let elapsed = total > 0 ? max(0, total - Int(timer.remaining)) : 0
        let epochStart = Int(Date().timeIntervalSince1970) - elapsed
        ConnectivityManager.shared.updateContext([
            "phase": app.phase.rawValue,
            "remaining": Int(timer.remaining),
            "focus": app.focusMinutes,
            "rest": app.restMinutes,
            "ts": Int(Date().timeIntervalSince1970),
            "epochStart": epochStart
        ])
    }
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
