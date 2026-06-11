import SwiftUI
import paperMDCore

@main
struct PaperMDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // One window per document; macOS groups them into native tabs.
        WindowGroup(for: DocumentRef.self) { $ref in
            DocumentWindowView(ref: ref)
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
        CommandGroup(replacing: .newItem) {
            Button("New") { post(.newFile) }.keyboardShortcut("n")
            Button("New Window") { post(.newTab) }.keyboardShortcut("t")
            Divider()
            Button("Open File…") { post(.openFile) }.keyboardShortcut("o")
            Button("Open Folder…") { post(.openFolder) }.keyboardShortcut("o", modifiers: [.command, .shift])
            Divider()
            Button("Close Window") { post(.closeTab) }.keyboardShortcut("w")
        }
        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Find…") { post(.find) }.keyboardShortcut("f")
            Button("Find and Replace…") { post(.findReplace) }.keyboardShortcut("f", modifiers: [.command, .option])
            Button("Go to Line…") { post(.goToLine) }.keyboardShortcut("l")
        }
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
