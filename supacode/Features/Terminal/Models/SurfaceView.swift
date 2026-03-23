import AppKit

/// Data container for the SplitTree. Holds either a terminal or browser surface.
/// Not rendered directly — SwiftUI extracts the inner view via NSViewRepresentable.
@MainActor
final class SurfaceView: NSView, Identifiable {
  enum Content {
    case terminal(GhosttySurfaceView)
    case browser(BrowserSurfaceView)
  }

  let content: Content

  nonisolated var id: UUID {
    switch content {
    case .terminal(let view): view.id
    case .browser(let view): view.id
    }
  }

  var terminalView: GhosttySurfaceView? {
    if case .terminal(let view) = content { return view }
    return nil
  }

  var browserView: BrowserSurfaceView? {
    if case .browser(let view) = content { return view }
    return nil
  }

  init(terminal: GhosttySurfaceView) {
    content = .terminal(terminal)
    super.init(frame: .zero)
  }

  init(browser: BrowserSurfaceView) {
    content = .browser(browser)
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }
}
