import SwiftUI
import AppKit

/// Reaches the hosting `NSWindow` and tints its titlebar/toolbar to match the
/// theme, so the top bar isn't a stock grey strip above themed content. Add it
/// as a near-invisible background view.
struct WindowThemer: NSViewRepresentable {
    var background: NSColor

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { apply(from: view) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { apply(from: nsView) }
    }

    private func apply(from view: NSView) {
        guard let window = view.window else { return }
        window.titlebarAppearsTransparent = true
        window.backgroundColor = background
        window.isMovableByWindowBackground = false
    }
}
