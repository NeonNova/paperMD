import Foundation

/// Persisted snapshot of the workspace, restored on the next launch.
public struct Session: Codable, Equatable, Sendable {
    /// Absolute path of the open folder, if any.
    public var folderPath: String?
    /// Absolute paths of open document tabs, left to right.
    public var openFiles: [String]
    /// Index into `openFiles` of the active tab.
    public var activeIndex: Int
    /// Last-used editor mode.
    public var mode: EditorMode
    /// Per-file caret offset (character index), keyed by absolute path.
    public var cursors: [String: Int]

    public init(folderPath: String? = nil,
                openFiles: [String] = [],
                activeIndex: Int = 0,
                mode: EditorMode = .edit,
                cursors: [String: Int] = [:]) {
        self.folderPath = folderPath
        self.openFiles = openFiles
        self.activeIndex = activeIndex
        self.mode = mode
        self.cursors = cursors
    }
}
