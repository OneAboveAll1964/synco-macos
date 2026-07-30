@testable import SyncoSync

struct RecordingAdvertiser: AdvertisementWithdrawing {
    let recorder: TeardownRecorder

    func withdrawAdvertisement() async {
        await recorder.record(.advertisementWithdrawn)
    }
}
