import Foundation

final class Packets: @unchecked Sendable {
  private let lock = NSLock()
  private var entries: [WireMessage] = []

  func append(_ packet: WireMessage) {
    lock.withLock { entries.append(packet) }
  }

  var values: [WireMessage] { lock.withLock { entries } }
}

@main
struct InputStreamTests {
  static func require(_ condition: Bool, _ message: String) {
    guard condition else { fatalError(message) }
  }

  static func main() {
    let packets = Packets()
    let stream = GameInputStream { packets.append($0) }
    let start = Date().timeIntervalSince1970 * 1000 - 1000
    stream.synchronize(enabled: true, epoch: 1, startAt: start, offset: 0)
    stream.resetSequence(42)
    stream.contact(0, position: 0.3)
    stream.contact(1, position: 0.7)

    // Block the UI thread longer than the server's 180ms freshness window.
    Thread.sleep(forTimeInterval: 0.45)
    for color in 0..<2 {
      let samples = packets.values.filter { $0.color == color }
      require(samples.count >= 12, "Held contacts must transmit while the UI thread is blocked")
      let times = samples.compactMap(\.time)
      require(times.count == samples.count, "Every input needs an actual sample time")
      let gaps = zip(times, times.dropFirst()).map { $1 - $0 }
      require(gaps.allSatisfy { $0 > 0 && $0 < 0.18 }, "Real samples must remain fresh")
      require(times.last! - times.first! > 0.3, "Do not backfill a burst after a UI stall")
      require(
        samples.allSatisfy { $0.x == (color == 0 ? 0.3 : 0.7) }, "Do not auto-track the chart")
    }

    var move = WireMessage(type: "input")
    move.kind = "laser"
    move.color = 0
    move.x = 0.8
    for _ in 0..<300 { stream.input(move, source: "touch") }
    Thread.sleep(forTimeInterval: 0.08)
    require(
      packets.values.count < 70, "Coalesce high-frequency moves instead of flooding the server")
    require(
      packets.values.last { $0.color == 0 }?.x == 0.8, "Fresh samples must use the latest touch")

    var button = WireMessage(type: "input")
    button.kind = "button"
    button.lane = 0
    button.down = true
    stream.input(button, source: "touch")
    stream.contact(0, position: nil)
    Thread.sleep(forTimeInterval: 0.06)
    let cyanCount = packets.values.filter { $0.color == 0 }.count
    let pinkCount = packets.values.filter { $0.color == 1 }.count
    Thread.sleep(forTimeInterval: 0.15)
    require(
      packets.values.filter { $0.color == 0 }.count == cyanCount, "Released contact must stop")
    require(
      packets.values.filter { $0.color == 1 }.count > pinkCount, "Other contact must continue")

    stream.releaseAll()
    Thread.sleep(forTimeInterval: 0.05)
    let releasedCount = packets.values.count
    Thread.sleep(forTimeInterval: 0.2)
    require(packets.values.count == releasedCount, "Cancellation must not leave phantom contacts")
    let sequences = packets.values.compactMap(\.seq)
    require(
      sequences == Array(42..<(42 + sequences.count)),
      "Buttons and samples share ordered resume sequence")
    require(packets.values.contains { $0.kind == "button" }, "Button path must share the transport")

    stream.synchronize(enabled: false, epoch: 1, startAt: start, offset: 0)
    stream.contact(0, position: 0.5)
    Thread.sleep(forTimeInterval: 0.2)
    require(packets.values.count == releasedCount, "Disconnected input must not transmit")
    stream.synchronize(enabled: true, epoch: 2, startAt: start, offset: 0)
    stream.resetSequence(0)
    Thread.sleep(forTimeInterval: 0.1)
    require(packets.values.count == releasedCount, "A new round must clear old contacts")
    stream.input(button, source: "touch")
    Thread.sleep(forTimeInterval: 0.05)
    require(
      packets.values.last?.seq == 0 && packets.values.last?.epoch == 2,
      "Rematch resets the sequence")
    stream.stop()
    print(
      "PASS: UI stall, fresh stationary contacts, move coalescing, release/cancel, resume and epoch isolation"
    )
  }
}
