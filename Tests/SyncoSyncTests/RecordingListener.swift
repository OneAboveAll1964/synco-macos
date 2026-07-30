@testable import SyncoSync

struct RecordingListener: ListenerStopping {
    let recorder: TeardownRecorder

    func stopListening() async {
        await recorder.record(.listenerStopped)
    }
}
