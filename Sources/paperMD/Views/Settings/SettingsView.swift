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
        .frame(width: 460, height: 360)
    }
}

// MARK: - Appearance

private struct AppearanceSettings: View {
    @State private var theme = ThemeManager.shared

    var body: some View {
        Form {
            Picker("Appearance", selection: $theme.appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)

            Section("Theme") {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(theme.themes) { t in
                            themeRow(t)
                        }
                    }
                }
                .frame(height: 150)

                HStack {
                    Button("Import…") { importTheme() }
                    Button("Export Current…") { exportTheme() }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func themeRow(_ t: Theme) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                swatch(t.colors.background); swatch(t.colors.surface)
                swatch(t.colors.text); swatch(t.colors.accent)
            }
            Text(t.name)
            Spacer()
            if t.name == theme.themeName {
                Image(systemName: "checkmark").foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .background(t.name == theme.themeName ? Color.secondary.opacity(0.15) : .clear,
                    in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture { theme.themeName = t.name }
    }

    private func swatch(_ hex: String) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(NSColor(hex: hex) ?? .gray))
            .frame(width: 14, height: 14)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.secondary.opacity(0.3)))
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
            Section("Body") {
                fontPicker(selection: $theme.bodyFontName)
                Stepper("Size: \(Int(theme.bodySize)) pt", value: $theme.bodySize, in: 11...24)
            }
            Section("Code") {
                fontPicker(selection: $theme.codeFontName)
                Stepper("Size: \(Int(theme.codeSize)) pt", value: $theme.codeSize, in: 10...20)
            }
        }
        .formStyle(.grouped)
    }

    private func fontPicker(selection: Binding<String>) -> some View {
        Picker("Font", selection: selection) {
            Text("System").tag("")
            Divider()
            ForEach(families, id: \.self) { Text($0).tag($0) }
        }
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
