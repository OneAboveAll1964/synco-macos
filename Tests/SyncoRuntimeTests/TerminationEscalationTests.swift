import XCTest

@testable import SyncoRuntime

final class TerminationEscalationTests: XCTestCase {
    func testTheFirstSignalRequestsAnOrderlyShutdown() {
        var escalation = TerminationEscalation()
        XCTAssertEqual(escalation.step(), .requestTermination)
    }

    func testAFurtherSignalDuringShutdownExitsImmediately() {
        var escalation = TerminationEscalation()
        XCTAssertEqual(escalation.step(), .requestTermination)
        XCTAssertEqual(escalation.step(), .exitImmediately)
        XCTAssertEqual(escalation.step(), .exitImmediately)
    }
}
