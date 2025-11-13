import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var mode: FocusMode = .adaptive
    @Published var phase: SessionPhase = .idle
    @Published var focusMinutes: Int = 25
    @Published var restMinutes: Int = 5
    @Published var heartRate: Double = 0
    @Published var hrv: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var isSimulatedHR: Bool = false
    @Published var showSummary: Bool = false
    @Published var aiAdvice: AIAdvice = .defaultAdvice
    @Published var aiEnabled: Bool = false
    @Published var aiBaseURL: String = "https://api.moonshot.cn"
    @Published var aiModel: String = "kimi-k2-turbo-preview"
    @Published var aiKeyHeaderName: String = "Authorization"
    @Published var aiKeyPrefix: String = "Bearer "
    @Published var aiRequireKey: Bool = false
    @Published var aiPath: String = "/v1/chat/completions"
    private var cancellables: Set<AnyCancellable> = []
    init() {
        let d = UserDefaults.standard
        if let m = FocusMode(rawValue: d.string(forKey: "mode") ?? mode.rawValue) { mode = m }
        focusMinutes = d.object(forKey: "focusMinutes") as? Int ?? focusMinutes
        restMinutes = d.object(forKey: "restMinutes") as? Int ?? restMinutes
        isSimulatedHR = d.object(forKey: "isSimulatedHR") as? Bool ?? isSimulatedHR
        aiEnabled = d.object(forKey: "aiEnabled") as? Bool ?? aiEnabled
        aiBaseURL = d.string(forKey: "aiBaseURL") ?? aiBaseURL
        aiModel = d.string(forKey: "aiModel") ?? aiModel
        aiKeyHeaderName = d.string(forKey: "aiKeyHeaderName") ?? aiKeyHeaderName
        aiKeyPrefix = d.string(forKey: "aiKeyPrefix") ?? aiKeyPrefix
        aiRequireKey = d.object(forKey: "aiRequireKey") as? Bool ?? aiRequireKey
        aiPath = d.string(forKey: "aiPath") ?? aiPath
        $mode.sink { d.set($0.rawValue, forKey: "mode") }.store(in: &cancellables)
        $focusMinutes.sink { d.set($0, forKey: "focusMinutes") }.store(in: &cancellables)
        $restMinutes.sink { d.set($0, forKey: "restMinutes") }.store(in: &cancellables)
        $isSimulatedHR.sink { d.set($0, forKey: "isSimulatedHR") }.store(in: &cancellables)
        $aiEnabled.sink { d.set($0, forKey: "aiEnabled") }.store(in: &cancellables)
        $aiBaseURL.sink { d.set($0, forKey: "aiBaseURL") }.store(in: &cancellables)
        $aiModel.sink { d.set($0, forKey: "aiModel") }.store(in: &cancellables)
        $aiKeyHeaderName.sink { d.set($0, forKey: "aiKeyHeaderName") }.store(in: &cancellables)
        $aiKeyPrefix.sink { d.set($0, forKey: "aiKeyPrefix") }.store(in: &cancellables)
        $aiRequireKey.sink { d.set($0, forKey: "aiRequireKey") }.store(in: &cancellables)
        $aiPath.sink { d.set($0, forKey: "aiPath") }.store(in: &cancellables)
    }
}

struct AIAdvice: Equatable {
    let focusMinutes: Int
    let restMinutes: Int
    let phrase: String
    static let defaultAdvice = AIAdvice(focusMinutes: 25, restMinutes: 5, phrase: "保持呼吸，稳步推进")
}
