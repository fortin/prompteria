import SwiftUI

struct BulkActionsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    let selectedPrompts: [Prompt]
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("\(selectedPrompts.count) prompts selected")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Move to Folder") {
                    // TODO: Show folder picker
                    onAction()
                }
                Button("Export") {
                    // TODO: Export selected
                    onAction()
                }
                Button("Delete", role: .destructive) {
                    for prompt in selectedPrompts {
                        appState.deletePrompt(prompt)
                    }
                    appState.selectedPromptIds.removeAll()
                    isPresented = false
                    onAction()
                }
                Button("Cancel") {
                    isPresented = false
                    onAction()
                }
            }
        }
        .padding(20)
    }
}
