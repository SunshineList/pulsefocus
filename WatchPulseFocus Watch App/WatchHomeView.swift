import SwiftUI
import HealthKit
import Combine
import WatchConnectivity
import WatchKit

struct WatchHomeView: View {
    @StateObject private var controller = WatchSessionController()
    var body: some View {
        VStack(spacing: 12) {
            Text("心率 \(Int(controller.heartRate))").font(.title2)
            Text(timeString(controller.remaining)).font(.title)
            HStack {
                Button("开始") { controller.start() }
                Button(controller.running ? "暂停" : "继续") { controller.toggle() }
                Button("重置") { controller.reset() }
            }
        }.onAppear { controller.setup() }
    }
    private func timeString(_ t: TimeInterval) -> String { let m = Int(t)/60; let s = Int(t)%60; return String(format: "%02d:%02d", m, s) }
}

@MainActor
final class WatchSessionController: NSObject, ObservableObject, WCSessionDelegate, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    @Published var heartRate: Double = 0
    @Published var remaining: TimeInterval = 0
    @Published var running: Bool = false
    @Published var focusMinutes: Int = 25
    @Published var restMinutes: Int = 5
    private let health = HKHealthStore()
    private var hrQuery: HKAnchoredObjectQuery?
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var dataSource: HKLiveWorkoutDataSource?
    private var wc: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private var tick: AnyCancellable?
    private var lastHRSent: Int = -1
    private var lastHRSentAt: Date = .distantPast
    private var lastStateSent: String = ""
    private var hrSeq: Int = 0
    private var lastContextRemaining: Int = -1
    private var lastContextAt: Date = .distantPast
    private var epochStart: Int = 0
    private var currentPhase: String = "idle"
    func setup() { requestHK() }
    func start() {
        running = true
        startWorkout()
        remaining = TimeInterval(focusMinutes * 60)
        startTimer()
        epochStart = Int(Date().timeIntervalSince1970)
        sendState("start", extra: ["remaining": Int(remaining), "epochStart": epochStart])
        currentPhase = "focus"
        WKInterfaceDevice.current().play(.start)
    }
    func toggle() {
        if running { pauseTimer(); running = false; sendState("pause"); WKInterfaceDevice.current().play(.directionDown) }
        else { running = true; startTimer(); sendState("resume"); WKInterfaceDevice.current().play(.directionUp) }
    }
    func reset() {
        pauseTimer(); remaining = 0; running = false; workoutSession?.end(); sendState("reset")
    }
    private func requestHK() {
        let types: Set = [HKObjectType.quantityType(forIdentifier: .heartRate)!]
        Task {
            try? await health.requestAuthorization(toShare: [], read: types)
            startHR()
            wc?.delegate = self
            wc?.activate()
        }
    }
    private func startHR() {
        let type = HKObjectType.quantityType(forIdentifier: .heartRate)!
        hrQuery = HKAnchoredObjectQuery(type: type, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { _, samples, _, _, _ in
            guard let s = samples as? [HKQuantitySample], let last = s.last else { return }
            let bpm = last.quantity.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async { self.heartRate = bpm; self.sendHR() }
        }
        hrQuery?.updateHandler = { _, samples, _, _, _ in
            guard let s = samples as? [HKQuantitySample], let last = s.last else { return }
            let bpm = last.quantity.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async { self.heartRate = bpm; self.sendHR() }
        }
        health.execute(hrQuery!)
    }
    private func startWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown
        workoutSession = try? HKWorkoutSession(healthStore: health, configuration: config)
        workoutBuilder = workoutSession?.associatedWorkoutBuilder()
        dataSource = HKLiveWorkoutDataSource(healthStore: health, workoutConfiguration: config)
        workoutBuilder?.dataSource = dataSource
        workoutSession?.delegate = self
        workoutBuilder?.delegate = self
        workoutSession?.startActivity(with: Date())
        workoutBuilder?.beginCollection(withStart: Date()) { _, _ in }
    }
    private func startTimer() {
        tick?.cancel()
        tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            guard self.running else { return }
            if self.epochStart > 0 && self.currentPhase != "idle" {
                let total = (self.currentPhase == "focus" ? self.focusMinutes : self.restMinutes) * 60
                let now = Int(Date().timeIntervalSince1970)
                let expected = max(0, total - max(0, now - self.epochStart))
                self.remaining = TimeInterval(expected)
                if expected == 0 { self.pauseTimer(); self.running = false; WKInterfaceDevice.current().play(.success); self.sendState("complete") }
            } else {
                if self.remaining > 0 { self.remaining -= 1 } else { self.pauseTimer(); self.running = false; WKInterfaceDevice.current().play(.success); self.sendState("complete") }
            }
        }
    }
    private func pauseTimer() { tick?.cancel(); tick = nil }
    private func sendState(_ state: String, extra: [String: Any] = [:]) {
        guard state != lastStateSent else { return }
        lastStateSent = state
        var payload: [String: Any] = ["state": state]
        for (k,v) in extra { payload[k] = v }
        if wc?.isReachable == true { wc?.sendMessage(payload, replyHandler: nil, errorHandler: nil) }
        else { _ = wc?.transferUserInfo(payload) }
    }
    private func sendHR() {
        let bpm = Int(heartRate)
        let elapsed = Date().timeIntervalSince(lastHRSentAt)
        let delta = abs(bpm - lastHRSent)
        guard delta >= 1 || elapsed >= 5 else { return }
        lastHRSent = bpm
        lastHRSentAt = Date()
        hrSeq += 1
        if wc?.isReachable == true { wc?.sendMessage(["hr": bpm, "seq": hrSeq, "ts": Int(Date().timeIntervalSince1970)], replyHandler: nil, errorHandler: nil) }
        else { _ = wc?.transferUserInfo(["hr": bpm, "seq": hrSeq, "ts": Int(Date().timeIntervalSince1970)]) }
    }
    // MARK: - HKWorkoutSessionDelegate
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .ended { running = false }
    }
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }
    // MARK: - HKLiveWorkoutBuilderDelegate
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        if collectedTypes.contains(hrType) {
            if let stats = workoutBuilder.statistics(for: hrType), let qty = stats.mostRecentQuantity() {
                let bpm = qty.doubleValue(for: HKUnit(from: "count/min"))
                DispatchQueue.main.async { self.heartRate = bpm; self.sendHR() }
            }
        }
    }
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionReachabilityDidChange(_ session: WCSession) {}
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let f = message["focus"] as? Int { self.focusMinutes = f }
            if let r = message["rest"] as? Int { self.restMinutes = r }
            if let rem = message["remaining"] as? Int {
                self.lastContextRemaining = rem
                if let ts = message["ts"] as? Int { self.lastContextAt = Date(timeIntervalSince1970: TimeInterval(ts)) } else { self.lastContextAt = Date() }
                let expected = max(0, rem - Int(Date().timeIntervalSince(self.lastContextAt)))
                self.remaining = TimeInterval(expected)
            }
            if let es = message["epochStart"] as? Int { self.epochStart = es }
            if let state = message["state"] as? String {
                switch state {
                case "start":
                    if !self.running {
                        self.startWorkout()
                        self.startTimer()
                        self.running = true
                        WKInterfaceDevice.current().play(.start)
                    }
                    self.currentPhase = "focus"
                case "pause":
                    self.pauseTimer(); self.running = false; WKInterfaceDevice.current().play(.directionDown)
                case "resume":
                    if !self.running { self.running = true; self.startTimer(); WKInterfaceDevice.current().play(.directionUp) }
                case "reset":
                    self.pauseTimer(); self.remaining = 0; self.running = false; self.workoutSession?.end()
                    self.currentPhase = "idle"
                default:
                    break
                }
            }
        }
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let f = applicationContext["focus"] as? Int { self.focusMinutes = f }
            if let rem = applicationContext["remaining"] as? Int {
                self.lastContextRemaining = rem
                if let ts = applicationContext["ts"] as? Int { self.lastContextAt = Date(timeIntervalSince1970: TimeInterval(ts)) } else { self.lastContextAt = Date() }
                let expected = max(0, rem - Int(Date().timeIntervalSince(self.lastContextAt)))
                self.remaining = TimeInterval(expected)
            }
            if let es = applicationContext["epochStart"] as? Int { self.epochStart = es }
            if let phase = applicationContext["phase"] as? String {
                switch phase {
                case "focus":
                    if !self.running { self.startWorkout(); self.startTimer() }
                    self.running = true
                    self.currentPhase = "focus"
                case "rest":
                    if !self.running { self.startTimer() }
                    self.running = true
                    self.currentPhase = "rest"
                default:
                    self.running = false
                    self.currentPhase = "idle"
                }
            }
        }
    }
}
