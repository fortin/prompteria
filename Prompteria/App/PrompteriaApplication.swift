import AppKit

/// Custom NSApplication subclass required for AppleScript. The actual link is
/// retrieved via the "fetch link" command (FetchLinkCommand).
@objc(PrompteriaApplication)
final class PrompteriaApplication: NSApplication {}
