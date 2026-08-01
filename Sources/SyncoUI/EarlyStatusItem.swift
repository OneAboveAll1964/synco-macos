import AppKit

@MainActor
public enum EarlyStatusItem {

    public static let autosaveName = "SyncoStatusItem"

    public static func make() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = autosaveName
        item.button?.image = MenuBarImage.logo()
        item.button?.toolTip = "Synco — starting"
        return item
    }
}
