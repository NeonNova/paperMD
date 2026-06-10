import Foundation

/// Lightweight fuzzy subsequence matcher for the command palette. Returns a
/// score (higher is better) when every character of `query` appears in order
/// within `candidate`, or nil when it doesn't match.
public enum FuzzyMatcher {
    public static func score(query: String, candidate: String) -> Int? {
        if query.isEmpty { return 0 }
        let q = Array(query.lowercased())
        let c = Array(candidate.lowercased())

        var qi = 0
        var total = 0
        var previousMatchIndex = -2

        for (ci, char) in c.enumerated() where qi < q.count {
            guard char == q[qi] else { continue }
            var points = 1
            // Bonus for matching at a word boundary (start or after separator).
            if ci == 0 || isSeparator(c[ci - 1]) { points += 3 }
            // Bonus for consecutive matches.
            if ci == previousMatchIndex + 1 { points += 2 }
            total += points
            previousMatchIndex = ci
            qi += 1
        }

        return qi == q.count ? total : nil
    }

    private static func isSeparator(_ ch: Character) -> Bool {
        ch == " " || ch == "-" || ch == "_" || ch == "/" || ch == "."
    }
}
