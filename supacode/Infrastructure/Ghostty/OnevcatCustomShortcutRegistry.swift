import AppKit

@MainActor
final class OnevcatCustomShortcutRegistry {
  static let shared = OnevcatCustomShortcutRegistry()

  private var shortcuts: [UserCustomShortcut] = []

  private init() {}

  func setShortcuts(_ shortcuts: [UserCustomShortcut]) {
    self.shortcuts = shortcuts.compactMap { shortcut in
      let normalized = shortcut.normalized()
      return normalized.isValid ? normalized : nil
    }
  }

  func matches(event: NSEvent) -> Bool {
    shortcuts.contains { $0.matches(event: event) }
  }

  #if DEBUG
    var registeredShortcutsForTesting: [UserCustomShortcut] {
      shortcuts
    }
  #endif
}
