import Foundation

/// Extracts an outline of ATX headings (`#`...`######`) from markdown source.
///
/// Headings inside fenced code blocks (``` ``` ``` or `~~~`) are ignored, as
/// are lines with seven or more hashes or no space after the hashes.
public enum OutlineParser {
    public static func parse(_ markdown: String) -> [OutlineItem] {
        var items: [OutlineItem] = []
        var inFence = false
        var fenceMarker: Character = "`"

        let lines = markdown.components(separatedBy: "\n")
        for (index, rawLine) in lines.enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            // Toggle fenced-code state on ``` or ~~~ openers/closers.
            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                let marker = line.first!
                if !inFence {
                    inFence = true
                    fenceMarker = marker
                } else if marker == fenceMarker {
                    inFence = false
                }
                continue
            }
            if inFence { continue }

            guard let item = heading(from: line, at: index) else { continue }
            items.append(item)
        }
        return items
    }

    private static func heading(from line: String, at lineNumber: Int) -> OutlineItem? {
        guard line.hasPrefix("#") else { return nil }

        var level = 0
        var rest = Substring(line)
        while rest.first == "#" {
            level += 1
            rest = rest.dropFirst()
        }
        // Must be 1...6 hashes followed by at least one space.
        guard (1...6).contains(level), rest.first == " " else { return nil }

        var title = rest.trimmingCharacters(in: .whitespaces)
        // Strip optional closing hashes ("## Hello ##").
        while title.hasSuffix("#") { title.removeLast() }
        title = title.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return nil }

        return OutlineItem(title: title, level: level, line: lineNumber)
    }
}
