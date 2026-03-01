import AppKit
import SwiftUI

// MARK: - Environment

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .systemDark
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

/// Represents an Xcode-compatible color theme (.xccolortheme).
/// Supports both editor syntax highlighting and UI skin colors.
struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let sourceURL: URL?
    let isBuiltIn: Bool

    // MARK: - Editor colors (from DVTSourceText*)
    let sourceTextBackground: NSColor
    let sourceTextSelection: NSColor
    let sourceTextInsertionPoint: NSColor
    let sourceTextCurrentLineHighlight: NSColor
    let sourceTextPlain: NSColor

    // MARK: - Syntax colors (from DVTSourceTextSyntaxColors)
    let syntaxPlain: NSColor
    let syntaxString: NSColor
    let syntaxComment: NSColor
    let syntaxKeyword: NSColor
    let syntaxNumber: NSColor
    let syntaxMarkup: NSColor
    let syntaxUrl: NSColor
    let syntaxAttribute: NSColor

    // MARK: - UI skin colors (derived from Xcode theme)
    let uiBackground: NSColor
    let uiSecondaryBackground: NSColor
    let uiTertiaryBackground: NSColor
    let uiText: NSColor
    let uiSecondaryText: NSColor
    let uiAccent: NSColor
    let uiSelection: NSColor

    var colorScheme: ColorScheme {
        let luminance = sourceTextBackground.luminance
        return luminance < 0.5 ? .dark : .light
    }

    // MARK: - SwiftUI Color helpers
    var sourceTextBackgroundColor: Color { Color(nsColor: sourceTextBackground) }
    var sourceTextSelectionColor: Color { Color(nsColor: sourceTextSelection) }
    var sourceTextPlainColor: Color { Color(nsColor: sourceTextPlain) }
    var syntaxPlainColor: Color { Color(nsColor: syntaxPlain) }
    var syntaxStringColor: Color { Color(nsColor: syntaxString) }
    var syntaxCommentColor: Color { Color(nsColor: syntaxComment) }
    var syntaxKeywordColor: Color { Color(nsColor: syntaxKeyword) }
    var syntaxNumberColor: Color { Color(nsColor: syntaxNumber) }
    var syntaxMarkupColor: Color { Color(nsColor: syntaxMarkup) }
    var syntaxUrlColor: Color { Color(nsColor: syntaxUrl) }
    var syntaxAttributeColor: Color { Color(nsColor: syntaxAttribute) }
    var uiBackgroundColor: Color { Color(nsColor: uiBackground) }
    var uiSecondaryBackgroundColor: Color { Color(nsColor: uiSecondaryBackground) }
    var uiTertiaryBackgroundColor: Color { Color(nsColor: uiTertiaryBackground) }
    var uiTextColor: Color { Color(nsColor: uiText) }
    var uiSecondaryTextColor: Color { Color(nsColor: uiSecondaryText) }
    var uiAccentColor: Color { Color(nsColor: uiAccent) }
    var uiSelectionColor: Color { Color(nsColor: uiSelection) }
}

// MARK: - Parsing

extension AppTheme {
    /// Parse an Xcode .xccolortheme plist file.
    static func load(from url: URL) -> AppTheme? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        return parse(plist, id: url.deletingPathExtension().lastPathComponent, name: url.deletingPathExtension().lastPathComponent, sourceURL: url, isBuiltIn: false)
    }

    static func parse(_ plist: [String: Any], id: String, name: String, sourceURL: URL? = nil, isBuiltIn: Bool = false) -> AppTheme? {
        func color(_ key: String) -> NSColor {
            guard let str = plist[key] as? String else { return fallbackColor(for: key) }
            return parseColor(str) ?? fallbackColor(for: key)
        }

        func colorFromDict(_ dict: [String: Any], key: String) -> NSColor {
            guard let str = dict[key] as? String else { return fallbackColor(for: key) }
            return parseColor(str) ?? fallbackColor(for: key)
        }

        let syntaxColors = plist["DVTSourceTextSyntaxColors"] as? [String: Any] ?? [:]

        return AppTheme(
            id: id,
            name: name,
            sourceURL: sourceURL,
            isBuiltIn: isBuiltIn,
            sourceTextBackground: color("DVTSourceTextBackground"),
            sourceTextSelection: color("DVTSourceTextSelectionColor"),
            sourceTextInsertionPoint: color("DVTSourceTextInsertionPointColor"),
            sourceTextCurrentLineHighlight: color("DVTSourceTextCurrentLineHighlightColor"),
            sourceTextPlain: colorFromDict(syntaxColors, key: "xcode.syntax.plain"),
            syntaxPlain: colorFromDict(syntaxColors, key: "xcode.syntax.plain"),
            syntaxString: colorFromDict(syntaxColors, key: "xcode.syntax.string"),
            syntaxComment: colorFromDict(syntaxColors, key: "xcode.syntax.comment"),
            syntaxKeyword: colorFromDict(syntaxColors, key: "xcode.syntax.keyword"),
            syntaxNumber: colorFromDict(syntaxColors, key: "xcode.syntax.number"),
            syntaxMarkup: colorFromDict(syntaxColors, key: "xcode.syntax.markup.code"),
            syntaxUrl: colorFromDict(syntaxColors, key: "xcode.syntax.url"),
            syntaxAttribute: colorFromDict(syntaxColors, key: "xcode.syntax.attribute"),
            uiBackground: color("DVTSourceTextBackground"),
            uiSecondaryBackground: color("DVTSourceTextCurrentLineHighlightColor"),
            uiTertiaryBackground: color("DVTMarkupTextBackgroundColor"),
            uiText: colorFromDict(syntaxColors, key: "xcode.syntax.plain"),
            uiSecondaryText: color("DVTMarkupTextOtherHeadingColor"),
            uiAccent: colorFromDict(syntaxColors, key: "xcode.syntax.keyword"),
            uiSelection: color("DVTSourceTextSelectionColor")
        )
    }

    private static func parseColor(_ str: String?) -> NSColor? {
        guard let str = str else { return nil }
        let parts = str.split(separator: " ").compactMap { Double(String($0)) }
        guard parts.count >= 3 else { return nil }
        let r = CGFloat(parts[0])
        let g = CGFloat(parts[1])
        let b = CGFloat(parts[2])
        let a = parts.count >= 4 ? CGFloat(parts[3]) : 1
        return NSColor(red: r, green: g, blue: b, alpha: a)
    }

    private static func fallbackColor(for key: String) -> NSColor {
        if key.contains("Background") {
            return NSColor(white: 0.2, alpha: 1)
        }
        if key.contains("Selection") {
            return NSColor(white: 0.3, alpha: 1)
        }
        if key.contains("Heading") || key.contains("Other") {
            return NSColor(white: 0.6, alpha: 1)
        }
        return NSColor.textColor
    }
}

