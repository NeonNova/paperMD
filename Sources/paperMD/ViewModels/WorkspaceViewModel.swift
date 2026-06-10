import Foundation
import AppKit
import Observation
import paperMDCore

/// Top-level workspace state: the open folder, open documents, and the active
/// one. Task 4 wires single-document open/save and external-change handling;
/// tabs and the file tree build on this in later tasks.
@Observable
final class WorkspaceViewModel {
    /// Shared reference so the AppDelegate can route Finder "open" events here.
    static weak var shared: WorkspaceViewModel?

    private(set) var folderURL: URL?
    private(set) var documents: [DocumentViewModel] = []
    var activeIndex: Int = 0

    var active: DocumentViewModel? {
        documents.indices.contains(activeIndex) ? documents[activeIndex] : nil
    }

    private var folderWatcher: FolderWatcher?
    private var fileWatcher: FolderWatcher?

    init() { WorkspaceViewModel.shared = self }

    // MARK: Opening

    /// Opens a markdown file: focuses an existing tab if already open, else adds.
    func open(_ url: URL) {
        if let index = documents.firstIndex(where: { $0.url == url }) {
            activeIndex = index
            return
        }
        do {
            let doc = try DocumentViewModel.open(url)
            documents.append(doc)
            activeIndex = documents.count - 1
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            watchActiveFile()
        } catch {
            present(error)
        }
    }

    func openFolder(_ url: URL) {
        folderURL = url
        folderWatcher = FolderWatcher(url: url) { /* tree refresh wired in Task 6 */ }
        folderWatcher?.start()
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
    }

    func newUntitled() {
        let doc = DocumentViewModel(url: nil, text: "")
        documents.append(doc)
        activeIndex = documents.count - 1
    }

    // MARK: Panels

    func showOpenFileDialog() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            panel.urls.filter(FileService.isMarkdown).forEach(open)
        }
    }

    func showOpenFolderDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url { openFolder(url) }
    }

    /// Save As… for an untitled document or an explicit relocation.
    func saveActiveAs() {
        guard let doc = active else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = doc.url?.lastPathComponent ?? "Untitled.md"
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        if panel.runModal() == .OK, let url = panel.url {
            do { try doc.assignURL(url); NSDocumentController.shared.noteNewRecentDocumentURL(url) }
            catch { present(error) }
        }
    }

    /// Manual save (⌘S). Routes untitled documents to Save As…
    func saveActive() {
        guard let doc = active else { return }
        if doc.url == nil { saveActiveAs() } else { doc.autosave().map(present) }
    }

    /// Flushes every dirty document (called on window blur and app quit).
    func saveAll() {
        for doc in documents where doc.isDirty && doc.url != nil { doc.autosave() }
    }

    // MARK: External changes

    private func watchActiveFile() {
        guard let url = active?.url else { return }
        fileWatcher = FolderWatcher(url: url.deletingLastPathComponent()) { [weak self] in
            self?.handleExternalChange()
        }
        fileWatcher?.start()
    }

    private func handleExternalChange() {
        guard let doc = active else { return }
        switch doc.checkForExternalChange() {
        case .none, .reloaded:
            break
        case .conflict:
            let alert = NSAlert()
            alert.messageText = "“\(doc.displayName)” changed on disk"
            alert.informativeText = "The file was modified by another app while you have unsaved changes."
            alert.addButton(withTitle: "Keep Mine")
            alert.addButton(withTitle: "Reload from Disk")
            if alert.runModal() == .alertSecondButtonReturn,
               let url = doc.url, let contents = try? FileService.read(url) {
                doc.applyExternal(contents)
            }
        }
    }

    // MARK: Errors

    private func present(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}
