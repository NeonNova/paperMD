import Foundation
import paperMDCore

// Each task appends its own suite of checks here. Task 1 only verifies that the
// test harness, the paperMDCore library, and cross-module imports all work.

TestKit.suite("Version") {
    TestKit.expectEqual(paperMDVersion, "1.0.0", "core version constant is reachable from tests")
}

OutlineParserTests.run()
ThemeTests.run()
SessionTests.run()
HighlighterTests.run()
FileServiceTests.run()
FileTreeTests.run()
SessionStoreTests.run()
ThemeLoaderTests.run()

TestKit.finish()
