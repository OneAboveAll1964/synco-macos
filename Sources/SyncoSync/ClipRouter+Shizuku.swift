import Foundation
import SyncoCore

extension ClipRouter {
    func startShizukuOverAdb() async {
        let outcome: ShizukuStartOutcome
        if policy.allowsAdbShizukuStart {
            outcome = await shizuku.start()
        } else {
            outcome = .notAllowed
        }
        try? await transport.send(
            .shizukuStartResult(
                ShizukuStartResultMessage(started: outcome.didStart, reason: outcome.reason)
            )
        )
    }
}
