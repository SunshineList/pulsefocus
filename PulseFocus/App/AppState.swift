import Foundation
import Combine

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
}

struct AIAdvice: Equatable {
    let focusMinutes: Int
    let restMinutes: Int
    let phrase: String
    static let defaultAdvice = AIAdvice(focusMinutes: 25, restMinutes: 5, phrase: "保持呼吸，稳步推进")
}
