import AppKit

/// Custom NSApplication subclass that exposes `selectedPromptLink` for AppleScript/Hookmark.
/// @objc exposes the class to the ObjC runtime so NSPrincipalClass can find it.
@objc(PrompteriaApplication)
final class PrompteriaApplication: NSApplication {
    override func value(forKey key: String) -> Any? {
        if key == "selectedPromptLink" {
            if let current = ScriptingBridge.shared.getCurrentPrompt() {
                return "prompteria://prompt/\(current.id)"
            }
            return ""
        }
        return super.value(forKey: key)
    }
}
