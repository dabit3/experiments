import Combine
import Foundation
import SwiftUI

struct Hero: Identifiable {
  let id: Int
  let name: String
  let subtitle: String
  let powerName: String
  let trait: String
  let hp: Int
  let color: Color
  var faction: String { id < 3 ? "DAWN PACT" : "ECLIPSE ORDER" }
  static let all: [Hero] = [
    Hero(
      id: 0, name: "HELION", subtitle: "THE LAST SUN", powerName: "SOLAR JUDGMENT",
      trait: "Balanced • 125 health", hp: 125, color: Color(hex: 0xF4C86A)),
    Hero(
      id: 1, name: "NOCTURNE", subtitle: "SILENCE STRIKES", powerName: "MIDNIGHT REQUIEM",
      trait: "Fast strikes • 105 health", hp: 105, color: Color(hex: 0xA4BCD9)),
    Hero(
      id: 2, name: "TEMPEST", subtitle: "CHASE THE STORM", powerName: "ION TEMPEST",
      trait: "Fastest startup • 100 health", hp: 100, color: Color(hex: 0x52D5F4)),
    Hero(
      id: 3, name: "MONOLITH", subtitle: "IRON NEVER KNEELS", powerName: "EXTINCTION ENGINE",
      trait: "Armored guard • 150 health", hp: 150, color: Color(hex: 0xF49B43)),
    Hero(
      id: 4, name: "HEX", subtitle: "BREAK REALITY", powerName: "FRACTURED DIMENSION",
      trait: "Amplified specials • 110 health", hp: 110, color: Color(hex: 0xCB81ED)),
    Hero(
      id: 5, name: "WRAITH", subtitle: "FEAR THE UNSEEN", powerName: "CRIMSON ECLIPSE",
      trait: "Lethal quick • 105 health", hp: 105, color: Color(hex: 0xF06878)),
  ]
}

extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 255) / 255,
      green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
  }
  static let titanGold = Color(hex: 0xEAC77E)
}

struct AttackState: Codable {
  let kind: String
  let impact: Double
  let tier: Int
  let mash: Int
  let lastMash: Double
}

struct Peer: Codable, Identifiable {
  let id: String
  let name: String
  let team: [Int]
  let connected: Bool
  let ready: Bool
  let rematch: Bool
  let active: Int
  let hp: [Int]
  let power: [Int]
  let blocking: Bool
  let action: String
  let actionAt: Double
  let actionUntil: Double
  let attack: AttackState?
  let lastSeq: Int
  let lastTag: Double
  let combo: Int
  let damage: Int
  let hits: Int
  let blocks: Int
  let specials: Int
  let tags: Int
  var hero: Hero { Hero.all[team[active]] }
}

struct CombatEvent: Codable, Identifiable {
  let id: Int
  let tick: Int
  let type: String
  let source: String
  let target: String
  let amount: Int
  let label: String
}

struct RoomState: Codable {
  let code: String
  let phase: String
  let tick: Int
  let time: Double
  let round: Int
  let players: [Peer]
  let events: [CombatEvent]
  let eventID: Int
  let winner: String
  let remaining: Double
  let startedAt: Double
}

struct Envelope: Codable {
  let type: String
  var id: String?
  var token: String?
  var code: String?
  var lastSeq: Int?
  var message: String?
}

struct Command: Codable {
  var type: String = "input"
  var seq: Int?
  var action: String?
  var down: Bool?
  var slot: Int?
  var team: [Int]?
  var name: String?
  var code: String?
  var token: String?
}

@MainActor
final class GameModel: ObservableObject {
  @Published var address = "ws://127.0.0.1:8793"
  @Published var guest = "Challenger"
  @Published var roomCode = ""
  @Published var selected = [0, 1, 2]
  @Published var room: RoomState?
  @Published var playerID = ""
  @Published var status = "LOCAL NETWORK • REAL-TIME PVP"
  @Published var connected = false
  @Published var connecting = false
  @Published var soundEnabled = true
  @Published var showGuide = false
  @Published var driver = ""
  let scene = BattleScene()
  let audio = GameAudio()
  private var socket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var generation = UUID()
  private var token = ""
  private var seq = 0
  private var driverTimer: Timer?
  private var driverStep = 0
  private var phaseAt = Date()
  private var autoStarted = false
  private var autoRematched = false
  private let automaticRematch: Bool
  private var lastEvent = 0
  private var holdingBlock = false
  private var guardTimer: Timer?
  private var lastLoggedTick = -1
  private let logURL: URL
  var me: Peer? { room?.players.first { $0.id == playerID } }
  var opponent: Peer? { room?.players.first { $0.id != playerID } }
  var fighting: Bool {
    room?.phase == "fight" && connected && room?.players.allSatisfy(\.connected) == true
  }
  var automated: Bool { !driver.isEmpty }

