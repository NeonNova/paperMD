import Foundation
import paperMDCore

enum SessionStoreTests {
    static func run() {
        TestKit.suite("SessionStore") {
            let file = FileManager.default.temporaryDirectory
                .appendingPathComponent("papermd-session-\(UUID().uuidString).json")
            defer { try? FileManager.default.removeItem(at: file) }

            let store = SessionStore(fileURL: file)
            TestKit.expect(store.load() == nil, "no session before any save")

            var session = Session()
            session.folderPath = "/Users/washi/notes"
            session.openFiles = ["/x/a.md", "/x/b.md"]
            session.activeIndex = 1
            session.mode = .split
            session.cursors = ["/x/a.md": 17]

            TestKit.expect(store.saveNow(session), "saveNow succeeds")
            let loaded = store.load()
            TestKit.expect(loaded != nil, "loads a saved session")
            TestKit.expectEqual(loaded?.openFiles, ["/x/a.md", "/x/b.md"], "round-trips open files")
            TestKit.expectEqual(loaded?.activeIndex, 1, "round-trips active index")
            TestKit.expectEqual(loaded?.mode, .split, "round-trips mode")
            TestKit.expectEqual(loaded?.cursors["/x/a.md"], 17, "round-trips cursor")

            store.clear()
            TestKit.expect(store.load() == nil, "clear removes the session file")
        }
    }
}
