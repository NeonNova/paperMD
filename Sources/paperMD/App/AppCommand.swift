import Foundation

/// Every user action that can be triggered from the menu bar, the command
/// palette, or a keyboard shortcut. Routing them all through one enum keeps a
/// single source of truth (no duplicate-shortcut conflicts) — the main window
/// subscribes to the bus and performs the work.
enum AppCommand: String, CaseIterable, Identifiable {
    case openFile, openFolder, newFile, newTab, closeTab
    case toggleSidebar, toggleOutline
    case editMode, previewMode, splitMode
    case find, findReplace, goToLine
    case increaseFontSize, decreaseFontSize
    case switchTheme, openSettings, commandPalette

    var id: String { rawValue }

    /// Title shown in the command palette.
    var title: String {
        switch self {
        case .openFile: return "Open File…"
        case .openFolder: return "Open Folder…"
        case .newFile: return "New File"
        case .newTab: return "New Tab"
        case .closeTab: return "Close Tab"
        case .toggleSidebar: return "Toggle Sidebar"
        case .toggleOutline: return "Toggle Outline"
        case .editMode: return "Edit Mode"
        case .previewMode: return "Preview Mode"
        case .splitMode: return "Split Mode"
        case .find: return "Search"
        case .findReplace: return "Find and Replace"
        case .goToLine: return "Go To Line"
        case .increaseFontSize: return "Increase Font Size"
        case .decreaseFontSize: return "Decrease Font Size"
        case .switchTheme: return "Switch Theme"
        case .openSettings: return "Open Settings"
        case .commandPalette: return "Command Palette"
        }
    }

    /// Human-readable shortcut hint shown in the palette (display only).
    var shortcutHint: String? {
        switch self {
        case .openFile: return "⌘O"
        case .openFolder: return "⇧⌘O"
        case .newTab: return "⌘T"
        case .closeTab: return "⌘W"
        case .toggleSidebar: return "⇧⌘E"
        case .toggleOutline: return "⇧⌘U"
        case .editMode: return "⌘1"
        case .splitMode: return "⌘2"
        case .previewMode: return "⌘3"
        case .find: return "⌘F"
        case .findReplace: return "⌥⌘F"
        case .goToLine: return "⌘L"
        case .increaseFontSize: return "⌘+"
        case .decreaseFontSize: return "⌘-"
        case .openSettings: return "⌘,"
        case .commandPalette: return "⇧⌘P"
        default: return nil
        }
    }

    /// Commands offered in the palette (excludes the palette itself).
    static var paletteCommands: [AppCommand] {
        allCases.filter { $0 != .commandPalette }
    }
}

extension Notification.Name {
    static let appCommand = Notification.Name("paperMD.appCommand")
}

/// Posts a command onto the shared bus.
func post(_ command: AppCommand) {
    NotificationCenter.default.post(name: .appCommand, object: command)
}
