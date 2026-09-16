import AVFoundation
import SwiftUI
import XCTest

@testable import FlappyOtter

@MainActor
final class AppTests: XCTestCase {
  func testGameStoreRecordsEachFinishedFlightExactlyOnceAndPersists() throws {
    let suite = "FlappyOtter.appTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = GameStore(defaults: defaults)
    store.toggleSound()
    store.toggleHaptics()
    store.prepareFlight()
    store.flap()
    var time = 0.0
    for _ in 0..<3_000 {
      let game = store.game
      let target =
        game.gates.first {
          $0.x + GameModel.gateWidth >= GameModel.playerX - GameModel.radius
        }?.center ?? 397
      if game.score < 2 && game.y > target + 12 && game.velocity >= 0 { store.flap() }
      time += GameModel.step
      store.update(at: time)
      if store.game.phase == .finished { break }
    }
    XCTAssertEqual(store.game.phase, .finished)
    XCTAssertGreaterThanOrEqual(store.record.best, 2)
    XCTAssertTrue(store.newBest)
    for _ in 0..<100 {
      time += 0.1
      store.update(at: time)
    }
    XCTAssertEqual(store.record.flights, 1)
    let reloaded = GameStore(defaults: defaults)
    XCTAssertEqual(reloaded.record, store.record)
    store.prepareFlight()
    XCTAssertEqual(store.game.phase, .ready)
    XCTAssertEqual(store.game.score, 0)
    XCTAssertFalse(store.newBest)
    XCTAssertEqual(store.record.flights, 1)
  }

  func testStoreResumingDiscardsBackgroundWallClockTime() throws {
    let suite = "FlappyOtter.appTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = GameStore(defaults: defaults)
    store.prepareFlight()
    store.flap()
    store.update(at: 10)
    store.update(at: 10.05)
    store.pause()
    let y = store.game.y
    store.update(at: 200)
    XCTAssertEqual(store.game.y, y)
    store.resume()
    store.update(at: 500)
    XCTAssertEqual(store.game.y, y)
    store.update(at: 500.02)
    XCTAssertNotEqual(store.game.y, y)
    XCTAssertEqual(store.game.phase, .playing)
    store.goHome()
    store.flap()
    XCTAssertTrue(store.home)
    XCTAssertEqual(store.game.phase, .ready)
  }

  func testBundledOtterAndIconExist() throws {
    let otter = try XCTUnwrap(UIImage(named: "Otter"))
    XCTAssertGreaterThan(otter.size.width, 500)
    XCTAssertGreaterThan(otter.size.height, 500)
    XCTAssertNotNil(Bundle.main.url(forResource: "Assets", withExtension: "car"))
    let infoURL = try XCTUnwrap(Bundle.main.url(forResource: "Info", withExtension: "plist"))
    let info = try PropertyListDecoder().decode(IconInfo.self, from: Data(contentsOf: infoURL))
    XCTAssertEqual(info.icons.primaryIcon.name, "AppIcon")
  }

  func testAllSynthesizedSoundEffectsDecode() throws {
    for cue in RiverCue.allCases {
      let player = try AVAudioPlayer(data: RiverAudio.wave(cue))
      XCTAssertGreaterThan(player.duration, 0.1)
      XCTAssertLessThan(player.duration, 0.4)
      XCTAssertEqual(player.numberOfChannels, 1)
    }
  }

  func testNativeHomeAndRiverRenderAtCompactAndLargePhoneSizes() {
    for size in [CGSize(width: 375, height: 667), CGSize(width: 440, height: 956)] {
      let host = UIHostingController(rootView: OtterGameView())
      host.view.frame = CGRect(origin: .zero, size: size)
      host.view.setNeedsLayout()
      host.view.layoutIfNeeded()
      let image = UIGraphicsImageRenderer(size: size).image { context in
        host.view.layer.render(in: context.cgContext)
      }
      XCTAssertEqual(image.size, size)
      XCTAssertGreaterThan(image.pngData()?.count ?? 0, 5_000)
      let attachment = XCTAttachment(image: image)
      attachment.name = "Home-\(Int(size.width))x\(Int(size.height))"
      attachment.lifetime = .keepAlways
      add(attachment)
    }
  }
}

private struct IconInfo: Decodable {
  let icons: Icons
  enum CodingKeys: String, CodingKey {
    case icons = "CFBundleIcons"
  }

  struct Icons: Decodable {
    let primaryIcon: PrimaryIcon
    enum CodingKeys: String, CodingKey {
      case primaryIcon = "CFBundlePrimaryIcon"
    }
  }

  struct PrimaryIcon: Decodable {
    let name: String
    enum CodingKeys: String, CodingKey {
      case name = "CFBundleIconName"
    }
  }
}
