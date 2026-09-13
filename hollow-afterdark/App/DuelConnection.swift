import Combine
import Foundation

@MainActor
final class DuelConnection: ObservableObject {
  @Published var state: MatchState?
  @Published var connected = false
  @Published private(set) var connecting = false
  @Published var status = "OFFLINE / LOCAL NETWORK"
  @Published var playerID = ""
  @Published var inRoom = false
  @Published var automation = false
  @Published var muted = false
  var held = HeldInput()
  var server = "ws://127.0.0.1:8787"
  var room = "NIGHT"
  var guest = "Ren"
  var driverRole = ""
  private var socket: URLSessionWebSocketTask?
  private var sequence = 0
  private var token = ""
  private var generation = 0
  private var timer: Timer?
  private var driverTick = 0
  private var autoReadyTick = 0
  private var stopReconnect = false
  private var lastStateDate = Date()
  private var retryPending = false
  private var lastPhase = ""
  private var phaseAge = 0
  let audio = NightAudio()

  init() {
    let arguments = ProcessInfo.processInfo.arguments
    func value(_ key: String) -> String? {
      guard let index = arguments.firstIndex(of: key), index + 1 < arguments.count else {
        return nil
      }
      return arguments[index + 1]
    }
    server = value("--server") ?? UserDefaults.standard.string(forKey: "server") ?? server
    room = value("--room") ?? room
    guest = value("--name") ?? guest
    driverRole = value("--driver") ?? ""
    automation = !driverRole.isEmpty
    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.pulse() }
    }
    if arguments.contains("--autojoin") {
      Task {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        join()
      }
    }
  }

  var local: Duelist? { state?.players.first { $0.id == playerID } }
  var opponent: Duelist? { state?.players.first { $0.id != playerID } }

  func join() {
    guard !connecting, !connected else { return }
    guard let url = URL(string: server),
      ["ws", "wss"].contains(url.scheme ?? ""), url.host != nil
    else {
      status = "Use ws://host:8787 or wss://host"
      return
    }
    connecting = true
    stopReconnect = false
    generation += 1
    let currentGeneration = generation
    socket?.cancel(with: .goingAway, reason: nil)
    let key = "\(server)|\(room.uppercased())"
    if UserDefaults.standard.string(forKey: "sessionRoom") == key {
      playerID = UserDefaults.standard.string(forKey: "peerID") ?? ""
      token = UserDefaults.standard.string(forKey: "peerToken") ?? ""
    } else {
      playerID = ""
      token = ""
      sequence = 0
    }
    status = "CONNECTING / \(room.uppercased())"
    UserDefaults.standard.set(server, forKey: "server")
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    send(JoinPacket(room: room.uppercased(), name: guest, id: playerID, token: token))
    receive(task, generation: currentGeneration)
    audio.start()
  }

  private func receive(_ task: URLSessionWebSocketTask, generation current: Int) {
    Task { [weak self] in
      do {
        let message = try await task.receive()
        guard let self, current == generation else { return }
        let data: Data
        switch message {
        case .string(let text): data = Data(text.utf8)
        case .data(let binary): data = binary
        @unknown default: return
        }
        handle(data)
        receive(task, generation: current)
      } catch {
        guard let self, current == generation, !stopReconnect else { return }
        connecting = false
        connected = false
        status = "SIGNAL LOST / RETRYING"
        scheduleReconnect()
      }
    }
  }

  private func handle(_ data: Data) {
    guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else { return }
    if envelope.type == "welcome" {
      playerID = envelope.id ?? ""
      token = envelope.token ?? ""
      sequence = max(sequence, (envelope.seq ?? -1) + 1)
      connecting = false
      connected = true
      inRoom = true
      lastStateDate = Date()
      status = "LIVE / \(room.uppercased())"
      UserDefaults.standard.set("\(server)|\(room.uppercased())", forKey: "sessionRoom")
      UserDefaults.standard.set(playerID, forKey: "peerID")
      UserDefaults.standard.set(token, forKey: "peerToken")
      autoReadyTick = 0
    } else if envelope.type == "state" {
      guard let next = try? JSONDecoder().decode(MatchState.self, from: data) else {
        status = "PROTOCOL ERROR / UPDATE BOTH PEERS"
        return
      }
      state = next
      lastStateDate = Date()
    } else if envelope.type == "error" {
      status = envelope.message ?? "Connection rejected"
      stopReconnect = true
      connecting = false
      inRoom = false
      connected = false
      socket?.cancel(with: .normalClosure, reason: nil)
    }
  }

  private func scheduleReconnect() {
    guard !stopReconnect, !retryPending else { return }
    retryPending = true
    Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      retryPending = false
      if !stopReconnect { join() }
    }
  }

  private func send<Packet: Encodable>(_ packet: Packet) {
    guard let socket, let data = try? JSONEncoder().encode(packet),
      let text = String(data: data, encoding: .utf8)
    else { return }
    socket.send(.string(text)) { _ in }
  }

  func press(_ name: String) {
    guard connected else { return }
    sequence += 1
    send(InputPacket(seq: sequence, held: held, press: name))
  }

  func setHeld(_ name: String, _ down: Bool) {
    switch name {
    case "left": held.left = down
    case "right": held.right = down
    case "guard": held.guard = down
    case "shield": held.shield = down
    default: break
    }
    press("")
  }

  func clearInput() {
    held = HeldInput()
    press("")
  }

  func ready() { send(CommandPacket(type: "ready")) }

  func reconnect() {
    clearInput()
    join()
  }

  func leave() {
    stopReconnect = true
    generation += 1
    socket?.cancel(with: .normalClosure, reason: nil)
    connecting = false
    connected = false
    inRoom = false
    state = nil
    status = "OFFLINE / LOCAL NETWORK"
    clearInput()
  }

  func toggleAudio() {
    muted.toggle()
    audio.muted = muted
  }

  func toggleDriver() {
    automation.toggle()
    if driverRole.isEmpty { driverRole = local?.slot == 1 ? "beta" : "alpha" }
    clearInput()
  }

  private func pulse() {
    guard connected else { return }
    if Date().timeIntervalSince(lastStateDate) > 5 {
      connected = false
      status = "SIGNAL TIMEOUT / RETRYING"
      scheduleReconnect()
      return
    }
    if automation { drive() }
    press("")
  }

  private func drive() {
    guard let state else { return }
    driverTick += 1
    if state.phase != lastPhase {
      lastPhase = state.phase
      phaseAge = 0
    }
    phaseAge += 1
    if state.phase == "lobby" {
      autoReadyTick += 1
      if autoReadyTick > 30, local?.ready == false { ready() }
      return
    }
    if state.phase == "result" {
      clearInput()
      if phaseAge > 70, state.matchNumber == 1, local?.ready == false { ready() }
      return
    }
    guard state.phase == "fight", let own = local, let other = opponent else { return }
    let delta = other.x - own.x
    let distance = abs(delta)
    let aggressive = driverRole != "beta"
    let phase = driverTick % 100
    held = HeldInput()
    if !aggressive && phase < 20 {
      held.shield = phase < 10
      held.guard = !held.shield
    } else if distance > (aggressive ? 78 : 115) {
      held.right = delta > 0
      held.left = delta < 0
    }
    if phase == 32 || (!aggressive && phase == 73) { press("jump") }
    if own.ascend && phase == 55 { press("shift") }
    if distance < 80 && phase % 27 == 0 { press("throw") }
    if own.meter >= 100 && distance < 205 && phase % 15 == 0 { press("ex") }
    if aggressive {
      if distance < 120 && driverTick % 5 == 0 { press("light") }
      if distance < 175 && driverTick % 5 == 2 { press("heavy") }
      if driverTick % 13 == 0 { press("special") }
    } else if phase >= 20 {
      if driverTick % 11 == 0 && distance < 180 { press("heavy") }
      if driverTick % 23 == 0 { press("special") }
    }
  }
}
