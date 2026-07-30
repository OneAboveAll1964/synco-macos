import AppKit
import SwiftUI
import XCTest

@testable import SyncoUI

@MainActor
final class DirectionChoiceButtonTests: XCTestCase {
    private let probeWidth: CGFloat = 84

    func testEveryChoiceRendersAtTheSameHeight() {
        let labelled = DirectionChoice.allCases.map { ($0.title, measuredHeight(of: $0, isSelected: false)) }
        let distinct = Set(labelled.map(\.1))
        XCTAssertEqual(
            distinct.count,
            1,
            "direction buttons must share one height, measured \(labelled.map { "\($0): \($1)" })"
        )
    }

    func testSelectionDoesNotChangeHeight() {
        for choice in DirectionChoice.allCases {
            XCTAssertEqual(
                measuredHeight(of: choice, isSelected: true),
                measuredHeight(of: choice, isSelected: false),
                accuracy: 0.5,
                "selecting \(choice.title) changed its height"
            )
        }
    }

    func testShippedLabelsStillDifferInLengthAndGlyph() {
        let titles = DirectionChoice.allCases.map(\.title)
        let symbols = DirectionChoice.allCases.map(\.symbolName)
        XCTAssertGreaterThan(Set(titles.map(\.count)).count, 1)
        XCTAssertEqual(Set(symbols).count, DirectionChoice.allCases.count)
    }

    private func measuredHeight(of choice: DirectionChoice, isSelected: Bool) -> CGFloat {
        let button = DirectionChoiceButton(choice: choice, isSelected: isSelected, action: {})
        let host = NSHostingView(rootView: button.frame(width: probeWidth))
        return host.fittingSize.height
    }
}
