import AppKit

@MainActor
enum LaunchFailureAlert {
    static func present(_ error: any Error) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Synco could not start"
        alert.informativeText = String(describing: error)
        alert.addButton(withTitle: "Quit")
        NSApp.activate()
        alert.runModal()
        NSApp.terminate(nil)
    }
}
