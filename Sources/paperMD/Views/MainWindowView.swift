import SwiftUI
import AppKit
import paperMDCore

/// The main window. Edits the workspace's active document; sidebar, tabs,
/// preview, and outline are layered on in later tasks.
struct MainWindowView: View {
    @State private var workspace = WorkspaceViewModel()
    @AppStorage("editorMode") private var mode: EditorMode = .edit
    @AppStorage("previewDebounceMs") private var previewDebounceMs: Int = 200
    @State private var wordWrap = true
    @StateObject private var editorController = EditorController()

    var body: some View {
        Group {
            if let doc = workspace.active {
                content(for: doc).id(doc.id)
            } else {
                emptyState
            }
        }
        .frame(minWidth: 500, minHeight: 360)
        .toolbar { toolbarContent }
        .dropDestination(for: URL.self) { urls, _ in
            handleDrop(urls); return true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            workspace.saveAll()
        }
        .background {
            // Invisible buttons providing ⌘1/⌘2/⌘3 mode shortcuts.
            Group {
                Button("") { mode = .edit }.keyboardShortcut("1", modifiers: .command)
                Button("") { mode = .split }.keyboardShortcut("2", modifiers: .command)
                Button("") { mode = .preview }.keyboardShortcut("3", modifiers: .command)
            }
            .opacity(0)
        }
    }

    @ViewBuilder
    private func content(for doc: DocumentViewModel) -> some View {
        switch mode {
        case .edit:
            editor(doc)
        case .preview:
            preview(doc)
        case .split:
            HSplitView {
                editor(doc)
                preview(doc)
            }
        }
    }

    private func editor(_ doc: DocumentViewModel) -> some View {
        EditorView(
            text: documentBinding(doc),
            palette: .system(),
            wordWrap: wordWrap,
            controller: editorController,
            onCursorChange: { doc.cursorOffset = $0 }
        )
        .frame(minWidth: 240)
    }

    private func preview(_ doc: DocumentViewModel) -> some View {
        PreviewView(
            text: doc.text,
            baseDirectory: doc.url?.deletingLastPathComponent(),
            debounceMs: previewDebounceMs
        )
        .frame(minWidth: 240)
    }

    private func documentBinding(_ doc: DocumentViewModel) -> Binding<String> {
        Binding(get: { doc.text }, set: { doc.text = $0 })
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No document open").font(.title3).foregroundStyle(.secondary)
            HStack {
                Button("Open File…") { workspace.showOpenFileDialog() }
                Button("Open Folder…") { workspace.showOpenFolderDialog() }
                Button("New") { workspace.newUntitled() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { workspace.showOpenFileDialog() } label: {
                Image(systemName: "doc.badge.plus")
            }
            .help("Open file")
            Button { workspace.showOpenFolderDialog() } label: {
                Image(systemName: "folder.badge.plus")
            }
            .help("Open folder")
        }
        ToolbarItemGroup(placement: .principal) {
            Picker("Mode", selection: $mode) {
                Image(systemName: "square.and.pencil").tag(EditorMode.edit)
                Image(systemName: "rectangle.split.2x1").tag(EditorMode.split)
                Image(systemName: "doc.richtext").tag(EditorMode.preview)
            }
            .pickerStyle(.segmented)
            .help("Edit / Split / Preview  (⌘1 / ⌘2 / ⌘3)")
        }
        ToolbarItem {
            Toggle(isOn: $wordWrap) { Image(systemName: "text.word.spacing") }
                .help("Word wrap")
        }
    }

    private func handleDrop(_ urls: [URL]) {
        for url in urls {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            if isDir.boolValue { workspace.openFolder(url) }
            else if FileService.isMarkdown(url) { workspace.open(url) }
        }
    }
}
