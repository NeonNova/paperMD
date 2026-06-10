import AppKit

/// Colours and fonts the editor uses for syntax highlighting. Theme-agnostic
/// for now (system colours); `ThemeManager` supplies a theme-derived palette in
/// the theming task.
public struct HighlightPalette {
    public var body: NSColor
    public var heading: NSColor
    public var emphasis: NSColor
    public var code: NSColor
    public var codeBackground: NSColor
    public var link: NSColor
    public var quote: NSColor
    public var listMarker: NSColor
    public var wikilink: NSColor

    public var bodyFont: NSFont
    public var codeFont: NSFont

    public init(body: NSColor, heading: NSColor, emphasis: NSColor, code: NSColor,
                codeBackground: NSColor, link: NSColor, quote: NSColor,
                listMarker: NSColor, wikilink: NSColor, bodyFont: NSFont, codeFont: NSFont) {
        self.body = body; self.heading = heading; self.emphasis = emphasis
        self.code = code; self.codeBackground = codeBackground; self.link = link
        self.quote = quote; self.listMarker = listMarker; self.wikilink = wikilink
        self.bodyFont = bodyFont; self.codeFont = codeFont
    }

    /// Default palette derived from system colours and standard fonts.
    public static func system(bodySize: CGFloat = 15, codeSize: CGFloat = 13) -> HighlightPalette {
        HighlightPalette(
            body: .labelColor,
            heading: .controlAccentColor,
            emphasis: .labelColor,
            code: .labelColor,
            codeBackground: .quaternaryLabelColor.withAlphaComponent(0.18),
            link: .linkColor,
            quote: .secondaryLabelColor,
            listMarker: .controlAccentColor,
            wikilink: .controlAccentColor,
            bodyFont: .systemFont(ofSize: bodySize),
            codeFont: .monospacedSystemFont(ofSize: codeSize, weight: .regular)
        )
    }
}
