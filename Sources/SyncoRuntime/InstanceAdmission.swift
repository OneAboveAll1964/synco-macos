import Foundation

public struct InstanceAdmission: Equatable, Sendable {
    public let allowsLaunch: Bool
    public let notice: String?

    public static let granted = InstanceAdmission(allowsLaunch: true, notice: nil)

    public static func refused(existing pid: pid_t?) -> InstanceAdmission {
        let owner = pid.map { "pid \($0)" } ?? "an unidentified process"
        return InstanceAdmission(
            allowsLaunch: false,
            notice: """
            Synco is already running for this user (\(owner)); \
            this launch is exiting before starting a second engine, listener, or Bonjour advertisement
            """
        )
    }

    public static func degraded(_ reason: String) -> InstanceAdmission {
        InstanceAdmission(
            allowsLaunch: true,
            notice: """
            the single instance lock is unavailable (\(reason)); \
            starting anyway, but a second Synco launched now would advertise the same device twice
            """
        )
    }
}
