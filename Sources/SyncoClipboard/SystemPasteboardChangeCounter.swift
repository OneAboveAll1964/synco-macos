import AppKit
import Foundation

public struct SystemPasteboardChangeCounter: PasteboardChangeCounting {
    public init() {}

    public var currentChangeCount: Int {
        NSPasteboard.general.changeCount
    }
}
