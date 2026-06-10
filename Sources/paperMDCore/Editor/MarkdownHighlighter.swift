import AppKit

/// Applies markdown syntax highlighting to an `NSTextStorage` as it changes.
///
/// On every edit it re-highlights only the affected paragraph range (cheap, so
/// typing stays responsive). Because fenced code blocks span paragraphs, a
/// debounced full-document pass marks fence interiors shortly after edits
/// settle. All attribute changes are made inside `didProcessEditing`, so they
/// do not register as separate undo steps.
public final class MarkdownHighlighter: NSObject, NSTextStorageDelegate {
    public var palette: HighlightPalette {
        didSet { rehighlightAll() }
    }

    private weak var textStorage: NSTextStorage?
    private var fenceWorkItem: DispatchWorkItem?

    // Compiled once. `anchorsMatchLines` makes `^`/`$` match per line.
    private static func re(_ pattern: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
    }
    private let headingRE   = re(#"^(#{1,6})\s+.*$"#)
    private let boldRE      = re(#"(\*\*|__)(?=\S)(.+?)(?<=\S)\1"#)
    private let italicRE    = re(#"(?<![\*_\w])([*_])(?![\*_])(.+?)(?<![\*_])\1(?![\*_\w])"#)
    private let inlineCodeRE = re(#"`[^`\n]+`"#)
    private let linkRE      = re(#"\[[^\]\n]+\]\([^)\n]+\)"#)
    private let autolinkRE  = re(#"<https?://[^>\s]+>"#)
    private let quoteRE     = re(#"^\s{0,3}>.*$"#)
    private let listRE      = re(#"^\s*([-*+]|\d+\.)\s"#)
    private let wikilinkRE  = re(#"\[\[[^\]\n]+\]\]"#)
    private let fenceLineRE = re(#"^\s*(```|~~~)"#)

    public init(palette: HighlightPalette) {
        self.palette = palette
    }

    public func attach(to storage: NSTextStorage) {
        self.textStorage = storage
        storage.delegate = self
        rehighlightAll()
    }

    // MARK: NSTextStorageDelegate

    public func textStorage(_ storage: NSTextStorage,
                            didProcessEditing editedMask: NSTextStorageEditActions,
                            range editedRange: NSRange,
                            changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }
        let ns = storage.string as NSString
        let paragraphRange = ns.paragraphRange(for: editedRange)
        highlightInline(in: storage, range: paragraphRange)
        scheduleFencePass()
    }

    // MARK: Highlighting

    private func rehighlightAll() {
        guard let storage = textStorage else { return }
        let full = NSRange(location: 0, length: storage.length)
        storage.beginEditing()
        highlightInline(in: storage, range: full)
        storage.endEditing()
        applyFences(in: storage)
    }

    /// Resets attributes in `range` to body style, then applies inline spans.
    private func highlightInline(in storage: NSTextStorage, range: NSRange) {
        let base: [NSAttributedString.Key: Any] = [
            .font: palette.bodyFont,
            .foregroundColor: palette.body,
        ]
        storage.setAttributes(base, range: range)

        apply(quoteRE, in: storage, range: range) { _ in
            [.foregroundColor: palette.quote]
        }
        apply(listRE, in: storage, range: range) { _ in
            [.foregroundColor: palette.listMarker]
        }
        apply(headingRE, in: storage, range: range) { match in
            let level = self.hashCount(storage, match.range)
            let size = self.headingSize(forLevel: level)
            return [
                .foregroundColor: palette.heading,
                .font: NSFont.boldSystemFont(ofSize: size),
            ]
        }
        apply(boldRE, in: storage, range: range) { _ in
            [.font: self.bold(palette.bodyFont)]
        }
        apply(italicRE, in: storage, range: range) { _ in
            [.font: self.italic(palette.bodyFont)]
        }
        apply(linkRE, in: storage, range: range) { _ in
            [.foregroundColor: palette.link, .underlineStyle: NSUnderlineStyle.single.rawValue]
        }
        apply(autolinkRE, in: storage, range: range) { _ in
            [.foregroundColor: palette.link, .underlineStyle: NSUnderlineStyle.single.rawValue]
        }
        apply(wikilinkRE, in: storage, range: range) { _ in
            [.foregroundColor: palette.wikilink]
        }
        apply(inlineCodeRE, in: storage, range: range) { _ in
            [.font: palette.codeFont, .backgroundColor: palette.codeBackground]
        }
    }

    /// Debounced full-document pass that styles fenced code-block interiors.
    private func scheduleFencePass() {
        fenceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, let storage = self.textStorage else { return }
            self.applyFences(in: storage)
        }
        fenceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }

    private func applyFences(in storage: NSTextStorage) {
        let ns = storage.string as NSString
        let full = NSRange(location: 0, length: ns.length)
        let fences = fenceLineRE.matches(in: storage.string, range: full)
        guard fences.count >= 2 else { return }

        storage.beginEditing()
        var i = 0
        while i + 1 < fences.count {
            let open = fences[i].range
            let close = fences[i + 1].range
            let start = open.location
            let end = close.location + close.length
            let blockRange = NSRange(location: start, length: min(end, ns.length) - start)
            storage.addAttributes(
                [.font: palette.codeFont,
                 .foregroundColor: palette.code,
                 .backgroundColor: palette.codeBackground],
                range: blockRange)
            i += 2
        }
        storage.endEditing()
    }

    // MARK: Helpers

    private func apply(_ regex: NSRegularExpression,
                       in storage: NSTextStorage,
                       range: NSRange,
                       attributes: (NSTextCheckingResult) -> [NSAttributedString.Key: Any]) {
        regex.enumerateMatches(in: storage.string, range: range) { match, _, _ in
            guard let match else { return }
            storage.addAttributes(attributes(match), range: match.range)
        }
    }

    private func hashCount(_ storage: NSTextStorage, _ range: NSRange) -> Int {
        let ns = storage.string as NSString
        var count = 0
        var idx = range.location
        while idx < ns.length, ns.character(at: idx) == UInt16(UnicodeScalar("#").value) {
            count += 1; idx += 1
        }
        return max(1, min(6, count))
    }

    private func headingSize(forLevel level: Int) -> CGFloat {
        let base = palette.bodyFont.pointSize
        switch level {
        case 1: return base + 10
        case 2: return base + 7
        case 3: return base + 4
        case 4: return base + 2
        default: return base + 1
        }
    }

    private func bold(_ font: NSFont) -> NSFont {
        withTraits(font, .bold)
    }
    private func italic(_ font: NSFont) -> NSFont {
        withTraits(font, .italic)
    }

    /// Adds symbolic traits via the font descriptor, which works reliably on the
    /// system font (unlike `NSFontManager.convert(toHaveTrait:)`).
    private func withTraits(_ font: NSFont, _ traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let existing = font.fontDescriptor.symbolicTraits
        let descriptor = font.fontDescriptor.withSymbolicTraits(existing.union(traits))
        return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
    }
}
