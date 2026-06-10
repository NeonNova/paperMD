import AppKit

/// `NSTextView` configured for editing plain markdown source: no rich text, no
/// smart substitutions, native find bar, line-number ruler. Opts into TextKit 1
/// (by touching `layoutManager` at setup) so the ruler and text-storage
/// highlighting use the mature classic APIs.
final class MarkdownTextView: NSTextView {
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

    /// Toggles soft word wrap. When off, the container grows horizontally and a
    /// horizontal scroller appears.
    func setWordWrap(_ wrap: Bool) {
        guard let container = textContainer, let scrollView = enclosingScrollView else { return }
        if wrap {
            isHorizontallyResizable = false
            container.widthTracksTextView = true
            container.containerSize = NSSize(
                width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            maxSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            scrollView.hasHorizontalScroller = false
            frame.size.width = scrollView.contentSize.width
        } else {
            isHorizontallyResizable = true
            container.widthTracksTextView = false
            container.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            scrollView.hasHorizontalScroller = true
        }
        needsLayout = true
    }
}
