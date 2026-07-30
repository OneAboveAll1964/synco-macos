import Foundation
import Observation

@MainActor
final class ObservationLoop {
    private let body: @MainActor () -> Void
    private var isCancelled = false

    init(_ body: @escaping @MainActor () -> Void) {
        self.body = body
        track()
    }

    func cancel() {
        isCancelled = true
    }

    private func track() {
        guard !isCancelled else { return }
        withObservationTracking {
            self.body()
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.track()
            }
        }
    }
}
