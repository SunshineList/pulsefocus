import Foundation

enum FocusMode: String, Codable, CaseIterable, Identifiable {
    case fixed
    case adaptive
    var id: String { rawValue }
}

enum SessionPhase: String, Codable, CaseIterable, Identifiable {
    case idle
    case focus
    case rest
    var id: String { rawValue }
}

