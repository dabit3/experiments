import Combine
import Foundation

@MainActor
final class DuelClient: ObservableObject {
  @Published var state: DuelState?
  @Published var status = "LOCAL NETWORK DUEL"
  @Published var connected = false
  @Published var playerID = ""
  @Published var serverAddress = "ws://127.0.0.1:8787"
  @Published var guestName = "Guest"
  @Published var roomCode = "AZURE"
  @Published var character = "seraph"
  @Published var automated = false
  @Published var driverStep = ""
  @Published var lastAction = ""
  @Published var showGuide = false
  let scene = BattleScene()
  private var socket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var heartbeat: AnyCancellable?
  private var token: String?
  private var joinedRoom = ""
  private var sequence = 0
  private var axis = 0.0
  private var guardHeld = false
  private var autoTick = 0
  private var phaseTick = 0
  private var previousPhase = ""
  private var nextAttack = 0
  private var driverRole = 0
  private var lastStateTime = Date.distantPast
  private var connectionGeneration = 0

  init() {
    scene.scaleMode = .aspectFit
    let args = ProcessInfo.processInfo.arguments
    func value(_ key: String) -> String? {
      guard let index = args.firstIndex(of: key), index + 1 < args.count else { return nil }
      return args[index + 1]
    }
    serverAddress = value("--server") ?? serverAddress
    guestName = value("--name") ?? guestName
    roomCode = value("--room") ?? roomCode
    character = value("--character") ?? character
    automated = args.contains("--autoplay")
    driverRole = Int(value("--driver") ?? "0") ?? 0
    heartbeat = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect().sink {
      [weak self] _ in
      self?.pulse()
    }
    if args.contains("--connect") || automated {
      Task { [weak self] in
        try? await Task.sleep(for: .seconds(0.8))
        self?.connect(create: true)
      }
    }
  }

  var me: FighterState? { state?.players.first { $0.id == playerID } }
  var inArena: Bool { state != nil && state?.phase != "lobby" }

  func connect(create: Bool) {
    guard let url = URL(string: serverAddress),
      ["ws", "wss"].contains(url.scheme ?? ""), url.host != nil
    else {
      status = "Enter a ws:// or wss:// server address"
      return
    }
    let normalized = roomCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if joinedRoom != normalized { token = nil }
    joinedRoom = normalized
    roomCode = normalized
    connectionGeneration += 1
    let generation = connectionGeneration
    receiveTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    connected = false
    sequence = 0
    axis = 0
    guardHeld = false
    status = "CONNECTING…"
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    send(
      Command(
        type: "join", version: 1, room: roomCode, name: guestName,
        character: character, create: create, token: token))
    receiveTask = Task { [weak self] in
      do {
        while !Task.isCancelled {
          let message = try await task.receive()
          let data: Data
          switch message {
          case .data(let bytes): data = bytes
          case .string(let text): data = Data(text.utf8)
          @unknown default: continue
          }
          guard let self, self.connectionGeneration == generation else { return }
          self.receive(data)
        }
      } catch {
        guard let self, self.connectionGeneration == generation, !Task.isCancelled else { return }
        self.connected = false
        self.status = "LINK LOST · TAP RECONNECT"
      }
    }
  }

  private func receive(_ data: Data) {
    do {
      let decoder = JSONDecoder()
      let envelope = try decoder.decode(Envelope.self, from: data)
      if envelope.type == "welcome" {
        playerID = envelope.id ?? ""
        token = envelope.token
        connected = true
        status = "CONNECTED · \(roomCode)"
        lastStateTime = Date()
      } else if envelope.type == "state" {
        let next = try decoder.decode(DuelState.self, from: data)
        state = next
        scene.render(next, localID: playerID)
        lastStateTime = Date()
        if next.phase != previousPhase {
          phaseTick = 0
          previousPhase = next.phase
          axis = 0
          guardHeld = false
          nextAttack = 0
          print(
            "AZURE_STATE phase=\(next.phase) tick=\(next.tick) round=\(next.round) match=\(next.match) winner=\(next.winner)"
          )
        }
      } else if envelope.type == "error" {
        status = envelope.message ?? "Connection rejected"
        connected = false
        socket?.cancel(with: .normalClosure, reason: nil)
        receiveTask?.cancel()
      }
    } catch {
      status = "Unsupported server response"
      print("AZURE_DECODE \(error.localizedDescription)")
    }
  }

  private func send(_ command: Command) {
    guard let socket, let data = try? JSONEncoder().encode(command),
      let text = String(data: data, encoding: .utf8)
    else { return }
    Task {
      do { try await socket.send(.string(text)) } catch { return }
    }
  }

