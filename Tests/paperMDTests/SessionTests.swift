import Foundation
import paperMDCore

enum SessionTests {
    static func run() {
        TestKit.suite("Session") {
            var session = Session()
            session.folderPath = "/Users/washi/notes"
            session.openFiles = ["/a.md", "/b.md"]
            session.activeIndex = 1
            session.mode = .split
            session.cursors = ["/a.md": 42, "/b.md": 0]

            guard let data = try? JSONEncoder().encode(session),
                  let back = try? JSONDecoder().decode(Session.self, from: data) else {
                TestKit.expect(false, "Session encodes and decodes")
                return
            }
            TestKit.expectEqual(back.folderPath, "/Users/washi/notes", "persists folder path")
            TestKit.expectEqual(back.openFiles, ["/a.md", "/b.md"], "persists open files")
            TestKit.expectEqual(back.activeIndex, 1, "persists active index")
            TestKit.expectEqual(back.mode, .split, "persists editor mode")
            TestKit.expectEqual(back.cursors["/a.md"], 42, "persists per-file cursor")

            // Defaults are sane for a first launch.
            let fresh = Session()
            TestKit.expect(fresh.folderPath == nil && fresh.openFiles.isEmpty, "empty default session")
            TestKit.expectEqual(fresh.mode, .edit, "defaults to edit mode")

            // EditorMode is round-trippable via its raw value (used by @AppStorage).
            TestKit.expectEqual(EditorMode(rawValue: "preview"), .preview, "EditorMode raw value decodes")
            TestKit.expectEqual(EditorMode.allCases.count, 3, "three editor modes")
        }
    }
}
