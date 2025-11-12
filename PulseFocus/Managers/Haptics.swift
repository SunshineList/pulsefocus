import Foundation
import UIKit

enum HapticEvent {
    case phaseChange
    case complete
    case aiHint
}

struct Haptics {
    static func play(_ event: HapticEvent) {
        switch event {
        case .phaseChange: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .complete: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .aiHint: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}

