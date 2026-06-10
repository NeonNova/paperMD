import Foundation

/// A single heading in a document's outline.
public struct OutlineItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    /// Heading text with markdown markers stripped.
    public let title: String
    /// Heading depth, 1...6.
    public let level: Int
    /// Zero-based line number of the heading in the source.
    public let line: Int

    public init(id: UUID = UUID(), title: String, level: Int, line: Int) {
        self.id = id
        self.title = title
        self.level = level
        self.line = line
    }

    /// Equality ignores `id` so two parses of the same document compare equal.
    public static func == (lhs: OutlineItem, rhs: OutlineItem) -> Bool {
        lhs.title == rhs.title && lhs.level == rhs.level && lhs.line == rhs.line
    }
}
