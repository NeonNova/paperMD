import AppKit
import paperMDCore

enum HighlighterTests {
    static func run() {
        TestKit.suite("MarkdownHighlighter") {
            let palette = HighlightPalette.system()
            let storage = NSTextStorage()
            let highlighter = MarkdownHighlighter(palette: palette)
            highlighter.attach(to: storage)

            let doc = "# Heading\n\nSome `code` and **bold** text.\n"
            storage.replaceCharacters(in: NSRange(location: 0, length: 0), with: doc)
            let ns = doc as NSString

            // Heading line uses the accent colour.
            let headingColor = storage.attribute(
                .foregroundColor, at: 0, effectiveRange: nil) as? NSColor
            TestKit.expectEqual(headingColor, palette.heading, "heading uses accent colour")

            // The inline `code` span uses the monospaced code font.
            let codeLoc = ns.range(of: "code").location
            let codeFont = storage.attribute(.font, at: codeLoc, effectiveRange: nil) as? NSFont
            TestKit.expectEqual(codeFont, palette.codeFont, "inline code uses code font")

            // The **bold** span is bold.
            let boldLoc = ns.range(of: "bold").location
            let boldFont = storage.attribute(.font, at: boldLoc, effectiveRange: nil) as? NSFont
            let isBold = boldFont?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
            TestKit.expect(isBold, "** bold ** span carries the bold trait")

            // Plain body text keeps the body colour.
            let plainLoc = ns.range(of: "text").location
            let plainColor = storage.attribute(
                .foregroundColor, at: plainLoc, effectiveRange: nil) as? NSColor
            TestKit.expectEqual(plainColor, palette.body, "body text uses body colour")
        }
    }
}
