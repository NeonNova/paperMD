import SwiftUI
import paperMDCore

@main
struct PaperMDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowToolbarStyle(.unified)
        .commands { menuCommands }

        Settings {
            SettingsView()
        }
    }

    @CommandsBuilder
    private var menuCommands: some Commands {
        // File
        CommandGroup(replacing: .newItem) {
            Button("New File") { post(.newFile) }.keyboardShortcut("n")
            Button("New Tab") { post(.newTab) }.keyboardShortcut("t")
            Divider()
            Button("Open File…") { post(.openFile) }.keyboardShortcut("o")
            Button("Open Folder…") { post(.openFolder) }.keyboardShortcut("o", modifiers: [.command, .shift])
            Divider()
            Button("Close Tab") { post(.closeTab) }.keyboardShortcut("w")
        }
        // Edit — find/replace/go-to-line
        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Find…") { post(.find) }.keyboardShortcut("f")
            Button("Find and Replace…") { post(.findReplace) }.keyboardShortcut("f", modifiers: [.command, .option])
            Button("Go to Line…") { post(.goToLine) }.keyboardShortcut("l")
        }
        // View — modes, panels, fonts, palette
        CommandGroup(after: .toolbar) {
            Button("Edit Mode") { post(.editMode) }.keyboardShortcut("1")
            Button("Split Mode") { post(.splitMode) }.keyboardShortcut("2")
            Button("Preview Mode") { post(.previewMode) }.keyboardShortcut("3")
            Divider()
            Button("Toggle Sidebar") { post(.toggleSidebar) }.keyboardShortcut("e", modifiers: [.command, .shift])
            Button("Toggle Outline") { post(.toggleOutline) }.keyboardShortcut("u", modifiers: [.command, .shift])
            Button("Toggle Full Width") { post(.toggleFullWidth) }.keyboardShortcut("f", modifiers: [.command, .control])
            Divider()
            Button("Increase Font Size") { post(.increaseFontSize) }.keyboardShortcut("+")
            Button("Decrease Font Size") { post(.decreaseFontSize) }.keyboardShortcut("-")
            Divider()
            Button("Command Palette") { post(.commandPalette) }.keyboardShortcut("p", modifiers: [.command, .shift])
            Button("Switch Theme") { post(.switchTheme) }
        }
    }
}
