import Foundation
import QuartzCore

@MainActor
final class Session {
  let audio = DeckAudio()
  let chart: Chart
  var state: RoomState?
  var you = ""
  var token = ""
  var address = UserDefaults.standard.string(forKey: "server") ?? "ws://127.0.0.1:8317"
  var guest = UserDefaults.standard.string(forKey: "guest") ?? "NOVA"
  var code = ""
  var status = "LOCAL NETWORK / NO ACCOUNT REQUIRED"
  var connected = false
  var offset = 0.0
  var rtt = 0.0
  var bestRTT = Double.infinity
  var calibration = UserDefaults.standard.double(forKey: "calibration")
  var speed =
    UserDefaults.standard.double(forKey: "speed") == 0
    ? 2.1 : UserDefaults.standard.double(forKey: "speed")
  var auto = false
  var autoDelay = 0.0
  var autoRematch = false
  var onChange: (() -> Void)?
  var onHit: ((Int, Bool) -> Void)?
  private var socket: URLSessionWebSocketTask?
  private var sequence = 0
  private var generation = 0
  private var clockBase = Date().timeIntervalSince1970 * 1000 - CACurrentMediaTime() * 1000
  private var lastProbe = -10000.0
  private var autoSent: Set<String> = []
  private var lastRound = 0
  private var resultAt = 0.0
  private var telemetryAt = 0.0
  private var readyScheduled = false

  init() {
    guard let url = Bundle.main.url(forResource: "chart", withExtension: "json"),
      let bytes = try? Data(contentsOf: url),
      let loaded = try? JSONDecoder().decode(Chart.self, from: bytes)
    else { fatalError("Bundled chart is required") }
    chart = loaded
  }

  var now: Double { clockBase + CACurrentMediaTime() * 1000 }
  var songTime: Double { now + offset - (state?.startAt ?? now + offset) }
  var me: Player? { state?.players.first(where: { $0.id == you }) }
  var opponent: Player? { state?.players.first(where: { $0.id != you }) }

  func connect(create: Bool) {
    guard let url = URL(string: address),
      ["ws", "wss"].contains(url.scheme ?? ""), url.host != nil
    else {
      status = "Enter a valid ws:// or wss:// server address"
      onChange?()
      return
    }
    guard !guest.trimmingCharacters(in: .whitespaces).isEmpty else {
      status = "Enter a guest name"
      onChange?()
      return
    }
    generation += 1
    let current = generation
    socket?.cancel(with: .goingAway, reason: nil)
    connected = false
    status = "CONNECTING TO DECK SERVER…"
    UserDefaults.standard.set(address, forKey: "server")
    UserDefaults.standard.set(guest, forKey: "guest")
    let connection = URLSession.shared.webSocketTask(with: url)
    socket = connection
    connection.resume()
    send(Command(type: "ping", sent: now))
    send(
      Command(
        type: "join", room: code.uppercased(), name: String(guest.prefix(20)), create: create,
        token: token))
    Task { [weak self] in
      while let self, current == self.generation {
        do {
          let response = try await connection.receive()
          let data: Data
          switch response {
          case .data(let bytes): data = bytes
          case .string(let text): data = Data(text.utf8)
          @unknown default: continue
          }
          if let packet = try? JSONDecoder().decode(Packet.self, from: data) {
            self.receive(packet)
          }
        } catch {
          if current == self.generation {
            self.connected = false
            self.status = "LINK LOST — TAP RECONNECT"
            self.audio.stop()
            self.onChange?()
          }
          break
        }
      }
    }
    onChange?()
  }

  func leave() {
    generation += 1
    socket?.cancel(with: .normalClosure, reason: nil)
    socket = nil
    state = nil
    token = ""
    you = ""
    code = ""
    connected = false
    auto = false
    audio.stop()
    status = "LOCAL NETWORK / NO ACCOUNT REQUIRED"
    onChange?()
  }

  func ready() { send(Command(type: "ready")) }

