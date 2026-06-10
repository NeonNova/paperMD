import SwiftUI
import paperMDCore

@main
struct PaperMDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 8) {
                Text("paperMD").font(.largeTitle)
                Text("v\(paperMDVersion)").foregroundStyle(.secondary)
            }
            .frame(minWidth: 600, minHeight: 400)
        }
    }
}
