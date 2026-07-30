public struct TerminationEscalation: Equatable, Sendable {
    private var didRequestTermination = false

    public init() {}

    public mutating func step() -> TerminationStep {
        guard !didRequestTermination else { return .exitImmediately }
        didRequestTermination = true
        return .requestTermination
    }
}
