import Foundation

/// The three ways the main content area can present a document.
public enum EditorMode: String, Codable, CaseIterable, Sendable {
    case edit
    case preview
    case split
}
