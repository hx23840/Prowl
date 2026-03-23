import Foundation

@MainActor
@Observable
final class BrowserSurfaceState {
  var currentURL: URL?
  var title: String = ""
  var canGoBack: Bool = false
  var canGoForward: Bool = false
  var isLoading: Bool = false
  var estimatedProgress: Double = 0
  var editableURLString: String = ""
}
