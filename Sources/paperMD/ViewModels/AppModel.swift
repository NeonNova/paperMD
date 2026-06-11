import Foundation
import AppKit
import Observation
import paperMDCore

/// App-wide state shared by every document window: the open folder (and its file
/// tree) plus a queue of files requested from Finder. Window creation itself is
/// done in the view layer via `@Environment(\.openWindow)`.
@Observable
final class AppModel {
    static let shared = AppModel()

    private(set) var folderURL: URL?
    let fileTree = FileTreeViewModel()

    /// Files/folders handed to us by Finder before a window could open them.
    /// A window drains this and opens the corresponding windows.
    var pendingOpens: [URL] = []

    private init() {
        if let path = UserDefaults.standard.string(forKey: "folderPath") {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) { openFolder(url) }
        }
    }

    // MARK: Folder

    func openFolder(_ url: URL) {
        folderURL = url
        fileTree.load(url)
        UserDefaults.standard.set(url.path, forKey: "folderPath")
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
    }

    func showOpenFolderDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url { openFolder(url) }
    }

    /// Returns markdown files chosen via an open panel (the caller opens windows).
    func chooseFilesToOpen() -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowsOtherFileTypes = true
        guard panel.runModal() == .OK else { return [] }
        return panel.urls.filter(FileService.isMarkdown)
    }

    // MARK: Finder routing

    func enqueueOpen(_ urls: [URL]) {
        for url in urls {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            if isDir.boolValue { openFolder(url) }
            else if FileService.isMarkdown(url) { pendingOpens.append(url) }
        }
    }

    /// Atomically returns and clears the pending file opens.
    func drainPendingOpens() -> [URL] {
        defer { pendingOpens.removeAll() }
        return pendingOpens
    }

    // MARK: File tree operations (sidebar context menu)

    func createFile(in directory: URL) {
        do {
            let url = try uniqueURL(in: directory, name: "Untitled.md")
            try FileService.create(name: url.lastPathComponent, in: directory)
            fileTree.refresh()
        } catch { present(error) }
    }

    func createFolder(in directory: URL) {
        do {
            let url = try uniqueURL(in: directory, name: "New Folder", directory: true)
            try FileService.createFolder(name: url.lastPathComponent, in: directory)
            fileTree.refresh()
        } catch { present(error) }
    }

    func rename(_ url: URL, to newName: String) {
        guard !newName.isEmpty, newName != url.lastPathComponent else { return }
        do { _ = try FileService.rename(url, to: newName); fileTree.refresh() }
        catch { present(error) }
    }

    func delete(_ url: URL) {
        do { try FileService.trash(url); fileTree.refresh() }
        catch { present(error) }
    }

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

    private func present(_ error: Error) {
        NSAlert(error: error).runModal()
    }
}
