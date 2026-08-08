import ApplicationServices
import CoreGraphics
import Foundation
import SyncoCore

@MainActor
public final class RemoteInputInjector {
    private let mapper: RemotePointerMapper
    private var cursor: CGPoint
    private var pressedButtons: Set<CGMouseButton> = []

    public init(bounds: CGRect) {
        mapper = RemotePointerMapper(bounds: bounds)
        cursor = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    public func inject(_ event: RemoteInputEvent) {
        switch event.kind {
        case "pa":
            movePointer(to: mapper.point(normalizedX: event.x ?? 0, normalizedY: event.y ?? 0))
        case "pm":
            movePointer(to: mapper.advance(from: cursor, byPixelsX: event.dx ?? 0, byPixelsY: event.dy ?? 0))
        case "b":
            button(event.button ?? "left", down: event.down ?? false)
        case "s":
            scroll(dx: event.dx ?? 0, dy: event.dy ?? 0)
        case "txt":
            type(event.text ?? "")
        default:
            break
        }
    }

    private func movePointer(to point: CGPoint) {
        cursor = point
        let dragging = pressedButtons.contains(.left)
        post(type: dragging ? .leftMouseDragged : .mouseMoved, button: .left)
    }

    private func button(_ name: String, down: Bool) {
        let button = mouseButton(for: name)
        if down { pressedButtons.insert(button) } else { pressedButtons.remove(button) }
        post(type: eventType(for: button, down: down), button: button)
    }

    private func scroll(dx: Double, dy: Double) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(dy),
            wheel2: Int32(dx),
            wheel3: 0
        ) else {
            return
        }
        event.post(tap: .cghidEventTap)
    }

    private func type(_ text: String) {
        for scalar in text.unicodeScalars {
            postCharacter(scalar)
        }
    }

    private func postCharacter(_ scalar: Unicode.Scalar) {
        var utf16 = Array(String(scalar).utf16)
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
        else {
            return
        }
        down.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        up.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private func post(type: CGEventType, button: CGMouseButton) {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: type,
            mouseCursorPosition: cursor,
            mouseButton: button
        ) else {
            return
        }
        event.post(tap: .cghidEventTap)
    }

    private func mouseButton(for name: String) -> CGMouseButton {
        switch name {
        case "right": return .right
        case "middle": return .center
        default: return .left
        }
    }

    private func eventType(for button: CGMouseButton, down: Bool) -> CGEventType {
        switch button {
        case .right: return down ? .rightMouseDown : .rightMouseUp
        case .center: return down ? .otherMouseDown : .otherMouseUp
        default: return down ? .leftMouseDown : .leftMouseUp
        }
    }
}