  func send(_ command: Command) {
    guard let bytes = try? JSONEncoder().encode(command),
      let text = String(data: bytes, encoding: .utf8)
    else { return }
    socket?.send(.string(text)) { _ in }
  }

  func input(lane: Int, down: Bool) {
    if down { audio.key(lane) }
    onHit?(lane, down)
    guard connected, state?.phase == "playing" else { return }
    sequence += 1
    send(
      Command(type: "input", seq: sequence, lane: lane, down: down, time: songTime + calibration))
  }

  private func receive(_ packet: Packet) {
    if packet.type == "error" {
      status = packet.message ?? "Server error"
      onChange?()
      return
    }
    if packet.type == "pong", let sent = packet.sent, let server = packet.serverTime {
      let elapsed = now - sent
      rtt = elapsed
      if elapsed < bestRTT {
        bestRTT = elapsed
        offset = server - (sent + now) / 2
      }
    }
    if let id = packet.you { you = id }
    if let secret = packet.token { token = secret }
    if let received = packet.state {
      state = received
      code = received.room
      connected = true
      sequence = max(sequence, me?.seq ?? 0)
      status = "ROOM \(code) • \(received.players.count)/2 DJs • LINKED"
      if received.round != lastRound {
        lastRound = received.round
        autoSent.removeAll()
        resultAt = 0
      }
      if received.phase == "playing" && audio.scheduledRound != received.round {
        audio.start(round: received.round, songTime: songTime)
      }
      if received.phase == "result" && resultAt == 0 {
        resultAt = now
        logTelemetry(event: "result")
      }
    }
    onChange?()
  }

  func tick() {
    if socket != nil && now - lastProbe > (bestRTT.isInfinite ? 200 : 1500) {
      lastProbe = now
      send(Command(type: "ping", sent: now))
    }
    if auto, let state {
      if state.phase == "lobby" && me?.ready == false && !readyScheduled && !bestRTT.isInfinite {
        readyScheduled = true
        Task { [weak self] in
          try? await Task.sleep(for: .seconds(1))
          self?.ready()
          self?.readyScheduled = false
        }
      }
      if state.phase == "playing" {
        let t = songTime - autoDelay
        for note in chart.notes {
          let head = "h\(note.id)"
          let tail = "t\(note.id)"
          if t >= note.time && !autoSent.contains(head) {
            autoSent.insert(head)
            input(lane: note.lane, down: true)
            if note.duration == 0 {
              Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(65))
                self?.input(lane: note.lane, down: false)
              }
            }
          }
          if note.duration > 0 && t >= note.time + note.duration && !autoSent.contains(tail) {
            autoSent.insert(tail)
            input(lane: note.lane, down: false)
          }
        }
      }
      if state.phase == "result" && autoRematch && state.round == 1 && now - resultAt > 6500
        && me?.ready == false
      {
        ready()
      }
    }
    if state != nil && now - telemetryAt > 1000 {
      telemetryAt = now
      logTelemetry(event: "snapshot")
    }
  }

  private func logTelemetry(event: String) {
    guard let state else { return }
    struct Telemetry: Encodable {
      let event: String
      let you: String
      let room: RoomState
      let songTime: Double
      let audioTime: Double
      let offset: Double
      let rtt: Double
      let automated: Bool
    }
    let entry = Telemetry(
      event: event, you: you, room: state, songTime: songTime,
      audioTime: audio.musicPosition * 1000, offset: offset, rtt: rtt, automated: auto)
    guard var data = try? JSONEncoder().encode(entry) else { return }
    data.append(10)
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let url = directory.appendingPathComponent("telemetry.jsonl")
    if !FileManager.default.fileExists(atPath: url.path) {
      FileManager.default.createFile(atPath: url.path, contents: nil)
    }
    if let handle = try? FileHandle(forWritingTo: url) {
      defer { try? handle.close() }
      _ = try? handle.seekToEnd()
      try? handle.write(contentsOf: data)
    }
  }
}
