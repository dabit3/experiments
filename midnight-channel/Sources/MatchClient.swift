import Combine
import Foundation

@MainActor
final class MatchClient: ObservableObject {
  @Published var state: MatchState?
  @Published var playerID = ""
  @Published var status = "OFF AIR"
  @Published var error = ""
  @Published var serverAddress = "ws://127.0.0.1:8794"
  @Published var guestName = "Guest"
  @Published var roomCode = "NITE"
  @Published var connected = false
  @Published var automated = false
  @Published var automationStep = ""
  @Published var muted = false
  let scene = ArenaScene()
  private var socket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var heartbeat: Timer?
  private var reconnectTask: Task<Void, Never>?
  private var seq = 0
  private var axis = 0.0
  private var guardHeld = false
  private var token = ""
  private var intentionalClose = false
  private var autoRole = ""
  private var autoCount = 0
  private var readyWait = 0
  private var lastEvent = 0
  private var lastPhase = ""
  private var joinGeneration = 0
  private let audio = GameAudio()
  private var evidence: FileHandle?
  var me: FighterState? { state?.fighters.first { $0.id == playerID } }

  init() {
    let args = ProcessInfo.processInfo.arguments
    func argument(_ key: String) -> String? {
      guard let index = args.firstIndex(of: key), index + 1 < args.count else { return nil }
      return args[index + 1]
    }
    serverAddress =
      argument("-server") ?? UserDefaults.standard.string(forKey: "server") ?? serverAddress
    roomCode = argument("-room") ?? roomCode
    guestName = argument("-name") ?? guestName
    autoRole = argument("-autoplay") ?? ""
    automated = !autoRole.isEmpty
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let logURL = documents.appendingPathComponent("match-evidence.jsonl")
    FileManager.default.createFile(atPath: logURL.path, contents: nil)
    evidence = try? FileHandle(forWritingTo: logURL)
    heartbeat = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.pulse() }
    }
    if automated || args.contains("-autoconnect") {
      Task {
        try? await Task.sleep(for: .seconds(1))
        connect()
      }
    }
  }

  func connect() {
    guard let url = URL(string: serverAddress),
      ["ws", "wss"].contains(url.scheme ?? ""), url.host != nil
    else {
      error = "Enter a ws:// or wss:// server address."
      return
    }
    let code = roomCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    guard code.range(of: "^[A-Z0-9]{4,8}$", options: .regularExpression) != nil else {
      error = "Room codes need 4–8 letters or digits."
      return
    }
    roomCode = code
    joinGeneration += 1
    let generation = joinGeneration
    receiveTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    intentionalClose = false
    error = ""
    status = "TUNING IN…"
    UserDefaults.standard.set(serverAddress, forKey: "server")
    let key = "\(serverAddress)/\(roomCode)"
    playerID = UserDefaults.standard.string(forKey: "\(key)/id") ?? ""
    token = UserDefaults.standard.string(forKey: "\(key)/token") ?? ""
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    send(ClientMessage(type: "join", code: code, name: guestName, playerID: playerID, token: token))
    receiveTask = Task { [weak self] in
      do {
        while !Task.isCancelled {
          let message = try await task.receive()
          guard let self, self.joinGeneration == generation else { return }
          let data: Data
          switch message {
          case .data(let value): data = value
          case .string(let value): data = Data(value.utf8)
          @unknown default: continue
          }
          self.handle(data)
        }
      } catch {
        guard let self, self.joinGeneration == generation, !self.intentionalClose else { return }
        self.connected = false
        self.status = "SIGNAL LOST • RECONNECTING"
        self.reconnectTask = Task {
          try? await Task.sleep(for: .seconds(2))
          if !Task.isCancelled && !self.intentionalClose { self.connect() }
        }
      }
    }
    audio.start()
  }

  private func handle(_ data: Data) {
    let decoder = JSONDecoder()
    guard let envelope = try? decoder.decode(ServerMessage.self, from: data) else { return }
    if envelope.type == "welcome", let id = envelope.playerID, let resume = envelope.token {
      playerID = id
      token = resume
      seq = envelope.lastSeq ?? 0
      let key = "\(serverAddress)/\(roomCode)"
      UserDefaults.standard.set(id, forKey: "\(key)/id")
      UserDefaults.standard.set(resume, forKey: "\(key)/token")
      connected = true
      status = "LIVE"
      log([
        "event": "welcome", "playerID": id, "room": roomCode, "slot": String(envelope.slot ?? -1),
      ])
    } else if envelope.type == "error" {
      error = envelope.message ?? "Server error"
      status = "CHECK SIGNAL"
      leave(keepError: true)
    } else if envelope.type == "state",
      let incoming = try? decoder.decode(MatchState.self, from: data)
    {
      state = incoming
      scene.apply(incoming, localID: playerID)
      if lastPhase != incoming.phase {
        lastPhase = incoming.phase
        readyWait = 0
        log([
          "event": "phase", "phase": incoming.phase, "match": String(incoming.match),
          "tick": String(incoming.tick), "winner": incoming.winner, "round": String(incoming.round),
          "peers": incoming.fighters.map(\.id).joined(separator: ","),
        ])
      }
      if incoming.tick % 60 < 2 {
        try? evidence?.write(contentsOf: data + Data([10]))
      }
      for event in incoming.events where event.id > lastEvent {
        audio.effect(event.kind)
        log([
          "event": event.kind, "id": String(event.id), "tick": String(event.tick),
          "player": event.player, "target": event.target ?? "", "damage": String(event.damage ?? 0),
        ])
        lastEvent = max(lastEvent, event.id)
      }
    }
  }

  func sendInput(_ action: String = "", source: String = "touch") {
    guard connected else { return }
    seq += 1
    send(ClientMessage(type: "input", seq: seq, axis: axis, guardHeld: guardHeld, action: action))
    if !action.isEmpty {
      log([
        "event": "input", "source": source, "action": action, "seq": String(seq),
        "player": playerID,
      ])
    }
  }

  func holdAxis(_ value: Double) {
    axis = value
    sendInput()
  }
  func holdGuard(_ value: Bool) {
    guardHeld = value
    sendInput()
  }
  func ready() {
    send(ClientMessage(type: "ready"))
    log(["event": "ready", "player": playerID])
  }
  func toggleMute() {
    muted.toggle()
    audio.muted = muted
  }

  func leave(keepError: Bool = false) {
    intentionalClose = true
    reconnectTask?.cancel()
    receiveTask?.cancel()
    socket?.cancel(with: .normalClosure, reason: nil)
    connected = false
    state = nil
    axis = 0
    guardHeld = false
    lastEvent = 0
    lastPhase = ""
    if !keepError {
      error = ""
      status = "OFF AIR"
    }
  }

  func reconnect() {
    status = "RECONNECTING"
    connected = false
    connect()
  }

  func handleURL(_ url: URL) {
    guard url.scheme == "midnightchannel" else { return }
    let values = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    func value(_ key: String) -> String { values.first { $0.name == key }?.value ?? "" }
    if url.host == "input" {
      automated = false
      axis = Double(value("axis")) ?? 0
      guardHeld = value("guard") == "1"
      sendInput(value("action"), source: "automation-url")
    } else if url.host == "ready" {
      ready()
    } else if url.host == "reconnect" {
      reconnect()
    } else if url.host == "autoplay" {
      autoRole = value("role")
      automated = !autoRole.isEmpty
    }
  }

  private func pulse() {
    if automated { drive() }
    if state?.phase == "fight" { sendInput("", source: automated ? "automated-driver" : "touch") }
  }

  private func drive() {
    guard let state, let me, connected, !state.paused else { return }
    if ["lobby", "result"].contains(state.phase) {
      readyWait += 1
      automationStep =
        state.phase == "result" ? "ASSERT SHARED RESULT → REMATCH" : "JOIN SAME ROOM → BOTH READY"
      if state.fighters.count == 2 && !me.ready && readyWait > (state.phase == "result" ? 80 : 30)
        && state.match < 2
      {
        ready()
      }
      return
    }
    guard state.phase == "fight", let other = state.fighters.first(where: { $0.id != playerID })
    else { return }
    autoCount += 1
    let distance = abs(me.x - other.x)
    axis = distance > 92 ? (other.x > me.x ? 1 : -1) : 0
    guardHeld = false
    let cycle = autoCount % 100
    let aggressive = autoRole == "alpha"
    automationStep = "AUTOMATED INPUT • \(aggressive ? "PRESSURE / COMPANION" : "GUARD / COUNTER")"
    if me.stun > 0 && me.burst >= 100 && me.hp < 760 {
      sendInput("burst", source: "automated-driver")
    } else if !aggressive && cycle < 12 {
      guardHeld = true
      axis = 0
    } else if autoCount % (aggressive ? 87 : 65) == 0 {
      sendInput("jump", source: "automated-driver")
    } else if me.meter >= 50 && distance < 390 && autoCount % 9 == 0 {
      sendInput("super", source: "automated-driver")
    } else if autoCount % (aggressive ? 13 : 26) == 0 {
      sendInput("summon", source: "automated-driver")
    } else if distance < 160 && autoCount % (aggressive ? 5 : 18) == 0 {
      sendInput(autoCount % 3 == 0 ? "heavy" : "light", source: "automated-driver")
    }
  }

  private func send(_ message: ClientMessage) {
    guard let data = try? JSONEncoder().encode(message),
      let text = String(data: data, encoding: .utf8)
    else { return }
    socket?.send(.string(text)) { _ in }
  }

  private func log(_ fields: [String: String]) {
    guard let data = try? JSONEncoder().encode(fields) else { return }
    try? evidence?.write(contentsOf: data + Data([10]))
  }
}
