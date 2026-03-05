import AppKit

/// AppleScript command that returns the URL (or Markdown link) of the currently selected prompt.
/// Invoked as: tell application "Prompteria" to fetch link
/// Returns a Markdown link [Title](url) so Hookmark displays the title with URL as subtitle.
final class FetchLinkCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if let current = ScriptingBridge.shared.getCurrentPrompt() {
            let url = "prompteria://prompt/\(current.id)"
            let escapedTitle = current.title
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "]", with: "\\]")
            return "[\(escapedTitle)](\(url))"
        }
        return ""
    }
}
