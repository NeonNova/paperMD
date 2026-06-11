import Foundation

/// Identifies the document a window edits. Used as the `WindowGroup(for:)` value
/// so each document gets its own window (which macOS groups into native tabs).
enum DocumentRef: Hashable, Codable {
    case file(URL)
    case untitled(UUID)

    static func new() -> DocumentRef { .untitled(UUID()) }

    var fileURL: URL? {
        if case .file(let url) = self { return url }
        return nil
    }
}
