import paperMDCore

enum FuzzyMatcherTests {
    static func run() {
        TestKit.suite("FuzzyMatcher") {
            TestKit.expect(FuzzyMatcher.score(query: "of", candidate: "Open File") != nil,
                           "matches a subsequence")
            TestKit.expect(FuzzyMatcher.score(query: "xyz", candidate: "Open File") == nil,
                           "rejects a non-subsequence")
            TestKit.expect(FuzzyMatcher.score(query: "", candidate: "Anything") != nil,
                           "empty query matches everything")

            let wordBoundary = FuzzyMatcher.score(query: "nf", candidate: "New File")!
            let scattered = FuzzyMatcher.score(query: "nf", candidate: "Info")!
            TestKit.expect(wordBoundary > scattered,
                           "word-boundary match scores higher than scattered")

            let consecutive = FuzzyMatcher.score(query: "ope", candidate: "Open")!
            let gappy = FuzzyMatcher.score(query: "opn", candidate: "Open")!
            TestKit.expect(consecutive > gappy, "consecutive matches beat gappy ones")

            TestKit.expect(FuzzyMatcher.score(query: "gl", candidate: "Go To Line") != nil,
                           "fuzzy 'gl' finds 'Go To Line'")
            TestKit.expect(FuzzyMatcher.score(query: "GL", candidate: "go to line") != nil,
                           "matching is case-insensitive")
        }
    }
}
