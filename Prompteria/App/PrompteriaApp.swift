import SwiftUI
import AppKit

@main
struct PrompteriaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .environment(\.appTheme, appState.currentTheme)
                .preferredColorScheme(appState.themeOverride.colorScheme ?? appState.currentTheme.colorScheme)
        }
        .handlesExternalEvents(matching: Set<String>())
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Prompt") {
                Button("New Prompt") {
                    appState.createNewPrompt()
                }
                .keyboardShortcut("n", modifiers: .command)
                Button("New Folder") {
                    appState.createNewFolder()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                Divider()
                Button("Select All Prompts") {
                    let displayed = appState.showFavoritesOnly ? appState.favorites : appState.prompts
                    if !displayed.isEmpty {
                        appState.selectedPromptIds = Set(displayed.map(\.id))
                    }
                }
                .keyboardShortcut("a", modifiers: .command)
            }
            CommandMenu("File") {
                Button("Export Backup...") {
                    appState.exportBackup()
                }
                Button("Import Backup...") {
                    appState.importBackup()
                }
                Button("Import Snippets...") {
                    appState.importSnippets()
                }
            }
        }
        Settings {
            SettingsView()
                .environmentObject(appState)
                .environment(\.appTheme, appState.currentTheme)
        }
    }
}
