import Foundation
import WatchConnectivity
import Combine

@MainActor
final class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = ConnectivityManager()
    @Published var received: [String: Any] = [:]
    private var session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private var lastContext: [String: Any] = [:]
    private var pendingMessages: [[String: Any]] = []
    private var lastHRSeq: Int = -1
    func activate() {
        guard let s = session, WCSession.isSupported() else { return }
        s.delegate = self
        s.activate()
    }
    func send(_ dict: [String: Any]) {
        guard let s = session else { return }
        if s.activationState != .activated { pendingMessages.append(dict); return }
        if s.isReachable { s.sendMessage(dict, replyHandler: nil, errorHandler: nil) }
        else { _ = s.transferUserInfo(dict) }
    }
    func updateContext(_ dict: [String: Any]) {
        guard let s = session else { return }
        lastContext = dict
        if s.activationState != .activated { return }
        try? s.updateApplicationContext(dict)
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            if !lastContext.isEmpty { try? session.updateApplicationContext(lastContext) }
            if !pendingMessages.isEmpty {
                let msgs = pendingMessages
                pendingMessages.removeAll()
                for m in msgs {
                    if session.isReachable { session.sendMessage(m, replyHandler: nil, errorHandler: nil) }
                    else { _ = session.transferUserInfo(m) }
                }
            }
        }
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.received = message
            if let seq = message["seq"] as? Int { if seq <= self.lastHRSeq { return } else { self.lastHRSeq = seq } }
            if let hr = message["hr"] as? Int { HealthManager.shared.heartRate = Double(hr); HealthManager.shared.setExternalOverride(seconds: 15) }
            if let state = message["state"] as? String {
                switch state { case "start": HealthManager.shared.start(); case "pause": HealthManager.shared.stop(); default: break }
            }
        }
    }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            self.received = userInfo
            if let seq = userInfo["seq"] as? Int { if seq <= self.lastHRSeq { return } else { self.lastHRSeq = seq } }
            if let hr = userInfo["hr"] as? Int { HealthManager.shared.heartRate = Double(hr); HealthManager.shared.setExternalOverride(seconds: 15) }
        }
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.received = applicationContext
            if let seq = applicationContext["seq"] as? Int { if seq <= self.lastHRSeq { return } else { self.lastHRSeq = seq } }
            if let hr = applicationContext["hr"] as? Int { HealthManager.shared.heartRate = Double(hr); HealthManager.shared.setExternalOverride(seconds: 15) }
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            if !lastContext.isEmpty { try? session.updateApplicationContext(lastContext) }
            if !pendingMessages.isEmpty {
                let msgs = pendingMessages
                pendingMessages.removeAll()
                for m in msgs { session.sendMessage(m, replyHandler: nil, errorHandler: nil) }
            }
        }
    }
}
