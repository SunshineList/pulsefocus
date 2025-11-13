import Foundation

struct PromptFactory {
    func coach(task: String, rhr: Double, hrv: Double, hrAvg: Double) -> String {
        """
        角色：你是一位数据驱动的健康与表现教练。
        输入：任务=\(task)，RHR=\(Int(rhr))，HRV=\(Int(hrv))，平均心率=\(Int(hrAvg))。
        目标：给出推荐的专注与休息时长，并附一句简洁的激励语。
        输出格式：
        - 专注：X 分钟
        - 休息：Y 分钟
        - 激励：一句话
        约束：总字数≤ 60，语言专业且通俗易懂。
        """
    }
    func review(sessionJSON: String, sparkline: String) -> String {
        """
        你是一位数据驱动的健康与表现分析师。
        输入：
        - 会话数据：\(sessionJSON)
        - 心率趋势字符图：\(sparkline)
        仅输出 JSON（不要额外文字），结构：
        {"summary":"≤200字总体表现摘要（含适量emoji，如📈⏱️💤），覆盖趋势稳定性/活动效率/恢复质量","suggestions":["📈 建议 #1（宏观趋势）：含可量化目标…","⏱️ 建议 #2（活动效率）：含可量化目标…","💤 建议 #3（恢复质量）：含可量化目标…"]}
        """
    }
    func breakdown(task: String) -> String {
        """
        任务拆解：\(task)
        目标：生成 3–5 个可执行子任务，每个给出建议番茄数（1–3）。
        输出格式：
        - 子任务1（番茄：N）
        - 子任务2（番茄：N）
        - 子任务3（番茄：N）
        要求：用中文，简洁明确，便于执行与追踪。
        """
    }
    func reviewAggregate(sessionsJSON: String, sparkline: String) -> String {
        """
        你是一位数据驱动的健康与表现分析师，需对近期多段数据做总体回顾。
        输入：
        - 近期会话集合：\(sessionsJSON)
        - 综合心率趋势字符图：\(sparkline)
        建议：至少给出3条，但是不局限于3条。
        仅输出 JSON（不要额外文字），结构：
        {"summary":"≤200字总体表现摘要（含适量emoji，如📈⏱️💤），覆盖趋势稳定性/活动效率/恢复质量","suggestions":["📈 1：含可量化目标的宏观趋势建议…","⏱️ 2：含可量化目标的活动效率建议…","💤 3：含可量化目标的恢复质量建议…"]}   
        """
    }
}
