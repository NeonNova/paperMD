import SwiftUI
import AppKit
import paperMDCore

/// The left sidebar: a folder tree with create/rename/delete/reveal actions.
/// Double-click opens a markdown file in a tab.
struct FileTreeView: View {
    @Bindable var workspace: WorkspaceViewModel
    var theme: ThemeManager

    var body: some View {
        Group {
            if let root = workspace.fileTree.root {
                List {
                    ForEach(root.children ?? []) { node in
                        FileNodeView(node: node, workspace: workspace)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            } else {
                VStack(spacing: 10) {
                    Text("No folder open").foregroundStyle(.secondary)
                    Button("Open Folder…") { workspace.showOpenFolderDialog() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(theme.current.surfaceColor))
    }
}

/// A single tree row, recursive for directories. A concrete `View` type can
/// reference itself in its body (unlike a `some View`-returning function).
private struct FileNodeView: View {
    let node: FileTreeNode
    @Bindable var workspace: WorkspaceViewModel
    @State private var isRenaming = false
    @State private var renameText = ""

    var body: some View {
        if node.isDirectory {
            DisclosureGroup {
                ForEach(node.children ?? []) { child in
                    FileNodeView(node: child, workspace: workspace)
                }
            } label: {
                row(icon: "folder")
            }
        } else {
            row(icon: "doc.text")
                .contentShape(Rectangle())
                .onTapGesture { workspace.open(node.url) }
        }
    }

    private func row(icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(.secondary).frame(width: 16)
            if isRenaming {
                TextField("Name", text: $renameText, onCommit: {
                    workspace.rename(node.url, to: renameText)
                    isRenaming = false
                })
                .textFieldStyle(.roundedBorder)
            } else {
                Text(node.name).lineLimit(1)
            }
        }
        .contextMenu {
            let directory = node.isDirectory ? node.url : node.url.deletingLastPathComponent()
            Button("New File") { workspace.createFile(in: directory) }
            Button("New Folder") { workspace.createFolder(in: directory) }
            Divider()
            Button("Rename") { renameText = node.name; isRenaming = true }
            Button("Delete", role: .destructive) { workspace.delete(node.url) }
            Divider()
            Button("Reveal in Finder") { FileService.revealInFinder(node.url) }
        }
    }
}
