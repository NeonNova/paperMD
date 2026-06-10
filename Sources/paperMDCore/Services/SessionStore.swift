import Foundation

/// Persists and restores the workspace `Session` as JSON. Saves are debounced so
/// frequent state changes (typing moves the cursor) don't thrash the disk.
public final class SessionStore {
    private let fileURL: URL
    private var saveWork: DispatchWorkItem?

    /// Defaults to the standard Application Support location; tests inject a
    /// temporary file.
    public init(fileURL: URL = AppPaths.sessionFile) {
        self.fileURL = fileURL
    }

    /// Writes immediately (used on quit). Returns false if encoding/writing fails.
    @discardableResult
    public func saveNow(_ session: Session) -> Bool {
        guard let data = try? JSONEncoder().encode(session) else { return false }
        do { try data.write(to: fileURL, options: .atomic); return true }
        catch { return false }
    }

    /// Debounced save (used during normal interaction).
    public func save(_ session: Session, after delay: TimeInterval = 2.0) {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in _ = self?.saveNow(session) }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    /// Loads the saved session, or nil if none exists / is unreadable.
    public func load() -> Session? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Session.self, from: data)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

/// Crash-recovery journal: lists orphaned unsaved buffers left by a hard crash.
public enum JournalStore {
    /// URLs of journal files currently present (each holds one unsaved buffer).
    public static func recoverableFiles() -> [URL] {
        let dir = AppPaths.journalDir
        let entries = (try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil)) ?? []
        return entries.filter { FileService.isMarkdown($0) }
    }

    /// Removes all journal files (called after a clean shutdown).
    public static func clearAll() {
        for url in recoverableFiles() { try? FileManager.default.removeItem(at: url) }
    }
}
