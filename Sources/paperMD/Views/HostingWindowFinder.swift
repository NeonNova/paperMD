import SwiftUI
import AppKit

/// Captures the `NSWindow` hosting a SwiftUI view into a binding, so the view
/// can ask whether it's the key window (used to route window-level commands to
/// only the focused window when several are open).
struct HostingWindowFinder: NSViewRepresentable {
    var onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onResolve(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { onResolve(nsView.window) }
    }
}
