import SwiftUI

struct PromptRowView: View {
    @Environment(\.appTheme) private var theme
    let prompt: Prompt
    let isSelected: Bool
    let isChecked: Bool
    let onSelect: () -> Void
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleSelection: () -> Void
    var onMoveToFolder: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            if let onMoveToFolder {
                MoveToFolderButton(onTap: onMoveToFolder)
            }

            Button {
                onToggleSelection()
            } label: {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)

            Button {
                onToggleFavorite()
            } label: {
                Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(prompt.isFavorite ? theme.uiAccentColor : theme.uiSecondaryTextColor)
            }
            .buttonStyle(.plain)

            if let emoji = prompt.emoji {
                Text(emoji)
            }
            if let colorHex = prompt.color, let color = Color(hex: colorHex) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(prompt.title)
                    .lineLimit(1)
                    .font(.headline)
                if let description = prompt.description, !description.isEmpty {
                    Text(description)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(theme.uiSecondaryTextColor)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture(count: 1).onEnded { onSelect() })
        .simultaneousGesture(TapGesture(count: 2).onEnded { onCopy() })
    }
}

private struct MoveToFolderButton: View {
    @Environment(\.appTheme) private var theme
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "folder")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isHovered ? theme.uiAccentColor : theme.uiSecondaryTextColor)
                .frame(minWidth: 28, minHeight: 24)
                .contentShape(Rectangle())
                .opacity(isHovered ? 1 : 0.7)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("Move to folder")
    }
}
