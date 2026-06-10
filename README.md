# paperMD

A native macOS Markdown editor and viewer — fast, focused, and intentionally
minimal. *If Apple built a Markdown editor and borrowed only the best ideas from
Obsidian.*

paperMD is a lightweight alternative to heavyweight note apps: a beautiful editor
and reader for `.md` / `.markdown` files, with a real macOS feel. No plugins, no
vaults, no graph view, no AI — just the best possible editing and reading
experience.

## Features

- **Native editor** — `NSTextView`-based, with live Markdown syntax
  highlighting, line numbers, word wrap, the native find bar, and full
  undo/IME/dictation support.
- **Live preview** — GitHub-Flavored Markdown via markdown-it, with tables, task
  lists, footnotes, syntax-highlighted code (highlight.js), math (KaTeX), and
  Mermaid diagrams. Edit / Split / Preview modes (⌘1 / ⌘2 / ⌘3). Everything is
  bundled and works fully offline.
- **Workspace** — folder sidebar (create / rename / delete / reveal), VS
  Code-style tabs with drag-to-reorder, and a document outline that jumps to
  headings.
- **Autosave & crash recovery** — debounced autosave to the real file; unsaved
  buffers are journaled so a crash never loses work. Sessions (open folder, tabs,
  mode, cursor positions) restore on launch.
- **Themes** — eight built-in JSON theme packs (System Light/Dark, GitHub
  Light/Dark, Nord, Dracula, Solarized Light/Dark), plus import/export. Themes
  affect the whole app and switch instantly.
- **Typography** — separate body and code fonts (any installed font) with
  adjustable sizes.
- **Command palette** (⇧⌘P) — fuzzy-filtered access to every command.
- **First-class macOS integration** — menu bar, keyboard shortcuts, Open Recent,
  drag-and-drop, Finder double-click, and an offer to become the default
  Markdown handler.

## Requirements

- macOS 26 or later (Apple Silicon).
- **No Xcode required** — builds with the Command Line Tools (Swift 6.x) alone.

## Build & Run

```bash
# 1. (first time / to bump versions) fetch the bundled preview JS/CSS:
Scripts/fetch-vendor.sh          # already committed; only needed to refresh

# 2. build the .app bundle (release, ad-hoc signed):
Scripts/build-app.sh

# 3. run it, or install it:
open dist/paperMD.app
cp -R dist/paperMD.app /Applications/
```

Development commands:

```bash
swift build            # debug build
swift run paperMD      # run unbundled (preview/themes resolve from the build dir)
swift run paperMDTests # run the test suite (see "Testing" below)
```

### Testing

This project ships with the Command Line Tools, which cannot run XCTest or
swift-testing under `swift test`. Tests are therefore a plain executable
(`paperMDTests`) using a tiny assertion harness (`TestKit`), run with
`swift run paperMDTests` (exit code 0 = pass, 1 = fail). All pure logic lives in
the `paperMDCore` library and is covered there.

## Dependencies

**Zero Swift package dependencies.** The preview pipeline vendors these JS/CSS
assets (committed under `Sources/paperMD/Resources/Preview/vendor/`, fetched by
`Scripts/fetch-vendor.sh`):

| Library                | Version | Purpose                        |
|------------------------|---------|--------------------------------|
| markdown-it            | 14.1.0  | GFM parsing & rendering        |
| markdown-it-footnote   | 4.0.0   | Footnotes                      |
| markdown-it-task-lists | 2.1.1   | `- [ ]` task lists             |
| highlight.js           | 11.10.0 | Code-block syntax highlighting |
| KaTeX                  | 0.16.11 | LaTeX math rendering           |
| Mermaid                | 11.4.0  | Diagrams                       |

## Architecture

MVVM, three SwiftPM targets:

- **`paperMDCore`** (library) — models (`Theme`, `Session`, `OutlineItem`,
  `FileTreeNode`), pure logic (`OutlineParser`, `FuzzyMatcher`), services
  (`FileService`, `FolderWatcher`, `SessionStore`, `ThemeLoader`), and the
  editor highlighting engine (`MarkdownHighlighter`, `HighlightPalette`,
  `Typography`). No SwiftUI; fully unit-tested.
- **`paperMD`** (app) — SwiftUI views, AppKit wrappers (`EditorView`,
  `PreviewView`), and view models (`WorkspaceViewModel`, `DocumentViewModel`,
  `ThemeManager`, `FileTreeViewModel`).
- **`paperMDTests`** (executable test runner).

```
Sources/
  paperMDCore/   Models · Logic · Services · Editor · Resources/Themes
  paperMD/       App · ViewModels · Views · Resources/Preview
Tests/paperMDTests/
Scripts/         build-app.sh · fetch-vendor.sh · make-icon.sh
```

## Theme Format

Themes are JSON files with a `name` and five colours (6-digit hex):

```json
{
  "name": "Nord",
  "colors": {
    "background": "#2E3440",
    "surface":    "#3B4252",
    "text":       "#ECEFF4",
    "muted":      "#D8DEE9",
    "accent":     "#88C0D0"
  }
}
```

- `background` — editor/preview/app background
- `surface` — sidebar, code blocks, table headers, raised chrome
- `text` — primary text
- `muted` — secondary text, line numbers, blockquotes
- `accent` — headings, links, list markers, selection, tint

Import via **Settings → Appearance → Import…** (copied to
`~/Library/Application Support/paperMD/Themes/`) or export the current theme from
the same panel. Invalid theme files are skipped, never crashing the app.

## Keyboard Shortcuts

| Action               | Shortcut |
|----------------------|----------|
| New File             | ⌘N       |
| New Tab              | ⌘T       |
| Open File…           | ⌘O       |
| Open Folder…         | ⇧⌘O      |
| Close Tab            | ⌘W       |
| Edit / Split / Preview | ⌘1 / ⌘2 / ⌘3 |
| Toggle Sidebar       | ⇧⌘E      |
| Toggle Outline       | ⇧⌘U      |
| Find                 | ⌘F       |
| Find and Replace     | ⌥⌘F      |
| Go to Line           | ⌘L       |
| Increase / Decrease Font | ⌘+ / ⌘- |
| Command Palette      | ⇧⌘P      |
| Settings             | ⌘,       |

## App Icon

The repository ships a static `.icns` built from the icon artwork
(`Scripts/make-icon.sh`). The source design is an Icon Composer `.icon`
(`paperMD.icon`) for macOS 26 Liquid Glass; compiling that into the dynamic
runtime icon requires Xcode's `actool`. To use it: compile `paperMD.icon` into an
`Assets.car` and drop it at `Scripts/Assets.car` — `build-app.sh` prefers it
automatically (via `CFBundleIconName`), no other changes needed.

## Future Extension Points

Designed for but intentionally not implemented (to keep the product focused):

- Editor ⟷ preview scroll sync.
- Clickable wikilinks (`[[…]]` currently renders as styled, non-clickable text).
- Export to PDF / standalone HTML.
- Typewriter / focus mode.

## License

Personal project. All rights reserved unless stated otherwise.
