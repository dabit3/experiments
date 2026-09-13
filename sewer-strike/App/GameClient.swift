import Combine
import Foundation
import SwiftUI

@MainActor
final class GameClient: ObservableObject {
  @Published var state: GameState?
  @Published var status = "OFFLINE"
  @Published var error = ""
  @Published var playerID = ""
  @Published var connected = false
  @Published var connecting = false
  @Published var automation = false
  @Published var driverStep = "MANUAL TOUCH CONTROLS"
  @Published var sentInputs = 0
  @Published var address = UserDefaults.standard.string(forKey: "server") ?? "ws://127.0.0.1:8767"
  @Published var guest = "Guest"
  @Published var room = ""
  @Published var hero = 0
  let world = GameWorld()
  let audio = GameAudio()
  let testMode: Bool
  private var socket: URLSessionWebSocketTask?
  private var timer: Timer?
  private var receiveTask: Task<Void, Never>?
  private var token = ""
  private var seq = 0
  private var movement = CGVector.zero
  private var pending: [String] = []
  private var lastAction = 0.0
  private var lastJump = 0.0
  private var readySent = false
  private var createRoom = false
  private var reconnecting = false
  private var generation = 0
  private var lastEvent = 0
  private var lastLoggedTick = -30
  private let autoReady: Bool
  private let autoRematch: Bool
  private let logger = EvidenceLog()

