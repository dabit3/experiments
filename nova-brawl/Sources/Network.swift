import Combine
import Foundation

struct Vec: Codable {
  var x: Double
  var y: Double
  var z: Double
}

struct FighterState: Codable, Identifiable {
  var id: String
  var name: String
  var slot: Int
  var connected: Bool
  var ready: Bool
  var hp: Double
  var energy: Double
  var pos: Vec
  var yaw: Double
  var flying: Bool
  var locked: Bool
  var mode: String
  var combo: Int
  var damage: Int
  var hits: Int
  var dodges: Int
}

struct ShotState: Codable {
  var id: Int
  var owner: String
  var pos: Vec
  var dir: Vec
}

struct CombatEffect: Codable {
  var event: Int
  var type: String
  var player: String?
  var target: String?
  var kind: String?
  var combo: Int?
  var amount: Int?
  var pos: Vec?
  var dir: Vec?
}

struct ArenaState: Codable {
  var code: String
  var phase: String
  var round: Int
  var tick: Int
  var time: Double
  var countdown: Double
  var winner: String
  var reason: String
  var paused: Bool
  var players: [FighterState]
  var projectiles: [ShotState]
  var effects: [CombatEffect]
}

private struct Envelope: Decodable {
  var type: String
  var id: String?
  var token: String?
  var message: String?
}

private struct JoinMessage: Encodable {
  var type = "join"
  var name: String
  var code: String
  var create: Bool
  var token: String
}

private struct InputMessage: Encodable {
  var type = "input"
  var seq: Int
  var x: Double
  var z: Double
  var lift: Double
  var charge: Bool
  var boost: Bool
  var actions: [String]
}

private struct SimpleMessage: Encodable {
  var type: String
}

@MainActor
final class GameModel: ObservableObject {
  @Published var state: ArenaState?
  @Published var playerID = ""
  @Published var connection = "OFFLINE"
  @Published var error = ""
  @Published var server = "ws://127.0.0.1:8787"
  @Published var guestName = "Flare"
  @Published var room = String(UUID().uuidString.prefix(6)).uppercased()
  @Published var help = false
  @Published var muted = false
  @Published var autoLabel = ""
  @Published var feedback = "LOCK ON • RISE ABOVE"
  @Published var reconnecting = false
  let arena = ArenaRenderer()
  let audio = ArenaAudio()
  var moveX = 0.0
  var moveZ = 0.0
  var lift = 0.0
  var charge = false
  var boost = false
  private var socket: URLSessionWebSocketTask?
  private var timer: Timer?
  private var token = ""
  private var activeRoom = ""
  private var seq = 0
  private var actions: [String] = []
  private var seenEvent = 0
  private var generation = 0
  private var wantsConnection = false
  private var autoRole = ""
  private var autoStep = 0
  private var lastReadyRound = -1
  private var resultAt = Date.distantPast
  private var lastPhase = ""

  var local: FighterState? { state?.players.first { $0.id == playerID } }
  var opponent: FighterState? { state?.players.first { $0.id != playerID } }
  var playing: Bool { state?.phase == "playing" }

