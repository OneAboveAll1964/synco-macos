import Dispatch
import Foundation

@MainActor
public enum TerminationSignalWatch {
    public static let watched: [Int32] = [SIGINT, SIGTERM, SIGHUP]

    private static var sources: [any DispatchSourceSignal] = []
    private static var escalation = TerminationEscalation()

    public static func install(
        onTerminationRequest handler: @escaping @Sendable @MainActor (Int32) -> Void
    ) {
        guard sources.isEmpty else { return }
        sources = watched.map { number in
            signal(number, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
            source.setEventHandler {
                MainActor.assumeIsolated { deliver(number, to: handler) }
            }
            source.resume()
            return source
        }
    }

    private static func deliver(
        _ number: Int32,
        to handler: @escaping @Sendable @MainActor (Int32) -> Void
    ) {
        switch escalation.step() {
        case .requestTermination:
            handler(number)
        case .exitImmediately:
            StartupConsole.emit("signal \(number) arrived again while shutting down; exiting now")
            exit(EXIT_FAILURE)
        }
    }
}
