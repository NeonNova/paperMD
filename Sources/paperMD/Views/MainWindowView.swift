import SwiftUI
import AppKit
import paperMDCore

/// The main window: sidebar (file tree) · tabbed content (editor/preview/split)
/// · outline inspector.
struct MainWindowView: View {
    @State private var workspace = WorkspaceViewModel()
    @State private var theme = ThemeManager.shared
    @AppStorage("editorMode") private var mode: EditorMode = .edit
    @AppStorage("previewDebounceMs") private var previewDebounceMs: Int = 200
    @AppStorage("showOutline") private var showOutline = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var wordWrap = true
    @State private var didRestore = false
    @State private var showPalette = false
    @State private var showGoToLine = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var showFirstLaunch = false
    @StateObject private var editorController = EditorController()
    @StateObject private var previewController = PreviewController()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FileTreeView(workspace: workspace)
                .navigationSplitViewColumnWidth(min: 180, ideal: 240, max: 400)
        } detail: {
            detailPane
        }
        .toolbar { toolbarContent }
        .dropDestination(for: URL.self) { urls, _ in handleDrop(urls); return true }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            workspace.saveAll()
        }
        .tint(theme.accent)
        .overlay(alignment: .top) { paletteOverlay }
        .sheet(isPresented: $showGoToLine) {
            GoToLineSheet(isPresented: $showGoToLine) { editorController.goToLine($0) }
        }
        .sheet(isPresented: $showFirstLaunch) {
            FirstLaunchView(isPresented: $showFirstLaunch)
        }
        .onReceive(NotificationCenter.default.publisher(for: .appCommand)) { note in
            if let command = note.object as? AppCommand { handle(command) }
        }
        .onAppear {
            theme.applyAppearance()
            if !didRestore {
                didRestore = true
                workspace.restoreOnLaunch()
                if !hasLaunchedBefore {
                    hasLaunchedBefore = true
                    showFirstLaunch = true
                }
            }
        }
    }

    @ViewBuilder
    private var paletteOverlay: some View {
        if showPalette {
            ZStack(alignment: .top) {
                Color.black.opacity(0.001)
                    .onTapGesture { showPalette = false }
                CommandPaletteView(isPresented: $showPalette) { handle($0) }
                    .padding(.top, 60)
            }
        }
    }

    /// Central dispatch for every command (menu bar, palette, shortcut).
    private func handle(_ command: AppCommand) {
        switch command {
        case .openFile: workspace.showOpenFileDialog()
        case .openFolder: workspace.showOpenFolderDialog()
        case .newFile, .newTab: workspace.newUntitled()
        case .closeTab: workspace.closeActiveTab()
        case .toggleSidebar:
            withAnimation { columnVisibility = columnVisibility == .all ? .detailOnly : .all }
        case .toggleOutline: showOutline.toggle()
        case .editMode: mode = .edit
        case .previewMode: mode = .preview
        case .splitMode: mode = .split
        case .find: editorController.showFind(replace: false)
        case .findReplace: editorController.showFind(replace: true)
        case .goToLine: showGoToLine = true
        case .increaseFontSize: theme.adjustBodySize(by: 1)
        case .decreaseFontSize: theme.adjustBodySize(by: -1)
        case .switchTheme: cycleTheme()
        case .openSettings: openSettingsWindow()
        case .commandPalette: showPalette.toggle()
        }
    }

    private func cycleTheme() {
        let names = theme.themes.map(\.name)
        guard let i = names.firstIndex(of: theme.themeName) else { return }
        theme.themeName = names[(i + 1) % names.count]
    }

    private func openSettingsWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    // MARK: Detail pane

    @ViewBuilder
    private var detailPane: some View {
        VStack(spacing: 0) {
            if !workspace.documents.isEmpty {
                TabBarView(workspace: workspace)
                Divider()
            }
            HStack(spacing: 0) {
                Group {
                    if let doc = workspace.active {
                        content(for: doc).id(doc.id)
                    } else {
                        emptyState
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showOutline, let doc = workspace.active {
                    Divider()
                    OutlineView(text: doc.text) { item, headingIndex in
                        editorController.goToLine(item.line + 1)
                        previewController.scrollToHeading(headingIndex)
                    }
                    .frame(width: 220)
                }
            }
        }
    }

    @ViewBuilder
    private func content(for doc: DocumentViewModel) -> some View {
        switch mode {
        case .edit:    editor(doc)
        case .preview: preview(doc)
        case .split:   HSplitView { editor(doc); preview(doc) }
        }
    }

    private func editor(_ doc: DocumentViewModel) -> some View {
        EditorView(
            text: documentBinding(doc),
            palette: theme.palette,
            wordWrap: wordWrap,
            controller: editorController,
            initialCursorOffset: doc.cursorOffset,
            onCursorChange: { doc.cursorOffset = $0 }
        )
        .frame(minWidth: 240)
    }

    private func preview(_ doc: DocumentViewModel) -> some View {
        PreviewView(
            text: doc.text,
            baseDirectory: doc.url?.deletingLastPathComponent(),
            debounceMs: previewDebounceMs,
            themeVars: theme.cssVars,
            controller: previewController
        )
        .frame(minWidth: 240)
    }

    private func documentBinding(_ doc: DocumentViewModel) -> Binding<String> {
        Binding(get: { doc.text }, set: { doc.text = $0 })
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text").font(.system(size: 48)).foregroundStyle(.tertiary)
            Text("No document open").font(.title3).foregroundStyle(.secondary)
            HStack {
                Button("Open File…") { workspace.showOpenFileDialog() }
                Button("Open Folder…") { workspace.showOpenFolderDialog() }
                Button("New") { workspace.newUntitled() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { workspace.showOpenFileDialog() } label: { Image(systemName: "doc.badge.plus") }
                .help("Open file")
            Button { workspace.showOpenFolderDialog() } label: { Image(systemName: "folder.badge.plus") }
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
        ToolbarItemGroup {
            Toggle(isOn: $wordWrap) { Image(systemName: "text.word.spacing") }
                .help("Word wrap")
            Toggle(isOn: $showOutline) { Image(systemName: "list.bullet.indent") }
                .help("Toggle outline (⌘⇧U)")
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
