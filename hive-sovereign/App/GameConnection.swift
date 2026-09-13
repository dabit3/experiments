import Combine
import Foundation
import UIKit

@MainActor
final class GameConnection: ObservableObject {
  @Published var address = "ws://127.0.0.1:8789"
  @Published var name = "Captain"
  @Published var roomCode = ""
  @Published var state: Envelope?
  @Published var connection = "OFFLINE"
  @Published var error = ""
  @Published var autoPilot = false
  @Published var driverLabel = ""
  @Published var muted = false
  let scene = HiveScene()
  private var socket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var inputTimer: Timer?
  private var reconnectTask: Task<Void, Never>?
  private var sequence = 0
  private var guestID = UUID().uuidString
  private var token = ""
  private var intentionalDisconnect = false
  private var readyMatch = -1
  private var lastMatch = 0
  private var driverOrder = "economy"
  var input = GameInput()

  var team: Int { me?.team ?? 0 }
  var me: PeerState? { state?.peers?.first { $0.id == guestID } }
  var controlled: UnitState? {
    state?.game?.units.first { $0.id == "\(team)-\(me?.slot ?? 1)" }
  }

  init() {
    let args = ProcessInfo.processInfo.arguments
    func argument(_ key: String) -> String? {
      guard let index = args.firstIndex(of: key), index + 1 < args.count else { return nil }
      return args[index + 1]
    }
    address = argument("--server") ?? address
    name = argument("--name") ?? name
    roomCode = argument("--room") ?? ""
    driverOrder = argument("--strategy") ?? "economy"
    autoPilot = args.contains("--autopilot")
    scene.connection = self
    inputTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) {
      [weak self] _ in
      Task { @MainActor in self?.pump() }
    }
    if args.contains("--create") || !roomCode.isEmpty {
      Task {
        try? await Task.sleep(for: .milliseconds(800))
        connect(create: args.contains("--create"))
      }
    }
  }

  func connect(create: Bool = false, resume: Bool = false) {
    guard let url = URL(string: address), ["ws", "wss"].contains(url.scheme ?? ""), url.host != nil
    else {
      error = "Enter a valid ws:// or wss:// server address."
      return
    }
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty, name.count <= 18 else {
      error = "Choose a guest name of 1–18 characters."
      return
    }
    if !create && roomCode.isEmpty {
      error = "Enter your opponent’s room code."
      return
    }
    intentionalDisconnect = false
    reconnectTask?.cancel()
    receiveTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    if !resume {
      token = ""
      state = nil
      guestID = UUID().uuidString
    }
    error = ""
    connection = "CONNECTING"
    sequence = 0
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    send(
      Command(
        type: "hello", id: guestID, name: name, room: roomCode.uppercased(), token: token,
        create: create))
    receiveTask = Task { [weak self] in
      while !Task.isCancelled {
        do {
          let message = try await task.receive()
          let data: Data
          switch message {
          case .string(let text): data = Data(text.utf8)
          case .data(let bytes): data = bytes
          @unknown default: continue
          }
          let envelope = try JSONDecoder().decode(Envelope.self, from: data)
          self?.accept(envelope)
        } catch {
          if !Task.isCancelled { self?.lostConnection() }
          return
        }
      }
    }
  }

  private func accept(_ envelope: Envelope) {
    if envelope.type == "welcome" {
      token = envelope.token ?? ""
      roomCode = envelope.room ?? ""
      connection = "CONNECTED"
      error = ""
    } else if envelope.type == "error" {
      error = envelope.message ?? "The server rejected this request."
      if state == nil {
        intentionalDisconnect = true
        receiveTask?.cancel()
        socket?.cancel(with: .normalClosure, reason: nil)
        connection = "OFFLINE"
      }
    } else if envelope.type == "state" {
      state = envelope
      connection = "CONNECTED"
      scene.apply(envelope)
      if let match = envelope.match, match != lastMatch {
        lastMatch = match
        send(Command(type: "order", order: driverOrder))
      }
    }
  }

  private func lostConnection() {
    guard !intentionalDisconnect else { return }
    input = GameInput()
    connection = "RECONNECTING"
    if token.isEmpty {
      connection = "OFFLINE"
      error = "Cannot reach host. Start the server and check the address."
      return
    }
    reconnectTask = Task {
      try? await Task.sleep(for: .seconds(2))
      guard !Task.isCancelled else { return }
      connect(resume: true)
    }
  }

  func disconnect() {
    intentionalDisconnect = true
    reconnectTask?.cancel()
    receiveTask?.cancel()
    socket?.cancel(with: .normalClosure, reason: nil)
    connection = "OFFLINE"
    state = nil
    input = GameInput()
    token = ""
    readyMatch = -1
  }

  func ready() { send(Command(type: "ready")) }
  func switchUnit() { select(slot: ((me?.slot ?? 1) + 1) % 5) }
  func select(slot: Int) {
    input = GameInput()
    send(Command(type: "switch", slot: slot))
  }
  func order(_ order: String) {
    driverOrder = order
    send(Command(type: "order", order: order))
  }
  func toggleAudio() {
    muted.toggle()
    scene.audio.muted = muted
  }

  func handleURL(_ url: URL) {
    guard url.scheme == "hivesovereign" else { return }
    let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    func value(_ key: String) -> String? { query.first { $0.name == key }?.value }
    if url.host == "driver" {
      autoPilot = value("enabled") != "0"
      if let strategy = value("strategy"), ["economy", "snail", "military"].contains(strategy) {
        order(strategy)
      }
    } else if url.host == "ready" {
      ready()
    } else if url.host == "select", let slot = Int(value("slot") ?? ""), (0...4).contains(slot) {
      select(slot: slot)
    } else if url.host == "reconnect" {
      connect(resume: true)
    }
  }

  private func send(_ command: Command) {
    guard let socket, let data = try? JSONEncoder().encode(command),
      let text = String(data: data, encoding: .utf8)
    else { return }
    Task { try? await socket.send(.string(text)) }
  }

  private func pump() {
    if autoPilot, let state {
      if state.phase == "lobby", state.peers?.count == 2, readyMatch != (state.match ?? 0) {
        readyMatch = state.match ?? 0
        ready()
      }
      if state.phase == "playing", let game = state.game, let unit = controlled {
        input = CaptainDriver.input(game: game, unit: unit, strategy: driverOrder)
        driverLabel = "\(driverOrder.uppercased()) • SAME NETWORK INPUT"
      }
    }
    guard state?.phase == "playing", connection == "CONNECTED" else { return }
    sequence += 1
    send(
      Command(
        type: "input", seq: sequence, move: input.move, jump: input.jump, action: input.action,
        dive: input.dive))
  }
}

