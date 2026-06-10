import Foundation

/// A node in the sidebar file tree. Directories have non-nil `children`
/// (possibly empty); files have nil `children`.
public struct FileTreeNode: Identifiable, Equatable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let isDirectory: Bool
    public var children: [FileTreeNode]?

    public var name: String { url.lastPathComponent }

    public init(url: URL, isDirectory: Bool, children: [FileTreeNode]? = nil) {
        self.url = url
        self.isDirectory = isDirectory
        self.children = children
    }

    /// Builds a tree rooted at `url`, showing directories and markdown files
    /// only, sorted directories-first then case-insensitively by name. Dotfiles
    /// are skipped. Recursion is bounded by `maxDepth` to stay responsive on
    /// deep trees.
    public static func build(at url: URL, maxDepth: Int = 12) -> FileTreeNode {
        FileTreeNode(url: url, isDirectory: true, children: childNodes(of: url, depth: maxDepth))
    }

    private static func childNodes(of directory: URL, depth: Int) -> [FileTreeNode] {
        guard depth > 0 else { return [] }
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]) else { return [] }

        var nodes: [FileTreeNode] = []
        for entry in entries {
            let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir {
                nodes.append(FileTreeNode(
                    url: entry, isDirectory: true,
                    children: childNodes(of: entry, depth: depth - 1)))
            } else if FileService.isMarkdown(entry) {
                nodes.append(FileTreeNode(url: entry, isDirectory: false))
            }
        }
        return nodes.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
