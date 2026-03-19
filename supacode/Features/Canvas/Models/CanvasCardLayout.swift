import CoreGraphics
import Foundation

struct CanvasCardLayout: Codable, Equatable, Hashable, Sendable {
  var positionX: CGFloat
  var positionY: CGFloat
  var width: CGFloat
  var height: CGFloat

  var position: CGPoint {
    get { CGPoint(x: positionX, y: positionY) }
    set {
      positionX = newValue.x
      positionY = newValue.y
    }
  }

  var size: CGSize {
    get { CGSize(width: width, height: height) }
    set {
      width = newValue.width
      height = newValue.height
    }
  }

  static let defaultSize = CGSize(width: 800, height: 550)

  init(position: CGPoint, size: CGSize = Self.defaultSize) {
    self.positionX = position.x
    self.positionY = position.y
    self.width = size.width
    self.height = size.height
  }
}

// MARK: - Card Packing

struct CanvasCardPacker {
  var spacing: CGFloat
  var titleBarHeight: CGFloat

  struct CardInfo {
    var key: String
    var size: CGSize
  }

  struct PackResult {
    var layouts: [String: CanvasCardLayout]
    var boundingSize: CGSize
  }

  /// Pack cards using a waterfall (masonry) layout that maximizes the
  /// fitToView scale — i.e., cards appear as large as possible on screen.
  ///
  /// `targetRatio` is the viewport's width/height. The algorithm tries every
  /// possible column count (1…N) and picks the one whose bounding box gives
  /// the highest `min(viewportW / boundingW, viewportH / boundingH)`.
  func pack(cards: [CardInfo], targetRatio: CGFloat) -> PackResult {
    guard !cards.isEmpty, targetRatio > 0 else {
      return PackResult(layouts: [:], boundingSize: .zero)
    }

    let columnWidth = cards.map(\.size.width).max()!
    var bestResult: PackResult?
    var bestScale: CGFloat = -1
    var bestArea = CGFloat.infinity

    for cols in 1...cards.count {
      let result = waterfallPack(cards: cards, columns: cols, columnWidth: columnWidth)
      let bW = result.boundingSize.width
      let bH = result.boundingSize.height
      let scale = min(targetRatio / bW, 1.0 / bH)
      let area = bW * bH
      if scale > bestScale || (scale == bestScale && area < bestArea) {
        bestScale = scale
        bestResult = result
        bestArea = area
      }
    }

    return bestResult ?? PackResult(layouts: [:], boundingSize: .zero)
  }

  // MARK: - Waterfall layout

  /// Place cards into equal-width columns, each card going to the shortest
  /// column. Cards are horizontally centered within their column.
  private func waterfallPack(
    cards: [CardInfo],
    columns: Int,
    columnWidth: CGFloat
  ) -> PackResult {
    var colHeights = Array(repeating: spacing, count: columns)
    var layouts: [String: CanvasCardLayout] = [:]

    for card in cards {
      let col = colHeights.enumerated().min(by: { $0.element < $1.element })!.offset
      let cardHeight = card.size.height + titleBarHeight
      let colLeft = spacing + CGFloat(col) * (columnWidth + spacing)

      layouts[card.key] = CanvasCardLayout(
        position: CGPoint(
          x: colLeft + columnWidth / 2,
          y: colHeights[col] + cardHeight / 2
        ),
        size: card.size
      )

      colHeights[col] += cardHeight + spacing
    }

    let totalWidth = spacing + CGFloat(columns) * (columnWidth + spacing)
    let totalHeight = colHeights.max() ?? spacing

    return PackResult(
      layouts: layouts,
      boundingSize: CGSize(width: totalWidth, height: totalHeight)
    )
  }
}

@MainActor
@Observable
final class CanvasLayoutStore {
  private static let storageKey = "canvasCardLayouts"

  var cardLayouts: [String: CanvasCardLayout] {
    didSet { save() }
  }

  init() {
    if let data = UserDefaults.standard.data(forKey: Self.storageKey),
      let layouts = try? JSONDecoder().decode([String: CanvasCardLayout].self, from: data)
    {
      self.cardLayouts = layouts
    } else {
      self.cardLayouts = [:]
    }
  }

  private func save() {
    if let data = try? JSONEncoder().encode(cardLayouts) {
      UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
  }
}
