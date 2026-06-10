import Foundation
import paperMDCore

enum FileServiceTests {
    static func run() {
        TestKit.suite("FileService") {
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("papermd-test-\(UUID().uuidString)")
            try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tmp) }

            // create + read + write round-trip
            let file = try? FileService.create(name: "note.md", in: tmp)
            TestKit.expect(file != nil, "creates a file")
            if let file {
                try? FileService.write("# Hello\nworld", to: file)
                TestKit.expectEqual(try? FileService.read(file), "# Hello\nworld",
                                    "reads back written contents")
            }

            // duplicate create fails
            var duplicated = false
            do { _ = try FileService.create(name: "note.md", in: tmp) }
            catch { duplicated = true }
            TestKit.expect(duplicated, "rejects creating a duplicate name")

            // rename
            if let file, let renamed = try? FileService.rename(file, to: "renamed.md") {
                TestKit.expectEqual(renamed.lastPathComponent, "renamed.md", "renames a file")
                TestKit.expect(FileManager.default.fileExists(atPath: renamed.path),
                               "renamed file exists on disk")
            }

            // createFolder
            let folder = try? FileService.createFolder(name: "sub", in: tmp)
            var isDir: ObjCBool = false
            let exists = folder.map {
                FileManager.default.fileExists(atPath: $0.path, isDirectory: &isDir)
            } ?? false
            TestKit.expect(exists && isDir.boolValue, "creates a folder")

            // trash
            if let toTrash = try? FileService.create(name: "trashme.md", in: tmp) {
                try? FileService.trash(toTrash)
                TestKit.expect(!FileManager.default.fileExists(atPath: toTrash.path),
                               "trash removes the file from its location")
            }

            // extension helpers
            TestKit.expect(FileService.isMarkdown(URL(fileURLWithPath: "/x/a.md")), "recognises .md")
            TestKit.expect(FileService.isMarkdown(URL(fileURLWithPath: "/x/a.MARKDOWN")),
                           "recognises .markdown case-insensitively")
            TestKit.expect(!FileService.isMarkdown(URL(fileURLWithPath: "/x/a.txt")), "rejects .txt")
        }
    }
}
