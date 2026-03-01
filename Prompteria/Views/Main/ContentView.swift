import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.appTheme) private var theme
    @FocusState private var isSearchFocused: Bool
    @State private var showBulkActions = false
    @State private var showMoveToFolder = false
    @State private var lastSelectedIndex: Int?
    @State private var showEmojiPickerForPromptId: String?
    @State private var showColorPickerForPromptId: String?

    var selectedPrompts: [Prompt] {
        appState.displayedPrompts.filter { appState.selectedPromptIds.contains($0.id) }
    }

    var body: some View {
        Group {
            if appState.showFavoritesOnly {
                promptList(prompts: appState.sortedFavorites, title: "Favourites")
            } else if appState.selectedFolderId == nil && !appState.searchQuery.isEmpty {
                promptList(prompts: appState.sortedPrompts, title: "Search Results")
            } else if appState.selectedFolderId == nil {
                promptList(prompts: appState.sortedPrompts, title: "All Prompts")
            } else {
                promptList(prompts: appState.sortedPrompts, title: "Prompts")
            }
        }
        .searchable(text: $appState.searchQuery, prompt: "Search prompts...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Section("Sort By") {
                        ForEach(PromptSortOption.allCases, id: \.self) { option in
                            Button {
                                appState.setPromptSortOption(option)
                            } label: {
                                HStack {
                                    Text(option.displayName)
                                    if appState.promptSortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
                .help("Sort prompts")
            }
            ToolbarItem(placement: .primaryAction) {
                if appState.selectedFolderId != nil || appState.sidebarSelection == AppState.allPromptsId {
                    Button {
                        appState.createNewPrompt()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            if !selectedPrompts.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Move to Folder...") {
                            showMoveToFolder = true
                        }
                        Button("Export Selected...") {
                            exportSelected()
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            for prompt in selectedPrompts {
                                appState.deletePrompt(prompt)
                            }
                            appState.selectedPromptIds.removeAll()
                        }
                    } label: {
                        Text("\(selectedPrompts.count) selected")
                    }
                }
            }
        }
        .sheet(isPresented: $showMoveToFolder) {
            MoveToFolderSheet(
                prompts: selectedPrompts,
                folders: appState.folders,
                onMove: { folderId in
                    for prompt in selectedPrompts {
                        appState.movePrompt(prompt, to: folderId)
                    }
                    appState.selectedPromptIds.removeAll()
                    showMoveToFolder = false
                },
                onCancel: {
                    showMoveToFolder = false
                }
            )
            .environmentObject(appState)
        }
        .popover(isPresented: Binding(
            get: { showEmojiPickerForPromptId != nil },
            set: { if !$0 { showEmojiPickerForPromptId = nil } }
        )) {
            if let promptId = showEmojiPickerForPromptId,
               let prompt = appState.prompts.first(where: { $0.id == promptId }) ?? appState.favorites.first(where: { $0.id == promptId }) {
                EmojiPickerView { emoji in
                    var updated = prompt
                    updated.emoji = emoji
                    appState.updatePrompt(updated)
                    showEmojiPickerForPromptId = nil
                }
            }
        }
        .popover(isPresented: Binding(
            get: { showColorPickerForPromptId != nil },
            set: { if !$0 { showColorPickerForPromptId = nil } }
        )) {
            if let promptId = showColorPickerForPromptId,
               let prompt = appState.prompts.first(where: { $0.id == promptId }) ?? appState.favorites.first(where: { $0.id == promptId }) {
                ColorPickerView { colorHex in
                    var updated = prompt
                    updated.color = colorHex
                    appState.updatePrompt(updated)
                    showColorPickerForPromptId = nil
                }
            }
        }
    }

    private func exportSelected() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "prompteria-selected-\(ISO8601DateFormatter().string(from: Date())).json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                do {
                    let backup = BackupData(
                        version: 1,
                        exportedAt: Date(),
                        folders: [],
                        prompts: selectedPrompts.map { p in
                            PromptBackup(
                                id: p.id,
                                folderId: p.folderId,
                                title: p.title,
                                prompt: p.prompt,
                                description: p.description,
                                notes: p.notes,
                                emoji: p.emoji,
                                color: p.color,
                                isFavorite: p.isFavorite,
                                sortOrder: p.sortOrder,
                                createdAt: p.createdAt,
                                updatedAt: p.updatedAt
                            )
                        }
                    )
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    let data = try encoder.encode(backup)
                    try data.write(to: url)
                    appState.selectedPromptIds.removeAll()
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }

    @ViewBuilder
    private func promptList(prompts: [Prompt], title: String) -> some View {
        if prompts.isEmpty {
            EmptyContentView(
                message: appState.searchQuery.isEmpty
                    ? "No prompts yet. Create one with the + button."
                    : "No matching prompts"
            )
        } else {
            List(selection: $appState.selectedPromptId) {
                ForEach(Array(prompts.enumerated()), id: \.element.id) { index, prompt in
                    PromptRowView(
                        prompt: prompt,
                        isSelected: appState.selectedPromptId == prompt.id,
                        isChecked: appState.selectedPromptIds.contains(prompt.id),
                        onSelect: {
                            appState.selectedPromptId = prompt.id
                            if appState.autoCopyOnSelect {
                                ClipboardService.copyToClipboard(prompt.prompt)
                            }
                        },
                        onToggleFavorite: {
                            appState.toggleFavorite(prompt)
                        },
                        onToggleSelection: {
                            let isShift = NSEvent.modifierFlags.contains(.shift)
                            if isShift, let last = lastSelectedIndex {
                                let range = min(last, index)...max(last, index)
                                for i in range {
                                    appState.selectedPromptIds.insert(prompts[i].id)
                                }
                            } else {
                                if appState.selectedPromptIds.contains(prompt.id) {
                                    appState.selectedPromptIds.remove(prompt.id)
                                } else {
                                    appState.selectedPromptIds.insert(prompt.id)
                                }
                            }
                            lastSelectedIndex = index
                        }
                    )
                    .tag(prompt.id)
                    .contextMenu {
                        Button("Copy Prompt") {
                            ClipboardService.copyToClipboard(prompt.prompt)
                        }
                        Button(prompt.isFavorite ? "Remove from Favourites" : "Add to Favourites") {
                            appState.toggleFavorite(prompt)
                        }
                        Button("Change Emoji") {
                            showEmojiPickerForPromptId = prompt.id
                        }
                        Button("Change Color") {
                            showColorPickerForPromptId = prompt.id
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            appState.deletePrompt(prompt)
                        }
                    }
                    .draggable(prompt.id)
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .background(theme.uiBackgroundColor)
        }
    }
}
