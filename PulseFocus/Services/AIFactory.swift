import Foundation

struct AIFactory {
    static func make(app: AppState) -> AIService {
        var endpoint = AIEndpoint(baseURL: app.aiBaseURL)
        endpoint.apiKeyHeaderName = app.aiKeyHeaderName
        endpoint.apiKeyPrefix = app.aiKeyPrefix
        endpoint.path = app.aiPath
        let key = app.aiRequireKey ? SecureStore.get("aiKey") : nil
        return AIService(provider: .remote, endpoint: endpoint, model: app.aiModel, apiKey: key)
    }
    static func available(app: AppState) -> Bool {
        if !app.aiEnabled { return false }
        if app.aiRequireKey { return (SecureStore.get("aiKey") ?? "").isEmpty == false }
        return true
    }
}

