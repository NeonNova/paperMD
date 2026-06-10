import Foundation
import Observation
import paperMDCore

/// One open document (one tab). Owns the text buffer, dirty state, caret
/// position, and autosave. Untitled buffers journal to Application Support so a
/// crash never loses work.
@Observable
final class DocumentViewModel: Identifiable {
    let id = UUID()
    private(set) var url: URL?
    var text: String {
        didSet {
            guard !isApplyingExternalChange, text != oldValue else { return }
            isDirty = true
            scheduleAutosave()
        }
    }
    private(set) var isDirty = false
    var cursorOffset = 0

    private var lastKnownModDate: Date?
    private var autosaveWork: DispatchWorkItem?
    private var isApplyingExternalChange = false
    private var journalURL: URL {
        AppPaths.journalDir.appendingPathComponent("\(id.uuidString).md")
    }

    var displayName: String { url?.lastPathComponent ?? "Untitled" }

    init(url: URL?, text: String = "") {
        self.url = url
        self.text = text
        self.lastKnownModDate = url.flatMap { FileService.modificationDate(of: $0) }
    }

    /// Opens a file from disk into a fresh document.
    static func open(_ url: URL) throws -> DocumentViewModel {
        let contents = try FileService.read(url)
        return DocumentViewModel(url: url, text: contents)
    }

    // MARK: Autosave

    private func scheduleAutosave() {
        autosaveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.autosave() }
        autosaveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    /// Persists immediately: to the real file if one exists, otherwise to the
    /// crash-recovery journal. Returns any error for the caller to surface.
    @discardableResult
    func autosave() -> Error? {
        autosaveWork?.cancel()
        guard isDirty else { return nil }
        if let url {
            do {
                try FileService.write(text, to: url)
                isDirty = false
                lastKnownModDate = FileService.modificationDate(of: url)
                removeJournal()
            } catch { return error }
        } else {
            writeJournal()
        }
        return nil
    }

    /// Assigns a destination URL (Save As…) and writes there.
    func assignURL(_ url: URL) throws {
        self.url = url
        try FileService.write(text, to: url)
        isDirty = false
        lastKnownModDate = FileService.modificationDate(of: url)
        removeJournal()
    }

    // MARK: External changes

    enum ExternalChange { case none, reloaded, conflict }

    /// Detects an on-disk change. Reloads silently when the buffer is clean;
    /// reports a conflict when the buffer has unsaved edits.
    func checkForExternalChange() -> ExternalChange {
        guard let url, let disk = FileService.modificationDate(of: url) else { return .none }
        if let known = lastKnownModDate, disk <= known { return .none }
        guard !isDirty else { return .conflict }
        if let contents = try? FileService.read(url) {
            applyExternal(contents)
            lastKnownModDate = disk
            return .reloaded
        }
        return .none
    }

    /// Marks the buffer dirty (used when reopening a recovered journal so it
    /// keeps re-journaling until the user saves it).
    func markDirty() {
        isDirty = true
        scheduleAutosave()
    }

    /// Replaces the buffer without marking it dirty (used for reloads).
    func applyExternal(_ newText: String) {
        isApplyingExternalChange = true
        text = newText
        isApplyingExternalChange = false
        isDirty = false
    }

    // MARK: Journal

    private func writeJournal() {
        try? FileService.write(text, to: journalURL)
    }
    private func removeJournal() {
        try? FileManager.default.removeItem(at: journalURL)
    }
}
