import SwiftUI
import paperMDCore

/// Horizontal tab strip with Liquid Glass pills and live drag reordering: while
/// dragging a tab it lifts and follows the pointer, and the other tabs slide
/// left/right in real time to make room (like native macOS / Ghostty tabs).
struct TabBarView: View {
    @Bindable var workspace: WorkspaceViewModel
    var theme: ThemeManager
    @Namespace private var glass

    private let tabWidth: CGFloat = 150
    private let spacing: CGFloat = 4

    @State private var draggingID: UUID?
    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: spacing) {
                HStack(spacing: spacing) {
                    ForEach(Array(workspace.documents.enumerated()), id: \.element.id) { index, doc in
                        chip(doc, index: index)
                    }
                }
                .padding(.horizontal, 6)
                .animation(.spring(response: 0.3, dampingFraction: 0.78),
                           value: workspace.documents.map(\.id))
            }
        }
        .frame(height: 36)
        .background(Color(theme.current.surfaceColor))
    }

    private func chip(_ doc: DocumentViewModel, index: Int) -> some View {
        let isDragging = draggingID == doc.id
        return TabChip(
            title: doc.displayName,
            isDirty: doc.isDirty,
            isActive: index == workspace.activeIndex,
            accent: theme.accent,
            interfaceFont: theme.interfaceFont,
            onSelect: { workspace.select(index) },
            onClose: { workspace.closeTab(at: index) }
        )
        .frame(width: tabWidth)
        .glassEffectID(doc.id, in: glass)
        .offset(x: isDragging ? dragTranslation : 0)
        .scaleEffect(isDragging ? 1.04 : 1)
        .shadow(color: .black.opacity(isDragging ? 0.25 : 0), radius: 8, y: 4)
        .zIndex(isDragging ? 1 : 0)
        .gesture(dragGesture(for: doc))
    }

    private func dragGesture(for doc: DocumentViewModel) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                if draggingID == nil { draggingID = doc.id }
                dragTranslation = value.translation.width

                guard let current = workspace.documents.firstIndex(where: { $0.id == doc.id }) else { return }
                let shift = Int((dragTranslation / (tabWidth + spacing)).rounded())
                let target = min(max(0, current + shift), workspace.documents.count - 1)
                if target != current {
                    workspace.moveTab(from: current, to: target)
                    // Keep the lifted tab under the pointer after the reorder.
                    dragTranslation -= CGFloat(target - current) * (tabWidth + spacing)
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    dragTranslation = 0
                }
                draggingID = nil
            }
    }
}

private struct TabChip: View {
    let title: String
    let isDirty: Bool
    let isActive: Bool
    let accent: Color
    let interfaceFont: Font
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(interfaceFont)
                .fontWeight(isActive ? .medium : .regular)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
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
            isActive ? .regular.tint(accent.opacity(0.20)).interactive() : .regular.interactive(),
            in: .rect(cornerRadius: 8))
        .opacity(isActive ? 1 : 0.72)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering = $0 }
        .help(title)
    }
}
