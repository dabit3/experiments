import Foundation

final class GameInputStream: @unchecked Sendable {
  private let queue = DispatchQueue(label: "laser-overdrive.input", qos: .userInteractive)
  private let timer: DispatchSourceTimer
  private let transmit: @Sendable (WireMessage) -> Void
  private var held: [Double?] = [nil, nil]
  private var enabled = false
  private var epoch = 0
  private var sequence = 0
  private var startAt = 0.0
  private var offset = 0.0

  init(transmit: @escaping @Sendable (WireMessage) -> Void) {
    self.transmit = transmit
    timer = DispatchSource.makeTimerSource(queue: queue)
    timer.schedule(deadline: .now(), repeating: .milliseconds(25), leeway: .milliseconds(2))
    timer.setEventHandler { [weak self] in self?.sample() }
    timer.resume()
  }

  deinit { timer.cancel() }

  func synchronize(enabled: Bool, epoch: Int, startAt: Double, offset: Double) {
    queue.async {
      if !enabled || self.epoch != epoch { self.held = [nil, nil] }
      self.enabled = enabled
      self.epoch = epoch
      self.startAt = startAt
      self.offset = offset
    }
  }

  func resetSequence(_ next: Int) {
    queue.async { self.sequence = next }
  }

  func send(_ message: WireMessage) {
    queue.async { self.transmit(message) }
  }

  func input(_ message: WireMessage, source: String, at: Double? = nil) {
    queue.async {
      if message.kind == "laser", let color = message.color,
        let x = message.x, self.held.indices.contains(color), self.held[color] != nil
      {
        if source == "touch" { self.held[color] = x }
        return
      }
      self.emit(message, source: source, at: at)
    }
  }

  func contact(_ color: Int, position: Double?) {
    queue.async {
      guard self.held.indices.contains(color) else { return }
      self.held[color] = position
    }
  }

  func releaseAll() {
    queue.async { self.held = [nil, nil] }
  }

  func stop() {
    queue.async {
      self.enabled = false
      self.held = [nil, nil]
      self.timer.cancel()
    }
  }

  private func sample() {
    for color in held.indices {
      guard let x = held[color] else { continue }
      var message = WireMessage(type: "input")
      message.kind = "laser"
      message.color = color
      message.x = x
      emit(message, source: "touch", at: nil)
    }
  }

  private func emit(_ message: WireMessage, source: String, at: Double?) {
    let time = (Date().timeIntervalSince1970 * 1000 + offset - startAt) / 1000
    guard enabled, time >= 0 else { return }
    var message = message
    message.time = at ?? time
    message.seq = sequence
    message.epoch = epoch
    message.source = source
    sequence += 1
    transmit(message)
  }
}
