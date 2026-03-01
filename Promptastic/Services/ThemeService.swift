import Foundation

/// Loads and discovers Xcode-compatible .xccolortheme files.
final class ThemeService {
    static let shared = ThemeService()

    /// Search paths for themes (in order of precedence).
    private var searchPaths: [URL] {
        [
            applicationSupportThemesURL,
            xcodeUserThemesURL,
            documentsThemesURL,
        ]
    }

    private var applicationSupportThemesURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Promptastic", isDirectory: true)
            .appendingPathComponent("Themes", isDirectory: true)
    }

    private var xcodeUserThemesURL: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Developer", isDirectory: true)
            .appendingPathComponent("Xcode", isDirectory: true)
            .appendingPathComponent("UserData", isDirectory: true)
            .appendingPathComponent("FontAndColorThemes", isDirectory: true)
    }

    private var documentsThemesURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Promptastic", isDirectory: true)
            .appendingPathComponent("Themes", isDirectory: true)
    }

    private init() {
        ensureThemesDirectoryExists()
    }

    private func ensureThemesDirectoryExists() {
        try? FileManager.default.createDirectory(at: applicationSupportThemesURL, withIntermediateDirectories: true)
    }

    /// All available themes: built-in first, then discovered .xccolortheme files.
    func loadThemes() -> [AppTheme] {
        var themes: [AppTheme] = AppTheme.builtInThemes
        var seenIds = Set(themes.map(\.id))

        for baseURL in searchPaths {
            guard let enumerator = FileManager.default.enumerator(
                at: baseURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for case let url as URL in enumerator {
                guard url.pathExtension == "xccolortheme",
                      let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey]),
                      resourceValues.isRegularFile == true
                else { continue }

                if let theme = AppTheme.load(from: url), !seenIds.contains(theme.id) {
                    seenIds.insert(theme.id)
                    themes.append(theme)
                }
            }
        }

        return themes
    }

    /// Load a theme by ID from all known sources.
    func theme(withId id: String) -> AppTheme? {
        if let builtIn = AppTheme.builtInThemes.first(where: { $0.id == id }) {
            return builtIn
        }
        for baseURL in searchPaths {
            guard let enumerator = FileManager.default.enumerator(
                at: baseURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }
            for case let url as URL in enumerator {
                guard url.pathExtension == "xccolortheme",
                      url.deletingPathExtension().lastPathComponent == id
                else { continue }
                return AppTheme.load(from: url)
            }
        }
        return nil
    }

    /// Copy a .xccolortheme file into the app's Themes folder for persistence.
    func importTheme(from sourceURL: URL) -> AppTheme? {
        let name = sourceURL.deletingPathExtension().lastPathComponent
        let destURL = applicationSupportThemesURL.appendingPathComponent("\(name).xccolortheme")
        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            return AppTheme.load(from: destURL)
        } catch {
            return nil
        }
    }
}
