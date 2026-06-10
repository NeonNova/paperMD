# paperMD — Design Spec

**Date:** 2026-06-10
**Status:** Approved (user reviewed design conversationally; spec-doc review waived)

## Product

A native macOS markdown editor/viewer. Personal-use, lightweight, fast alternative
to Obsidian. "If Apple built a markdown editor and borrowed only the best ideas
from Obsidian."

Priorities, in order: native macOS feel → performance → simplicity → beautiful
reading/editing → maintainability.

**Non-goals:** plugins, AI, vaults, backlinks, graph view, sync, daily notes,
tasks/kanban, databases, web-tech-as-primary-UI, vim/emacs modes, collaboration.

## Decisions Made (with user)

1. **Build system:** SwiftPM executable package, no Xcode (machine has CLT only:
   Swift 6.0.3, macOS 15.2 SDK). `Scripts/build-app.sh` assembles `paperMD.app`,
   ad-hoc codesigns, installs to /Applications. Deployment target macOS 15.
2. **Wikilinks:** `[[Note Name]]` renders as styled (non-clickable) text in
   preview. No resolution, no backlinks.
3. **Preview pipeline:** markdown-it in WKWebView with KaTeX, Mermaid,
   highlight.js — all bundled offline (~3 MB). Not swift-markdown.
4. **Repo:** public, on GitHub (account NeonNova).

## Architecture (MVVM)

Zero Swift package dependencies. Four layers:

- **Views (SwiftUI):** `MainWindowView` (sidebar / content / outline split),
  custom `TabBarView` (drag-reorder, VS Code-style), `EditorView` +
  `PreviewView` as `NSViewRepresentable`, `CommandPaletteView` overlay,
  `SettingsView` (Settings scene).
- **ViewModels (`@Observable`):** `WorkspaceViewModel` (folder, tabs, session),
  `DocumentViewModel` (per-tab text/dirty/cursor), `FileTreeViewModel`,
  `OutlineViewModel`, `ThemeManager`.
- **Services:** `FileService` (CRUD + DispatchSource folder watching),
  `AutosaveService` (debounced ~1 s + on blur/quit), `SessionStore` (JSON in
  Application Support: tabs, mode, cursor), `ThemeLoader`.
- **Models:** plain structs — `Document`, `FileTreeNode`, `Theme`,
  `OutlineItem`, `Command`.

## Editor

`NSTextView` in `NSScrollView`, custom `NSRulerView` line numbers. Syntax
highlighting via `NSTextStorage` delegate: regex-based, edited-paragraph-range
only (debounced wider pass for code fences). Native find bar (⌘F, ⌥⌘F
find-and-replace), native undo/IME. Go-to-line sheet. Word wrap toggle.

## Preview

One WKWebView per tab; local HTML shell loads bundled markdown-it (+ GFM,
footnotes, wikilink-style plugin), highlight.js, KaTeX, Mermaid. Debounced
re-render on edit (default 200 ms, configurable in Settings → Advanced).
Mermaid blocks cached by content hash. Scroll position preserved across
re-renders. Three modes: Edit / Preview / Split; per-app remembered.

## Themes

JSON packs (name + colors: background, surface, text, muted, accent). Eight
built-ins: System Light/Dark, GitHub Light/Dark, Nord, Dracula, Solarized
Light/Dark. User imports → `~/Library/Application Support/paperMD/Themes/`.
One `Theme` struct drives SwiftUI chrome + editor colors + CSS variables in
preview; switching is instant. Import/export via file panels.

## Typography

Separate body and code font settings (family + size), system font picker,
persisted in UserDefaults, applied to editor and preview.

## Tabs, Sidebar, Outline, Palette

- Tabs: open/reorder/close, session restore.
- Sidebar: folder tree; create/rename/delete file & folder, reveal in Finder.
- Outline: parsed from headings, click jumps to heading, toggleable.
- Command palette (⌘⇧P): fuzzy filter over fixed command list (open file/folder,
  new file/folder/tab, close tab, toggle sidebar/outline, modes, search,
  find/replace, go to line, font size ±, switch theme, settings).

## Files & macOS Integration

`.md`/`.markdown` via CFBundleDocumentTypes; Finder double-click; drag-and-drop;
Open Recent; native menu bar with standard shortcuts. First launch: one-time
panel with "Make default for Markdown" button (`NSWorkspace.setDefaultApplication`,
supported API only). External changes: auto-reload if clean, prompt if dirty.

## Autosave & Crash Safety

Autosave writes to the actual file (Obsidian-style). Untitled/unsaved buffers
journal to Application Support; recovered on next launch. Cursor positions
persisted per file.

## Error Handling

I/O failures → native alerts. Invalid theme JSON → fall back to System theme.
Missing files on session restore → skip silently.

## Testing

`swift test` unit tests: outline parser, theme decoding, session store,
markdown preprocessing. No XCUITest (requires Xcode).

## Future Extension Points (documented, not built)

Editor/preview scroll sync, clickable wikilinks, PDF/HTML export,
typewriter mode.
