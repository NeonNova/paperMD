import Foundation

/// Loads built-in and user theme packs, and imports/exports theme JSON.
/// Invalid files are skipped rather than crashing the app.
public enum ThemeLoader {
    /// Built-in themes shipped in the bundle, in display order.
    public static func builtInThemes() -> [Theme] {
        let bundle = Bundle.module
        let order = ["system-light", "system-dark", "github-light", "github-dark",
                     "nord", "dracula", "solarized-light", "solarized-dark"]
        return order.compactMap { name in
            guard let url = bundle.url(forResource: name, withExtension: "json",
                                       subdirectory: "Resources/Themes")
                ?? bundle.url(forResource: name, withExtension: "json", subdirectory: "Themes")
                ?? bundle.url(forResource: name, withExtension: "json") else { return nil }
            return decode(url)
        }
    }

    /// User-imported themes from Application Support.
    public static func userThemes(directory: URL = AppPaths.themesDir) -> [Theme] {
        let entries = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil)) ?? []
        return entries
            .filter { $0.pathExtension.lowercased() == "json" }
            .compactMap(decode)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// All available themes (built-ins first, then user themes), de-duplicated
    /// by name (built-ins win).
    public static func allThemes() -> [Theme] {
        var seen = Set<String>()
        var result: [Theme] = []
        for theme in builtInThemes() + userThemes() where seen.insert(theme.name).inserted {
            result.append(theme)
        }
        return result
    }

    /// Decodes a theme file, returning nil on malformed JSON.
    public static func decode(_ url: URL) -> Theme? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Theme.self, from: data)
    }

    /// Validates and copies an imported theme file into the user themes folder.
    /// Returns the imported theme, or throws if the JSON is invalid.
    @discardableResult
    public static func importTheme(from url: URL,
                                   into directory: URL = AppPaths.themesDir) throws -> Theme {
        guard let theme = decode(url) else {
            throw FileError.operationFailed("Import theme", DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Not a valid paperMD theme JSON.")))
        }
        let dest = directory.appendingPathComponent(
            theme.name.replacingOccurrences(of: "/", with: "-") + ".json")
        let data = try JSONEncoder.pretty.encode(theme)
        try data.write(to: dest, options: .atomic)
        return theme
    }

    /// Writes a theme as pretty-printed JSON to `url` (export).
    public static func export(_ theme: Theme, to url: URL) throws {
        let data = try JSONEncoder.pretty.encode(theme)
        try data.write(to: url, options: .atomic)
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}
