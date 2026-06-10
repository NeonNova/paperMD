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
    @AppStorage("fullWidth") private var fullWidth = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var wordWrap = true
    @State private var didRestore = false
    @State private var zoomHovering = false
    @State private var zoomActive = false
    @State private var showPalette = false
    @State private var showGoToLine = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var showFirstLaunch = false
    @StateObject private var editorController = EditorController()
    @StateObject private var previewController = PreviewController()

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                FileTreeView(workspace: workspace, theme: theme)
                    .navigationSplitViewColumnWidth(min: 180, ideal: 240, max: 400)
            } detail: {
                detailPane
                    .background(Color(theme.current.backgroundColor))
            }
            .toolbar { toolbarContent }
            .dropDestination(for: URL.self) { urls, _ in handleDrop(urls); return true }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
                workspace.saveAll()
            }

            // Command palette lives at the window root (not as a NavigationSplitView
            // overlay, which doesn't reliably cover the whole window).
            if showPalette {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture { showPalette = false }
                CommandPaletteView(isPresented: $showPalette) { handle($0) }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 80)
                    .transition(.opacity)
            }
        }
        .tint(theme.accent)
        .font(theme.interfaceFont)
        .background(WindowThemer(background: theme.current.backgroundColor))
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
        case .toggleFullWidth: fullWidth.toggle()
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
                TabBarView(workspace: workspace, theme: theme)
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
            .overlay(alignment: .bottomTrailing) {
                if workspace.active != nil { zoomControl }
            }
        }
    }

    /// Non-invasive floating zoom control (bottom-right). Normally just a faint
    /// icon; the slider and size reveal on hover, and the value shows while
    /// dragging — like the zoom affordance in native Mac apps.
    private var zoomControl: some View {
        HStack(spacing: 6) {
            if zoomActive {
                Text("\(Int(theme.bodySize)) pt")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            if zoomHovering || zoomActive {
                Slider(value: Binding(get: { theme.bodySize },
                                      set: { theme.bodySize = $0.rounded() }),
                       in: 11...30) { editing in zoomActive = editing }
                    .frame(width: 90)
                    .controlSize(.mini)
            }
            Image(systemName: "textformat.size")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .glassEffect(.regular, in: .capsule)
        .opacity(zoomHovering || zoomActive ? 1 : 0.45)
        .padding(8)
        .onHover { zoomHovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: zoomHovering)
        .animation(.easeInOut(duration: 0.15), value: zoomActive)
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
            themeVars: theme.cssVars.merging(
                ["content-width": fullWidth ? "100%" : "820px"]) { _, new in new },
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
            .disabled(hasNoDocument)
        }
        ToolbarItemGroup {
            activeButton("text.word.spacing", on: wordWrap, help: "Word wrap") { wordWrap.toggle() }
            activeButton("list.bullet.indent", on: showOutline, help: "Toggle outline (⇧⌘U)") { showOutline.toggle() }
            activeButton("arrow.left.and.right", on: fullWidth, help: "Full width (⌃⌘F)") { fullWidth.toggle() }
        }
    }

    private var hasNoDocument: Bool { workspace.active == nil }

    /// Toolbar button that shows an accent tint when active and greys out when no
    /// document is open — consistent across all three (no Toggle "pressed" look).
    private func activeButton(_ symbol: String, on: Bool, help: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(on ? AnyShapeStyle(theme.accent) : AnyShapeStyle(.secondary))
        }
        .help(help)
        .disabled(hasNoDocument)
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
