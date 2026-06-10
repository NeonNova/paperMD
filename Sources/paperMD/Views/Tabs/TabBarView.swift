import SwiftUI
import paperMDCore

/// VS Code-style horizontal tab strip with Liquid Glass active tabs. Tabs show
/// the filename and a dirty dot, can be closed (× on hover), and reordered by
/// dragging. The drag payload is the source index as a String, which uses the
/// built-in `Transferable` conformance (no custom UTType to register).
struct TabBarView: View {
    @Bindable var workspace: WorkspaceViewModel
    var theme: ThemeManager
    @Namespace private var glassNamespace
    @State private var dragging: Int?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(Array(workspace.documents.enumerated()), id: \.element.id) { index, doc in
                        TabChip(
                            title: doc.displayName,
                            isDirty: doc.isDirty,
                            isActive: index == workspace.activeIndex,
                            accent: theme.accent,
                            onSelect: { workspace.select(index) },
                            onClose: { workspace.closeTab(at: index) }
                        )
                        .glassEffectID(doc.id, in: glassNamespace)
                        .opacity(dragging == index ? 0.35 : 1)
                        .draggable("\(index)") {
                            TabDragPreview(title: doc.displayName, accent: theme.accent)
                                .onAppear { dragging = index }
                                .onDisappear { dragging = nil }
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard let from = items.first.flatMap(Int.init) else { return false }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                workspace.moveTab(from: from, to: index)
                            }
                            dragging = nil
                            return true
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        .frame(height: 36)
        .background(Color(theme.current.surfaceColor))
    }
}

/// Glassy drag preview shown while reordering a tab.
private struct TabDragPreview: View {
    let title: String
    let accent: Color
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12).frame(height: 28)
            .glassEffect(.regular.tint(accent.opacity(0.25)), in: .rect(cornerRadius: 8))
    }
}

private struct TabChip: View {
    let title: String
    let isDirty: Bool
    let isActive: Bool
    let accent: Color
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .font(.system(size: 12, weight: isActive ? .medium : .regular))
            ZStack {
                if isDirty && !hovering {
                    Circle().fill(.secondary).frame(width: 7, height: 7)
                } else if hovering {
                    Button(action: onClose) {
                        Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .help("Close Tab")
                }
            }
            .frame(width: 14, height: 14)
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .glassEffect(
            isActive ? .regular.tint(accent.opacity(0.18)).interactive() : .regular.interactive(),
            in: .rect(cornerRadius: 8))
        .opacity(isActive ? 1 : 0.7)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering = $0 }
        .help(title)
    }
}
