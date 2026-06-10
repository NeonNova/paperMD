import SwiftUI
import paperMDCore

/// VS Code-style command palette: a centered overlay that fuzzy-filters the
/// fixed command list. ↑/↓ to move, Return to run, Esc to dismiss.
struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    var onRun: (AppCommand) -> Void

    @State private var query = ""
    @State private var selection = 0
    @FocusState private var fieldFocused: Bool

    private var results: [AppCommand] {
        let commands = AppCommand.paletteCommands
        if query.isEmpty { return commands }
        return commands
            .compactMap { cmd -> (AppCommand, Int)? in
                FuzzyMatcher.score(query: query, candidate: cmd.title).map { (cmd, $0) }
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Run a command…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .padding(12)
                .focused($fieldFocused)
                .onChange(of: query) { selection = 0 }
                .onSubmit(run)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, cmd in
                            row(cmd, isSelected: index == selection)
                                .id(index)
                                .onTapGesture { selection = index; run() }
                        }
                    }
                }
                .frame(maxHeight: 320)
                .onChange(of: selection) { proxy.scrollTo(selection, anchor: .center) }
            }
        }
        .frame(width: 520)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.12)))
        .shadow(radius: 30, y: 10)
        .onAppear { fieldFocused = true }
        .background { keyHandlers }
    }

    private func row(_ cmd: AppCommand, isSelected: Bool) -> some View {
        HStack {
            Text(cmd.title)
            Spacer()
            if let hint = cmd.shortcutHint {
                Text(hint).foregroundStyle(.secondary).font(.system(size: 12))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.25) : .clear)
        .contentShape(Rectangle())
    }

    private var keyHandlers: some View {
        Group {
            Button("") { move(1) }.keyboardShortcut(.downArrow, modifiers: [])
            Button("") { move(-1) }.keyboardShortcut(.upArrow, modifiers: [])
            Button("") { isPresented = false }.keyboardShortcut(.cancelAction)
        }
        .opacity(0)
    }

    private func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        selection = (selection + delta + results.count) % results.count
    }

    private func run() {
        guard results.indices.contains(selection) else { return }
        let cmd = results[selection]
        isPresented = false
        onRun(cmd)
    }
}
