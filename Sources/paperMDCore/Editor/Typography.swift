import AppKit

/// User typography preferences. An empty font name means "use the system font".
public struct Typography: Equatable, Sendable {
    public var bodyFontName: String
    public var bodySize: CGFloat
    public var codeFontName: String
    public var codeSize: CGFloat

    public init(bodyFontName: String = "", bodySize: CGFloat = 15,
                codeFontName: String = "", codeSize: CGFloat = 13) {
        self.bodyFontName = bodyFontName
        self.bodySize = bodySize
        self.codeFontName = codeFontName
        self.codeSize = codeSize
    }

    public func bodyFont() -> NSFont {
        bodyFontName.isEmpty
            ? .systemFont(ofSize: bodySize)
            : (NSFont(name: bodyFontName, size: bodySize) ?? .systemFont(ofSize: bodySize))
    }

    public func codeFont() -> NSFont {
        codeFontName.isEmpty
            ? .monospacedSystemFont(ofSize: codeSize, weight: .regular)
            : (NSFont(name: codeFontName, size: codeSize) ?? .monospacedSystemFont(ofSize: codeSize, weight: .regular))
    }

    /// CSS font-family value for the preview (quoted, with sensible fallbacks).
    public var bodyCSSFamily: String {
        bodyFontName.isEmpty ? "-apple-system, BlinkMacSystemFont, sans-serif"
                             : "\"\(bodyFontName)\", -apple-system, sans-serif"
    }
    public var codeCSSFamily: String {
        codeFontName.isEmpty ? "ui-monospace, \"SF Mono\", Menlo, monospace"
                             : "\"\(codeFontName)\", ui-monospace, monospace"
    }
}
