import XCTest

@testable import SyncoSync

final class NetworkTeardownTests: XCTestCase {
    func testTheAdvertisementIsWithdrawnBeforeTheListenerStops() async {
        let recorder = TeardownRecorder()
        await NetworkTeardown.run(
            advertiser: RecordingAdvertiser(recorder: recorder),
            listener: RecordingListener(recorder: recorder)
        )
        let steps = await recorder.recordedSteps()
        XCTAssertEqual(steps, [.advertisementWithdrawn, .listenerStopped])
    }

    func testAListenerThatNeverAdvertisedIsStillStopped() async {
        let recorder = TeardownRecorder()
        await NetworkTeardown.run(
            advertiser: nil,
            listener: RecordingListener(recorder: recorder)
        )
        let steps = await recorder.recordedSteps()
        XCTAssertEqual(steps, [.listenerStopped])
    }

    func testAnAdvertiserWithoutALiveListenerIsStillWithdrawn() async {
        let recorder = TeardownRecorder()
        await NetworkTeardown.run(
            advertiser: RecordingAdvertiser(recorder: recorder),
            listener: nil
        )
        let steps = await recorder.recordedSteps()
        XCTAssertEqual(steps, [.advertisementWithdrawn])
    }

    func testTeardownOnAnEngineThatNeverStartedDoesNothing() async {
        await NetworkTeardown.run(advertiser: nil, listener: nil)
    }

    func testRepeatedTeardownWithdrawsAgainRatherThanSkipping() async {
        let recorder = TeardownRecorder()
        let advertiser = RecordingAdvertiser(recorder: recorder)
        let listener = RecordingListener(recorder: recorder)
        await NetworkTeardown.run(advertiser: advertiser, listener: listener)
        await NetworkTeardown.run(advertiser: advertiser, listener: listener)
        let steps = await recorder.recordedSteps()
        XCTAssertEqual(
            steps,
            [.advertisementWithdrawn, .listenerStopped, .advertisementWithdrawn, .listenerStopped]
        )
    }
}
