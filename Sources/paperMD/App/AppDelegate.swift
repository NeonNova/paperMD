import AppKit
import paperMDCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Needed when running as a bare SwiftPM executable (swift run);
        // harmless when launched from the bundled .app.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    /// Files opened from Finder (double-click, "Open With", drag onto the icon).
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            if isDir.boolValue {
                WorkspaceViewModel.shared?.openFolder(url)
            } else if FileService.isMarkdown(url) {
                WorkspaceViewModel.shared?.open(url)
            }
        }
    }

    /// Flush unsaved work before the app quits.
    func applicationWillTerminate(_ notification: Notification) {
        WorkspaceViewModel.shared?.saveAll()
    }
}
