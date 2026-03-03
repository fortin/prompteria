import AppKit
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.appTheme) private var theme
    @State private var editingFolderId: String?
    @State private var editingName: String = ""
    @State private var showEmojiPickerForFolderId: String?
    @State private var showColorPickerForFolderId: String?

    private static let favoritesId = "__FAVORITES__"
    private static let allPromptsId = "__ALL__"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                navButton(title: "Favourites", icon: "star.fill", id: Self.favoritesId) {
                    appState.showFavoritesOnly = true
                    appState.selectedFolderId = nil
                    appState.sidebarSelection = Self.favoritesId
                }

                navButton(title: "All Prompts", icon: "square.stack", id: Self.allPromptsId) {
                    appState.showFavoritesOnly = false
                    appState.selectedFolderId = nil
                    appState.sidebarSelection = Self.allPromptsId
                }

                Text("Folders")
                    .font(.headline)
                    .foregroundStyle(theme.uiSecondaryTextColor)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                ForEach(appState.folders) { folder in
                    if editingFolderId == folder.id {
                        TextField("Folder name", text: $editingName)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .onSubmit {
                                if !editingName.isEmpty {
                                    var updated = folder
                                    updated.name = editingName
                                    appState.updateFolder(updated)
                                }
                                editingFolderId = nil
                            }
                    } else {
                        folderRow(folder: folder)
                    }
                }
            }
        }
        .background(theme.uiBackgroundColor)
        .onChange(of: appState.sidebarSelection) { _, newValue in
            if newValue == Self.favoritesId {
                appState.showFavoritesOnly = true
                appState.selectedFolderId = nil
            } else if newValue == Self.allPromptsId {
                appState.showFavoritesOnly = false
                appState.selectedFolderId = nil
            } else if let folderId = newValue, !folderId.isEmpty {
                appState.showFavoritesOnly = false
                appState.selectedFolderId = folderId
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.createNewFolder()
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .navigationTitle("Prompteria")
        .popover(isPresented: Binding(
            get: { showEmojiPickerForFolderId != nil },
            set: { if !$0 { showEmojiPickerForFolderId = nil } }
        )) {
            if let folderId = showEmojiPickerForFolderId {
                EmojiPickerView { emoji in
                    if let folder = appState.folders.first(where: { $0.id == folderId }) {
                        var updated = folder
                        updated.emoji = emoji
                        appState.updateFolder(updated)
                    }
                    showEmojiPickerForFolderId = nil
                }
            }
        }
        .popover(isPresented: Binding(
            get: { showColorPickerForFolderId != nil },
            set: { if !$0 { showColorPickerForFolderId = nil } }
        )) {
            if let folderId = showColorPickerForFolderId {
                ColorPickerView { colorHex in
                    if let folder = appState.folders.first(where: { $0.id == folderId }) {
                        var updated = folder
                        updated.color = colorHex
                        appState.updateFolder(updated)
                    }
                    showColorPickerForFolderId = nil
                }
            }
        }
    }

    private func navButton(title: String, icon: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(appState.sidebarSelection == id ? theme.uiSelectionColor.opacity(0.3) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func folderRow(folder: Folder) -> some View {
        let isSelected = appState.selectedFolderId == folder.id
        FolderRowView(
            folder: folder,
            isSelected: isSelected
        ) {
            appState.showFavoritesOnly = false
            appState.selectedFolderId = folder.id
            appState.sidebarSelection = folder.id
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? theme.uiSelectionColor.opacity(0.3) : Color.clear)
        .contentShape(Rectangle())
        .draggable("folder:\(folder.id)")
        .dropDestination(for: String.self) { items, _ in
            guard let id = items.first, id.hasPrefix("folder:") else { return false }
            let draggedFolderId = String(id.dropFirst("folder:".count))
            guard let fromIndex = appState.folders.firstIndex(where: { $0.id == draggedFolderId }),
                  let toIndex = appState.folders.firstIndex(where: { $0.id == folder.id }),
                  fromIndex != toIndex else { return false }
            var folders = appState.folders
            let moved = folders.remove(at: fromIndex)
            let newToIndex = toIndex > fromIndex ? toIndex - 1 : toIndex
            folders.insert(moved, at: newToIndex)
            appState.setFolders(folders)
            Task {
                do {
                    try await FolderService().reorderFolders(folders)
                    appState.refresh()
                } catch {
                    appState.refresh()
                }
            }
            return true
        }
        .contextMenu {
            Button("Rename") {
                editingName = folder.name
                editingFolderId = folder.id
            }
            Button("Change Emoji") {
                showEmojiPickerForFolderId = folder.id
            }
            Button("Change Color") {
                showColorPickerForFolderId = folder.id
            }
            Button("New Prompt", role: .none) {
                appState.createNewPrompt(in: folder.id)
            }
            Divider()
            Button("Delete", role: .destructive) {
                appState.deleteFolder(folder)
            }
        }
    }
}

struct FolderRowView: View {
    let folder: Folder
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                if let emoji = folder.emoji {
                    Text(emoji)
                }
                if let colorHex = folder.color, let color = Color(hex: colorHex) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                Text(folder.name)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