  func select(_ choice: String) {
    character = choice
    if connected { send(Command(type: "select", character: choice)) }
  }

  func ready() { send(Command(type: "ready", ready: !(me?.ready ?? false))) }
  func rematch() { send(Command(type: "rematch")) }
  func move(_ value: Double) {
    axis = value
    sendInput()
  }
  func barrier(_ held: Bool) {
    guardHeld = held
    sendInput()
  }
  func action(_ action: String) {
    lastAction = action.uppercased()
    sendInput(action)
  }
  func setAutomation(_ enabled: Bool) {
    automated = enabled
    axis = 0
    guardHeld = false
    autoTick = 0
    nextAttack = 0
    sendInput()
  }
  func leave() {
    connectionGeneration += 1
    receiveTask?.cancel()
    socket?.cancel(with: .normalClosure, reason: nil)
    connected = false
    state = nil
    token = nil
    playerID = ""
    status = "LOCAL NETWORK DUEL"
    automated = false
    axis = 0
    guardHeld = false
    AudioEngine.shared.stopMusic()
  }

  private func sendInput(_ action: String? = nil) {
    guard connected else { return }
    sequence += 1
    send(Command(type: "input", seq: sequence, axis: axis, guardHeld: guardHeld, action: action))
  }

  private func pulse() {
    guard connected else { return }
    if Date().timeIntervalSince(lastStateTime) > 4 {
      status = "SERVER STALLED · RECONNECT"
    }
    phaseTick += 1
    autoTick += 1
    if automated { drive() }
    sendInput()
  }

  private func drive() {
    guard let state, let me else { return }
    if state.paused {
      driverStep = "PAUSED · WAITING FOR PEER"
      return
    }
    if state.phase == "lobby" {
      driverStep = "01  DISTINCT GUESTS → SAME ROOM → READY"
      if phaseTick == 45 && !me.ready { ready() }
      if phaseTick > 45 && phaseTick % 40 == 0 && !me.ready { ready() }
      return
    }
    if state.phase == "result" {
      driverStep = "04  SHARED RESULT · \(state.winner == me.id ? "VICTORY" : "DEFEAT")"
      axis = 0
      guardHeld = false
      if state.match == 1 && phaseTick == 120 { rematch() }
      return
    }
    guard state.phase == "fight", let opponent = state.players.first(where: { $0.id != me.id })
    else {
      driverStep = state.match > 1 ? "05  REMATCH · SAME TWO PEERS" : "02  ROUND CLOCK SYNCHRONIZED"
      return
    }
    let distance = abs(opponent.x - me.x)
    let direction = opponent.x >= me.x ? 1.0 : -1.0
    let cycle = phaseTick % 200
    guardHeld = driverRole == 1 && cycle >= 65 && cycle < 92
    axis = distance > (character == "lyra" ? 145 : 105) ? direction : 0
    if guardHeld { axis = 0 }
    driverStep =
      state.match > 1
      ? "05  REMATCH · LIVE NETWORK INPUT" : "03  MOVE / AIR / CHAIN / DRIVE / SUPER"
    if phaseTick == 18 { action("jump") }
    if phaseTick == 23 { action("jump") }
    if phaseTick == 28 { action("dash") }
    if phaseTick > 40 && phaseTick % 230 == 0 { action("jump") }
    if phaseTick > 40 && phaseTick % 230 == 6 { action("dash") }
    if phaseTick % (driverRole == 0 ? 5 : 12) == 0 && !guardHeld {
      if me.heat >= 50 && distance < 390 {
        action("super")
      } else if distance < 200 {
        let chain = ["light", "medium", "heavy", "drive"]
        action(chain[nextAttack % chain.count])
        nextAttack += 1
      } else if character == "lyra" && distance < 700 {
        action("drive")
      } else if distance > 400 && phaseTick % 30 == 0 {
        action("dash")
      }
    }
  }

  func handle(_ url: URL) {
    guard url.scheme == "azureparadox" else { return }
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let actionName = components?.queryItems?.first { $0.name == "action" }?.value ?? url.host ?? ""
    switch actionName {
    case "ready": ready()
    case "rematch": rematch()
    case "reconnect": connect(create: false)
    case "auto-on": setAutomation(true)
    case "auto-off": setAutomation(false)
    case "left": move(-1)
    case "right": move(1)
    case "neutral":
      move(0)
      barrier(false)
    case "guard": barrier(true)
    case "jump", "dash", "light", "medium", "heavy", "drive", "super": action(actionName)
    default: break
    }
  }
}