  var me: PlayerState? { state?.players.first { $0.id == playerID } }
  init() {
    let args = ProcessInfo.processInfo.arguments
    func value(_ flag: String) -> String? {
      guard let i = args.firstIndex(of: flag), args.indices.contains(i + 1) else { return nil }
      return args[i + 1]
    }
    testMode = args.contains("-testMode") || args.contains("-autoplay")
    autoReady = args.contains("-autoReady")
    autoRematch = args.contains("-autoRematch")
    if let server = value("-server") { address = server }
    if let name = value("-guest") { guest = name }
    if let code = value("-room") { room = code }
    if let number = value("-hero"), let selected = Int(number), (0..<4).contains(selected) {
      hero = selected
    }
    automation = args.contains("-autoplay")
    if args.contains("-connect") {
      Task {
        try? await Task.sleep(for: .milliseconds(600))
        connect(create: args.contains("-create"))
      }
    }
  }
  func connect(create: Bool) {
    guard let url = URL(string: address), ["ws", "wss"].contains(url.scheme), url.host != nil else {
      error = "Enter a WebSocket address, for example ws://192.168.1.5:8767"
      return
    }
    createRoom = create
    error = ""
    connecting = true
    status = token.isEmpty ? "CONNECTING" : "RECONNECTING"
    UserDefaults.standard.set(address, forKey: "server")
    generation += 1
    let currentGeneration = generation
    receiveTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    send(Outbound(type: "hello", name: guest, hero: hero, code: room, create: create, token: token))
    receiveTask = Task { [weak self] in
      while !Task.isCancelled {
        do {
          let message = try await task.receive()
          let data: Data
          switch message {
          case .data(let bytes): data = bytes
          case .string(let text): data = Data(text.utf8)
          @unknown default: continue
          }
          guard let self, currentGeneration == self.generation else { return }
          self.receive(data)
        } catch {
          guard let self, currentGeneration == self.generation, !Task.isCancelled else { return }
          self.connected = false
          self.connecting = false
          self.status = "CONNECTION LOST"
          self.error = "Server unreachable. Check its address and Wi-Fi. Retry to keep your hero."
          self.logger.write(["event": "connectionLost", "detail": error.localizedDescription])
          if !self.token.isEmpty && !self.reconnecting {
            self.reconnecting = true
            try? await Task.sleep(for: .seconds(2))
            if currentGeneration == self.generation {
              self.reconnecting = false
              self.connect(create: false)
            }
          }
          return
        }
      }
    }
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.frame() }
    }
    audio.start()
  }
  private func receive(_ data: Data) {
    do {
      let header = try JSONDecoder().decode(Envelope.self, from: data)
      if header.type == "welcome" {
        playerID = header.id ?? ""
        token = header.token ?? ""
        room = header.code ?? room
        seq = 0
        connected = true
        connecting = false
        error = ""
        status = header.resumed == true ? "REJOINED • LIVE" : "LIVE • 30 HZ"
        logger.write([
          "event": "welcome", "id": playerID, "code": room, "resumed": header.resumed ?? false,
        ])
      } else if header.type == "error" {
        error = header.message ?? "Connection rejected"
        connecting = false
      } else if header.type == "state" {
        let next = try JSONDecoder().decode(GameState.self, from: data)
        state = next
        world.update(next, localID: playerID)
        for event in next.events where event.id > lastEvent {
          if event.tick >= next.tick - 8 { audio.play(event.kind) }
          lastEvent = event.id
        }
        if next.tick - lastLoggedTick >= 30 {
          logger.state(next, playerID: playerID)
          lastLoggedTick = next.tick
        }
      }
    } catch {
      self.error = "Protocol mismatch: \(error.localizedDescription)"
      logger.write(["event": "decodeError", "detail": error.localizedDescription])
    }
  }
  func send(_ message: Outbound) {
    guard let data = try? JSONEncoder().encode(message),
      let text = String(data: data, encoding: .utf8)
    else { return }
    socket?.send(.string(text)) { _ in }
  }
  func ready() { send(Outbound(type: "ready")) }
  func rematch() { send(Outbound(type: "rematch")) }
  func move(_ vector: CGVector) {
    movement = vector
  }
  func action(_ name: String) {
    if pending.count < 4 { pending.append(name) }
  }
  func toggleAutomation() {
    automation.toggle()
    movement = .zero
    pending = []
    driverStep = automation ? "AUTOMATED INPUT DRIVER" : "MANUAL TOUCH CONTROLS"
  }
  func retry() {
    reconnecting = false
    connect(create: token.isEmpty ? createRoom : false)
  }
  func reconnectTest() {
    generation += 1
    receiveTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    connected = false
    status = "REJOINING SAME HERO…"
    Task {
      try? await Task.sleep(for: .seconds(1))
      connect(create: false)
    }
  }
  func leave() {
    generation += 1
    timer?.invalidate()
    receiveTask?.cancel()
    socket?.cancel(with: .normalClosure, reason: nil)
    state = nil
    token = ""
    playerID = ""
    connected = false
    connecting = false
    readySent = false
    lastEvent = 0
    lastLoggedTick = -30
    movement = .zero
    pending = []
    error = ""
    status = "OFFLINE"
  }
  private func frame() {
    guard connected, let state else { return }
    if autoReady && state.phase == "lobby" && !readySent {
      readySent = true
      ready()
    }
    if autoRematch && state.phase == "clear" && state.match == 1 && !((me?.rematch) ?? false) {
      if state.tick - (state.events.last(where: { $0.kind == "clear" })?.tick ?? state.tick) > 150 {
        rematch()
      }
    }
    if automation && state.phase == "playing" { drive(state) }
    guard state.phase == "playing" else { return }
    let action = pending.isEmpty ? nil : pending.removeFirst()
    send(Outbound(type: "input", seq: seq, dx: movement.dx, dy: movement.dy, action: action))
    seq += 1
    sentInputs += 1
    if let action {
      logger.write(["event": "input", "seq": seq - 1, "action": action, "automated": automation])
    }
  }
  private func drive(_ state: GameState) {
    guard let me, me.hp > 0 else {
      movement = .zero
      return
    }
    let t = Double(state.tick) / 30
    if let down = state.players.first(where: { $0.id != playerID && $0.hp == 0 && $0.connected }) {
      steer(x: down.x, y: down.y, me: me, stop: 40)
      driverStep = "AUTO • REVIVING TEAMMATE"
      return
    }
    if let slice = state.pickups.min(by: { abs($0.x - me.x) < abs($1.x - me.x) }), me.hp < 65 {
      steer(x: slice.x, y: slice.y, me: me, stop: 10)
      driverStep = "AUTO • COLLECTING POWER SLICE"
      return
    }
    guard
      let target = state.enemies.min(by: {
        hypot($0.x - me.x, ($0.y - me.y) * 1.5) < hypot($1.x - me.x, ($1.y - me.y) * 1.5)
      })
    else {
      steer(x: Double(state.gate) + 35, y: me.hero % 2 == 0 ? -30 : 30, me: me, stop: 10)
      driverStep = "AUTO • CREW ADVANCES TO NEXT SECTOR"
      return
    }
    let reach = [78.0, 65, 110, 55][me.hero]
    let dx = target.x - me.x
    let dy = target.y - me.y
    steer(x: target.x, y: target.y, me: me, stop: reach)
    if abs(dy) > 25 { movement.dy = dy > 0 ? 0.8 : -0.8 }
    if abs(dx) < reach + 20 && abs(dy) < 40 {
      movement.dx = dx > 0 ? 0.08 : -0.08
      driverStep =
        target.kind == "boss" ? "AUTO • BOSS COMBOS / JUMP DODGES" : "AUTO • SHARED WAVE COMBAT"
      if t - lastAction > 0.35 {
        action(me.power >= 50 ? "special" : "attack")
        lastAction = t
      }
    } else {
      driverStep = "AUTO • APPROACHING ENEMY"
    }
    if t - lastJump > 2.1 || (target.action == "windup" && target.timer < 0.6 && t - lastJump > 1.1)
    {
      action("jump")
      lastJump = t
    }
  }
  private func steer(x: Double, y: Double, me: PlayerState, stop: Double) {
    let dx = x - me.x
    let dy = y - me.y
    movement = CGVector(
      dx: abs(dx) > stop ? (dx > 0 ? 1 : -1) : 0,
      dy: abs(dy) > 15 ? (dy > 0 ? 0.7 : -0.7) : 0)
  }
}

final class EvidenceLog {
  private let handle: FileHandle?
  init() {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("session.jsonl")
    if !FileManager.default.fileExists(atPath: url.path) {
      FileManager.default.createFile(atPath: url.path, contents: nil)
    }
    handle = try? FileHandle(forWritingTo: url)
    try? handle?.seekToEnd()
  }
  func write(_ object: [String: any Sendable]) {
    guard JSONSerialization.isValidJSONObject(object),
      let bytes = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    else { return }
    try? handle?.write(contentsOf: bytes + Data([10]))
  }
  func state(_ state: GameState, playerID: String) {
    guard let bytes = try? JSONEncoder().encode(state) else { return }
    try? handle?.write(contentsOf: bytes + Data([10]))
  }
}
