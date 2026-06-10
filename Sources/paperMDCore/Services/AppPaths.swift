import Foundation

/// Canonical on-disk locations under Application Support, created on demand.
public enum AppPaths {
    public static let appName = "paperMD"

    public static var supportDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return ensure(base.appendingPathComponent(appName, isDirectory: true))
    }

    /// Unsaved-buffer journals for crash recovery.
    public static var journalDir: URL {
        ensure(supportDir.appendingPathComponent("Journal", isDirectory: true))
    }

    /// User-imported theme packs.
    public static var themesDir: URL {
        ensure(supportDir.appendingPathComponent("Themes", isDirectory: true))
    }

    /// Restored-session state.
    public static var sessionFile: URL {
        supportDir.appendingPathComponent("session.json")
    }

    @discardableResult
    private static func ensure(_ url: URL) -> URL {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
}
