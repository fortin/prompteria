import SwiftUI

struct PromptEditorView: View {
    @Binding var prompt: Prompt
    let onSave: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Title") {
                TextField("Prompt title", text: $prompt.title)
                    .onChange(of: prompt.title) { _, _ in onSave() }
            }
            Section("Prompt") {
                SyntaxHighlightedEditor(
                    text: $prompt.prompt,
                    theme: appState.currentTheme
                )
                .frame(minHeight: 120)
                .onChange(of: prompt.prompt) { _, _ in onSave() }
            }
            Section("Description") {
                ZStack(alignment: .topLeading) {
                    if (prompt.description ?? "").isEmpty {
                        Text("What does this prompt do?")
                            .foregroundStyle(.tertiary)
                            .font(.system(.body))
                            .padding(.leading, 5)
                            .padding(.top, 8)
                            .offset(y: -8)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: Binding(
                        get: { prompt.description ?? "" },
                        set: { newValue in
                            var updated = prompt
                            updated.description = newValue.isEmpty ? nil : newValue
                            prompt = updated
                        }
                    ))
                    .font(.system(.body))
                    .frame(minHeight: 44)
                    .scrollContentBackground(.hidden)
                    .onChange(of: prompt.description) { _, _ in onSave() }
                }
            }
            Section("Notes") {
                SyntaxHighlightedEditor(
                    text: Binding(
                        get: { prompt.notes ?? "" },
                        set: { newValue in
                            var updated = prompt
                            updated.notes = newValue.isEmpty ? nil : newValue
                            prompt = updated
                        }
                    ),
                    theme: appState.currentTheme
                )
                .frame(minHeight: 80)
                .onChange(of: prompt.notes) { _, _ in onSave() }
            }
        }
        .formStyle(.grouped)
    }
}
