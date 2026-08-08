import Foundation
import SyncoCore

public protocol RemoteHostDelegate: AnyObject, Sendable {
    func remoteHost(_ host: RemoteHost, didProduce frame: MediaFrame) async
    func remoteHost(_ host: RemoteHost, didAcceptWith accept: RemoteAcceptMessage) async
    func remoteHost(_ host: RemoteHost, didRejectWith reject: RemoteRejectMessage) async
    func remoteHostDidStop(_ host: RemoteHost) async
}
