import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// One-time welcome shown on first launch. Offers to make paperMD the default
/// Markdown handler using the supported `NSWorkspace.setDefaultApplication`
/// API. Only meaningful when running from the bundled .app.
struct FirstLaunchView: View {
    @Binding var isPresented: Bool
    @State private var status: String?

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Welcome to paperMD")
                .font(.title.bold())
            Text("A fast, native Markdown editor for macOS. Open a file or folder to begin — drag one onto the window any time.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)

            if let status {
                Text(status).font(.callout).foregroundStyle(.secondary)
            }

            HStack {
                Button("Not Now") { isPresented = false }
                Button("Make paperMD the Default for Markdown") { makeDefault() }
                    .buttonStyle(.borderedProminent)
            }

            if isRunningFromBundle == false {
                Text("Tip: drag paperMD into /Applications to install it.")
                    .font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(36)
        .frame(width: 460)
    }

    private var isRunningFromBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    private func makeDefault() {
        guard isRunningFromBundle,
              let markdown = UTType("net.daringfireball.markdown") else {
            status = "Run paperMD from the built app to set it as the default."
            return
        }
        let appURL = Bundle.main.bundleURL
        NSWorkspace.shared.setDefaultApplication(at: appURL, toOpen: markdown) { error in
            DispatchQueue.main.async {
                status = error == nil
                    ? "paperMD is now the default for Markdown files."
                    : "Couldn't set the default: \(error!.localizedDescription)"
            }
        }
    }
}
