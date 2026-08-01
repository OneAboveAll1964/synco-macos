import Foundation

public enum ShizukuStartOutcome: String, Sendable {
    case started
    case notAllowed
    case adbMissing
    case noDevice
    case notInstalled
    case noStarter
    case failed

    public var didStart: Bool { self == .started }

    public var reason: String? { self == .started ? nil : rawValue }
}
