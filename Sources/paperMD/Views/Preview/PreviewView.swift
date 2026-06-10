import SwiftUI
import WebKit
import paperMDCore

/// Live markdown preview backed by a `WKWebView` running the bundled markdown-it
/// pipeline. Re-renders are debounced and the latest text is buffered until the
/// web view finishes loading.
struct PreviewView: NSViewRepresentable {
    var text: String
    var baseDirectory: URL?
    var debounceMs: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground") // transparent until CSS paints
        context.coordinator.webView = webView

        guard let indexURL = Bundle.main.url(
            forResource: "index", withExtension: "html", subdirectory: "Preview") ??
            previewIndexURL() else {
            return webView
        }
        // Allow read access to the home directory so relative images resolve.
        webView.navigationDelegate = context.coordinator
        webView.loadFileURL(indexURL,
            allowingReadAccessTo: FileManager.default.homeDirectoryForCurrentUser)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.scheduleRender(text: text,
                                           baseDirectory: baseDirectory,
                                           debounceMs: debounceMs)
    }

    /// Resolves the preview index inside the resource bundle (`paperMD_paperMD.bundle`).
    private func previewIndexURL() -> URL? {
        Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "Preview")
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        private var loaded = false
        private var pendingText: String?
        private var pendingBase: URL?
        private var work: DispatchWorkItem?

        func scheduleRender(text: String, baseDirectory: URL?, debounceMs: Int) {
            pendingText = text
            pendingBase = baseDirectory
            work?.cancel()
            let delay = max(0, Double(debounceMs)) / 1000.0
            let work = DispatchWorkItem { [weak self] in self?.flush() }
            self.work = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }

        private func flush() {
            guard loaded, let webView, let text = pendingText else { return }
            if let base = pendingBase {
                let href = base.absoluteString
                evaluate(webView, "setBaseDir(\(jsString(href)))")
            }
            evaluate(webView, "renderMarkdown(\(jsString(text)))")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loaded = true
            flush()
        }

        private func evaluate(_ webView: WKWebView, _ js: String) {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        /// JSON-encodes a string into a safe JS string literal.
        private func jsString(_ s: String) -> String {
            let data = try? JSONSerialization.data(withJSONObject: [s])
            if let data, let array = String(data: data, encoding: .utf8) {
                // array is like ["..."] — strip the surrounding brackets.
                return String(array.dropFirst().dropLast())
            }
            return "\"\""
        }
    }
}