  init() {
    let args = ProcessInfo.processInfo.arguments
    func value(_ key: String) -> String? {
      guard let index = args.firstIndex(of: key), index + 1 < args.count else { return nil }
      return args[index + 1]
    }
    server = value("--server") ?? UserDefaults.standard.string(forKey: "nova.server") ?? server
    guestName = value("--name") ?? guestName
    room = value("--room") ?? room
    autoRole = value("--auto") ?? ""
    if !autoRole.isEmpty {
      autoLabel = "AUTOMATED INPUT • \(autoRole.uppercased())"
    }
    arena.preview()
    timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.frame() }
    }
    if args.contains("--connect") {
      Task { [weak self] in
        try? await Task.sleep(nanoseconds: 700_000_000)
        self?.connect(create: args.contains("--create"))
      }
    }
  }

  func connect(create: Bool) {
    guard let url = URL(string: server),
      ["ws", "wss"].contains(url.scheme?.lowercased() ?? ""), url.host != nil
    else {
      error = "Enter a valid ws:// or wss:// server address."
      return
    }
    if activeRoom != room.uppercased() {
      token = ""
      state = nil
      seenEvent = 0
      activeRoom = room.uppercased()
    }
    guard !guestName.trimmingCharacters(in: .whitespaces).isEmpty else {
      error = "Choose a guest name."
      return
    }
    UserDefaults.standard.set(server, forKey: "nova.server")
    wantsConnection = true
    error = ""
    connection = "CONNECTING"
    generation += 1
    let current = generation
    socket?.cancel(with: .goingAway, reason: nil)
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    send(
      JoinMessage(name: guestName, code: activeRoom, create: token.isEmpty && create, token: token))
    Task { [weak self] in
      do {
        while !Task.isCancelled {
          let message = try await task.receive()
          guard let self, self.generation == current else { return }
          let data: Data
          switch message {
          case .data(let bytes): data = bytes
          case .string(let text): data = Data(text.utf8)
          @unknown default: continue
          }
          self.receive(data)
        }
      } catch {
        guard let self, self.generation == current, self.wantsConnection else { return }
        self.connection = "DISCONNECTED"
        self.reconnecting = !self.token.isEmpty
        self.error =
          self.token.isEmpty
          ? "Could not reach server. Check its address and that it is running." : ""
        if self.reconnecting {
          try? await Task.sleep(nanoseconds: 1_500_000_000)
          guard self.generation == current, self.wantsConnection else { return }
          self.connect(create: false)
        }
      }
    }
  }

  private func send<T: Encodable>(_ message: T) {
    guard let data = try? JSONEncoder().encode(message),
      let text = String(data: data, encoding: .utf8)
    else { return }
    socket?.send(.string(text)) { _ in }
  }

  private func receive(_ data: Data) {
    guard let message = try? JSONDecoder().decode(Envelope.self, from: data) else { return }
    if message.type == "welcome" {
      playerID = message.id ?? ""
      token = message.token ?? ""
      connection = "LIVE"
      reconnecting = false
      seq = 0
      print("NOVA_PEER \(playerID) \(activeRoom)")
    } else if message.type == "error" {
      leave()
      error = message.message ?? "Server rejected request."
    } else if message.type == "state",
      let next = try? JSONDecoder().decode(ArenaState.self, from: data)
    {
      if next.phase != lastPhase {
        print("NOVA_PHASE \(next.phase) round=\(next.round) peer=\(playerID) winner=\(next.winner)")
        if next.phase == "result" {
          resultAt = Date()
          audio.play("result")
        }
        if next.phase == "playing" { audio.play("start") }
        lastPhase = next.phase
      }
      state = next
      arena.update(next, localID: playerID)
      for effect in next.effects where effect.event > seenEvent {
        if effect.type == "hit" {
          feedback =
            effect.target == playerID
            ? "IMPACT −\(effect.amount ?? 0)"
            : "\(effect.kind?.uppercased() ?? "HIT") +\(effect.amount ?? 0)"
          audio.play(effect.kind == "beam" ? "beam" : "hit")
        } else if ["shot", "beamCharge", "dodge", "melee"].contains(effect.type) {
          audio.play(effect.type)
        }
        seenEvent = effect.event
      }
    }
  }

  func action(_ action: String) {
    guard playing, actions.count < 6 else { return }
    actions.append(action)
  }

  func ready() { send(SimpleMessage(type: "ready")) }
  func leave() {
    wantsConnection = false
    reconnecting = false
    generation += 1
    socket?.cancel(with: .normalClosure, reason: nil)
    state = nil
    token = ""
    activeRoom = ""
    seenEvent = 0
    lastPhase = ""
    lastReadyRound = -1
    playerID = ""
    connection = "OFFLINE"
    resetControls()
    arena.preview()
  }

  func resetControls() {
    moveX = 0
    moveZ = 0
    lift = 0
    charge = false
    boost = false
    actions = []
  }

  func toggleMute() {
    muted.toggle()
    audio.muted = muted
  }

  private func frame() {
    guard connection == "LIVE", let state else { return }
    if !autoRole.isEmpty { automate(state) }
    seq += 1
    send(
      InputMessage(
        seq: seq, x: moveX, z: moveZ, lift: lift, charge: charge, boost: boost, actions: actions))
    actions = []
  }

  private func automate(_ state: ArenaState) {
    autoStep += 1
    if ["lobby", "result"].contains(state.phase) {
      resetControls()
      if state.players.count == 2 && lastReadyRound != state.round
        && (state.phase == "lobby" || Date().timeIntervalSince(resultAt) > 7)
      {
        lastReadyRound = state.round
        ready()
      }
      return
    }
    guard playing, !state.paused, let me = local, let other = opponent else { return }
    let elapsed = 90 - state.time
    let distance = hypot(me.pos.x - other.pos.x, me.pos.z - other.pos.z)
    let cycle = Int(elapsed) % 15
    let aggressive = autoRole == "flare"
    moveX = 0
    moveZ = 0
    lift = 0
    charge = false
    boost = false
    if elapsed < 2 {
      if !me.flying && autoStep % 10 == 0 { action("flight") }
      lift = 0.8
      moveX = aggressive ? 0.35 : -0.35
    } else if cycle >= 11 || me.energy < 12 {
      charge = true
    } else if cycle == 4 && autoStep % 18 == 0 {
      action("dodge")
    } else {
      if me.flying { lift = max(-1, min(1, (other.pos.y - me.pos.y) / 3)) }
      if distance > 3.0 {
        moveZ = 0.9
        boost = distance > 10
        if autoStep % (aggressive ? 13 : 24) == 0 { action("shot") }
      } else if autoStep % (aggressive ? 8 : 15) == 0 {
        action("melee")
      }
      if cycle == 7 && me.energy >= 45 && autoStep % 20 == 0 {
        moveZ = 0
        action("beam")
      }
    }
  }
}
