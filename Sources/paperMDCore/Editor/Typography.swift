import AppKit

/// User typography preferences. An empty font name means "use the system font".
public struct Typography: Equatable, Sendable {
    /// Font for app chrome (sidebar, tabs, menus).
    public var interfaceFontName: String
    public var interfaceSize: CGFloat
    /// Font for editor + preview body text.
    public var bodyFontName: String
    public var bodySize: CGFloat
    /// Font for code (editor code spans/blocks + preview code).
    public var codeFontName: String
    public var codeSize: CGFloat

    public init(interfaceFontName: String = "", interfaceSize: CGFloat = 13,
                bodyFontName: String = "", bodySize: CGFloat = 15,
                codeFontName: String = "", codeSize: CGFloat = 13) {
        self.interfaceFontName = interfaceFontName
        self.interfaceSize = interfaceSize
        self.bodyFontName = bodyFontName
        self.bodySize = bodySize
        self.codeFontName = codeFontName
        self.codeSize = codeSize
    }

    public func interfaceFont() -> NSFont {
        interfaceFontName.isEmpty
            ? .systemFont(ofSize: interfaceSize)
            : (NSFont(name: interfaceFontName, size: interfaceSize) ?? .systemFont(ofSize: interfaceSize))
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
