import paperMDCore

enum OutlineParserTests {
    static func run() {
        TestKit.suite("OutlineParser") {
            let md = "# Career Plan\n\nbody\n## MBA\n### Timeline\n## Finance\n"
            let items = OutlineParser.parse(md)
            TestKit.expectEqual(items.map(\.title), ["Career Plan", "MBA", "Timeline", "Finance"],
                                "parses ATX heading titles in order")
            TestKit.expectEqual(items.map(\.level), [1, 2, 3, 2],
                                "captures heading levels")
            TestKit.expectEqual(items[1].line, 3, "records 0-based line of '## MBA'")

            let fenced = "```\n# not a heading\n```\n# Real\n"
            TestKit.expectEqual(OutlineParser.parse(fenced).map(\.title), ["Real"],
                                "ignores headings inside fenced code")

            let tildeFenced = "~~~\n# nope\n~~~\n## Yes\n"
            TestKit.expectEqual(OutlineParser.parse(tildeFenced).map(\.title), ["Yes"],
                                "honours ~~~ fences too")

            TestKit.expectEqual(OutlineParser.parse("## Hello ##\n").first?.title, "Hello",
                                "strips trailing closing hashes")

            TestKit.expect(OutlineParser.parse("").isEmpty, "empty document yields no items")
            TestKit.expect(OutlineParser.parse("####### too deep\n").isEmpty,
                           "rejects 7+ hashes (not a heading)")
            TestKit.expect(OutlineParser.parse("#nospace\n").isEmpty,
                           "requires space after hashes")
        }
    }
}