  init() {
    logURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("titan-client.jsonl")
    let args = ProcessInfo.processInfo.arguments
    automaticRematch = !args.contains("--hold-result")
    func argument(_ name: String) -> String? {
      guard let i = args.firstIndex(of: name), args.indices.contains(i + 1) else { return nil }
      return args[i + 1]
    }
    address = argument("--server") ?? UserDefaults.standard.string(forKey: "server") ?? address
    guest = argument("--guest") ?? UserDefaults.standard.string(forKey: "guest") ?? guest
    driver = argument("--driver") ?? ""
    if driver == "beta" { selected = [3, 4, 5] }
    roomCode = argument("--room") ?? ""
    scene.scaleMode = .resizeFill
    scene.audio = audio
    driverTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.drive() }
    }
    if args.contains("--host") || argument("--room") != nil {
      Task {
        try? await Task.sleep(for: .milliseconds(700))
        connect(create: args.contains("--host"))
      }
    }
  }

  func choose(_ hero: Int) {
    guard me?.ready != true else { return }
    if selected.contains(hero) {
      selected.removeAll { $0 == hero }
    } else if selected.count < 3 {
      selected.append(hero)
    }
    if room != nil && selected.count == 3 { sendInput("team", team: selected) }
    audio.play("tap")
  }

  func connect(create: Bool) {
    guard selected.count == 3 else {
      status = "Choose exactly three hero cards"
      return
    }
    guard let url = URL(string: address), ["ws", "wss"].contains(url.scheme), url.host != nil else {
      status = "Enter a valid ws://host:port address"
      return
    }
    guard !guest.trimmingCharacters(in: .whitespaces).isEmpty else {
      status = "Enter a guest name"
      return
    }
    token = ""
    room = nil
    seq = 0
    lastEvent = 0
    lastLoggedTick = -1
    autoStarted = false
    autoRematched = false
    UserDefaults.standard.set(address, forKey: "server")
    UserDefaults.standard.set(guest, forKey: "guest")
    open(
      url: url,
      command: Command(
        type: create ? "create" : "join", team: selected,
        name: guest, code: roomCode.uppercased()))
  }

  private func open(url: URL, command: Command) {
    receiveTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    generation = UUID()
    let current = generation
    connecting = true
    connected = false
    status = "CONNECTING TO ARENA…"
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    transmit(command)
    receiveTask = Task { [weak self] in
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
        guard let self, self.generation == current, !Task.isCancelled else { return }
        self.connected = false
        self.connecting = false
        self.status = "CONNECTION LOST • RECONNECT TO RESUME"
      }
    }
  }

  private func receive(_ data: Data) {
    guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else { return }
    if envelope.type == "welcome" {
      playerID = envelope.id ?? ""
      token = envelope.token ?? ""
      roomCode = envelope.code ?? ""
      seq = envelope.lastSeq ?? 0
      connected = true
      connecting = false
      status = "CONNECTED • \(playerID.prefix(8))"
      if let safe = try? JSONEncoder().encode(
        Envelope(type: "welcome", id: playerID, code: roomCode, lastSeq: seq))
      {
        log(safe)
      }
    } else if envelope.type == "error" {
      status = envelope.message ?? "Connection error"
      connecting = false
    } else if envelope.type == "state",
      let state = try? JSONDecoder().decode(RoomState.self, from: data)
    {
      if room?.phase != state.phase { phaseAt = Date() }
      room = state
      if let peer = me { seq = max(seq, peer.lastSeq) }
      scene.apply(state: state, localID: playerID)
      if state.tick != lastLoggedTick && (state.tick % 4 == 0 || state.phase == "result") {
        log(data)
        lastLoggedTick = state.tick
      }
      for event in state.events where event.id > lastEvent {
        if event.type == "fight" { audio.play("start") }
        if event.type == "result" { audio.play("win") }
        lastEvent = event.id
      }
    }
  }

  func sendInput(_ action: String, down: Bool? = nil, slot: Int? = nil, team: [Int]? = nil) {
    guard connected else { return }
    seq += 1
    transmit(Command(seq: seq, action: action, down: down, slot: slot, team: team))
  }

  private func transmit(_ command: Command) {
    guard let data = try? JSONEncoder().encode(command),
      let text = String(data: data, encoding: .utf8)
    else { return }
    if command.token == nil { log(data) }
    let current = generation
    socket?.send(.string(text)) { [weak self] error in
      if error != nil {
        Task { @MainActor in
          guard let self, self.generation == current else { return }
          self.status = "SERVER UNREACHABLE • CHECK ADDRESS"
          self.connecting = false
        }
      }
    }
  }

  private func log(_ data: Data) {
    if !FileManager.default.fileExists(atPath: logURL.path) {
      FileManager.default.createFile(atPath: logURL.path, contents: nil)
    }
    guard let handle = try? FileHandle(forWritingTo: logURL) else { return }
    defer { try? handle.close() }
    do {
      try handle.seekToEnd()
      try handle.write(contentsOf: data + Data([10]))
    } catch {}
  }

  func block(_ down: Bool) {
    if down == holdingBlock { return }
    holdingBlock = down
    sendInput("block", down: down)
    guardTimer?.invalidate()
    if down {
      guardTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
        Task { @MainActor in self?.sendInput("block", down: true) }
      }
    }
  }

  func reconnect() {
    guard let url = URL(string: address), !token.isEmpty else { return }
    open(url: url, command: Command(type: "resume", token: token))
  }

  func leave() {
    transmit(Command(type: "leave"))
    generation = UUID()
    receiveTask?.cancel()
    socket?.cancel(with: .normalClosure, reason: nil)
    connected = false
    connecting = false
    room = nil
    token = ""
    playerID = ""
    holdingBlock = false
    guardTimer?.invalidate()
    status = "LOCAL NETWORK • REAL-TIME PVP"
    driver = ""
  }

  func toggleAudio() {
    soundEnabled.toggle()
    audio.enabled = soundEnabled
  }

  func handleURL(_ url: URL) {
    guard url.scheme == "titanuprising",
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else { return }
    let value = { (key: String) in components.queryItems?.first { $0.name == key }?.value }
    if url.host == "input", let action = value("action") {
      sendInput(
        action, down: value("down").map { $0 == "true" }, slot: value("slot").flatMap(Int.init))
    } else if url.host == "reconnect" {
      reconnect()
    } else if url.host == "driver" {
      driver = value("mode") ?? ""
    }
  }

  private func drive() {
    guard automated, connected, let room, let me else { return }
    driverStep += 1
    if room.phase == "lobby", room.players.count == 2, !me.ready, !autoStarted {
      if Date().timeIntervalSince(phaseAt) > 2 {
        sendInput("ready")
        autoStarted = true
      }
      return
    }
    if room.phase == "result", automaticRematch, !autoRematched,
      Date().timeIntervalSince(phaseAt) > 7
    {
      sendInput("rematch")
      autoRematched = true
      return
    }
    guard fighting else { return }
    if me.attack?.kind == "special" {
      sendInput("special")
      return
    }
    let isAlpha = driver == "alpha"
    if driverStep % 87 == 0 {
      let next = (me.active + 1) % 3
      if me.hp[next] > 0 {
        sendInput("tag", slot: next)
        return
      }
    }
    if me.power[me.active] >= 100 {
      sendInput("special")
      return
    }
    if isAlpha {
      if driverStep % 19 == 0 {
        sendInput("strong")
      } else if driverStep % 3 == 0 {
        sendInput("quick")
      }
    } else {
      if driverStep % 28 == 0 {
        sendInput("block", down: true)
      } else if driverStep % 28 == 4 {
        sendInput("block", down: false)
      } else if driverStep % 9 == 0 {
        sendInput("quick")
      } else if driverStep % 17 == 0 {
        sendInput("strong")
      }
    }
  }
}
