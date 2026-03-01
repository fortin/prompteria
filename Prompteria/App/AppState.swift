import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppState: ObservableObject {
    static let allPromptsId = "__ALL__"

    @Published var folders: [Folder] = []
    @Published var prompts: [Prompt] = []
    @Published var favorites: [Prompt] = []
    @Published var selectedFolderId: String? = nil
    @Published var sidebarSelection: String? = "__ALL__"
    @Published var selectedPromptId: String? = nil
    @Published var searchQuery: String = ""
    @Published var selectedPromptIds: Set<String> = []
    @Published var showFavoritesOnly: Bool = false
    @Published var themeOverride: ThemeOverride = .system
    @Published var selectedThemeId: String = "system-dark"
    @Published var autoCopyOnSelect: Bool = false
    @Published var promptToOpenFromURL: String? = nil
    @Published var promptSortOption: PromptSortOption = .dateModified

    private let folderService = FolderService()
    private let promptService = PromptService()
    private var refreshTask: Task<Void, Never>?

    init() {
        loadSettings()
        setupURLHandler()
    }

    private func loadSettings() {
        themeOverride = ThemeOverride(rawValue: UserDefaults.standard.string(forKey: "themeOverride") ?? "") ?? .system
        autoCopyOnSelect = UserDefaults.standard.bool(forKey: "autoCopyOnSelect")
        selectedThemeId = UserDefaults.standard.string(forKey: "selectedThemeId") ?? "system-dark"
        promptSortOption = PromptSortOption(rawValue: UserDefaults.standard.string(forKey: "promptSortOption") ?? "") ?? .dateModified
    }

    private func setupURLHandler() {
        NotificationCenter.default.addObserver(
            forName: .openPromptFromURL,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let id = notification.userInfo?["promptId"] as? String {
                MainActor.assumeIsolated {
                    self?.promptToOpenFromURL = id
                }
            }
        }
    }

    var selectedPrompt: Prompt? {
        guard let id = selectedPromptId else { return nil }
        return prompts.first { $0.id == id } ?? favorites.first { $0.id == id }
    }

    var displayedPrompts: [Prompt] {
        if showFavoritesOnly {
            return sortedFavorites
        }
        return sortedPrompts
    }

    var sortedPrompts: [Prompt] {
        sortPrompts(prompts)
    }

    var sortedFavorites: [Prompt] {
        sortPrompts(favorites)
    }

    private func sortPrompts(_ prompts: [Prompt]) -> [Prompt] {
        switch promptSortOption {
        case .alphabetical:
            return prompts.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .dateCreated:
            return prompts.sorted { $0.createdAt > $1.createdAt }
        case .dateModified:
            return prompts.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    func setPromptSortOption(_ option: PromptSortOption) {
        promptSortOption = option
        UserDefaults.standard.set(option.rawValue, forKey: "promptSortOption")
    }

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            await loadData()
        }
    }

    /// Clears prompts to avoid showing stale data when switching folders/search.
    func clearPromptsForReload() {
        prompts = []
    }

    func loadData() async {
        do {
            folders = try await folderService.fetchFolders()
            favorites = try await promptService.fetchFavorites()

            if showFavoritesOnly {
                prompts = []
            } else if searchQuery.isEmpty {
                prompts = try await promptService.fetchPrompts(in: selectedFolderId)
            } else {
                prompts = try await promptService.searchPrompts(query: searchQuery, folderId: selectedFolderId)
            }

            if let promptId = promptToOpenFromURL {
                selectedPromptId = promptId
                showFavoritesOnly = false
                if let prompt = prompts.first(where: { $0.id == promptId }) ?? favorites.first(where: { $0.id == promptId }) {
                    selectedFolderId = prompt.folderId
                    await loadData()
                }
                promptToOpenFromURL = nil
            }
        } catch {
            print("Failed to load data: \(error)")
        }
    }

    func createNewPrompt() {
        guard let folderId = selectedFolderId ?? folders.first?.id else { return }
        let prompt = Prompt(folderId: folderId, title: "New Prompt", prompt: "")
        Task {
            try? await promptService.create(prompt)
            refresh()
            selectedPromptId = prompt.id
        }
    }

    func createNewFolder() {
        let folder = Folder(name: "New Folder")
        Task {
            try? await folderService.create(folder)
            refresh()
            selectedFolderId = folder.id
            sidebarSelection = folder.id
        }
    }

    func createNewPrompt(in folderId: String) {
        let prompt = Prompt(folderId: folderId, title: "New Prompt", prompt: "")
        Task {
            try? await promptService.create(prompt)
            refresh()
            selectedPromptId = prompt.id
        }
    }

    func duplicatePrompt(_ prompt: Prompt) {
        let copy = Prompt(
            folderId: prompt.folderId,
            title: prompt.title + " (Copy)",
            prompt: prompt.prompt,
            description: prompt.description,
            notes: prompt.notes,
            emoji: prompt.emoji,
            color: prompt.color,
            isFavorite: false
        )
        Task {
            try? await promptService.create(copy)
            refresh()
            selectedPromptId = copy.id
        }
    }

    func deletePrompt(_ prompt: Prompt) {
        Task {
            try? await promptService.delete(prompt)
            if selectedPromptId == prompt.id {
                selectedPromptId = nil
            }
            refresh()
        }
    }

    func deleteFolder(_ folder: Folder) {
        Task {
            try? await folderService.delete(folder)
            if selectedFolderId == folder.id {
                selectedFolderId = nil
                selectedPromptId = nil
            }
            refresh()
        }
    }

    func toggleFavorite(_ prompt: Prompt) {
        Task {
            try? await promptService.toggleFavorite(prompt)
            refresh()
        }
    }

    func movePrompt(_ prompt: Prompt, to folderId: String) {
        Task {
            try? await promptService.movePrompt(prompt, to: folderId)
            refresh()
        }
    }

    func updatePrompt(_ prompt: Prompt) {
        Task {
            try? await promptService.update(prompt)
            refresh()
        }
    }

    func updateFolder(_ folder: Folder) {
        Task {
            try? await folderService.update(folder)
            refresh()
        }
    }

    func setFolders(_ newFolders: [Folder]) {
        folders = newFolders
    }

    func setThemeOverride(_ theme: ThemeOverride) {
        themeOverride = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "themeOverride")
    }

    func setSelectedThemeId(_ id: String) {
        selectedThemeId = id
        UserDefaults.standard.set(id, forKey: "selectedThemeId")
    }

    var currentTheme: AppTheme {
        ThemeService.shared.theme(withId: selectedThemeId) ?? .systemDark
    }

    func setAutoCopyOnSelect(_ enabled: Bool) {
        autoCopyOnSelect = enabled
        UserDefaults.standard.set(enabled, forKey: "autoCopyOnSelect")
    }

    func exportBackup() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "prompteria-backup-\(ISO8601DateFormatter().string(from: Date())).json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                do {
                    let data = try BackupService().exportToJSON()
                    try data.write(to: url)
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }

    func importBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let data = try Data(contentsOf: url)
                    try BackupService().importFromJSON(data)
                    self.refresh()
                } catch {
                    print("Import failed: \(error)")
                }
            }
        }
    }

    func importSnippets() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = "Select a snippet JSON export (categories + snippets format)"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let data = try Data(contentsOf: url)
                    try BackupService().importSnippetJSON(data)
                    self.refresh()
                } catch {
                    print("Import snippets failed: \(error)")
                }
            }
        }
    }
}

enum PromptSortOption: String, CaseIterable {
    case alphabetical = "alphabetical"
    case dateCreated = "dateCreated"
    case dateModified = "dateModified"

    var displayName: String {
        switch self {
        case .alphabetical: return "Alphabetically"
        case .dateCreated: return "Date Created"
        case .dateModified: return "Date Modified"
        }
    }
}

enum ThemeOverride: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
