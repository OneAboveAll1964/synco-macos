import SyncoCore

public enum NetworkTeardown {
    public static func run(
        advertiser: (any AdvertisementWithdrawing)?,
        listener: (any ListenerStopping)?
    ) async {
        await advertiser?.withdrawAdvertisement()
        await listener?.stopListening()
        SyncoLog.discovery.info("advertisement withdrawn and listener stopped")
    }
}
