import Foundation
import Observation
import paperMDCore

/// Owns the sidebar's file tree for the open folder and rebuilds it when the
/// folder changes on disk.
@Observable
final class FileTreeViewModel {
    private(set) var root: FileTreeNode?
    var rootURL: URL? { root?.url }

    private var watcher: FolderWatcher?

    func load(_ url: URL) {
        root = FileTreeNode.build(at: url)
        watcher = FolderWatcher(url: url) { [weak self] in self?.refresh() }
        watcher?.start()
    }

    func refresh() {
        guard let url = root?.url else { return }
        root = FileTreeNode.build(at: url)
    }

    func clear() {
        watcher?.stop()
        watcher = nil
        root = nil
    }
}
