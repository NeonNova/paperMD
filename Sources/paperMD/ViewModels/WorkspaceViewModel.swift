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
    let fileTree = FileTreeViewModel()

    var active: DocumentViewModel? {
        documents.indices.contains(activeIndex) ? documents[activeIndex] : nil
    }

    private var fileWatcher: FolderWatcher?
    private let sessionStore = SessionStore()

    init() { WorkspaceViewModel.shared = self }

    // MARK: Session restore & crash recovery

    /// Restores the previous session (folder, tabs, mode, cursors) when enabled,
    /// then reopens any crash-recovery journals as untitled tabs. Call once on
    /// launch, after the window exists.
    func restoreOnLaunch() {
        let restoreEnabled = UserDefaults.standard.object(forKey: "restoreSession") as? Bool ?? true
        if restoreEnabled, let session = sessionStore.load() {
            if let path = session.folderPath {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: url.path) { openFolder(url) }
            }
            for path in session.openFiles {
                let url = URL(fileURLWithPath: path)
                guard FileManager.default.fileExists(atPath: url.path) else { continue } // skip missing
                if let doc = try? DocumentViewModel.open(url) {
                    doc.cursorOffset = session.cursors[path] ?? 0
                    documents.append(doc)
                    NSDocumentController.shared.noteNewRecentDocumentURL(url)
                }
            }
            activeIndex = min(max(0, session.activeIndex), max(0, documents.count - 1))
        }

        // Crash recovery: reopen orphaned unsaved buffers as untitled tabs.
        for journal in JournalStore.recoverableFiles() {
            if let text = try? FileService.read(journal), !text.isEmpty {
                let doc = DocumentViewModel(url: nil, text: text)
                doc.markDirty() // keep it dirty so it stays journaled
                documents.append(doc)
            }
            try? FileManager.default.removeItem(at: journal)
        }
        persistSession()
    }

    /// Captures current state and schedules a debounced save.
    func persistSession() {
        var session = Session()
        session.folderPath = folderURL?.path
        session.openFiles = documents.compactMap { $0.url?.path }
        // Active index expressed against the titled-files list.
        if let active = active, let url = active.url,
           let idx = session.openFiles.firstIndex(of: url.path) {
            session.activeIndex = idx
        }
        session.mode = EditorMode(rawValue: UserDefaults.standard.string(forKey: "editorMode") ?? "edit") ?? .edit
        session.cursors = Dictionary(uniqueKeysWithValues:
            documents.compactMap { doc in doc.url.map { ($0.path, doc.cursorOffset) } })
        sessionStore.save(session)
    }

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
            persistSession()
        } catch {
            present(error)
        }
    }

    func openFolder(_ url: URL) {
        folderURL = url
        fileTree.load(url)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        persistSession()
    }

    // MARK: File tree operations (sidebar context menu)

    /// Closes any open tab pointing at `url` (used before delete/rename).
    private func closeTab(for url: URL) {
        if let index = documents.firstIndex(where: { $0.url == url }) {
            closeTab(at: index)
        }
    }

    func createFile(in directory: URL, name: String = "Untitled.md") {
        do {
            let url = try uniqueURL(in: directory, name: name)
            try FileService.create(name: url.lastPathComponent, in: directory)
            fileTree.refresh()
            open(url)
        } catch { present(error) }
    }

    func createFolder(in directory: URL, name: String = "New Folder") {
        do {
            let url = try uniqueURL(in: directory, name: name, directory: true)
            try FileService.createFolder(name: url.lastPathComponent, in: directory)
            fileTree.refresh()
        } catch { present(error) }
    }

    func rename(_ url: URL, to newName: String) {
        guard !newName.isEmpty, newName != url.lastPathComponent else { return }
        do {
            let newURL = try FileService.rename(url, to: newName)
            // Re-point an open tab at the new location.
            if let doc = documents.first(where: { $0.url == url }) {
                try? doc.assignURL(newURL)
            }
            fileTree.refresh()
        } catch { present(error) }
    }

    func delete(_ url: URL) {
        do {
            closeTab(for: url)
            try FileService.trash(url)
            fileTree.refresh()
        } catch { present(error) }
    }

    /// Appends a numeric suffix if `name` is already taken in `directory`.
    private func uniqueURL(in directory: URL, name: String, directory isDir: Bool = false) throws -> URL {
        let ext = (name as NSString).pathExtension
        let base = (name as NSString).deletingPathExtension
        var candidate = directory.appendingPathComponent(name)
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let newName = ext.isEmpty ? "\(base) \(n)" : "\(base) \(n).\(ext)"
            candidate = directory.appendingPathComponent(newName)
            n += 1
        }
        return candidate
    }

    func newUntitled() {
        let doc = DocumentViewModel(url: nil, text: "")
        documents.append(doc)
        activeIndex = documents.count - 1
    }

    // MARK: Tabs

    func select(_ index: Int) {
        guard documents.indices.contains(index) else { return }
        activeIndex = index
        persistSession()
    }

    func closeTab(at index: Int) {
        guard documents.indices.contains(index) else { return }
        documents[index].autosave()
        documents.remove(at: index)
        activeIndex = min(activeIndex, documents.count - 1)
        if activeIndex < 0 { activeIndex = 0 }
        persistSession()
    }

    func closeActiveTab() {
        guard !documents.isEmpty else { return }
        closeTab(at: activeIndex)
    }

    func selectNextTab() {
        guard !documents.isEmpty else { return }
        activeIndex = (activeIndex + 1) % documents.count
    }

    func selectPreviousTab() {
        guard !documents.isEmpty else { return }
        activeIndex = (activeIndex - 1 + documents.count) % documents.count
    }

    /// Reorders a tab (drag-and-drop in the tab bar).
    func moveTab(from source: Int, to destination: Int) {
        guard documents.indices.contains(source) else { return }
        let activeDoc = active
        let doc = documents.remove(at: source)
        let dest = min(max(0, destination), documents.count)
        documents.insert(doc, at: dest)
        if let activeDoc, let newIndex = documents.firstIndex(where: { $0.id == activeDoc.id }) {
            activeIndex = newIndex
        }
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
    /// Titled documents write to disk; untitled ones journal for crash recovery.
    func saveAll() {
        for doc in documents where doc.isDirty { doc.autosave() }
    }

    /// Clean-shutdown flush: persist docs and the session synchronously.
    func flushOnQuit() {
        saveAll()
        var session = Session()
        session.folderPath = folderURL?.path
        session.openFiles = documents.compactMap { $0.url?.path }
        if let active, let url = active.url, let idx = session.openFiles.firstIndex(of: url.path) {
            session.activeIndex = idx
        }
        session.mode = EditorMode(rawValue: UserDefaults.standard.string(forKey: "editorMode") ?? "edit") ?? .edit
        session.cursors = Dictionary(uniqueKeysWithValues:
            documents.compactMap { doc in doc.url.map { ($0.path, doc.cursorOffset) } })
        sessionStore.saveNow(session)
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
