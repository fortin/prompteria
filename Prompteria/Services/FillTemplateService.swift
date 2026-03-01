import AppKit
import SwiftUI
import GRDB
import UserNotifications

enum FillTemplateService {
    /// Loads prompt by ID from database, shows fill dialog if variables, copies to clipboard.
    static func copyPromptToClipboard(promptId: String) {
        let promptRecord: Prompt? = try? DatabaseManager.shared.dbQueue.read { db in
            try Prompt.fetchOne(db, key: promptId)
        }
        guard let record = promptRecord else { return }
        showFillTemplateWindow(prompt: record.prompt, title: record.title)
    }

    /// Extracts variable names from template in order of first appearance.
    static func extractVariables(from prompt: String) -> [String] {
        let pattern = #"\{\{\s*([^}]+)\s*\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(prompt.startIndex..., in: prompt)
        var ordered: [String] = []
        var seen: Set<String> = []
        regex.enumerateMatches(in: prompt, range: nsRange) { match, _, _ in
            guard let match, match.numberOfRanges >= 2,
                  let nameRange = Range(match.range(at: 1), in: prompt) else { return }
            let name = String(prompt[nameRange]).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty, !seen.contains(name) {
                seen.insert(name)
                ordered.append(name)
            }
        }
        return ordered
    }

    /// Shows a window to fill template variables, then copies result to clipboard.
    /// - Parameters:
    ///   - prompt: The prompt text (with optional {{ variables }})
    ///   - title: Optional prompt title for the notification (e.g. "My Prompt" → "My Prompt copied to clipboard")
    static func showFillTemplateWindow(prompt: String, title: String? = nil) {
        let displayTitle = title ?? "Prompt"
        let variables = extractVariables(from: prompt)
        if variables.isEmpty {
            ClipboardService.copyToClipboard(prompt)
            showCopiedNotification(title: displayTitle)
            return
        }

        let themeId = UserDefaults.standard.string(forKey: "selectedThemeId") ?? "system-dark"
        let theme = ThemeService.shared.theme(withId: themeId) ?? AppTheme.systemDark

        let rowHeight: CGFloat = 52
        let header: CGFloat = 44
        let buttons: CGFloat = 44
        let padding: CGFloat = 40
        let height = min(header + CGFloat(variables.count) * rowHeight + buttons + padding, 450)
        let width: CGFloat = 360

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Prompteria: Template Variables"
        window.isReleasedWhenClosed = false

        let view = FillTemplateView(
            prompt: prompt,
            variables: variables,
            theme: theme,
            onComplete: { result in
                ClipboardService.copyToClipboard(result)
                showCopiedNotification(title: displayTitle)
                window.close()
            },
            onCancel: {
                window.close()
            }
        )
        window.contentView = NSHostingView(rootView: view)
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private static func showCopiedNotification(title: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = "Copied to clipboard"
            content.subtitle = "Prompteria"
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request) { _ in }
        }
    }
}
