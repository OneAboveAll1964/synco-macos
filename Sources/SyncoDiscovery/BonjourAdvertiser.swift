import Foundation
import Network
import SyncoCore

public actor BonjourAdvertiser {
    private let listener: NWListener
    private var advertisement: ServiceAdvertisement
    private var isAdvertising = false

    public init(listener: NWListener, advertisement: ServiceAdvertisement) {
        self.listener = listener
        self.advertisement = advertisement
    }

    public var currentAdvertisement: ServiceAdvertisement {
        advertisement
    }

    public func start() {
        isAdvertising = true
        applyService()
    }

    public func update(displayName: String) {
        guard advertisement.displayName != displayName else { return }
        advertisement = advertisement.renamed(displayName)
        guard isAdvertising else { return }
        applyService()
    }

    public func restart() {
        guard isAdvertising else { return }
        listener.service = nil
        applyService()
    }

    public func stop() {
        isAdvertising = false
        listener.service = nil
    }

    private func applyService() {
        var service = NWListener.Service(
            name: advertisement.serviceInstanceName,
            type: SyncoConstants.Discovery.serviceType,
            domain: SyncoConstants.Discovery.domain,
            txtRecord: TXTRecordCodec.txtRecord(for: advertisement)
        )
        service.noAutoRename = true
        listener.service = service
        SyncoLog.discovery.info(
            "advertising \(self.advertisement.deviceID.rawValue, privacy: .public)"
        )
    }
}
