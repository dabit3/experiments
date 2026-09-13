import Combine
import Foundation
import SwiftUI

@MainActor
final class GameClient: ObservableObject {
  @Published var serverAddress = "ws://127.0.0.1:8769"
  @Published var guest = "Player"
  @Published var room = "IRON"
  @Published var team = [0, 1]
  @Published var state: ArenaState?
  @Published var identity = ""
  @Published var status = "LOCAL NETWORK • GUEST PLAY"
  @Published var connected = false
  @Published var connecting = false
  @Published var muted = false
  @Published var showGuide = false
  @Published var automation = ""
  @Published var demoStep = ""
  var receivedAt = Date.timeIntervalSinceReferenceDate
  let audio = ArenaAudio()
  private var socket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var sendTail: Task<Void, Never>?
  private var clock: Timer?
  private var sequence = 0
  private var token = ""
  private var credentialRoom = ""
  private var lastEvent = 0
  private var movement = (x: 0.0, z: 0.0)
  private var guarding = false
  private var heartbeat = 0
  private var autoActionTick = -1000
  private var autoRound = 0
  private var autoTagged = false
  private var readyAt = Date.timeIntervalSinceReferenceDate
  private var resultAt = 0.0
  private var telemetry: FileHandle?

  var me: FighterState? { state?.players.first { $0.id == identity } }
  var opponent: FighterState? { state?.players.first { $0.id != identity } }

