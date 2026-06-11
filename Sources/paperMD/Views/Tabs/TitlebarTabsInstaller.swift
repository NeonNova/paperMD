import SwiftUI
import AppKit

/// Installs the document tab strip into the window's titlebar as a Liquid Glass
/// accessory (the single-window equivalent of Ghostty's native titlebar tabs).
/// Add it as a near-invisible background view in the main window.
struct TitlebarTabsInstaller: NSViewRepresentable {
    var workspace: WorkspaceViewModel
    var theme: ThemeManager

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { install(from: view, context: context) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Re-attempt install if the window appeared late, and toggle the strip's
        // visibility with the document count (no empty strip on the welcome view).
        install(from: nsView, context: context)
        context.coordinator.accessory?.isHidden = workspace.documents.isEmpty
    }

    private func install(from view: NSView, context: Context) {
        guard let window = view.window else { return }

        // Unified titlebar: hide the title text and let the glass show through so
        // the tab strip reads as part of the titlebar.
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        guard context.coordinator.accessory == nil else { return }

        let host = NSHostingView(rootView: TabBarView(workspace: workspace, theme: theme))
        host.frame = NSRect(x: 0, y: 0, width: window.frame.width, height: 36)
        host.autoresizingMask = [.width]

        let accessory = NSTitlebarAccessoryViewController()
        accessory.layoutAttribute = .bottom
        accessory.view = host
        accessory.isHidden = workspace.documents.isEmpty
        window.addTitlebarAccessoryViewController(accessory)

        context.coordinator.accessory = accessory
    }

    final class Coordinator {
        weak var accessory: NSTitlebarAccessoryViewController?
    }
}
