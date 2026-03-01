import SwiftUI

struct MoveToFolderSheet: View {
    @EnvironmentObject var appState: AppState
    let prompts: [Prompt]
    let folders: [Folder]
    let onMove: (String) -> Void
    let onCancel: () -> Void
    @State private var selectedFolderId: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Move \(prompts.count) prompt(s) to folder")
                .font(.headline)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(folders.enumerated()), id: \.element.id) { _, folder in
                        Button {
                            selectedFolderId = folder.id
                        } label: {
                            HStack {
                                if let emoji = folder.emoji {
                                    Text(emoji)
                                }
                                Text(folder.name)
                                Spacer()
                                if selectedFolderId == folder.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 200)

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Move") {
                    if let folderId = selectedFolderId {
                        onMove(folderId)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFolderId == nil)
            }
        }
        .padding(20)
        .frame(width: 300)
    }
}
