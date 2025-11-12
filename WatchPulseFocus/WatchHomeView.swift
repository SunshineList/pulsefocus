import SwiftUI
import HealthKit
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
    func setup() { requestHK() }
    func start() { remaining = 25*60; running = true; startWorkout(); sendState("start") }
    func toggle() { running.toggle(); sendState(running ? "resume" : "pause") }
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
    private func sendState(_ state: String) {
        guard wc?.isReachable == true else { return }
        wc?.sendMessage(["state": state], replyHandler: nil, errorHandler: nil)
    }
    private func sendHR() {
        guard wc?.isReachable == true else { return }
        wc?.sendMessage(["hr": Int(heartRate)], replyHandler: nil, errorHandler: nil)
    }
}
