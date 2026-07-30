import Foundation

public final class FileInstanceLock: InstanceLocking {
    private let location: InstanceLockLocation
    private let liveness: any ProcessLiveness
    private var descriptor: Int32?

    public init(
        location: InstanceLockLocation = .default,
        liveness: any ProcessLiveness = SignalProcessLiveness()
    ) {
        self.location = location
        self.liveness = liveness
    }

    public func acquire() -> InstanceLockOutcome {
        guard descriptor == nil else { return .acquired }
        try? FileManager.default.createDirectory(
            at: location.directoryURL,
            withIntermediateDirectories: true
        )
        let opened = open(location.fileURL.path(percentEncoded: false), O_CREAT | O_RDWR | O_CLOEXEC, 0o644)
        guard opened >= 0 else { return .unavailable(Self.describe(errno)) }
        guard flock(opened, LOCK_EX | LOCK_NB) == 0 else {
            let failure = errno
            let owner = recordedOwner()
            close(opened)
            guard failure == EWOULDBLOCK else { return .unavailable(Self.describe(failure)) }
            return .alreadyRunning(pid: owner)
        }
        record(getpid(), in: opened)
        descriptor = opened
        return .acquired
    }

    public func release() {
        guard let held = descriptor else { return }
        descriptor = nil
        flock(held, LOCK_UN)
        close(held)
    }

    private func recordedOwner() -> pid_t? {
        guard
            let data = try? Data(contentsOf: location.fileURL),
            let text = String(data: data, encoding: .utf8),
            let recorded = pid_t(text.trimmingCharacters(in: .whitespacesAndNewlines)),
            liveness.isRunning(recorded)
        else { return nil }
        return recorded
    }

    private func record(_ pid: pid_t, in descriptor: Int32) {
        ftruncate(descriptor, 0)
        lseek(descriptor, 0, SEEK_SET)
        let line = Array("\(pid)\n".utf8)
        line.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            write(descriptor, base, buffer.count)
        }
    }

    private static func describe(_ code: Int32) -> String {
        String(cString: strerror(code))
    }
}
