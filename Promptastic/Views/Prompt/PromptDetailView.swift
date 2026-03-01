import SwiftUI

struct PromptDetailView: View {
    @EnvironmentObject var appState: AppState
    @State var prompt: Prompt
    @State private var isEditing = true
    @State private var showEmojiPicker = false
    @State private var showColorPicker = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            if isEditing {
                PromptEditorView(
                    prompt: $prompt,
                    onSave: {
                        appState.updatePrompt(prompt)
                    }
                )
            } else {
                FormatPreviewView(content: prompt.prompt, theme: appState.currentTheme)
            }
        }
        .frame(minWidth: 300, minHeight: 200)
        .popover(isPresented: $showEmojiPicker) {
            EmojiPickerView { emoji in
                prompt.emoji = emoji
                appState.updatePrompt(prompt)
                showEmojiPicker = false
            }
        }
        .popover(isPresented: $showColorPicker) {
            ColorPickerView { colorHex in
                prompt.color = colorHex
                appState.updatePrompt(prompt)
                showColorPicker = false
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Picker("", selection: $isEditing) {
                Text("Editor").tag(true)
                Text("Preview").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            Spacer()

            Button {
                showEmojiPicker = true
            } label: {
                if let emoji = prompt.emoji {
                    Text(emoji)
                } else {
                    Image(systemName: "face.smiling")
                }
            }
            .buttonStyle(.plain)

            if let colorHex = prompt.color, Color(hex: colorHex) != nil {
                Circle()
                    .fill(Color(hex: colorHex)!)
                    .frame(width: 16, height: 16)
            }
            Button {
                showColorPicker = true
            } label: {
                Image(systemName: "paintpalette")
            }

            Button {
                ClipboardService.copyToClipboard(prompt.prompt)
            } label: {
                Image(systemName: "doc.on.doc")
            }

            Button {
                appState.toggleFavorite(prompt)
            } label: {
                Image(systemName: prompt.isFavorite ? "star.fill" : "star")
            }
        }
        .padding(8)
    }
}
