import SpriteKit
import XCTest

@testable import CrownClash

final class FighterPoseTests: XCTestCase {
  @MainActor
  func testHeldCrouchRemainsShorterThanStandingAcrossRenderFrames() throws {
    let node = FighterNode()
    var peer = PeerState(
      id: "pose-test", name: "ATLAS", roster: [MemberState(fighter: "atlas", hp: 100)],
      connected: true, ready: true, active: 0, meter: 0, x: 500, y: 0, face: 1,
      pose: "idle", guardValue: 100, guarding: false, crouch: false, combo: 0,
      ack: 0, rematch: false, damage: 0, knockouts: 0)
    node.update(peer, ground: 225, time: 0, delta: 1.0 / 60)
    let sprite = try XCTUnwrap(node.children.compactMap { $0 as? SKSpriteNode }.first)
    let standingHeight = sprite.frame.height
    peer.crouch = true
    peer.pose = "crouch"
    for frame in 1...120 {
      node.update(peer, ground: 225, time: Double(frame) / 60, delta: 1.0 / 60)
      XCTAssertLessThan(sprite.frame.height, standingHeight * 0.8, "Frame \(frame)")
      XCTAssertGreaterThan(sprite.frame.height, standingHeight * 0.65, "Frame \(frame)")
    }
    peer.crouch = false
    peer.pose = "idle"
    node.update(peer, ground: 225, time: 3, delta: 1.0 / 60)
    XCTAssertEqual(sprite.frame.height, standingHeight, accuracy: standingHeight * 0.02)
  }
}
