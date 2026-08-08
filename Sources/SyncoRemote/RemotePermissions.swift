import ApplicationServices
import CoreGraphics
import Foundation

public enum RemoteScreenPermission: Sendable {
    case granted
    case denied

    public static func current() -> RemoteScreenPermission {
        CGPreflightScreenCaptureAccess() ? .granted : .denied
    }

    @discardableResult
    public static func request() -> Bool {
        CGRequestScreenCaptureAccess()
    }
}

public enum RemoteInputPermission: Sendable {
    case granted
    case denied

    public static func current() -> RemoteInputPermission {
        AXIsProcessTrusted() ? .granted : .denied
    }

    public static func request() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: kCFBooleanTrue as Any] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