enum CaptainDriver {
  private static func distance(_ a: UnitState, _ x: Double, _ y: Double) -> Double {
    hypot(a.x - x, a.y - y)
  }
  private static func direction(_ delta: Double) -> Double {
    abs(delta) < 7 ? 0 : (delta > 0 ? 1 : -1)
  }
  static func input(game: GameState, unit: UnitState, strategy: String) -> GameInput {
    if unit.dead > 0 { return GameInput() }
    if unit.role != "worker" {
      let foe = game.units.first { $0.team != unit.team && $0.role == "queen" }
      return GameInput(
        move: direction((foe?.x ?? 480) - unit.x),
        jump: unit.y < (foe?.y ?? 300) + 24 && unit.cooldown <= 0,
        dive: unit.role == "queen" && abs((foe?.x ?? 0) - unit.x) < 22
          && unit.y > (foe?.y ?? 0) + 20)
    }
    var tx = unit.team == 0 ? 385.0 : 575.0
    var ty = 395.0
    var use = false
    if strategy == "snail" {
      tx = game.snail.x
      ty = 65
      use = true
    } else if !unit.berry {
      if let b = game.berries.min(by: {
        distance(unit, $0.x, $0.y) < distance(unit, $1.x, $1.y)
      }) {
        tx = b.x
        ty = b.y
      }
    } else if strategy == "military",
      let gate = game.gates.filter({
        $0.kind == "warrior" && ($0.team == -1 || $0.team == unit.team)
      })
      .min(by: { distance(unit, $0.x, $0.y) < distance(unit, $1.x, $1.y) })
    {
      tx = gate.x
      ty = gate.y
      use = true
    }
    if distance(unit, tx, ty) < 24 && use { return GameInput(action: true) }
    return navigate(game.platforms, unit: unit, x: tx, y: ty)
  }

  private static func navigate(_ platforms: [PlatformState], unit: UnitState, x: Double, y: Double)
    -> GameInput
  {
    func nearest(_ x: Double, _ y: Double) -> Int {
      platforms.indices.min {
        let a = platforms[$0]
        let b = platforms[$1]
        return abs(y - a.y) * 3 + max(a.x - x, x - a.x - a.w, 0) < abs(y - b.y) * 3
          + max(b.x - x, x - b.x - b.w, 0)
      } ?? 0
    }
    let from = nearest(unit.x, unit.y)
    let dest = nearest(x, y)
    var paths = [[from]]
    var visited: Set<Int> = [from]
    var route = [from, dest]
    while !paths.isEmpty {
      let path = paths.removeFirst()
      guard let last = path.last else { break }
      if last == dest {
        route = path
        break
      }
      for i in platforms.indices where !visited.contains(i) {
        let a = platforms[last]
        let b = platforms[i]
        let gap = max(b.x - a.x - a.w, a.x - b.x - b.w, 0)
        if b.y - a.y <= 95 && b.y - a.y >= -180 && gap <= 90 {
          visited.insert(i)
          paths.append(path + [i])
        }
      }
    }
    if from == dest { return GameInput(move: direction(x - unit.x)) }
    let next = platforms[route.count > 1 ? route[1] : dest]
    if !unit.grounded {
      let tx = max(next.x + 15, min(next.x + next.w - 15, unit.x))
      return GameInput(move: direction(tx - unit.x))
    }
    if next.y > unit.y + 10 {
      let tx = max(next.x + 20, min(next.x + next.w - 20, unit.x))
      return GameInput(
        move: direction(tx - unit.x), jump: abs(tx - unit.x) < 115 && unit.cooldown <= 0)
    }
    let current = platforms[from]
    let left = current.x - 18
    let right = current.x + current.w + 18
    return GameInput(move: direction((abs(x - left) < abs(x - right) ? left : right) - unit.x))
  }
}
