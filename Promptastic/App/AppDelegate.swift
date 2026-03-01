import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure Application Support directory exists
        _ = DatabaseManager.shared
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "promptastic", url.host == "prompt" {
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                if let id = pathComponents.first {
                    application.activate(ignoringOtherApps: true)
                    NotificationCenter.default.post(
                        name: .openPromptFromURL,
                        object: nil,
                        userInfo: ["promptId": id]
                    )
                }
            }
        }
    }
}

extension Notification.Name {
    static let openPromptFromURL = Notification.Name("openPromptFromURL")
}
