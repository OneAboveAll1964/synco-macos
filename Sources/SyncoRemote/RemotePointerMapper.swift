import CoreGraphics
import Foundation

public struct RemotePointerMapper: Hashable, Sendable {
    public let bounds: CGRect

    public init(bounds: CGRect) {
        self.bounds = bounds
    }

    public func point(normalizedX: Double, normalizedY: Double) -> CGPoint {
        let clampedX = min(max(normalizedX, 0.0), 1.0)
        let clampedY = min(max(normalizedY, 0.0), 1.0)
        return CGPoint(
            x: bounds.origin.x + clampedX * bounds.width,
            y: bounds.origin.y + clampedY * bounds.height
        )
    }

    public func advance(from current: CGPoint, byPixelsX dx: Double, byPixelsY dy: Double) -> CGPoint {
        let x = min(max(current.x + dx, bounds.minX), bounds.maxX)
        let y = min(max(current.y + dy, bounds.minY), bounds.maxY)
        return CGPoint(x: x, y: y)
    }
}
