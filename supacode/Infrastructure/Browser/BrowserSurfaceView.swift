import AppKit
import WebKit

private let browserLogger = SupaLogger("Browser")

/// Custom WKWebView subclass that reports focus changes and routes keyboard shortcuts.
@MainActor
final class BrowserWebView: WKWebView {
  var onFocusChange: ((Bool) -> Void)?
  var onKeyEquivalent: ((NSEvent) -> Bool)?

  override var acceptsFirstResponder: Bool { true }

  override func becomeFirstResponder() -> Bool {
    let result = super.becomeFirstResponder()
    if result {
      onFocusChange?(true)
    }
    return result
  }

  override func resignFirstResponder() -> Bool {
    let result = super.resignFirstResponder()
    if result {
      onFocusChange?(false)
    }
    return result
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    // Cmd-modified keys: check app-level shortcuts first (Cmd+D, Cmd+W, Cmd+T)
    if event.modifierFlags.contains(.command) {
      if let onKeyEquivalent, onKeyEquivalent(event) {
        return true
      }
    }
    return super.performKeyEquivalent(with: event)
  }
}

@MainActor
final class BrowserSurfaceView: NSView, Identifiable {
  let id = UUID()
  let state = BrowserSurfaceState()
  let webView: BrowserWebView

  private var observations: [NSKeyValueObservation] = []

  override init(frame frameRect: NSRect) {
    let config = WKWebViewConfiguration()
    config.preferences.isElementFullscreenEnabled = true
    webView = BrowserWebView(frame: frameRect, configuration: config)
    super.init(frame: frameRect)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  private func setup() {
    webView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(webView)
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: topAnchor),
      webView.bottomAnchor.constraint(equalTo: bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])

    webView.navigationDelegate = self
    webView.allowsBackForwardNavigationGestures = true

    observations = [
      webView.observe(\.title) { [weak self] webView, _ in
        MainActor.assumeIsolated {
          self?.state.title = webView.title ?? ""
        }
      },
      webView.observe(\.url) { [weak self] webView, _ in
        MainActor.assumeIsolated {
          self?.state.currentURL = webView.url
          self?.state.editableURLString = webView.url?.absoluteString ?? ""
        }
      },
      webView.observe(\.canGoBack) { [weak self] webView, _ in
        MainActor.assumeIsolated {
          self?.state.canGoBack = webView.canGoBack
        }
      },
      webView.observe(\.canGoForward) { [weak self] webView, _ in
        MainActor.assumeIsolated {
          self?.state.canGoForward = webView.canGoForward
        }
      },
      webView.observe(\.isLoading) { [weak self] webView, _ in
        MainActor.assumeIsolated {
          self?.state.isLoading = webView.isLoading
        }
      },
      webView.observe(\.estimatedProgress) { [weak self] webView, _ in
        MainActor.assumeIsolated {
          self?.state.estimatedProgress = webView.estimatedProgress
        }
      },
    ]
  }

  override var acceptsFirstResponder: Bool { true }

  func loadURL(_ url: URL) {
    browserLogger.info("Loading URL: \(url.absoluteString)")
    state.editableURLString = url.absoluteString
    webView.load(URLRequest(url: url))
  }

  func goBack() { webView.goBack() }
  func goForward() { webView.goForward() }
  func reload() { webView.reload() }
  func stopLoading() { webView.stopLoading() }

  deinit {
    observations.removeAll()
  }
}

extension BrowserSurfaceView: WKNavigationDelegate {
  nonisolated func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction
  ) -> WKNavigationActionPolicy {
    .allow
  }

  nonisolated func webView(
    _ webView: WKWebView,
    didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    let message = error.localizedDescription
    Task { @MainActor in
      browserLogger.warning("Navigation failed: \(message)")
    }
  }
}
