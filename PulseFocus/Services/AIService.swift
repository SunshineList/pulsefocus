import Foundation

enum AIProviderKind { case local, remote }

struct AIService {
    var provider: AIProviderKind = .local
    var endpoint: AIEndpoint = .openAI
    var model: String = "gpt-4o-mini"
    var apiKey: String?
    func coach(task: String, rhr: Double, hrv: Double, hrAvg: Double) async -> AIAdvice {
        switch provider {
        case .local:
            let rhrSafe = max(rhr, 40)
            let hrDelta = hrAvg - rhrSafe
            let hrvFactor = max(hrv, 1)
            let pressure = max(0, hrDelta) / hrvFactor
            let focus = max(15, min(45, Int(25 - pressure.rounded())))
            let rest = max(3, min(10, Int(5 + max(0, pressure - 1).rounded())))
            let phrase: String = {
                if pressure < 0.5 { return "状态稳定，稳步推进" }
                if pressure < 1.5 { return "略有压力，注意呼吸节奏" }
                return "压力偏高，适度缩短专注并延长休息"
            }()
            return AIAdvice(focusMinutes: focus, restMinutes: rest, phrase: phrase)
        case .remote:
            let prompt = PromptFactory().coach(task: task, rhr: rhr, hrv: hrv, hrAvg: hrAvg)
            let text = await callRemote(prompt: prompt)
            return parseCoach(text: text)
        }
    }
    func ping() async -> Bool {
        let text = await callRemote(prompt: "请仅回复：OK")
        return text.uppercased().contains("OK")
    }
    func testContent(prompt: String = "请用一句话回复：连接正常") async -> String {
        return await callRemote(prompt: prompt)
    }
    func testConnectivity(prompt: String = "请用一句话回复：连接正常") async -> (Bool, String) {
        guard let key = apiKey, !key.isEmpty, let url = endpoint.url() else { return (false, "") }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue(endpoint.apiKeyPrefix + key, forHTTPHeaderField: endpoint.apiKeyHeaderName)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.0
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data), let content = decoded.choices?.first?.message?.content {
                return (status == 200 && !(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty), content)
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let choices = json["choices"] as? [[String: Any]] {
                let content = (choices.first? ["message"] as? [String: Any])? ["content"] as? String ?? ""
                return (status == 200 && !(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty), content)
            }
            return (status == 200, "")
        } catch {
            return (false, "")
        }
    }
    func review(summaryInput: String) async -> (String, [String]) {
        switch provider {
        case .local:
            return ("专注完成，保持节奏，注意适度休息。", ["减少中途分心", "优化任务拆解", "放松呼吸稳定心率"])
        case .remote:
            let text = await callRemote(prompt: summaryInput)
            return parseReview(text: text)
        }
    }
    func breakdown(task: String) async -> [(String, Int)] {
        switch provider {
        case .local:
            return [(task, 2)]
        case .remote:
            let prompt = PromptFactory().breakdown(task: task)
            let text = await callRemote(prompt: prompt)
            return parseBreakdown(text: text)
        }
    }
    private func callRemote(prompt: String) async -> String {
        guard let key = apiKey, !key.isEmpty else { return "" }
        guard let url = endpoint.url() else { return "" }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue(endpoint.apiKeyPrefix + key, forHTTPHeaderField: endpoint.apiKeyHeaderName)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.2
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let result = try await URLSession.shared.data(for: req)
            let data = result.0
            if let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data), let content = decoded.choices?.first?.message?.content, !content.isEmpty {
                return content
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let choices = json["choices"] as? [[String: Any]] {
                let content = (choices.first?["message"] as? [String: Any])?["content"] as? String
                if let content, !content.isEmpty { return content }
            }
        } catch {
            return ""
        }
        return ""
    }
    private func parseCoach(text: String) -> AIAdvice {
        guard !text.isEmpty else { return AIAdvice(focusMinutes: 0, restMinutes: 0, phrase: "AI连接失败，请检查设置") }
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
        let focus = numbers.first ?? 25
        let rest = numbers.dropFirst().first ?? 5
        return AIAdvice(focusMinutes: focus, restMinutes: rest, phrase: text)
    }
    private func parseReview(text: String) -> (String, [String]) {
        guard !text.isEmpty else { return ("AI连接失败，请检查设置", []) }
        let lines = text.split(separator: "\n").map { String($0) }
        let summary = lines.first ?? text
        let tips = Array(lines.dropFirst().prefix(3))
        return (summary, tips)
    }
    private func parseBreakdown(text: String) -> [(String, Int)] {
        guard !text.isEmpty else { return [] }
        let items = text.split(separator: "\n").map { String($0) }
        return items.prefix(5).map { line in
            let n = line.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }.first ?? 1
            return (line, max(1, min(3, n)))
        }
    }
}

private struct ChatResponse: Decodable {
    let choices: [Choice]?
    struct Choice: Decodable { let message: Message? }
    struct Message: Decodable { let content: String? }
}
