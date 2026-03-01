import Down
import SwiftUI
import WebKit

enum ContentFormat {
    case plain
    case markdown
    case html
    case json
    case xml

    static func detect(from content: String) -> ContentFormat {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .plain }
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") { return .json }
        if trimmed.hasPrefix("<?xml") || (trimmed.hasPrefix("<") && trimmed.contains(">")) {
            let tag = trimmed.dropFirst().prefix(while: { $0 != " " && $0 != ">" })
            let lower = String(tag).lowercased()
            if lower == "html" || lower == "body" || lower.hasPrefix("!doctype") {
                return .html
            }
            return .xml
        }
        if trimmed.lowercased().hasPrefix("<html") || trimmed.lowercased().hasPrefix("<body") {
            return .html
        }
        return .markdown
    }
}

struct FormatPreviewView: View {
    let content: String
    var theme: AppTheme = .systemDark

    var body: some View {
        switch ContentFormat.detect(from: content) {
        case .plain:
            Text(content)
                .textSelection(.enabled)
                .foregroundStyle(theme.syntaxPlainColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
                .background(theme.sourceTextBackgroundColor)
        case .markdown:
            MarkdownPreviewView(content: content, theme: theme)
        case .html:
            HTMLPreviewView(content: content)
                .background(theme.sourceTextBackgroundColor)
        case .json:
            JSONTreeView(content: content, theme: theme)
        case .xml:
            XMLTreeView(content: content, theme: theme)
        }
    }
}

struct MarkdownPreviewView: View {
    let content: String
    var theme: AppTheme = .systemDark

    var body: some View {
        MarkdownWebView(markdown: content, theme: theme)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.sourceTextBackgroundColor)
    }
}

private struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let theme: AppTheme

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        loadMarkdown(webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        loadMarkdown(webView)
    }

    private func loadMarkdown(_ webView: WKWebView) {
        let html: String
        do {
            let down = Down(markdownString: markdown)
            html = try down.toHTML()
        } catch {
            html = "<pre>\(markdown.htmlEscaped)</pre>"
        }
        let bg = theme.sourceTextBackground.hexCSS
        let fg = theme.syntaxPlain.hexCSS
        let fullHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.5; padding: 16px; background: \(bg); color: \(fg); }
                h1, h2, h3 { margin-top: 1em; margin-bottom: 0.5em; }
                ul, ol { margin: 0.5em 0; padding-left: 1.5em; }
                pre, code { font-family: ui-monospace, monospace; background: rgba(128,128,128,0.2); padding: 2px 4px; border-radius: 4px; }
                pre { padding: 12px; overflow-x: auto; }
                a { color: \(theme.syntaxUrl.hexCSS); }
            </style>
        </head>
        <body>\(html)</body>
        </html>
        """
        webView.loadHTMLString(fullHTML, baseURL: nil)
    }
}

private extension String {
    var htmlEscaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

struct HTMLPreviewView: View {
    let content: String

    var body: some View {
        WebView(html: content)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.loadHTMLString(wrapInHTML(html), baseURL: nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(wrapInHTML(html), baseURL: nil)
    }

    private func wrapInHTML(_ body: String) -> String {
        if body.lowercased().contains("<html") || body.lowercased().contains("<body") {
            return body
        }
        return """
        <!DOCTYPE html><html><head><meta charset="utf-8"></head><body>\(body)</body></html>
        """
    }
}

struct JSONTreeView: View {
    let content: String
    var theme: AppTheme = .systemDark

    var body: some View {
        ScrollView {
            if let data = content.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) {
                JSONNodeView(value: json, key: nil, theme: theme)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding()
            } else {
                Text(content)
                    .textSelection(.enabled)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(theme.syntaxPlainColor)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding()
            }
        }
        .background(theme.sourceTextBackgroundColor)
    }
}

struct JSONNodeView: View {
    let value: Any
    let key: String?
    var theme: AppTheme = .systemDark
    @State private var isExpanded = true

    var body: some View {
        if let dict = value as? [String: Any] {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(Array(dict.keys.sorted()), id: \.self) { k in
                    JSONNodeView(value: dict[k]!, key: k, theme: theme)
                }
            } label: {
                Text(key ?? "{}")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(theme.syntaxPlainColor)
            }
        } else if let array = value as? [Any] {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(Array(array.enumerated()), id: \.offset) { i, v in
                    JSONNodeView(value: v, key: "[\(i)]", theme: theme)
                }
            } label: {
                Text((key ?? "") + " [\(array.count)]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(theme.syntaxPlainColor)
            }
        } else {
            HStack {
                if let k = key {
                    Text(k + ":")
                        .foregroundStyle(theme.uiSecondaryTextColor)
                }
                Text(stringValue(value))
                    .foregroundStyle(colorForValue(value))
            }
            .font(.system(.body, design: .monospaced))
        }
    }

    private func stringValue(_ v: Any) -> String {
        if v is NSNull { return "null" }
        if let b = v as? Bool { return b ? "true" : "false" }
        if let n = v as? NSNumber {
            if n.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(n.intValue)"
            }
            return "\(n.doubleValue)"
        }
        if let s = v as? String { return "\"\(s)\"" }
        return "\(v)"
    }

    private func colorForValue(_ v: Any) -> Color {
        if v is NSNull { return theme.uiSecondaryTextColor }
        if v is Bool { return theme.syntaxKeywordColor }
        if v is NSNumber { return theme.syntaxNumberColor }
        if v is String { return theme.syntaxStringColor }
        return theme.syntaxPlainColor
    }
}

struct XMLTreeView: View {
    let content: String
    var theme: AppTheme = .systemDark

    var body: some View {
        ScrollView {
            if let parsed = parseXML(content) {
                XMLNodeView(node: parsed, theme: theme)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding()
            } else {
                Text(content)
                    .textSelection(.enabled)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(theme.syntaxPlainColor)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding()
            }
        }
        .background(theme.sourceTextBackgroundColor)
    }

    private func parseXML(_ xml: String) -> XMLNode? {
        guard let data = xml.data(using: .utf8) else { return nil }
        let parser = XMLParser(data: data)
        let delegate = XMLTreeParserDelegate()
        parser.delegate = delegate
        guard parser.parse() else { return nil }
        return delegate.root
    }
}

class XMLNode {
    let name: String
    let attributes: [String: String]
    var children: [XMLNode] = []
    var text: String?

    init(name: String, attributes: [String: String] = [:], children: [XMLNode] = [], text: String? = nil) {
        self.name = name
        self.attributes = attributes
        self.children = children
        self.text = text
    }
}

struct XMLNodeView: View {
    let node: XMLNode
    var theme: AppTheme = .systemDark
    @State private var isExpanded = true

    var body: some View {
        if node.children.isEmpty && node.text == nil {
            Text("<\(node.name)\(attributesString(node.attributes))/>" )
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(theme.syntaxKeywordColor)
        } else {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(Array(node.children.enumerated()), id: \.offset) { _, child in
                    XMLNodeView(node: child, theme: theme)
                }
                if let text = node.text, !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(theme.syntaxStringColor)
                }
            } label: {
                Text("<\(node.name)\(attributesString(node.attributes))>")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(theme.syntaxKeywordColor)
            }
        }
    }

    private func attributesString(_ attrs: [String: String]) -> String {
        attrs.map { " \($0.key)=\"\($0.value)\"" }.joined()
    }
}

class XMLTreeParserDelegate: NSObject, XMLParserDelegate {
    var root: XMLNode?
    private var stack: [XMLNode] = []
    private var currentText: String = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentText = ""
        let node = XMLNode(name: elementName, attributes: attributeDict, children: [], text: nil)
        stack.append(node)
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard let node = stack.popLast() else { return }
        let text = currentText.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty {
            node.text = text
        }
        if let parent = stack.last {
            parent.children.append(node)
        } else {
            root = node
        }
    }
}
