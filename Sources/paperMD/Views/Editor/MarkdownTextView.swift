import AppKit

/// `NSTextView` configured for editing plain markdown source: no rich text, no
/// smart substitutions, native find bar, line-number ruler. Opts into TextKit 1
/// (by touching `layoutManager` at setup) so the ruler and text-storage
/// highlighting use the mature classic APIs.
final class MarkdownTextView: NSTextView {
    /// Mouse tracking so the gutter can show which line the pointer is over.
    private var hoverTracking: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverTracking { removeTrackingArea(hoverTracking) }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self, userInfo: nil)
        addTrackingArea(area)
        hoverTracking = area
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard let layoutManager, let textContainer else { return }
        var point = convert(event.locationInWindow, from: nil)
        point.x -= textContainerInset.width
        point.y -= textContainerInset.height
        let glyph = layoutManager.glyphIndex(for: point, in: textContainer)
        let charIndex = layoutManager.characterIndexForGlyph(at: glyph)
        ruler?.hoveredLine = lineNumber(at: charIndex)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        ruler?.hoveredLine = nil
    }

    private var ruler: LineNumberRulerView? {
        enclosingScrollView?.verticalRulerView as? LineNumberRulerView
    }

    /// 1-based line number containing `charIndex` (counts preceding newlines).
    private func lineNumber(at charIndex: Int) -> Int {
        let ns = string as NSString
        let clamped = min(max(0, charIndex), ns.length)
        var line = 1
        var i = 0
        while i < clamped { if ns.character(at: i) == 0x0A { line += 1 }; i += 1 }
        return line
    }

    static func makeScrollView() -> (scrollView: NSScrollView, textView: MarkdownTextView) {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true

        let textView = MarkdownTextView(frame: .zero)
        // Force TextKit 1: accessing layoutManager opts out of TextKit 2.
        _ = textView.layoutManager

        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.drawsBackground = false   // scroll view paints the themed background
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 8, height: 12)
        textView.font = .systemFont(ofSize: 15)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = textView
        return (scrollView, textView)
    }

    private var wrapEnabled = true
    /// Max text column width when not full-width; nil = fill the editor.
    private var readingMaxWidth: CGFloat?

    /// Configures soft word wrap and the reading-column width. When wrap is off,
    /// text doesn't wrap and a horizontal scroller appears. When wrap is on and
    /// `readingMaxWidth` is set, text wraps at that comfortable column width.
    func setLayout(wrap: Bool, readingMaxWidth: CGFloat?) {
        self.wrapEnabled = wrap
        self.readingMaxWidth = readingMaxWidth
        applyLayout()
    }

    override func layout() {
        super.layout()
        applyLayout()
    }

    private func applyLayout() {
        guard let container = textContainer, let scrollView = enclosingScrollView else { return }
        let available = scrollView.contentSize.width

        if wrapEnabled {
            isHorizontallyResizable = false
            scrollView.hasHorizontalScroller = false
            let target = readingMaxWidth.map { min($0, available) } ?? available
            container.widthTracksTextView = (readingMaxWidth == nil)
            if abs(container.containerSize.width - target) > 0.5 {
                container.containerSize = NSSize(width: target, height: CGFloat.greatestFiniteMagnitude)
            }
            maxSize = NSSize(width: available, height: CGFloat.greatestFiniteMagnitude)
        } else {
            isHorizontallyResizable = true
            scrollView.hasHorizontalScroller = true
            container.widthTracksTextView = false
            container.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
    }
}
