import Foundation
import Network

public struct NetworkPathChange: Hashable, Sendable {
    public let isSatisfied: Bool
    public let isExpensive: Bool
    public let interfaceSignature: String

    public init(isSatisfied: Bool, isExpensive: Bool, interfaceSignature: String) {
        self.isSatisfied = isSatisfied
        self.isExpensive = isExpensive
        self.interfaceSignature = interfaceSignature
    }

    init(path: NWPath) {
        isSatisfied = path.status == .satisfied
        isExpensive = path.isExpensive
        interfaceSignature = path.availableInterfaces
            .map(\.name)
            .sorted()
            .joined(separator: ",")
    }

    public var allowsLocalDiscovery: Bool {
        isSatisfied && !interfaceSignature.isEmpty
    }
}
