import Foundation

struct AIEndpoint {
    var baseURL: String
    var path: String = "/v1/chat/completions"
    var queryItems: [URLQueryItem] = []
    var apiKeyHeaderName: String = "Authorization"
    var apiKeyPrefix: String = "Bearer "
    static let openAI = AIEndpoint(baseURL: "https://api.moonshot.cn")
    func url() -> URL? {
        var comps = URLComponents(string: baseURL)
        comps?.path += path
        if !queryItems.isEmpty { comps?.queryItems = queryItems }
        return comps?.url
    }
}

