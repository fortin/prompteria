import AppKit
import SwiftUI

/// A text editor with markdown-style syntax highlighting, themed via Xcode .xccolortheme format.
struct SyntaxHighlightedEditor: NSViewRepresentable {
    @Binding var text: String
    let theme: AppTheme
    var font: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular)
    var minHeight: CGFloat = 120

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = theme.sourceTextBackground

        let textView = PrompteriaTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.font = font
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.delegate = context.coordinator
        textView.theme = theme
        textView.font = font

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView

        textView.string = text
        textView.updateSelectionColor()
        context.coordinator.applyHighlighting()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PrompteriaTextView else { return }
        let coordinator = context.coordinator

        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(selectedRange)
        }

        textView.theme = theme
        textView.font = font
        scrollView.backgroundColor = theme.sourceTextBackground
        coordinator.applyHighlighting()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxHighlightedEditor
        weak var textView: PrompteriaTextView?
        weak var scrollView: NSScrollView?

        init(_ parent: SyntaxHighlightedEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            applyHighlighting()
        }

        func applyHighlighting() {
            textView?.applySyntaxHighlighting()
        }
    }
}

// MARK: - Custom NSTextView

final class PrompteriaTextView: NSTextView {
    var theme: AppTheme = .systemDark {
        didSet {
            applySyntaxHighlighting()
            updateInsertionPointColor()
            updateSelectionColor()
        }
    }

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
    }

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
    }

    override var string: String {
        didSet { applySyntaxHighlighting() }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateInsertionPointColor()
    }

    override func insertNewline(_ sender: Any?) {
        super.insertNewline(sender)
        applySyntaxHighlighting()
    }

    override func insertTab(_ sender: Any?) {
        super.insertTab(sender)
        applySyntaxHighlighting()
    }

    override func didChangeText() {
        super.didChangeText()
        applySyntaxHighlighting()
    }

    private func updateInsertionPointColor() {
        insertionPointColor = theme.sourceTextInsertionPoint
    }

    func updateSelectionColor() {
        selectedTextAttributes = [
            .backgroundColor: theme.sourceTextSelection,
            .foregroundColor: theme.syntaxPlain,
        ]
    }

    func applySyntaxHighlighting() {
        guard let textStorage = textStorage else { return }
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let str = textStorage.string

        textStorage.beginEditing()
        textStorage.setAttributes(
            [
                .foregroundColor: theme.syntaxPlain,
                .font: font ?? .monospacedSystemFont(ofSize: 13, weight: .regular),
            ],
            range: fullRange
        )

        MarkdownHighlighter.highlight(
            textStorage,
            string: str,
            theme: theme,
            baseFont: font ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
        )
        textStorage.endEditing()
    }
}

// MARK: - Markdown highlighter

private enum MarkdownHighlighter {
    static func highlight(_ textStorage: NSTextStorage, string: String, theme: AppTheme, baseFont: NSFont) {
        let nsString = string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        // Headers: # ## ### ####
        try? NSRegularExpression(pattern: "^(#{1,6})\\s+(.+)$", options: .anchorsMatchLines)
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match, match.numberOfRanges >= 3 else { return }
                let hashRange = match.range(at: 1)
                let textRange = match.range(at: 2)
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxKeyword, range: hashRange)
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxPlain, range: textRange)
            }

        // Bold: **text** or __text__
        try? NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*|__([^_]+)__")
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match else { return }
                let contentRange = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
                if contentRange.location != NSNotFound {
                    textStorage.addAttribute(.foregroundColor, value: theme.syntaxKeyword, range: contentRange)
                }
            }

        // Italic: *text* or _text_
        try? NSRegularExpression(pattern: "(?<!\\*)\\*([^*]+)\\*(?!\\*)|(?<!_)_([^_]+)_(?!_)")
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match else { return }
                let r1 = match.range(at: 1)
                let r2 = match.range(at: 2)
                let contentRange = r1.location != NSNotFound ? r1 : r2
                if contentRange.location != NSNotFound {
                    textStorage.addAttribute(.foregroundColor, value: theme.syntaxComment, range: contentRange)
                }
            }

        // Inline code: `code`
        try? NSRegularExpression(pattern: "`([^`]+)`")
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match, match.numberOfRanges >= 2 else { return }
                let contentRange = match.range(at: 1)
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxMarkup, range: contentRange)
            }

        // Fenced code blocks: ```...```
        try? NSRegularExpression(pattern: "```[^\\n]*\\n([\\s\\S]*?)```", options: .dotMatchesLineSeparators)
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match, match.numberOfRanges >= 2 else { return }
                let contentRange = match.range(at: 1)
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxMarkup, range: contentRange)
            }

        // Links: [text](url)
        try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)")
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match, match.numberOfRanges >= 3 else { return }
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxUrl, range: textRange)
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxUrl, range: urlRange)
            }

        // Bare URLs
        try? NSRegularExpression(pattern: "https?://[^\\s<>\"']+")
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match else { return }
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxUrl, range: match.range)
            }

        // Strings: "..." or '...'
        try? NSRegularExpression(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'")
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match else { return }
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxString, range: match.range)
            }

        // Template variables: {{var}} or {var}
        try? NSRegularExpression(pattern: "\\{\\{[^}]+\\}\\}|\\{[^}]+\\}")
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match else { return }
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxAttribute, range: match.range)
            }

        // Numbers (standalone)
        try? NSRegularExpression(pattern: "\\b\\d+\\.?\\d*\\b")
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match else { return }
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxNumber, range: match.range)
            }

        // List markers: - or * or 1.
        try? NSRegularExpression(pattern: "^(\\s*)([-*+]|\\d+\\.)\\s+", options: .anchorsMatchLines)
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match, match.numberOfRanges >= 3 else { return }
                let markerRange = match.range(at: 2)
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxKeyword, range: markerRange)
            }

        // Blockquote: >
        try? NSRegularExpression(pattern: "^(>+)\\s*", options: .anchorsMatchLines)
            .enumerateMatches(in: string, range: fullRange) { match, _, _ in
                guard let match, match.numberOfRanges >= 2 else { return }
                textStorage.addAttribute(.foregroundColor, value: theme.syntaxComment, range: match.range(at: 1))
            }
    }
}
