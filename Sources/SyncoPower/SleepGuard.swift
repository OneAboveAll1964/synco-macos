import Foundation
import IOKit.pwr_mgt
import SyncoCore

@MainActor
public final class SleepGuard {
    public static let shared = SleepGuard()

    private var display: IOPMAssertionID = 0
    private var system: IOPMAssertionID = 0

    public init() {}

    public var isHolding: Bool { display != 0 || system != 0 }

    public func hold(reason: String = "Synco is keeping this Mac awake") {
        guard !isHolding else { return }
        display = assertion(kIOPMAssertionTypePreventUserIdleDisplaySleep, reason)
        system = assertion(kIOPMAssertionTypePreventUserIdleSystemSleep, reason)
        SyncoLog.settings.notice("sleep guard held")
    }

    public func release() {
        guard isHolding else { return }
        if display != 0 {
            IOPMAssertionRelease(display)
            display = 0
        }
        if system != 0 {
            IOPMAssertionRelease(system)
            system = 0
        }
        SyncoLog.settings.notice("sleep guard released")
    }

    public func apply(_ enabled: Bool) {
        if enabled { hold() } else { release() }
    }

    private func assertion(_ type: String, _ reason: String) -> IOPMAssertionID {
        var identifier: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &identifier
        )
        guard result == kIOReturnSuccess else {
            SyncoLog.settings.error("sleep assertion \(type, privacy: .public) failed")
            return 0
        }
        return identifier
    }
}
