import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var mode: FocusMode
    var phase: SessionPhase
    var focusMinutes: Int
    var restMinutes: Int
    var heartRateAvg: Double
    var hrvAvg: Double
    var restingHeartRate: Double
    var score: Double
    var pauseCount: Int
    var hrSeries: [Double]

    init(id: UUID = UUID(), startedAt: Date = .now, endedAt: Date? = nil, mode: FocusMode = .fixed, phase: SessionPhase = .idle, focusMinutes: Int = 25, restMinutes: Int = 5, heartRateAvg: Double = 0, hrvAvg: Double = 0, restingHeartRate: Double = 0, score: Double = 0, pauseCount: Int = 0, hrSeries: [Double] = []) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.mode = mode
        self.phase = phase
        self.focusMinutes = focusMinutes
        self.restMinutes = restMinutes
        self.heartRateAvg = heartRateAvg
        self.hrvAvg = hrvAvg
        self.restingHeartRate = restingHeartRate
        self.score = score
        self.pauseCount = pauseCount
        self.hrSeries = hrSeries
    }
}

