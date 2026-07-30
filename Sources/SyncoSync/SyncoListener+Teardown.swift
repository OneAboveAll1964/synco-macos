import SyncoTransport

extension SyncoListener: ListenerStopping {
    public func stopListening() async {
        stop()
    }
}
