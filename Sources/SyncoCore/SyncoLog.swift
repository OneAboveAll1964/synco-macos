import Foundation
import os

public enum SyncoLog {
    public static let subsystem = "com.shkomaghdid.synco.macos"

    public static let core = Logger(subsystem: subsystem, category: "core")
    public static let crypto = Logger(subsystem: subsystem, category: "crypto")
    public static let transport = Logger(subsystem: subsystem, category: "transport")
    public static let discovery = Logger(subsystem: subsystem, category: "discovery")
    public static let transfer = Logger(subsystem: subsystem, category: "transfer")
    public static let clipboard = Logger(subsystem: subsystem, category: "clipboard")
    public static let settings = Logger(subsystem: subsystem, category: "settings")
    public static let session = Logger(subsystem: subsystem, category: "session")
    public static let ui = Logger(subsystem: subsystem, category: "ui")
    public static let app = Logger(subsystem: subsystem, category: "app")
}
