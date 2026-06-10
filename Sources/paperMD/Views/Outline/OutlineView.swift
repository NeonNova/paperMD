import SwiftUI
import paperMDCore

/// Right-hand panel listing the active document's headings. Clicking a row jumps
/// the editor (and preview) to that heading.
struct OutlineView: View {
    let text: String
    var onSelect: (OutlineItem, _ headingIndex: Int) -> Void

    private var items: [OutlineItem] { OutlineParser.parse(text) }

    var body: some View {
        Group {
            if items.isEmpty {
                Text("No headings")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        Button {
                            onSelect(item, index)
                        } label: {
                            Text(item.title)
                                .lineLimit(1)
                                .font(.system(size: 12))
                                .padding(.leading, CGFloat(item.level - 1) * 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}