// MARK: - Built-in themes

extension AppTheme {
    static let draculaPro = AppTheme.parse(
        [
            "DVTSourceTextBackground": "0.133333 0.129412 0.172549 1",
            "DVTSourceTextSelectionColor": "0.270588 0.254902 0.345098 1",
            "DVTSourceTextInsertionPointColor": "1 1 1 1",
            "DVTSourceTextCurrentLineHighlightColor": "0.177292 0.1725 0.23 1",
            "DVTMarkupTextBackgroundColor": "0.188245 0.192381 0.226996 1",
            "DVTMarkupTextOtherHeadingColor": "0.877929 0.872979 0.878041 0.5",
            "DVTSourceTextSyntaxColors": [
                "xcode.syntax.plain": "0.965416 0.966618 0.933125 1",
                "xcode.syntax.string": "1 1 0.501961 1",
                "xcode.syntax.comment": "0.47451 0.439216 0.662745 1",
                "xcode.syntax.keyword": "1 0.501961 0.74902 1",
                "xcode.syntax.number": "0.584314 0.501961 1 1",
                "xcode.syntax.markup.code": "1 0.501961 0.74902 1",
                "xcode.syntax.url": "0.584314 0.501961 1 1",
                "xcode.syntax.attribute": "0.87451 0.772549 0.623529 1",
            ],
        ] as [String: Any],
        id: "dracula-pro",
        name: "Dracula Pro",
        isBuiltIn: true
    )!

    static let systemLight = AppTheme.parse(
        [
            "DVTSourceTextBackground": "1 1 1 1",
            "DVTSourceTextSelectionColor": "0.678431 0.847059 1 1",
            "DVTSourceTextInsertionPointColor": "0 0 0 1",
            "DVTSourceTextCurrentLineHighlightColor": "0.95 0.95 0.95 1",
            "DVTMarkupTextBackgroundColor": "0.97 0.97 0.97 1",
            "DVTMarkupTextOtherHeadingColor": "0.4 0.4 0.4 1",
            "DVTSourceTextSyntaxColors": [
                "xcode.syntax.plain": "0 0 0 1",
                "xcode.syntax.string": "0.8 0.2 0.2 1",
                "xcode.syntax.comment": "0.4 0.5 0.4 1",
                "xcode.syntax.keyword": "0.6 0.2 0.8 1",
                "xcode.syntax.number": "0.2 0.4 0.8 1",
                "xcode.syntax.markup.code": "0.5 0.3 0.1 1",
                "xcode.syntax.url": "0.2 0.4 0.6 1",
                "xcode.syntax.attribute": "0.6 0.4 0.2 1",
            ],
        ] as [String: Any],
        id: "system-light",
        name: "System Light",
        isBuiltIn: true
    )!

    static let systemDark = AppTheme.parse(
        [
            "DVTSourceTextBackground": "0.15 0.15 0.17 1",
            "DVTSourceTextSelectionColor": "0.25 0.4 0.55 1",
            "DVTSourceTextInsertionPointColor": "1 1 1 1",
            "DVTSourceTextCurrentLineHighlightColor": "0.2 0.2 0.22 1",
            "DVTMarkupTextBackgroundColor": "0.18 0.18 0.2 1",
            "DVTMarkupTextOtherHeadingColor": "0.6 0.6 0.6 1",
            "DVTSourceTextSyntaxColors": [
                "xcode.syntax.plain": "0.95 0.95 0.95 1",
                "xcode.syntax.string": "0.9 0.7 0.5 1",
                "xcode.syntax.comment": "0.5 0.6 0.5 1",
                "xcode.syntax.keyword": "0.8 0.6 1 1",
                "xcode.syntax.number": "0.6 0.8 1 1",
                "xcode.syntax.markup.code": "0.9 0.8 0.6 1",
                "xcode.syntax.url": "0.5 0.7 0.9 1",
                "xcode.syntax.attribute": "0.9 0.7 0.5 1",
            ],
        ] as [String: Any],
        id: "system-dark",
        name: "System Dark",
        isBuiltIn: true
    )!

    static var builtInThemes: [AppTheme] {
        [systemLight, systemDark, draculaPro]
    }
}

// MARK: - NSColor luminance

private extension NSColor {
    var luminance: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let sRGB = usingColorSpace(.sRGB) ?? self
        sRGB.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
}
