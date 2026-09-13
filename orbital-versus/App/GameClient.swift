import Combine
import Foundation
import SwiftUI

@MainActor
final class GameClient: ObservableObject {
  @Published var state: ArenaState?
  @Published var playerID = ""
  @Published var connected = false
  @Published var connecting = false
  @Published var error = ""
  @Published var name = "PILOT"
  @Published var code = ""
  @Published var address = "ws://127.0.0.1:8787"
  @Published var automation = false
  @Published var automationStep = ""
  @Published var ping = 0
  @Published var muted = false
  @Published var hitFlash = false
  @Published var reticle = CGPoint(x: -500, y: -500)
  @Published var incoming = false
  let renderer = ArenaRenderer()
  let audio = GameAudio()
  var move = CGSize.zero
  var boosting = false
  var guarding = false
  private var actions: [String] = []
  private var task: URLSessionWebSocketTask?
  private var session: URLSession?
  private var timer: Timer?
  private var sequence = 0
  private var token = ""
  private var lastEvent = 0
  private var frame = 0
  private var generation = 0
  private var lastStateAt = Date()
  private var resultFrames = 0
  private var automaticReady = false
  private var automaticRematch = false
  private var lastAutoRound = 0
  private var logHandle: FileHandle?

  var me: UnitState? { state?.units.first { $0.id == playerID } }
  var target: UnitState? { state?.units.first { $0.id == me?.target } }
  var wing: UnitState? { state?.units.first { $0.team == me?.team && $0.ai } }

