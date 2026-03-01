import SwiftUI

struct FillTemplateView: View {
    let prompt: String
    let variables: [String]
    let theme: AppTheme
    let onComplete: (String) -> Void
    let onCancel: () -> Void

    @State private var values: [String: String] = [:]
    @FocusState private var focusedField: Int?

    private var contentHeight: CGFloat {
        let rowHeight: CGFloat = 52
        let header: CGFloat = 44
        let buttons: CGFloat = 44
        let padding: CGFloat = 40
        return header + CGFloat(variables.count) * rowHeight + buttons + padding
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Template Variables")
                .font(.headline)
                .foregroundStyle(theme.uiTextColor)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(variables.enumerated()), id: \.element) { index, name in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(name):")
                            .font(.subheadline)
                            .foregroundStyle(theme.uiSecondaryTextColor)
                        TextField("", text: Binding(
                            get: { values[name] ?? "" },
                            set: { values[name] = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(theme.uiTertiaryBackgroundColor)
                        .foregroundStyle(theme.uiTextColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(theme.uiSecondaryTextColor.opacity(0.3), lineWidth: 1)
                        )
                        .focused($focusedField, equals: index)
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(theme.uiTextColor)
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("OK") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.uiAccentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360, height: min(contentHeight, 450))
        .background(theme.uiBackgroundColor)
        .preferredColorScheme(theme.colorScheme == .dark ? .dark : .light)
        .onAppear {
            for v in variables {
                if values[v] == nil { values[v] = "" }
            }
            focusedField = 0
        }
    }

    private func submit() {
        let pattern = #"\{\{\s*([^}]+)\s*\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            onComplete(prompt)
            return
        }
        let nsRange = NSRange(prompt.startIndex..., in: prompt)
        var result = prompt
        let matches = regex.matches(in: prompt, range: nsRange)
        for match in matches.reversed() {
            guard match.numberOfRanges >= 2,
                  let fullRange = Range(match.range, in: prompt),
                  let nameRange = Range(match.range(at: 1), in: prompt) else { continue }
            let name = String(prompt[nameRange]).trimmingCharacters(in: .whitespaces)
            let value = values[name] ?? ""
            result.replaceSubrange(fullRange, with: value)
        }
        onComplete(result)
    }
}
