import AppKit

public extension Theme {
    var backgroundColor: NSColor { NSColor(hex: colors.background) ?? .windowBackgroundColor }
    var surfaceColor: NSColor { NSColor(hex: colors.surface) ?? .underPageBackgroundColor }
    var textColor: NSColor { NSColor(hex: colors.text) ?? .labelColor }
    var mutedColor: NSColor { NSColor(hex: colors.muted) ?? .secondaryLabelColor }
    var accentColor: NSColor { NSColor(hex: colors.accent) ?? .controlAccentColor }

    /// True when the background is dark — drives `NSAppearance` and the
    /// highlight.js stylesheet choice.
    var isDark: Bool {
        guard let bg = NSColor(hex: colors.background)?.usingColorSpace(.sRGB) else { return false }
        // Rec. 601 luma.
        let luma = 0.299 * bg.redComponent + 0.587 * bg.greenComponent + 0.114 * bg.blueComponent
        return luma < 0.5
    }

    /// Editor highlight palette derived from this theme and the user's fonts.
    func palette(typography: Typography) -> HighlightPalette {
        HighlightPalette(
            body: textColor,
            heading: accentColor,
            emphasis: textColor,
            code: textColor,
            codeBackground: surfaceColor,
            link: accentColor,
            quote: mutedColor,
            listMarker: accentColor,
            wikilink: accentColor,
            background: backgroundColor,
            bodyFont: typography.bodyFont(),
            codeFont: typography.codeFont()
        )
    }

    /// CSS custom-property dictionary injected into the preview web view.
    func cssVars(typography: Typography) -> [String: String] {
        [
            "background": colors.background,
            "surface": colors.surface,
            "text": colors.text,
            "muted": colors.muted,
            "accent": colors.accent,
            "body-font": typography.bodyCSSFamily,
            "code-font": typography.codeCSSFamily,
            "body-size": "\(Int(typography.bodySize))px",
            "code-size": "\(String(format: "%.1f", typography.codeSize))px",
            "is-dark": isDark ? "1" : "0",
        ]
    }
}