  init() {
    let arguments = ProcessInfo.processInfo.arguments
    func argument(_ key: String) -> String? {
      guard let index = arguments.firstIndex(of: key), index + 1 < arguments.count else {
        return nil
      }
      return arguments[index + 1]
    }
    name = argument("--name") ?? UserDefaults.standard.string(forKey: "pilotName") ?? "PILOT"
    address = argument("--server") ?? UserDefaults.standard.string(forKey: "server") ?? address
    code = argument("--room") ?? ""
    automation = arguments.contains("--autopilot")
    automaticReady = arguments.contains("--auto-ready")
    automaticRematch = arguments.contains("--auto-rematch")
    if let document = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      let path = document.appendingPathComponent("telemetry.jsonl")
      FileManager.default.createFile(atPath: path.path, contents: nil)
      logHandle = try? FileHandle(forWritingTo: path)
    }
    renderer.reticleChanged = { [weak self] position in self?.reticle = position }
    timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.update() }
    }
    if arguments.contains("--join") {
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 600_000_000)
        connect()
      }
    }
  }

  func connect(rejoin: Bool = false) {
    guard let url = URL(string: address),
      ["ws", "wss"].contains(url.scheme), url.host != nil
    else {
      error = "Enter a ws:// or wss:// server address"
      return
    }
    generation += 1
    let currentGeneration = generation
    task?.cancel(with: .goingAway, reason: nil)
    session?.invalidateAndCancel()
    error = ""
    connecting = true
    connected = false
    sequence = 0
    if !rejoin {
      token = ""
      state = nil
      lastEvent = 0
    }
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 8
    let session = URLSession(configuration: configuration)
    self.session = session
    let socket = session.webSocketTask(with: url)
    task = socket
    socket.resume()
    UserDefaults.standard.set(address, forKey: "server")
    UserDefaults.standard.set(name, forKey: "pilotName")
    send(
      ClientMessage(type: "join", name: name, code: code.uppercased(), token: rejoin ? token : nil))
    audio.start()
    Task {
      do {
        while !Task.isCancelled {
          let result = try await socket.receive()
          guard currentGeneration == generation else { return }
          let data: Data
          switch result {
          case .data(let bytes): data = bytes
          case .string(let text): data = Data(text.utf8)
          @unknown default: continue
          }
          receive(data)
        }
      } catch {
        guard currentGeneration == generation else { return }
        self.connected = false
        self.connecting = false
        self.error = "Connection lost. Check the server, then RECONNECT."
        log(type: "disconnect", detail: error.localizedDescription)
      }
    }
  }

  func leave() {
    generation += 1
    task?.cancel(with: .normalClosure, reason: nil)
    session?.invalidateAndCancel()
    task = nil
    state = nil
    connected = false
    connecting = false
    token = ""
    error = ""
    playerID = ""
    move = .zero
    boosting = false
    guarding = false
    actions = []
    renderer.reset()
  }

  func reconnect() { connect(rejoin: !token.isEmpty) }
  func ready() {
    send(ClientMessage(type: "ready"))
    audio.play("confirm")
  }
  func rematch() {
    send(ClientMessage(type: "rematch"))
    audio.play("confirm")
  }
  func press(_ action: String) {
    actions.append(action)
    log(type: "control", detail: action)
    if action == "lock" { audio.play("lock") }
  }
  func toggleMute() {
    muted.toggle()
    audio.muted = muted
  }
  func toggleAutomation() {
    automation.toggle()
    move = .zero
    boosting = false
    guarding = false
  }
  func suspendInput() {
    move = .zero
    boosting = false
    guarding = false
    actions = []
  }
  private func send(_ message: ClientMessage) {
    guard let bytes = try? JSONEncoder().encode(message),
      let text = String(data: bytes, encoding: .utf8)
    else { return }
    let socket = task
    Task { try? await socket?.send(.string(text)) }
  }
  private func receive(_ data: Data) {
    guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else { return }
    if envelope.type == "welcome" {
      playerID = envelope.id ?? ""
      token = envelope.token ?? ""
      code = envelope.code ?? ""
      connected = true
      connecting = false
      lastStateAt = Date()
      log(type: "welcome", detail: "\(playerID) room=\(code)")
    } else if envelope.type == "state",
      let snapshot = try? JSONDecoder().decode(ArenaState.self, from: data)
    {
      lastStateAt = Date()
      let oldPhase = state?.phase
      state = snapshot
      renderer.apply(snapshot, playerID: playerID)
      for event in snapshot.events where event.id > lastEvent {
        renderer.effect(event)
        if event.kind == "hit" && event.unit == playerID {
          hitFlash = true
          Task {
            try? await Task.sleep(nanoseconds: 160_000_000)
            hitFlash = false
          }
        }
        if event.kind == "fire" || event.kind == "saber" || event.kind == "destroy"
          || event.kind == "burst"
        {
          audio.play(event.kind)
        } else if event.kind == "hit" {
          audio.play("hit")
        }
        lastEvent = max(lastEvent, event.id)
      }
      incoming = snapshot.units.contains {
        $0.team != me?.team && $0.target == playerID && $0.hp > 0
      }
      if oldPhase != snapshot.phase {
        log(type: "phase", detail: "\(snapshot.phase) round=\(snapshot.round)")
        audio.play(snapshot.phase == "result" ? "result" : "confirm")
        if snapshot.phase == "result" { resultFrames = 0 }
      }
      if snapshot.tick % 30 == 0 || oldPhase != snapshot.phase {
        try? logHandle?.write(contentsOf: data + Data("\n".utf8))
      }
    } else if envelope.type == "error" {
      error = envelope.message ?? "Server rejected request"
      connecting = false
    } else if envelope.type == "pong", let sent = envelope.sent {
      ping = Int((Date().timeIntervalSince1970 - sent) * 1000)
    }
  }
  private func update() {
    frame += 1
    renderer.animate()
    guard connected else { return }
    if Date().timeIntervalSince(lastStateAt) > 6 {
      error = "Server is not responding. RECONNECT to resume."
      connected = false
      return
    }
    if frame % 60 == 0 { send(ClientMessage(type: "ping", sent: Date().timeIntervalSince1970)) }
    if automaticReady && state?.phase == "lobby" && frame % 30 == 0 { ready() }
    if state?.phase == "result" {
      resultFrames += 1
      if automaticRematch && resultFrames == 210 && state?.round == 1 { rematch() }
    }
    guard state?.phase == "playing", let me else { return }
    if automation { drive(me) }
    sequence += 1
    let angle = me.yaw
    let x = Float(move.width) * cos(angle) - Float(move.height) * sin(angle)
    let z = -Float(move.width) * sin(angle) - Float(move.height) * cos(angle)
    send(
      ClientMessage(
        type: "input", seq: sequence, x: x, z: z, boost: boosting,
        guardAction: guarding, actions: actions))
    actions.removeAll()
  }
  private func drive(_ me: UnitState) {
    guard let state, let target else { return }
    if lastAutoRound != state.round { lastAutoRound = state.round }
    let elapsed = 90 - state.time
    let range = hypot(target.x - me.x, target.z - me.z)
    let cycle = Int(elapsed * 30)
    automationStep =
      elapsed < 8 ? "01 / BOOST & BEAM" : elapsed < 18 ? "02 / SABER ENGAGE" : "03 / COST BATTLE"
    if target.hp <= 0 && cycle % 15 == 0 { press("lock") }
    boosting = elapsed < 8 ? cycle % 100 < 40 : cycle % 230 < 24
    guarding = me.team == 1 && cycle % 180 > 153
    move = CGSize(
      width: sin(elapsed * 0.8 + Double(me.team)) * (range < 10 ? 0.15 : 0.35),
      height: range > 8 ? -0.85 : range < 4 ? 0.3 : 0)
    if elapsed < 8 || range > 17 {
      if cycle % 18 == 0 { press("fire") }
    } else {
      if cycle % 18 == 0 { press("melee") }
      if cycle % 50 == 24 { press("fire") }
    }
    if cycle % 150 == 99 { press("dodge") }
    if me.burst >= 50 && cycle % 30 == 0 { press("burst") }
  }
  private func log(type: String, detail: String) {
    struct Entry: Encodable {
      let type: String
      let detail: String
      let time: Double
    }
    if let data = try? JSONEncoder().encode(
      Entry(type: type, detail: detail, time: Date().timeIntervalSince1970))
    {
      try? logHandle?.write(contentsOf: data + Data("\n".utf8))
    }
  }
}
