import Foundation
import AppKit

/// A colour theme pack. Persisted as JSON; see the spec in the README for the
/// file format. `id` mirrors `name`, so theme names are expected to be unique.
public struct Theme: Codable, Equatable, Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let colors: Colors

    public struct Colors: Codable, Equatable, Sendable {
        public let background: String
        public let surface: String
        public let text: String
        public let muted: String
        public let accent: String

        public init(background: String, surface: String, text: String,
                    muted: String, accent: String) {
            self.background = background
            self.surface = surface
            self.text = text
            self.muted = muted
            self.accent = accent
        }
    }

    public init(name: String, colors: Colors) {
        self.name = name
        self.colors = colors
    }
}

public extension NSColor {
    /// Parses a 6-digit hex colour (`#RRGGBB` or `RRGGBB`). Returns nil for any
    /// other length or non-hex content, so callers can fall back safely.
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
