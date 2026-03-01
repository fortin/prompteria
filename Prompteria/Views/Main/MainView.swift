import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.appTheme) private var theme
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
        } content: {
            ContentView()
        } detail: {
            if let prompt = appState.selectedPrompt {
                PromptDetailView(prompt: prompt)
                    .id(prompt.id)
            } else {
                EmptyDetailView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(theme.uiBackgroundColor)
        .task {
            await appState.loadData()
        }
        .onChange(of: appState.selectedFolderId) { _, _ in
            appState.clearPromptsForReload()
            Task { await appState.loadData() }
        }
        .onChange(of: appState.showFavoritesOnly) { _, _ in
            Task { await appState.loadData() }
        }
        .onChange(of: appState.searchQuery) { _, _ in
            Task { await appState.loadData() }
        }
        .onChange(of: appState.promptToOpenFromURL) { _, newValue in
            if newValue != nil {
                Task { await appState.loadData() }
            }
        }
        .refreshable {
            await appState.loadData()
        }
    }
}
