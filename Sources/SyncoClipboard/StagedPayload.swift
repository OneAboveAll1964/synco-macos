import Foundation
import SyncoCore
import SyncoTransfer

public struct StagedPayload: Hashable, Sendable {
    public let url: URL
    public let measurement: FileMeasurement

    public init(url: URL, measurement: FileMeasurement) {
        self.url = url
        self.measurement = measurement
    }

    public static func stage(
        _ data: Data,
        transferID: TransferID,
        pathExtension: String?,
        paths: TransferPaths
    ) throws -> StagedPayload {
        let suffix = pathExtension.map { ".\($0)" } ?? ""
        let url = try paths.stagingFile(named: "\(transferID.stringValue)\(suffix)")
        try data.write(to: url, options: .atomic)
        return StagedPayload(url: url, measurement: FileMeasurement(data: data))
    }

    public static func stage(
        _ data: Data,
        transferID: TransferID,
        mime: String,
        paths: TransferPaths
    ) throws -> StagedPayload {
        try stage(
            data,
            transferID: transferID,
            pathExtension: MIMEType.preferredFilenameExtension(for: mime),
            paths: paths
        )
    }
}
