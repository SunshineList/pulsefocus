import Foundation

struct PromptFactory {
    func coach(task: String, rhr: Double, hrv: Double, hrAvg: Double) -> String {
        "任务: \(task), RHR=\(Int(rhr)), HRV=\(Int(hrv)), 平均HR=\(Int(hrAvg))。请建议专注与休息时长，并附一句激励短语。"
    }
    func review(sessionJSON: String, sparkline: String) -> String {
        "Session 数据: \(sessionJSON), 心率趋势: \(sparkline)。请总结表现并给出 3 条改进建议。"
    }
    func breakdown(task: String) -> String {
        "任务: \(task)，请分解为 3–5 个小任务，每个建议番茄数量。"
    }
}

