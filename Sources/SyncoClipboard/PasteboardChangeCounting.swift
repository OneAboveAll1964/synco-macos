import Foundation

public protocol PasteboardChangeCounting: Sendable {
    var currentChangeCount: Int { get }
}
