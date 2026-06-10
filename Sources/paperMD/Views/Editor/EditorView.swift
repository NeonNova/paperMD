import SwiftUI
import AppKit
import paperMDCore

/// Imperative handle to the editor for actions that don't fit a binding:
/// jumping to a line/offset, focusing the find bar. A view obtains one, passes
/// it to `EditorView`, and later calls these methods (e.g. from the outline or
/// the command palette).
final class EditorController: ObservableObject {
    fileprivate weak var textView: MarkdownTextView?

    /// Moves the caret to the start of `line` (1-based) and scrolls to it.
    func goToLine(_ line: Int) {
        guard let textView else { return }
        let ns = textView.string as NSString
        var current = 1
        var location = 0
        while current < line, location < ns.length {
            let lineRange = ns.lineRange(for: NSRange(location: location, length: 0))
            location = NSMaxRange(lineRange)
            current += 1
        }
        let target = NSRange(location: min(location, ns.length), length: 0)
        textView.setSelectedRange(target)
        textView.scrollRangeToVisible(target)
        textView.window?.makeFirstResponder(textView)
    }

    /// Moves the caret to a character `offset` (used to restore cursor state).
    func jumpToOffset(_ offset: Int) {
        guard let textView else { return }
        let clamped = max(0, min(offset, (textView.string as NSString).length))
        let target = NSRange(location: clamped, length: 0)
        textView.setSelectedRange(target)
        textView.scrollRangeToVisible(target)
    }

    /// Opens the native find bar, optionally in find-and-replace mode.
    func showFind(replace: Bool) {
        let action: NSTextFinder.Action = replace ? .showReplaceInterface : .showFindInterface
        let item = NSMenuItem()
        item.tag = action.rawValue
        textView?.performFindPanelAction(item)
    }
}

/// SwiftUI wrapper around `MarkdownTextView` with a line-number ruler and live
/// syntax highlighting.
struct EditorView: NSViewRepresentable {
    @Binding var text: String
    var palette: HighlightPalette
    var wordWrap: Bool
    var controller: EditorController
    var onCursorChange: (Int) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let (scrollView, textView) = MarkdownTextView.makeScrollView()
        textView.delegate = context.coordinator
        textView.string = text

        let highlighter = MarkdownHighlighter(palette: palette)
        highlighter.attach(to: textView.textStorage!)
        context.coordinator.highlighter = highlighter

        let ruler = LineNumberRulerView(textView: textView, palette: palette)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        context.coordinator.ruler = ruler

        controller.textView = textView
        textView.setWordWrap(wordWrap)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? MarkdownTextView else { return }

        // Only overwrite the buffer when the external value genuinely differs,
        // to avoid clobbering the caret while the user types.
        if textView.string != text {
            let selected = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(NSRange(
                location: min(selected.location, (text as NSString).length), length: 0))
        }

        context.coordinator.highlighter?.palette = palette
        context.coordinator.ruler?.palette = palette
        textView.setWordWrap(wordWrap)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: EditorView
        var highlighter: MarkdownHighlighter?
        var ruler: LineNumberRulerView?

        init(_ parent: EditorView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.onCursorChange(textView.selectedRange().location)
        }
    }
}
