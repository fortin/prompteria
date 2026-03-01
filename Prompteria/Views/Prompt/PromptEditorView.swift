import SwiftUI

struct PromptEditorView: View {
    @Binding var prompt: Prompt
    let onSave: () -> Void
    @EnvironmentObject var appState: AppState

    @State private var promptEditorHeight: CGFloat = 120
    @State private var notesEditorHeight: CGFloat = 80
    @State private var resizeStartHeight: CGFloat?

    private let minEditorHeight: CGFloat = 80
    private let maxEditorHeight: CGFloat = 400

    var body: some View {
        ScrollView {
            Form {
                Section("Title") {
                    TextField("Prompt title", text: $prompt.title)
                        .onChange(of: prompt.title) { _, _ in onSave() }
                }
                Section("Prompt") {
                    resizableEditorSection(
                        height: $promptEditorHeight,
                        content: {
                            SyntaxHighlightedEditor(
                                text: $prompt.prompt,
                                theme: appState.currentTheme
                            )
                            .onChange(of: prompt.prompt) { _, _ in onSave() }
                        }
                    )
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
                    resizableEditorSection(
                        height: $notesEditorHeight,
                        content: {
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
                            .onChange(of: prompt.notes) { _, _ in onSave() }
                        }
                    )
                }
            }
            .formStyle(.grouped)
        }
        .scrollIndicators(.visible)
    }

    @ViewBuilder
    private func resizableEditorSection<Content: View>(
        height: Binding<CGFloat>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            content()
                .frame(height: height.wrappedValue)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            resizeHandle(height: height)
        }
    }

    private func resizeHandle(height: Binding<CGFloat>) -> some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 8)
            .overlay(
                Rectangle()
                    .fill(.tertiary)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            )
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    NSCursor.resizeUpDown.push()
                case .ended:
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if resizeStartHeight == nil {
                            resizeStartHeight = height.wrappedValue
                        }
                        let baseHeight = resizeStartHeight ?? height.wrappedValue
                        let newHeight = baseHeight + value.translation.height
                        height.wrappedValue = min(max(newHeight, minEditorHeight), maxEditorHeight)
                    }
                    .onEnded { _ in
                        resizeStartHeight = nil
                    }
            )
    }
}
