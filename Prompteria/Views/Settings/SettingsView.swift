import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var themes: [AppTheme] = []
    @State private var showImportSheet = false

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Color scheme", selection: Binding(
                    get: { appState.themeOverride },
                    set: { appState.setThemeOverride($0) }
                )) {
                    Text("System").tag(ThemeOverride.system)
                    Text("Light").tag(ThemeOverride.light)
                    Text("Dark").tag(ThemeOverride.dark)
                }

                Picker("Theme", selection: Binding(
                    get: { appState.selectedThemeId },
                    set: { appState.setSelectedThemeId($0) }
                )) {
                    ForEach(themes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                .onAppear { themes = ThemeService.shared.loadThemes() }
                .help("Affects app appearance and editor syntax highlighting")

                Button("Import .xccolortheme...") {
                    showImportSheet = true
                }
            }

            Section("Behavior") {
                Toggle("Auto-copy on select", isOn: Binding(
                    get: { appState.autoCopyOnSelect },
                    set: { appState.setAutoCopyOnSelect($0) }
                ))
            }

            Section("Backup") {
                Text("Use File → Export Backup to save your library as JSON. Use File → Import Backup to restore.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 280)
        .fileImporter(
            isPresented: $showImportSheet,
            allowedContentTypes: [UTType(filenameExtension: "xccolortheme") ?? .xml, .xml, .propertyList],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            if let theme = ThemeService.shared.importTheme(from: url) {
                appState.setSelectedThemeId(theme.id)
                themes = ThemeService.shared.loadThemes()
            }
        }
    }
}
