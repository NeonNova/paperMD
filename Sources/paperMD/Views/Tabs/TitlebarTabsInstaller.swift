import SwiftUI
import AppKit

/// Marker so we can find (and not duplicate) our accessory on the window.
final class PaperMDTabsAccessory: NSTitlebarAccessoryViewController {}

/// Installs the document tab strip into the window's titlebar as a Liquid Glass
/// accessory (the single-window equivalent of Ghostty's native titlebar tabs).
/// Add it as a near-invisible background view in the main window.
///
/// Idempotent against the *window* (not coordinator state), because SwiftUI may
/// re-instantiate this representable and its coordinator across updates.
struct TitlebarTabsInstaller: NSViewRepresentable {
    var workspace: WorkspaceViewModel
    var theme: ThemeManager

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { sync(from: view) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { sync(from: nsView) }
    }

    private func sync(from view: NSView) {
        guard let window = view.window else { return }

        // Unified titlebar so the strip reads as part of it.
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        let existing = window.titlebarAccessoryViewControllers
            .compactMap { $0 as? PaperMDTabsAccessory }

        let accessory: PaperMDTabsAccessory
        if let found = existing.first {
            accessory = found
            // Remove any accidental duplicates from earlier installs.
            for dup in existing.dropFirst() {
                if let idx = window.titlebarAccessoryViewControllers.firstIndex(of: dup) {
                    window.removeTitlebarAccessoryViewController(at: idx)
                }
            }
        } else {
            let host = NSHostingView(rootView:
                TabBarView(workspace: workspace, theme: theme)
                    .frame(maxWidth: .infinity))
            host.sizingOptions = []     // don't shrink to fitting size; fill width
            host.frame = NSRect(x: 0, y: 0, width: max(window.frame.width, 600), height: 38)
            host.autoresizingMask = [.width]

            let acc = PaperMDTabsAccessory()
            acc.layoutAttribute = .bottom
            acc.view = host
            window.addTitlebarAccessoryViewController(acc)
            accessory = acc
        }

        accessory.isHidden = workspace.documents.isEmpty
    }
}
