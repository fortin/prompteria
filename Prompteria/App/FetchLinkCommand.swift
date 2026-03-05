import AppKit

/// AppleScript command that returns the URL of the currently selected prompt.
/// Invoked as: tell application "Prompteria" to fetch link
final class FetchLinkCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        if let current = ScriptingBridge.shared.getCurrentPrompt() {
            return "prompteria://prompt/\(current.id)"
        }
        return ""
    }
}
