import AppKit
import paperMDCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Needed when running as a bare SwiftPM executable (swift run);
        // harmless when launched from the bundled .app.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Show tooltips quickly (default is ~1–2s). Value is in milliseconds.
        UserDefaults.standard.register(defaults: ["NSInitialToolTipDelay": 350])
        // Group document windows into native tabs.
        NSWindow.allowsAutomaticWindowTabbing = true
    }

    /// Files/folders opened from Finder (double-click, "Open With", drag onto the
    /// icon). Queued on the AppModel; an open window drains the queue and opens a
    /// window per file (folders update the shared sidebar).
    func application(_ application: NSApplication, open urls: [URL]) {
        AppModel.shared.enqueueOpen(urls)
    }

    /// Flush every open document before the app quits.
    func applicationWillTerminate(_ notification: Notification) {
        DocumentViewModel.flushAll()
    }
}
