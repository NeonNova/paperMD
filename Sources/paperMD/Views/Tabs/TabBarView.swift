import SwiftUI
import UniformTypeIdentifiers

/// VS Code-style horizontal tab strip. Tabs show the filename and a dirty dot,
/// can be closed (× or middle-click), and reordered by dragging.
struct TabBarView: View {
    @Bindable var workspace: WorkspaceViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(workspace.documents.enumerated()), id: \.element.id) { index, doc in
                    TabChip(
                        title: doc.displayName,
                        isDirty: doc.isDirty,
                        isActive: index == workspace.activeIndex,
                        onSelect: { workspace.select(index) },
                        onClose: { workspace.closeTab(at: index) }
                    )
                    .draggable(TabID(index: index)) {
                        Text(doc.displayName).padding(6)
                    }
                    .dropDestination(for: TabID.self) { items, _ in
                        guard let from = items.first?.index else { return false }
                        workspace.moveTab(from: from, to: index)
                        return true
                    }
                }
            }
        }
        .frame(height: 32)
        .background(.bar)
    }
}

/// Lightweight transferable payload carrying a tab's source index.
struct TabID: Codable, Transferable {
    let index: Int
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .paperMDTab)
    }
}

extension UTType {
    static let paperMDTab = UTType(exportedAs: "com.washi.papermd.tab")
}

private struct TabChip: View {
    let title: String
    let isDirty: Bool
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .font(.system(size: 12))
            ZStack {
                if isDirty && !hovering {
                    Circle().fill(.secondary).frame(width: 7, height: 7)
                } else if hovering {
                    Button(action: onClose) {
                        Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 14, height: 14)
        }
        .padding(.horizontal, 10)
        .frame(maxHeight: .infinity)
        .background(isActive ? AnyShapeStyle(.selection) : AnyShapeStyle(.clear))
        .overlay(alignment: .trailing) {
            Divider().opacity(0.5)
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering = $0 }
        .help(title)
    }
}
