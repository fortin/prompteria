import SwiftUI

struct PromptRowView: View {
    let prompt: Prompt
    let isSelected: Bool
    let isChecked: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleSelection: () -> Void

    var body: some View {
        HStack(spacing: 8) {
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
                    .foregroundStyle(prompt.isFavorite ? .yellow : .secondary)
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
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
