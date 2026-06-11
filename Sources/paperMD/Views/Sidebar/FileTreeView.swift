import SwiftUI
import AppKit
import paperMDCore

/// The left sidebar: a folder tree with create/rename/delete/reveal actions.
/// Single-click a markdown file to open it (the host decides how — here, a new
/// window that macOS groups into native tabs).
struct FileTreeView: View {
    @Bindable var appModel: AppModel
    var theme: ThemeManager
    var onOpen: (URL) -> Void

    var body: some View {
        Group {
            if let root = appModel.fileTree.root {
                List {
                    ForEach(root.children ?? []) { node in
                        FileNodeView(node: node, appModel: appModel, onOpen: onOpen)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            } else {
                VStack(spacing: 10) {
                    Text("No folder open").foregroundStyle(.secondary)
                    Button("Open Folder…") { appModel.showOpenFolderDialog() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(theme.current.surfaceColor))
    }
}

/// A single tree row, recursive for directories.
private struct FileNodeView: View {
    let node: FileTreeNode
    @Bindable var appModel: AppModel
    var onOpen: (URL) -> Void
    @State private var isRenaming = false
    @State private var renameText = ""

    var body: some View {
        if node.isDirectory {
            DisclosureGroup {
                ForEach(node.children ?? []) { child in
                    FileNodeView(node: child, appModel: appModel, onOpen: onOpen)
                }
            } label: {
                row(icon: "folder")
            }
        } else {
            row(icon: "doc.text")
                .contentShape(Rectangle())
                .onTapGesture { onOpen(node.url) }
        }
    }

    private func row(icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(.secondary).frame(width: 16)
            if isRenaming {
                TextField("Name", text: $renameText, onCommit: {
                    appModel.rename(node.url, to: renameText)
                    isRenaming = false
                })
                .textFieldStyle(.roundedBorder)
            } else {
                Text(node.name).lineLimit(1)
            }
        }
        .contextMenu {
            let directory = node.isDirectory ? node.url : node.url.deletingLastPathComponent()
            Button("New File") { appModel.createFile(in: directory) }
            Button("New Folder") { appModel.createFolder(in: directory) }
            Divider()
            Button("Rename") { renameText = node.name; isRenaming = true }
            Button("Delete", role: .destructive) { appModel.delete(node.url) }
            Divider()
            Button("Reveal in Finder") { FileService.revealInFinder(node.url) }
        }
    }
}
