import SwiftUI
import AppKit
import UniformTypeIdentifiers
import paperMDCore

/// Native Settings window with four sections (Appearance, Typography, Files,
/// Advanced), matching the spec.
struct SettingsView: View {
    var body: some View {
        TabView {
            AppearanceSettings()
                .tabItem { Label("Appearance", systemImage: "paintpalette") }
            TypographySettings()
                .tabItem { Label("Typography", systemImage: "textformat") }
            FilesSettings()
                .tabItem { Label("Files", systemImage: "folder") }
            AdvancedSettings()
                .tabItem { Label("Advanced", systemImage: "gearshape.2") }
        }
        .frame(width: 480, height: 400)
    }
}

// MARK: - Appearance

private struct AppearanceSettings: View {
    @State private var theme = ThemeManager.shared

    private let columns = [GridItem(.adaptive(minimum: 200), spacing: 8)]

    var body: some View {
        Form {
            Picker("Appearance", selection: $theme.appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)

            Section {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(theme.themes) { themeCard($0) }
                }
                .padding(.vertical, 4)
            } header: {
                HStack {
                    Text("Theme")
                    Spacer()
                    Button("Import…") { importTheme() }.controlSize(.small)
                    Button("Export…") { exportTheme() }.controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func themeCard(_ t: Theme) -> some View {
        let selected = t.name == theme.themeName
        return HStack(spacing: 8) {
            // Mini preview chip: background with text + accent dots.
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5).fill(Color(NSColor(hex: t.colors.background) ?? .gray))
                HStack(spacing: 3) {
                    Circle().fill(Color(NSColor(hex: t.colors.text) ?? .gray)).frame(width: 6, height: 6)
                    Circle().fill(Color(NSColor(hex: t.colors.accent) ?? .gray)).frame(width: 6, height: 6)
                }.padding(.leading, 6)
            }
            .frame(width: 34, height: 22)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.secondary.opacity(0.25)))

            Text(t.name).lineLimit(1).font(.system(size: 12))
            Spacer(minLength: 0)
            if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
        .background(selected ? AnyShapeStyle(.tint.opacity(0.12)) : AnyShapeStyle(Color.secondary.opacity(0.06)),
                    in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(selected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear), lineWidth: 1.5))
        .contentShape(Rectangle())
        .onTapGesture { theme.themeName = t.name }
    }

    private func importTheme() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url { theme.importTheme(from: url) }
    }

    private func exportTheme() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = theme.current.name + ".json"
        if panel.runModal() == .OK, let url = panel.url { theme.exportCurrent(to: url) }
    }
}

// MARK: - Typography

private struct TypographySettings: View {
    @State private var theme = ThemeManager.shared
    private let families = NSFontManager.shared.availableFontFamilies

    var body: some View {
        Form {
            Section("Interface") {
                fontPicker(selection: $theme.interfaceFontName)
                sizeStepper(value: $theme.interfaceSize, range: 11...18)
                Text("Sidebar, tabs, and controls.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Text") {
                fontPicker(selection: $theme.bodyFontName)
                sizeStepper(value: $theme.bodySize, range: 11...30)
                Text("Editor and preview body text and headings.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Code") {
                fontPicker(selection: $theme.codeFontName)
                sizeStepper(value: $theme.codeSize, range: 10...22)
                Text("Code spans and fenced code blocks.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func fontPicker(selection: Binding<String>) -> some View {
        Picker("Font", selection: selection) {
            Text("System Default").tag("")
            Divider()
            ForEach(families, id: \.self) { Text($0).tag($0) }
        }
    }

    private func sizeStepper(value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        Stepper("Size: \(Int(value.wrappedValue)) pt", value: value, in: range)
    }
}

// MARK: - Files

private struct FilesSettings: View {
    @AppStorage("restoreSession") private var restoreSession = true

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Restore previous session", isOn: $restoreSession)
                Text("Reopen the folder and tabs from your last session on launch.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Advanced

private struct AdvancedSettings: View {
    @AppStorage("previewDebounceMs") private var previewDebounceMs = 200
    @AppStorage("editorMode") private var defaultMode: EditorMode = .edit

    var body: some View {
        Form {
            Section("Preview") {
                VStack(alignment: .leading) {
                    Text("Update delay: \(previewDebounceMs) ms")
                    Slider(value: .init(get: { Double(previewDebounceMs) },
                                        set: { previewDebounceMs = Int($0) }),
                           in: 100...1000, step: 50)
                }
            }
            Section("Editor") {
                Picker("Default mode", selection: $defaultMode) {
                    Text("Edit").tag(EditorMode.edit)
                    Text("Split").tag(EditorMode.split)
                    Text("Preview").tag(EditorMode.preview)
                }
            }
        }
        .formStyle(.grouped)
    }
}
