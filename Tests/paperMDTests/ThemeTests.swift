import Foundation
import AppKit
import paperMDCore

enum ThemeTests {
    static func run() {
        TestKit.suite("Theme") {
            let json = """
            {"name":"Nord","colors":{"background":"#2E3440","surface":"#3B4252",
            "text":"#ECEFF4","muted":"#D8DEE9","accent":"#88C0D0"}}
            """
            guard let theme = try? JSONDecoder().decode(Theme.self, from: Data(json.utf8)) else {
                TestKit.expect(false, "decodes the spec theme JSON")
                return
            }
            TestKit.expectEqual(theme.name, "Nord", "decodes name")
            TestKit.expectEqual(theme.id, "Nord", "id mirrors name")
            TestKit.expectEqual(theme.colors.background, "#2E3440", "decodes background hex")

            // Round-trip
            if let data = try? JSONEncoder().encode(theme),
               let again = try? JSONDecoder().decode(Theme.self, from: data) {
                TestKit.expectEqual(again, theme, "encode/decode round-trips equal")
            } else {
                TestKit.expect(false, "encode/decode round-trips equal")
            }

            // Hex → NSColor
            let white = NSColor(hex: "#FFFFFF")
            TestKit.expect(white != nil, "parses #FFFFFF")
            if let w = white?.usingColorSpace(.sRGB) {
                TestKit.expect(abs(w.redComponent - 1) < 0.01 && abs(w.blueComponent - 1) < 0.01,
                               "#FFFFFF is white")
            }
            let accent = NSColor(hex: "88C0D0") // no leading #
            TestKit.expect(accent != nil, "parses hex without leading #")
            TestKit.expect(NSColor(hex: "#GGGGGG") == nil, "rejects invalid hex")
            TestKit.expect(NSColor(hex: "#FFF") == nil, "rejects 3-digit shorthand (spec uses 6-digit)")
        }
    }
}
