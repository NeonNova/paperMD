import SwiftUI

/// Small modal for jumping the editor to a line number.
struct GoToLineSheet: View {
    @Binding var isPresented: Bool
    var onGo: (Int) -> Void

    @State private var lineText = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Go to Line").font(.headline)
            TextField("Line number", text: $lineText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .focused($focused)
                .onSubmit(go)
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }.keyboardShortcut(.cancelAction)
                Button("Go") { go() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 260)
        .onAppear { focused = true }
    }

    private func go() {
        if let line = Int(lineText.trimmingCharacters(in: .whitespaces)), line > 0 {
            onGo(line)
        }
        isPresented = false
    }
}
