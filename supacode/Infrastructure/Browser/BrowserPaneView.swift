import SwiftUI
import WebKit

struct BrowserPaneView: View {
  let browserView: BrowserSurfaceView

  var body: some View {
    VStack(spacing: 0) {
      browserToolbar
      Divider()
      ZStack(alignment: .top) {
        BrowserWebViewRepresentable(webView: browserView.webView)
        if browserView.state.isLoading {
          ProgressView(value: browserView.state.estimatedProgress)
            .progressViewStyle(.linear)
        }
      }
    }
  }

  private var browserToolbar: some View {
    HStack(spacing: 6) {
      Button {
        browserView.goBack()
      } label: {
        Image(systemName: "chevron.left")
          .accessibilityLabel("Back")
      }
      .disabled(!browserView.state.canGoBack)
      .help("Back")

      Button {
        browserView.goForward()
      } label: {
        Image(systemName: "chevron.right")
          .accessibilityLabel("Forward")
      }
      .disabled(!browserView.state.canGoForward)
      .help("Forward")

      Button {
        if browserView.state.isLoading {
          browserView.stopLoading()
        } else {
          browserView.reload()
        }
      } label: {
        Image(systemName: browserView.state.isLoading ? "xmark" : "arrow.clockwise")
          .accessibilityLabel(browserView.state.isLoading ? "Stop" : "Reload")
      }
      .help(browserView.state.isLoading ? "Stop" : "Reload")

      TextField(
        "URL",
        text: Binding(
          get: { browserView.state.editableURLString },
          set: { browserView.state.editableURLString = $0 }
        )
      )
      .textFieldStyle(.roundedBorder)
      .font(.callout)
      .monospaced()
      .onSubmit {
        let input = browserView.state.editableURLString
        if let url = urlFromInput(input) {
          browserView.loadURL(url)
        }
      }
    }
    .buttonStyle(.borderless)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
  }

  private func urlFromInput(_ input: String) -> URL? {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return nil }
    if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
      return URL(string: trimmed)
    }
    return URL(string: "https://\(trimmed)")
  }
}

private struct BrowserWebViewRepresentable: NSViewRepresentable {
  let webView: BrowserWebView

  func makeNSView(context: Context) -> BrowserWebView {
    webView
  }

  func updateNSView(_ nsView: BrowserWebView, context: Context) {}
}
