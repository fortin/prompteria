import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure Application Support directory exists
        _ = DatabaseManager.shared
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard url.scheme == "prompteria" else { continue }
            if url.host == "prompt" {
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                if let id = pathComponents.first {
                    application.activate(ignoringOtherApps: true)
                    NotificationCenter.default.post(
                        name: .openPromptFromURL,
                        object: nil,
                        userInfo: ["promptId": id]
                    )
                }
            } else if url.host == "copy-prompt" {
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                if let id = pathComponents.first {
                    application.activate(ignoringOtherApps: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        FillTemplateService.copyPromptToClipboard(promptId: id)
                    }
                }
            } else if url.host == "fill-template" {
                application.activate(ignoringOtherApps: true)
                var prompt: String?
                var title: String?
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let fileParam = components.queryItems?.first(where: { $0.name == "file" })?.value,
                   let path = fileParam.removingPercentEncoding,
                   let content = try? String(contentsOfFile: path, encoding: .utf8) {
                    if let data = content.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        prompt = json["prompt"] as? String
                        title = json["title"] as? String
                    } else {
                        prompt = content
                    }
                    try? FileManager.default.removeItem(atPath: path)
                } else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                          let encoded = components.queryItems?.first(where: { $0.name == "prompt" })?.value,
                          let decoded = decodeBase64URL(encoded) {
                    prompt = decoded
                }
                if let p = prompt, !p.isEmpty {
                    DispatchQueue.main.async {
                        FillTemplateService.showFillTemplateWindow(prompt: p, title: title)
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    static let openPromptFromURL = Notification.Name("openPromptFromURL")
}

private func decodeBase64URL(_ string: String) -> String? {
    var base64 = string
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let padding = base64.count % 4
    if padding > 0 {
        base64 += String(repeating: "=", count: 4 - padding)
    }
    guard let data = Data(base64Encoded: base64) else { return nil }
    return String(data: data, encoding: .utf8)
}
