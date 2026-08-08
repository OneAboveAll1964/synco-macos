import Foundation

public struct RemoteInputMessage: Codable, Hashable, Sendable {
    public let events: [RemoteInputEvent]

    public init(events: [RemoteInputEvent]) {
        self.events = events
    }

    enum CodingKeys: String, CodingKey {
        case events = "ev"
    }
}

public struct RemoteInputEvent: Codable, Hashable, Sendable {
    public let kind: String
    public let x: Double?
    public let y: Double?
    public let dx: Double?
    public let dy: Double?
    public let button: String?
    public let down: Bool?
    public let scale: Double?
    public let code: Int?
    public let mods: Int?
    public let text: String?

    public init(
        kind: String,
        x: Double? = nil,
        y: Double? = nil,
        dx: Double? = nil,
        dy: Double? = nil,
        button: String? = nil,
        down: Bool? = nil,
        scale: Double? = nil,
        code: Int? = nil,
        mods: Int? = nil,
        text: String? = nil
    ) {
        self.kind = kind
        self.x = x
        self.y = y
        self.dx = dx
        self.dy = dy
        self.button = button
        self.down = down
        self.scale = scale
        self.code = code
        self.mods = mods
        self.text = text
    }

    enum CodingKeys: String, CodingKey {
        case kind = "k"
        case x
        case y
        case dx
        case dy
        case button = "btn"
        case down
        case scale
        case code
        case mods
        case text = "s"
    }
}
