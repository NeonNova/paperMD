import Foundation
import AppKit

/// Disk operations for documents and the folder tree. Pure of UI; throws
/// `FileError` on failure so callers can surface a native alert.
public enum FileError: LocalizedError {
    case readFailed(URL, Error)
    case writeFailed(URL, Error)
    case alreadyExists(URL)
    case operationFailed(String, Error)

    public var errorDescription: String? {
        switch self {
        case .readFailed(let url, let e):  return "Couldn't open “\(url.lastPathComponent)”: \(e.localizedDescription)"
        case .writeFailed(let url, let e): return "Couldn't save “\(url.lastPathComponent)”: \(e.localizedDescription)"
        case .alreadyExists(let url):      return "“\(url.lastPathComponent)” already exists."
        case .operationFailed(let what, let e): return "\(what) failed: \(e.localizedDescription)"
        }
    }
}

public enum FileService {
    /// Markdown extensions paperMD recognises.
    public static let markdownExtensions: Set<String> = ["md", "markdown"]

    public static func isMarkdown(_ url: URL) -> Bool {
        markdownExtensions.contains(url.pathExtension.lowercased())
    }

    public static func read(_ url: URL) throws -> String {
        do { return try String(contentsOf: url, encoding: .utf8) }
        catch {
            // Fall back to lossy decoding so odd encodings still open.
            if let data = try? Data(contentsOf: url) {
                return String(decoding: data, as: UTF8.self)
            }
            throw FileError.readFailed(url, error)
        }
    }

    /// Writes atomically (temp file + rename) so a crash mid-write can't corrupt
    /// the original.
    public static func write(_ text: String, to url: URL) throws {
        do { try text.write(to: url, atomically: true, encoding: .utf8) }
        catch { throw FileError.writeFailed(url, error) }
    }

    /// Creates an empty file `name` inside `directory`, returning its URL.
    @discardableResult
    public static func create(name: String, in directory: URL) throws -> URL {
        let url = directory.appendingPathComponent(name)
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw FileError.alreadyExists(url)
        }
        do { try "".write(to: url, atomically: true, encoding: .utf8); return url }
        catch { throw FileError.operationFailed("Create file", error) }
    }

    @discardableResult
    public static func createFolder(name: String, in directory: URL) throws -> URL {
        let url = directory.appendingPathComponent(name, isDirectory: true)
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw FileError.alreadyExists(url)
        }
        do { try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false); return url }
        catch { throw FileError.operationFailed("Create folder", error) }
    }

    /// Renames an item, returning its new URL.
    @discardableResult
    public static func rename(_ url: URL, to newName: String) throws -> URL {
        let dest = url.deletingLastPathComponent().appendingPathComponent(newName)
        guard !FileManager.default.fileExists(atPath: dest.path) else {
            throw FileError.alreadyExists(dest)
        }
        do { try FileManager.default.moveItem(at: url, to: dest); return dest }
        catch { throw FileError.operationFailed("Rename", error) }
    }

    /// Moves an item to the Trash (safer than deleting outright).
    public static func trash(_ url: URL) throws {
        do { try FileManager.default.trashItem(at: url, resultingItemURL: nil) }
        catch { throw FileError.operationFailed("Move to Trash", error) }
    }

    public static func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    public static func modificationDate(of url: URL) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }
}