  init() {
    let arguments = ProcessInfo.processInfo.arguments
    func argument(_ key: String) -> String? {
      guard let index = arguments.firstIndex(of: key), index + 1 < arguments.count else {
        return nil
      }
      return arguments[index + 1]
    }
    if let value = argument("--server") { serverAddress = value }
    if let value = argument("--guest") { guest = value }
    if let value = argument("--room") { room = value }
    if let value = argument("--drive") {
      automation = value
      if value == "bravo" { team = [2, 3] }
    }
    let file = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("arena-evidence.jsonl")
    FileManager.default.createFile(atPath: file.path, contents: nil)
    telemetry = try? FileHandle(forWritingTo: file)
    clock = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.pulse() }
    }
    if arguments.contains("--connect") || !automation.isEmpty {
      Task {
        try? await Task.sleep(for: .seconds(1))
        connect()
      }
    }
  }

  func connect() {
    guard let url = URL(string: serverAddress),
      ["ws", "wss"].contains(url.scheme), url.host != nil
    else {
      status = "Enter a WebSocket address: ws://host:8769"
      return
    }
    receiveTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    connected = false
    connecting = true
    if credentialRoom != serverAddress + room.uppercased() {
      token = ""
      identity = ""
      state = nil
      sequence = 0
      lastEvent = 0
    }
    credentialRoom = serverAddress + room.uppercased()
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    status = "CONNECTING TO ARENA…"
    audio.start()
    send(Outbound(type: "join", code: room.uppercased(), name: guest, team: team, token: token))
    receiveTask = Task { [weak self] in
      while !Task.isCancelled {
        do {
          let message = try await task.receive()
          let data: Data
          switch message {
          case .data(let bytes): data = bytes
          case .string(let string): data = Data(string.utf8)
          @unknown default: continue
          }
          self?.receive(data)
        } catch {
          if !Task.isCancelled {
            self?.connected = false
            self?.connecting = false
            self?.status = "CONNECTION LOST • Reconnect to keep your fighter"
          }
          return
        }
      }
    }
  }

  func leave() {
    receiveTask?.cancel()
    socket?.cancel(with: .normalClosure, reason: nil)
    socket = nil
    connected = false
    connecting = false
    state = nil
    movement = (0, 0)
    guarding = false
    status = "LOCAL NETWORK • GUEST PLAY"
  }

  func action(_ name: String) {
    input(name)
    log(
      EvidenceRecord(
        type: "control", action: name, driver: automation.isEmpty ? "touch" : automation))
  }

  func move(x: Double, z: Double) {
    movement = (x, z)
    input("move", x: x, z: z)
  }

  func guardDown(_ value: Bool) {
    guarding = value
    input("guard", down: value)
  }

  func ready() { send(Outbound(type: "ready")) }
  func rematch() { send(Outbound(type: "rematch")) }

  func handleURL(_ url: URL) {
    guard url.scheme == "ironrelay",
      let parts = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else { return }
    let items = parts.queryItems ?? []
    let value = { (key: String) in items.first { $0.name == key }?.value ?? "" }
    if url.host == "input" {
      let name = value("action")
      if ["punch", "kick", "launch", "tag"].contains(name) { action(name) }
      if name == "move" { move(x: Double(value("x")) ?? 0, z: Double(value("z")) ?? 0) }
      if name == "guard" { guardDown(value("down") == "true") }
    }
    if url.host == "ready" { ready() }
    if url.host == "rematch" { rematch() }
    if url.host == "reconnect" { connect() }
    if url.host == "drive" { automation = value("role") }
  }

  private func input(_ action: String, x: Double? = nil, z: Double? = nil, down: Bool? = nil) {
    sequence += 1
    send(Outbound(type: "input", seq: sequence, action: action, x: x, z: z, down: down))
  }

  private func send(_ body: Outbound) {
    guard let data = try? JSONEncoder().encode(body),
      let text = String(data: data, encoding: .utf8), let socket
    else { return }
    let previous = sendTail
    sendTail = Task {
      await previous?.value
      try? await socket.send(.string(text))
    }
  }

  private func receive(_ data: Data) {
    guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else { return }
    if envelope.type == "welcome" {
      identity = envelope.id ?? ""
      token = envelope.token ?? ""
      sequence = max(sequence, (envelope.seq ?? -1) + 1)
      connected = true
      connecting = false
      readyAt = Date.timeIntervalSinceReferenceDate
      status = "CONNECTED • ROOM \(room.uppercased())"
    } else if envelope.type == "error" {
      status = envelope.message ?? "Connection error"
      connecting = false
    } else if envelope.type == "state",
      let world = try? JSONDecoder().decode(ArenaState.self, from: data)
    {
      state = world
      receivedAt = Date.timeIntervalSinceReferenceDate
      for event in world.events where event.id > lastEvent {
        if ["hit", "juggle", "launch", "block", "tag", "ko"].contains(event.kind) {
          audio.sound(event.kind)
        }
        log(EvidenceRecord(type: "event", event: event))
      }
      lastEvent = world.events.last?.id ?? lastEvent
    }
  }

  private func pulse() {
    guard connected, let state else { return }
    heartbeat += 1
    if !automation.isEmpty { drive(state) }
    if state.phase == "fight" {
      input("move", x: movement.x, z: movement.z)
      if guarding { input("guard", down: true) }
    }
    if heartbeat % 10 == 0 {
      log(EvidenceRecord(type: "snapshot", identity: identity, state: state))
    }
  }

  private func drive(_ state: ArenaState) {
    guard let me, let opponent else {
      demoStep = "01 • WAIT FOR DISTINCT PEER"
      return
    }
    if state.phase == "lobby" {
      demoStep = "02 • BOTH PEERS READY"
      if !me.ready && Date.timeIntervalSinceReferenceDate - readyAt > 5 { ready() }
      return
    }
    if state.phase == "result" {
      movement = (0, 0)
      demoStep = "07 • SHARED WINNER → MUTUAL REMATCH"
      if resultAt == 0 { resultAt = Date.timeIntervalSinceReferenceDate }
      if Date.timeIntervalSinceReferenceDate - resultAt > 7 { rematch() }
      return
    }
    resultAt = 0
    guard state.phase == "fight", !state.paused else { return }
    if autoRound != state.round {
      autoRound = state.round
      autoTagged = false
    }
    let elapsed = 3600 - state.remaining
    let dx = opponent.x - me.x
    let dz = opponent.z - me.z
    let sign = dx > 0 ? 1.0 : -1.0
    movement = (abs(dx) > 1.24 ? sign : 0, abs(dz) > 0.15 ? (dz > 0 ? 1 : -1) : 0)
    guarding = false
    demoStep = "04 • COMBOS / LAUNCH / SHARED DAMAGE"
    if elapsed < 80 {
      demoStep = "03 • SIDESTEP + GUARD"
      movement.z = automation == "alpha" ? 0.65 : -0.65
      guarding = automation == "bravo"
    }
    if elapsed > 310 && !autoTagged && me.attack.isEmpty && me.stun == 0 {
      action("tag")
      autoTagged = true
      demoStep = "05 • TAG RESERVE FIGHTER"
    }
    if elapsed < 100 { return }
    let interval = automation == "alpha" ? 30 : 85
    if state.tick - autoActionTick >= interval {
      let step = (elapsed / interval) % 7
      let attack = step == 0 ? "launch" : step == 3 || step == 6 ? "kick" : "punch"
      action(attack)
      autoActionTick = state.tick
    }
  }

  private func log(_ body: EvidenceRecord) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    guard let bytes = try? encoder.encode(body) else { return }
    try? telemetry?.write(contentsOf: bytes + Data("\n".utf8))
  }
}
