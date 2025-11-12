import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phase: String
        var remaining: Int
        var heartRate: Int
    }
}

@available(iOS 16.1, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<FocusActivityAttributes>?
    func start(phase: SessionPhase, remaining: Int, heartRate: Int) {
        let attributes = FocusActivityAttributes()
        let state = FocusActivityAttributes.ContentState(phase: phase.rawValue.capitalized, remaining: remaining, heartRate: heartRate)
        activity = try? Activity.request(attributes: attributes, contentState: state, pushType: nil)
    }
    func update(phase: SessionPhase, remaining: Int, heartRate: Int) {
        let state = FocusActivityAttributes.ContentState(phase: phase.rawValue.capitalized, remaining: remaining, heartRate: heartRate)
        Task { await activity?.update(using: state) }
    }
    func end() { Task { await activity?.end(nil) } }
}

