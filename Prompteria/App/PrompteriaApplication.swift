import AppKit

/// Custom NSApplication subclass that exposes `currentPromptURL` for AppleScript/Hookmark.
final class PrompteriaApplication: NSApplication {
    override func value(forKey key: String) -> Any? {
        if key == "selectedPromptURL" {
            if let current = ScriptingBridge.shared.getCurrentPrompt() {
                return "prompteria://prompt/\(current.id)"
            }
            return ""
        }
        return super.value(forKey: key)
    }
}
