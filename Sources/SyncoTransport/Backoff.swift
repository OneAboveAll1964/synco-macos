import Foundation
import SyncoCore

public struct Backoff: Sendable {
    public let baseSeconds: TimeInterval
    public let capSeconds: TimeInterval
    public let factor: Double
    public private(set) var attempt: Int = 0

    public init(
        baseSeconds: TimeInterval = SyncoConstants.Timing.reconnectBackoffBaseSeconds,
        capSeconds: TimeInterval = SyncoConstants.Timing.reconnectBackoffCapSeconds,
        factor: Double = SyncoConstants.Timing.reconnectBackoffFactor
    ) {
        self.baseSeconds = baseSeconds
        self.capSeconds = capSeconds
        self.factor = factor
    }

    public var ceilingSeconds: TimeInterval {
        min(capSeconds, baseSeconds * pow(factor, Double(attempt)))
    }

    public mutating func nextDelay() -> Duration {
        let ceiling = ceilingSeconds
        attempt += 1
        return .seconds(Double.random(in: 0...ceiling))
    }

    public mutating func reset() {
        attempt = 0
    }
}
