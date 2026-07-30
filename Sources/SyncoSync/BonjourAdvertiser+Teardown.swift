import SyncoDiscovery

extension BonjourAdvertiser: AdvertisementWithdrawing {
    public func withdrawAdvertisement() async {
        stop()
    }
}
