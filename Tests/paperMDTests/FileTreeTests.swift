import Foundation
import paperMDCore

enum FileTreeTests {
    static func run() {
        TestKit.suite("FileTreeNode") {
            let root = FileManager.default.temporaryDirectory
                .appendingPathComponent("papermd-tree-\(UUID().uuidString)")
            let fm = FileManager.default
            try? fm.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: root) }

            // Layout: root/{a.md, notes.txt, .hidden.md, sub/{b.markdown}}
            try? "".write(to: root.appendingPathComponent("a.md"), atomically: true, encoding: .utf8)
            try? "".write(to: root.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)
            try? "".write(to: root.appendingPathComponent(".hidden.md"), atomically: true, encoding: .utf8)
            let sub = root.appendingPathComponent("sub")
            try? fm.createDirectory(at: sub, withIntermediateDirectories: true)
            try? "".write(to: sub.appendingPathComponent("b.markdown"), atomically: true, encoding: .utf8)

            let tree = FileTreeNode.build(at: root)
            let names = (tree.children ?? []).map(\.name)

            TestKit.expectEqual(names, ["sub", "a.md"], "directories first, then markdown files; .txt and dotfiles excluded")

            let subNode = tree.children?.first { $0.name == "sub" }
            TestKit.expect(subNode?.isDirectory == true, "sub is a directory")
            TestKit.expectEqual(subNode?.children?.map(\.name), ["b.markdown"],
                                "recurses into subdirectories, includes .markdown")

            let fileNode = tree.children?.first { $0.name == "a.md" }
            TestKit.expect(fileNode?.children == nil, "files have nil children")

            // Empty folders (no markdown inside) are hidden.
            let empty = root.appendingPathComponent("emptydir")
            try? fm.createDirectory(at: empty, withIntermediateDirectories: true)
            try? "plain".write(to: empty.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)
            let tree2 = FileTreeNode.build(at: root)
            TestKit.expect(!(tree2.children ?? []).contains { $0.name == "emptydir" },
                           "folders with no markdown are hidden")
        }
    }
}
