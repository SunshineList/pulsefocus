import Foundation

struct AdaptiveController {
    func advise(focusBase: Int, restBase: Int, rhr: Double, hrv: Double, hrAvg: Double) -> (focus: Int, rest: Int, score: Double) {
        let rhrSafe = max(rhr, 40)
        let hrDelta = hrAvg - rhrSafe
        let hrvFactor = max(hrv, 1)
        let pressure = max(0, hrDelta) / hrvFactor
        let clampFocus = max(15, min(45, Int(Double(focusBase) - pressure.rounded())))
        let clampRest = max(3, min(10, Int(Double(restBase) + max(0, pressure - 1).rounded())))
        let score = max(0, 100 - min(100, pressure * 10))
        return (clampFocus, clampRest, score)
    }
}

