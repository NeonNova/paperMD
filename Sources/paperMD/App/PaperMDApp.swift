import SwiftUI
import paperMDCore

@main
struct PaperMDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowToolbarStyle(.unified)

        Settings {
            SettingsView()
        }
    }
}
