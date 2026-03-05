import Foundation

/// Bridge for external access (URL handlers, Hookmark, AppleScript) to the currently selected prompt.
/// AppState updates this whenever selection changes so AppDelegate can read it synchronously.
final class ScriptingBridge {
    static let shared = ScriptingBridge()

    private let queue = DispatchQueue(label: "com.prompteria.scriptingbridge", qos: .userInteractive)

    private(set) var currentPromptId: String?
    private(set) var currentPromptTitle: String?

    private init() {}

    /// Thread-safe update. Call from main actor or any queue.
    func update(currentPromptId: String?, currentPromptTitle: String?) {
        queue.sync {
            self.currentPromptId = currentPromptId
            self.currentPromptTitle = currentPromptTitle
        }
    }

    /// Thread-safe read. Used by AppDelegate when handling URLs.
    func getCurrentPrompt() -> (id: String, title: String)? {
        queue.sync {
            guard let id = currentPromptId, let title = currentPromptTitle else { return nil }
            return (id, title)
        }
    }
}
