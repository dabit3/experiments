import SceneKit
import XCTest

@testable import DominoDaydream

final class DioramaTests: XCTestCase {
  @MainActor
  func testBoardProjectionFindsEveryCellOnCompactAndLargeViewports() {
    for size in [CGSize(width: 375, height: 300), CGSize(width: 440, height: 440)] {
      let view = DioramaView(frame: CGRect(origin: .zero, size: size))
      let model = Diorama(puzzle: Puzzle.all[0], labels: true)
      view.model = model
      view.scene = model.scene
      view.pointOfView = model.camera
      _ = view.snapshot()
      for y in 0..<9 {
        for x in 0..<7 {
          let point = view.projectPoint(SCNVector3(Float(x - 3), 0.08, Float(y - 4)))
          XCTAssertEqual(
            view.cell(at: CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))),
            Cell(x: x, y: y), "Incorrect touch projection at \(x),\(y) on \(size)")
        }
      }
      XCTAssertNil(view.cell(at: CGPoint(x: -1000, y: -1000)))
    }
  }
}
