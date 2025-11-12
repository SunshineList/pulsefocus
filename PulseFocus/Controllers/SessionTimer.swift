import Foundation
import Combine

final class SessionTimer: ObservableObject {
    @Published var remaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    private var timer: AnyCancellable?
    private var endAction: (() -> Void)?

    func start(minutes: Int, endAction: @escaping () -> Void) {
        self.endAction = endAction
        remaining = TimeInterval(minutes * 60)
        isRunning = true
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            if self.remaining > 0 { self.remaining -= 1 } else { self.stop(); self.endAction?() }
        }
    }

    func pause() { isRunning = false; timer?.cancel() }
    func resume() {
        guard remaining > 0 else { return }
        isRunning = true
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            if self.remaining > 0 { self.remaining -= 1 } else { self.stop(); self.endAction?() }
        }
    }
    func stop() { isRunning = false; timer?.cancel(); timer = nil }
    func reset() { stop(); remaining = 0 }
}

