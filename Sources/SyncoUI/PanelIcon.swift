import AppKit

enum PanelIcon {

    static let pointSize = CGFloat(30)

    static func image() -> NSImage? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "png"),
              let image = NSImage(contentsOf: url)
        else {
            return nil
        }
        image.size = NSSize(width: pointSize, height: pointSize)
        image.isTemplate = true
        return image
    }

    private static let resourceName = "MenuBarIcon"
}
