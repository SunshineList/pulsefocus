import SwiftUI
import HealthKit
import Combine
import WatchConnectivity
import WatchKit
import WatchConnectivity

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

final class WatchSessionController: ObservableObject {
    @Published var heartRate: Double = 0
    @Published var remaining: TimeInterval = 0
    @Published var running: Bool = false
    private let health = HKHealthStore()
    private var hrQuery: HKAnchoredObjectQuery?
    private var workoutSession: HKWorkoutSession?
    private var wc: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private var tick: AnyCancellable?
    func setup() { requestHK() }
    func start() {
        remaining = max(1.0, remaining > 0 ? remaining : TimeInterval(25*60))
        running = true
        startWorkout()
        startTimer()
        sendState("start")
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
            wc?.delegate = nil
            wc?.activate()
        }
    }
    private func startHR() {
        let type = HKObjectType.quantityType(forIdentifier: .heartRate)!
        hrQuery = HKAnchoredObjectQuery(type: type, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { _, samples, _, _, _ in
            guard let s = samples as? [HKQuantitySample], let last = s.last else { return }
            self.heartRate = last.quantity.doubleValue(for: HKUnit(from: "count/min"))
            self.sendHR()
        }
        hrQuery?.updateHandler = { _, samples, _, _, _ in
            guard let s = samples as? [HKQuantitySample], let last = s.last else { return }
            self.heartRate = last.quantity.doubleValue(for: HKUnit(from: "count/min"))
            self.sendHR()
        }
        health.execute(hrQuery!)
    }
    private func startWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown
        workoutSession = try? HKWorkoutSession(healthStore: health, configuration: config)
        workoutSession?.startActivity(with: Date())
    }
    private func startTimer() {
        tick?.cancel()
        tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            guard self.running else { return }
            if self.remaining > 0 { self.remaining -= 1 } else { self.pauseTimer(); self.running = false; WKInterfaceDevice.current().play(.success); self.sendState("complete") }
        }
    }
    private func pauseTimer() { tick?.cancel(); tick = nil }
    private func sendState(_ state: String) {
        guard wc?.isReachable == true else { return }
        wc?.sendMessage(["state": state], replyHandler: nil, errorHandler: nil)
    }
    private func sendHR() {
        guard wc?.isReachable == true else { return }
        wc?.sendMessage(["hr": Int(heartRate)], replyHandler: nil, errorHandler: nil)
    }
}
