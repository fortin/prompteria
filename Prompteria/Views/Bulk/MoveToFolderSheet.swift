import SwiftUI

struct MoveToFolderSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.appTheme) private var theme
    let prompts: [Prompt]
    let folders: [Folder]
    let onMove: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Move \(prompts.count) prompt\(prompts.count == 1 ? "" : "s") to folder")
                .font(.headline)
                .foregroundStyle(theme.uiTextColor)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(folders) { folder in
                        folderButton(folder)
                    }
                }
            }
            .frame(height: 200)

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(theme.uiTextColor)
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(theme.uiBackgroundColor)
        .preferredColorScheme(theme.colorScheme == .dark ? .dark : .light)
    }

    private func folderButton(_ folder: Folder) -> some View {
        FolderButtonView(
            folder: folder,
            theme: theme,
            onTap: { onMove(folder.id) }
        )
    }
}

private struct FolderButtonView: View {
    let folder: Folder
    let theme: AppTheme
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if let emoji = folder.emoji {
                    Text(emoji)
                        .font(.body)
                } else {
                    Image(systemName: "folder.fill")
                        .font(.body)
                        .foregroundStyle(theme.uiSecondaryTextColor)
                }
                if let colorHex = folder.color, let color = Color(hex: colorHex) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                Text(folder.name)
                    .foregroundStyle(theme.uiTextColor)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isHovered ? theme.uiAccentColor : theme.uiSecondaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? theme.uiSelectionColor.opacity(0.3) : theme.uiSecondaryBackgroundColor)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
