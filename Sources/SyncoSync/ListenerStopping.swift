public protocol ListenerStopping: Sendable {
    func stopListening() async
}
