import Foundation
import SyncoCore
import SyncoTransfer

public struct ManualClips: Sendable {
    private let deviceID: DeviceID
    private let limit: @Sendable () -> BlobSizeLimit

    public init(deviceID: DeviceID, limit: @escaping @Sendable () -> BlobSizeLimit) {
        self.deviceID = deviceID
        self.limit = limit
    }

    public func text(_ value: String) -> LocalClip? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var bundle = ClipRepresentationBundle()
        if let url = URL(string: trimmed), ["http", "https"].contains(url.scheme ?? "") {
            bundle.append(.url(ClipURLRepresentation(url: trimmed)))
        }
        bundle.append(.text(value))
        return clip(from: bundle)
    }

    public func files(_ urls: [URL]) -> LocalClip? {
        var bundle = ClipRepresentationBundle()
        for source in FileRepresentationSource.expand(urls) {
            guard let measurement = try? FileMeasurement.measure(fileURL: source.url),
                  limit().allows(measurement.size)
            else {
                continue
            }
            let transferID = TransferID()
            bundle.appendBlob(
                .file(ClipFileRepresentation(
                    mime: MIMEType.forFile(at: source.url),
                    name: source.name,
                    size: measurement.size,
                    sha256: measurement.sha256,
                    transferID: transferID,
                    rel: source.relativePath
                )),
                transferID: transferID,
                source: source.url
            )
        }
        return clip(from: bundle)
    }

    private func clip(from bundle: ClipRepresentationBundle) -> LocalClip? {
        let snapshot = bundle.snapshot(changeCount: 0)
        guard !snapshot.isEmpty else { return nil }
        return LocalClip(origin: deviceID, snapshot: snapshot)
    }
}
