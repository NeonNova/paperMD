import SwiftUI
import AppKit
import paperMDCore

/// One window = one document. The folder sidebar (shared via AppModel) sits on
/// the left; the editor/preview/outline on the right. Opening a file spawns a
/// new window, which macOS groups into native tabs. Window-level commands act
/// only when this is the key window.
struct DocumentWindowView: View {
    let ref: DocumentRef?

    @State private var appModel = AppModel.shared
    @State private var theme = ThemeManager.shared
    @State private var document: DocumentViewModel?
    @State private var window: NSWindow?

    @State private var mode: EditorMode = EditorMode(
        rawValue: UserDefaults.standard.string(forKey: "editorMode") ?? "edit") ?? .edit
    @AppStorage("sidebarVisible") private var sidebarVisible = true
    @AppStorage("showOutline") private var showOutline = false
    @AppStorage("fullWidth") private var fullWidth = false
    @AppStorage("previewDebounceMs") private var previewDebounceMs = 200
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var wordWrap = true
    @State private var showPalette = false
    @State private var showGoToLine = false
    @State private var zoomHovering = false
    @State private var zoomActive = false

    @StateObject private var editorController = EditorController()
    @StateObject private var previewController = PreviewController()
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                FileTreeView(appModel: appModel, theme: theme) { url in
                    openWindow(value: DocumentRef.file(url))
                }
                .navigationSplitViewColumnWidth(min: 180, ideal: 240, max: 400)
            } detail: {
                detailPane
                    .background(Color(theme.current.backgroundColor))
            }
            .toolbar { toolbarContent }

            if showPalette {
                Color.black.opacity(0.15).ignoresSafeArea().onTapGesture { showPalette = false }
                CommandPaletteView(isPresented: $showPalette) { handle($0) }
                    .frame(maxHeight: .infinity, alignment: .top).padding(.top, 80)
            }
        }
        .tint(theme.accent)
        .font(theme.interfaceFont)
        .navigationTitle(document?.displayName ?? "paperMD")
        .background(HostingWindowFinder { window = $0 })
        .sheet(isPresented: $showGoToLine) {
            GoToLineSheet(isPresented: $showGoToLine) { editorController.goToLine($0) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appCommand)) { note in
            guard window?.isKeyWindow == true, let command = note.object as? AppCommand else { return }
            handle(command)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            document?.autosave()
        }
        .onChange(of: columnVisibility) { sidebarVisible = columnVisibility != .detailOnly }
        .onChange(of: appModel.pendingOpens) { if !appModel.pendingOpens.isEmpty { drainPendingOpens() } }
        .task(id: refKey) { loadDocument() }
        .onAppear {
            theme.applyAppearance()
            columnVisibility = sidebarVisible ? .all : .detailOnly
            drainPendingOpens()
        }
    }

    private var refKey: String {
        switch ref {
        case .file(let url): return "file:\(url.path)"
        case .untitled(let id): return "untitled:\(id)"
        case .none: return "none"
        }
    }

    private func loadDocument() {
        guard document == nil else { return }
        switch ref {
        case .file(let url):
            document = (try? DocumentViewModel.open(url)) ?? DocumentViewModel(url: url)
        case .untitled, .none:
            document = DocumentViewModel(url: nil)
        }
    }

    /// Opens any files Finder/launch handed us, and closes this window if it's
    /// the stray empty default window created at launch (so opening a file
    /// doesn't leave an extra blank untitled window behind).
    private func drainPendingOpens() {
        let urls = appModel.drainPendingOpens()
        guard !urls.isEmpty else { return }
        for url in urls { openWindow(value: DocumentRef.file(url)) }
        if ref == nil, document?.url == nil, document?.isDirty == false {
            DispatchQueue.main.async { window?.performClose(nil) }
        }
    }

    // MARK: Detail

    @ViewBuilder
    private var detailPane: some View {
        if let doc = document {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    content(for: doc).frame(maxWidth: .infinity, maxHeight: .infinity)
                    if showOutline {
                        Divider()
                        OutlineView(text: doc.text) { item, headingIndex in
                            editorController.goToLine(item.line + 1)
                            previewController.scrollToHeading(headingIndex)
                        }
                        .frame(width: 220)
                    }
                }
                .overlay(alignment: .bottomTrailing) { zoomControl }
            }
        } else {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
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
            text: Binding(get: { doc.text }, set: { doc.text = $0 }),
            palette: theme.palette,
            wordWrap: wordWrap,
            fullWidth: fullWidth,
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
            themeVars: theme.cssVars.merging(["content-width": fullWidth ? "100%" : "820px"]) { _, n in n },
            controller: previewController
        )
        .frame(minWidth: 240)
    }

    private var zoomControl: some View {
        HStack(spacing: 6) {
            if zoomActive {
                Text("\(Int(theme.bodySize)) pt").font(.system(size: 10))
                    .foregroundStyle(.secondary).monospacedDigit()
            }
            if zoomHovering || zoomActive {
                Slider(value: Binding(get: { theme.bodySize },
                                      set: { theme.bodySize = $0.rounded() }), in: 11...30) { e in zoomActive = e }
                    .frame(width: 90).controlSize(.mini)
            }
            Image(systemName: "textformat.size").font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .glassEffect(.regular, in: .capsule)
        .opacity(zoomHovering || zoomActive ? 1 : 0.45)
        .padding(8)
        .onHover { zoomHovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: zoomHovering)
        .animation(.easeInOut(duration: 0.15), value: zoomActive)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { openFiles() } label: { Image(systemName: "doc.badge.plus") }.help("Open file")
            Button { appModel.showOpenFolderDialog() } label: { Image(systemName: "folder.badge.plus") }.help("Open folder")
        }
        ToolbarItemGroup(placement: .principal) {
            Picker("Mode", selection: $mode) {
                Image(systemName: "square.and.pencil").tag(EditorMode.edit)
                Image(systemName: "rectangle.split.2x1").tag(EditorMode.split)
                Image(systemName: "doc.richtext").tag(EditorMode.preview)
            }
            .pickerStyle(.segmented).help("Edit / Split / Preview (⌘1 / ⌘2 / ⌘3)")
        }
        ToolbarItemGroup {
            activeButton("text.word.spacing", on: wordWrap, help: "Word wrap") { wordWrap.toggle() }
            activeButton("list.bullet.indent", on: showOutline, help: "Outline (⇧⌘U)") { showOutline.toggle() }
            activeButton("arrow.left.and.right", on: fullWidth, help: "Full width (⌃⌘F)") { fullWidth.toggle() }
        }
    }

    private func activeButton(_ symbol: String, on: Bool, help: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(on ? AnyShapeStyle(theme.accent) : AnyShapeStyle(.secondary))
        }
        .help(help)
    }

    // MARK: Commands

    private func handle(_ command: AppCommand) {
        switch command {
        case .openFile: openFiles()
        case .openFolder: appModel.showOpenFolderDialog()
        case .newFile, .newTab: openWindow(value: DocumentRef.new())
        case .closeTab: window?.performClose(nil)
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
        case .openSettings: NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        case .commandPalette: showPalette.toggle()
        }
    }

    private func openFiles() {
        for url in appModel.chooseFilesToOpen() { openWindow(value: DocumentRef.file(url)) }
    }

    private func cycleTheme() {
        let names = theme.themes.map(\.name)
        guard let i = names.firstIndex(of: theme.themeName) else { return }
        theme.themeName = names[(i + 1) % names.count]
    }
}
