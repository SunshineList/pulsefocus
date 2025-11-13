import Foundation
import WatchConnectivity
import Combine

final class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = ConnectivityManager()
    @Published var received: [String: Any] = [:]
    private var session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    func activate() {
        guard let s = session, WCSession.isSupported() else { return }
        s.delegate = self
        if s.isPaired { s.activate() }
    }
    func send(_ dict: [String: Any]) { if session?.isPaired == true { session?.sendMessage(dict, replyHandler: nil, errorHandler: nil) } }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.received = message
            if let hr = message["hr"] as? Int { HealthManager.shared.heartRate = Double(hr) }
            if let state = message["state"] as? String {
                switch state { case "start": HealthManager.shared.start(); case "pause": HealthManager.shared.stop(); default: break }
            }
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    func sessionReachabilityDidChange(_ session: WCSession) {}
}
