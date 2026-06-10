import AppKit
import paperMDCore

/// A vertical ruler that draws line numbers alongside an `NSTextView`.
///
/// Numbers are word-wrap aware: a logical line that wraps onto several screen
/// lines is numbered only once, on its first fragment. Uses TextKit 1's layout
/// manager, so the host text view must be opted into TextKit 1.
final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?
    var palette: HighlightPalette { didSet { needsDisplay = true } }

    init(textView: NSTextView, palette: HighlightPalette) {
        self.textView = textView
        self.palette = palette
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 44

        NotificationCenter.default.addObserver(
            self, selector: #selector(textDidChange),
            name: NSText.didChangeNotification, object: textView)
        // Redraw line numbers as the view scrolls.
        textView.enclosingScrollView?.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(boundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: textView.enclosingScrollView?.contentView)
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is unused") }

    @objc private func textDidChange() { needsDisplay = true }
    @objc private func boundsDidChange() { needsDisplay = true }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        // Fill the gutter with the editor background so it's themed, not white.
        palette.background.setFill()
        bounds.fill()

        guard let textView,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer else { return }

        let content = textView.string as NSString
        let visibleRect = textView.visibleRect
        let inset = textView.textContainerInset.height

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: palette.quote,
        ]

        // Glyphs currently on screen.
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        // Line number of the first visible character: count newline characters
        // in the prefix [0, location). (NSString.replacingOccurrences(range:)
        // returns the *whole* string with replacements scoped to the range, so
        // it cannot be used to count within a prefix.)
        var lineNumber = 1
        var i = 0
        while i < charRange.location {
            if content.character(at: i) == 0x0A { lineNumber += 1 }
            i += 1
        }

        var index = charRange.location
        while index < NSMaxRange(charRange) {
            let lineRange = content.lineRange(for: NSRange(location: index, length: 0))
            let firstFragmentGlyph = layoutManager.glyphIndexForCharacter(at: lineRange.location)
            var effectiveRange = NSRange()
            let fragmentRect = layoutManager.lineFragmentRect(
                forGlyphAt: firstFragmentGlyph, effectiveRange: &effectiveRange)

            let y = fragmentRect.minY + inset - visibleRect.minY
            let label = "\(lineNumber)" as NSString
            let size = label.size(withAttributes: attrs)
            label.draw(
                at: NSPoint(x: ruleThickness - size.width - 5, y: y + (fragmentRect.height - size.height) / 2),
                withAttributes: attrs)

            lineNumber += 1
            index = NSMaxRange(lineRange)
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
