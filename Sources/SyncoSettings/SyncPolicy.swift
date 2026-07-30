import Foundation
import SyncoCore

public struct SyncPolicy: Hashable, Sendable {
    public var direction: PeerDirectionPolicy
    public var paused: Bool
    public var maxBlobBytes: Int64

    public static let `default` = SyncPolicy(
        direction: .bidirectional,
        paused: false,
        maxBlobBytes: SyncoConstants.Limits.defaultMaxBlobBytes
    )

    public init(direction: PeerDirectionPolicy, paused: Bool, maxBlobBytes: Int64) {
        self.direction = direction
        self.paused = paused
        self.maxBlobBytes = maxBlobBytes
    }

    public var effectiveSendFlags: ClipTypeFlags { paused ? .none : direction.send }

    public var effectiveReceiveFlags: ClipTypeFlags { paused ? .none : direction.receive }

    public var capsMessage: CapsMessage {
        CapsMessage(
            accepts: effectiveReceiveFlags,
            sends: effectiveSendFlags,
            maxBlob: maxBlobBytes
        )
    }

    public func maySend(kind: ClipRepresentationKind) -> Bool {
        effectiveSendFlags.allows(kind)
    }

    public func mayAccept(kind: ClipRepresentationKind) -> Bool {
        effectiveReceiveFlags.allows(kind)
    }

    public func maySend(_ representation: ClipRepresentation) -> Bool {
        maySend(kind: representation.kind) && allowsSize(of: representation)
    }

    public func mayAccept(_ representation: ClipRepresentation) -> Bool {
        mayAccept(kind: representation.kind) && allowsSize(of: representation)
    }

    public func sendable(_ representations: [ClipRepresentation]) -> [ClipRepresentation] {
        representations.filter { maySend($0) }
    }

    public func acceptable(_ representations: [ClipRepresentation]) -> [ClipRepresentation] {
        representations.filter { mayAccept($0) }
    }

    public func allowsBlobSize(_ size: Int64) -> Bool {
        size >= 0 && size <= maxBlobBytes
    }

    public func rejection(for representations: [ClipRepresentation]) -> ClipRejectionReason? {
        guard !acceptable(representations).isEmpty else {
            if paused || effectiveReceiveFlags.allowsNothing { return .receiveDisabled }
            if representations.contains(where: { !allowsSize(of: $0) }) { return .tooLarge }
            return .typeDisabled
        }
        return nil
    }

    private func allowsSize(of representation: ClipRepresentation) -> Bool {
        switch representation {
        case .image(let image): return allowsBlobSize(image.size)
        case .file(let file): return allowsBlobSize(file.size)
        default: return true
        }
    }
}
