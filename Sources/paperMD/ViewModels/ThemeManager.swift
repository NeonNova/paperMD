import SwiftUI
import AppKit
import Observation
import paperMDCore

enum AppearanceMode: String, CaseIterable {
    case system, light, dark
    var label: String { rawValue.capitalized }
}

/// Central theme + typography state, shared between the main window and the
/// Settings scene. Persists choices to UserDefaults and applies the matching
/// `NSAppearance` to the whole app.
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private(set) var themes: [Theme]
    var themeName: String { didSet { defaults.set(themeName, forKey: "themeName"); applyAppearance() } }
    var appearanceMode: AppearanceMode { didSet { defaults.set(appearanceMode.rawValue, forKey: "appearanceMode"); applyAppearance() } }

    var interfaceFontName: String { didSet { defaults.set(interfaceFontName, forKey: "interfaceFontName") } }
    var interfaceSize: Double { didSet { defaults.set(interfaceSize, forKey: "interfaceSize") } }
    var bodyFontName: String { didSet { defaults.set(bodyFontName, forKey: "bodyFontName") } }
    var bodySize: Double { didSet { defaults.set(bodySize, forKey: "bodySize") } }
    var codeFontName: String { didSet { defaults.set(codeFontName, forKey: "codeFontName") } }
    var codeSize: Double { didSet { defaults.set(codeSize, forKey: "codeSize") } }

    private let defaults = UserDefaults.standard

    private init() {
        themes = ThemeLoader.allThemes()
        themeName = defaults.string(forKey: "themeName") ?? "System Light"
        appearanceMode = AppearanceMode(rawValue: defaults.string(forKey: "appearanceMode") ?? "system") ?? .system
        interfaceFontName = defaults.string(forKey: "interfaceFontName") ?? ""
        interfaceSize = defaults.object(forKey: "interfaceSize") as? Double ?? 13
        bodyFontName = defaults.string(forKey: "bodyFontName") ?? ""
        bodySize = defaults.object(forKey: "bodySize") as? Double ?? 15
        codeFontName = defaults.string(forKey: "codeFontName") ?? ""
        codeSize = defaults.object(forKey: "codeSize") as? Double ?? 13
    }

    // MARK: Derived

    var current: Theme {
        themes.first { $0.name == themeName } ?? themes.first
            ?? Theme(name: "System Light",
                     colors: .init(background: "#FFFFFF", surface: "#ECECEC",
                                   text: "#1D1D1F", muted: "#86868B", accent: "#0A84FF"))
    }

    var typography: Typography {
        Typography(interfaceFontName: interfaceFontName, interfaceSize: interfaceSize,
                   bodyFontName: bodyFontName, bodySize: bodySize,
                   codeFontName: codeFontName, codeSize: codeSize)
    }

    var palette: HighlightPalette { current.palette(typography: typography) }
    var cssVars: [String: String] { current.cssVars(typography: typography) }
    var accent: Color { Color(current.accentColor) }

    /// SwiftUI font for app chrome (sidebar, tabs, controls).
    var interfaceFont: Font {
        interfaceFontName.isEmpty
            ? .system(size: interfaceSize)
            : .custom(interfaceFontName, size: interfaceSize)
    }

    // MARK: Actions

    func reloadThemes() {
        themes = ThemeLoader.allThemes()
    }

    func importTheme(from url: URL) {
        do {
            let theme = try ThemeLoader.importTheme(from: url)
            reloadThemes()
            themeName = theme.name
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func exportCurrent(to url: URL) {
        try? ThemeLoader.export(current, to: url)
    }

    func adjustBodySize(by delta: Double) {
        bodySize = min(24, max(11, bodySize + delta))
    }

    /// Applies the appearance to the whole app (chrome, menus, panels). In
    /// `system` mode the appearance follows the *theme's* darkness so chrome
    /// text stays legible against themed backgrounds (a light theme → light
    /// chrome, Nord/Dracula → dark chrome). Explicit light/dark override that.
    func applyAppearance() {
        let named: NSAppearance.Name
        switch appearanceMode {
        case .system: named = current.isDark ? .darkAqua : .aqua
        case .light:  named = .aqua
        case .dark:   named = .darkAqua
        }
        NSApp.appearance = NSAppearance(named: named)
    }
}
