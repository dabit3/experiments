import UIKit
import XCTest

@testable import CrownClash

final class AssetTests: XCTestCase {
  @MainActor
  func testEveryFighterPoseAndPortraitLoadsFromTheApplicationBundle() throws {
    for fighter in Fighter.all {
      for suffix in ["idle.png", "punch.png", "kick.png", "hurt.png", "portrait.jpg"] {
        let filename = "\(fighter.id)-\(suffix)"
        let image = try XCTUnwrap(UIImage(named: filename), "Missing artwork: \(filename)")
        XCTAssertGreaterThan(image.size.width, 80)
        XCTAssertGreaterThan(image.size.height, 100)
      }
    }
    let arena = try XCTUnwrap(UIImage(named: "festival.png"))
    XCTAssertGreaterThan(arena.size.width, 1000)
  }
}
