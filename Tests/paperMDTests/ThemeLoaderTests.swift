import Foundation
import paperMDCore

enum ThemeLoaderTests {
    static func run() {
        TestKit.suite("ThemeLoader") {
            let builtins = ThemeLoader.builtInThemes()
            TestKit.expectEqual(builtins.count, 8, "loads all 8 built-in themes")
            TestKit.expectEqual(builtins.first?.name, "System Light", "first built-in is System Light")
            TestKit.expect(builtins.contains { $0.name == "Nord" }, "includes Nord")
            TestKit.expect(builtins.contains { $0.name == "Dracula" }, "includes Dracula")

            // Import + export round-trip in a temp themes dir.
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("papermd-themes-\(UUID().uuidString)")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: dir) }

            let valid = dir.appendingPathComponent("incoming.json")
            try? Data("""
            {"name":"My Theme","colors":{"background":"#000000","surface":"#111111",
            "text":"#FFFFFF","muted":"#888888","accent":"#FF00FF"}}
            """.utf8).write(to: valid)
            let imported = try? ThemeLoader.importTheme(from: valid, into: dir)
            TestKit.expectEqual(imported?.name, "My Theme", "imports a valid theme")

            // Invalid JSON is rejected (throws), not crashing.
            let invalid = dir.appendingPathComponent("bad.json")
            try? Data("{ not valid theme }".utf8).write(to: invalid)
            var threw = false
            do { _ = try ThemeLoader.importTheme(from: invalid, into: dir) } catch { threw = true }
            TestKit.expect(threw, "rejects invalid theme JSON")

            // userThemes lists the imported one (skips the invalid file).
            let user = ThemeLoader.userThemes(directory: dir)
            TestKit.expect(user.contains { $0.name == "My Theme" }, "userThemes lists imported theme")
            TestKit.expect(!user.contains { $0.name == "" }, "userThemes skips malformed files")

            // Export round-trips.
            if let theme = imported {
                let out = dir.appendingPathComponent("exported.json")
                try? ThemeLoader.export(theme, to: out)
                TestKit.expectEqual(ThemeLoader.decode(out)?.name, "My Theme", "export round-trips")
            }
        }
    }
}
